Enemy = class("Enemy", PhysicalEntity)
Enemy.ACTIVATE_RANGE = 450
Enemy.MELEE_COOLDOWN = 1
Enemy.DEATH_BLOOD = 1
Enemy.DEATH_BLOOD_SCATTER = 6

function Enemy.static.fromData(enemy)
  if enemy.values.type == "RUSHER" then
    return EnemyRusher:new(enemy.x, enemy.y)
  elseif enemy.values.type == "SNIPER" then
    return EnemySniper:new(enemy.x, enemy.y)
  elseif enemy.values.type == "TANK" then
    return EnemyTank:new(enemy.x, enemy.y)
  end
end

function Enemy.static.killAll(enemy)
  for e in Enemy.all:iterate() do
    e.world = nil
  end

  Enemy.resetList()
end

function Enemy.static.resetList()
  Enemy.all = LinkedList:new("_nextEnemy", "_prevEnemy")
end

Enemy.resetList()

function Enemy:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.initialX = x
  self.initialY = y
  self.layer = 5
  self.scale = 1
  self.health = self.BASE_HEALTH
  self.draining = false
  self.meleeTimer = 0
  self.shootTimer = 0
  self.activated = false
end

function Enemy:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(3)
  Enemy.all:push(self)
end

function Enemy:update(dt)
  if self.dead then
    return
  end

  if not self.activated then
    if math.dist(self.x, self.y, self.world.player.x, self.world.player.y) < Enemy.ACTIVATE_RANGE then
      self.activated = true
    else
      return
    end
  end

  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  if self.map then
    self.map:update(dt)
  end

  if self.meleeTimer > 0 then
    self.meleeTimer = self.meleeTimer - dt
  end

  if self.shootTimer > 0 then
    self.shootTimer = self.shootTimer - dt
  end

  if not self.draining then
    self:attackRoutine(dt)
  end
end

function Enemy:attackRoutine(dt) end

function Enemy:draw()
  if self.map then
    self.map:draw(self.x, self.y, self.angle, self.scale, self.scale, self.originX or self.width / 2, self.originY or self.height / 2)
  elseif self.image then
    self:drawImage()
  end
end

function Enemy:collided(other)
  if other:isInstanceOf(Player) then
    if self.meleeTimer <= 0 then
      self:meleeAttack()
    end
  end
end

function Enemy:meleeAttack()
  self.world.player:damage(self.MELEE_DAMAGE, math.angle(self.x, self.y, self.world.player.x, self.world.player.y))
  self.meleeTimer = self.MELEE_COOLDOWN
end

function Enemy:damage(amount, angle)
  self.health = self.health - amount

  if not self.draining then
    self.world:add(BloodSpurt:new(self.x, self.y, angle, 2))
  end

  if self.health <= 0 then
    self:die()
  end
end

function Enemy:die()
  if self.dead then return end

  for i = 1, self.DEATH_BLOOD do
    self.world:add(BloodSpurt:new(self.x, self.y, math.tau * math.random(), self.DEATH_BLOOD_SCATTER, self.DEATH_BLOOD_SCATTER, 1))
  end

  playSound("splat")
  self.dead = true
  self.world = nil
  self:destroy()
  Enemy.all:remove(self)
end

function Enemy:isTarget()
  self.draining = true
  self.velx = 0
  self.vely = 0
end

function Enemy:isNotTarget()
  self.draining = false
end
