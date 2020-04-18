Enemy = class("Enemy", PhysicalEntity)
Enemy.static.all = LinkedList:new("_nextEnemy", "_prevEnemy")

Enemy.BASE_HEALTH = 100
Enemy.MELEE_DAMAGE = 25
Enemy.MELEE_COOLDOWN = 1
Enemy.width = 12
Enemy.height = 12
Enemy.image = getRectImage(12, 12, 255, 0, 0)

function Enemy:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 5
  self.health = Enemy.BASE_HEALTH
  self.draining = false
  self.speed = 70
  self.meleeTimer = 0
end

function Enemy:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(3)
  Enemy.all:push(self)
end

function Enemy:removed()
  self:destroy()
  Enemy.all:remove(self)
end

function Enemy:update(dt)
  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  if self.meleeTimer > 0 then
    self.meleeTimer = self.meleeTimer - dt
  end

  if not self.draining then
    self:attackRoutine(dt)
  end
end

function Enemy:attackRoutine(dt)
  self.angle = math.angle(self.x, self.y, self.world.player.x, self.world.player.y)
  self.velx = math.cos(self.angle) * self.speed
  self.vely = math.sin(self.angle) * self.speed
end

function Enemy:draw()
  self:drawImage()
end

function Enemy:collided(other)
  if other:isInstanceOf(Player) then
    if self.meleeTimer <= 0 then
      self:meleeAttack()
    end
  end
end

function Enemy:meleeAttack()
  self.world.player:damage(self.MELEE_DAMAGE)
  self.meleeTimer = self.MELEE_COOLDOWN
end

function Enemy:damage(amount)
  self.health = self.health - amount

  if self.health <= 0 then
    self:die()
  end
end

function Enemy:die()
  self.dead = true
  self.world = nil
end

function Enemy:isTarget()
  self.draining = true
  self.velx = 0
  self.vely = 0
end

function Enemy:isNotTarget()
  self.draining = false
end
