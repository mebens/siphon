EnemyBomb = class("EnemyBomb", PhysicalEntity)
EnemyBomb.static.all = LinkedList:new("_nextBomb", "_prevBomb")
EnemyBomb.SPEED = 800
EnemyBomb.DIRECT_DAMAGE = 25
EnemyBomb.MIN_DAMAGE = 5
EnemyBomb.SPLASH_RADIUS = 40

EnemyBomb.radius = 12
EnemyBomb.color = MAGENTA

EnemyBomb.LIGHT_RADIUS = 40
EnemyBomb.LIGHT_IMAGE = Light.createCircularImage(EnemyBomb.LIGHT_RADIUS)

function EnemyBomb:initialize(x, y, angle, damage)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 6
  self.width = 12
  self.height = 12
  self.angle = angle
  self.damage = damage
  self.image = assets.images.bomb

  self.light = Light:new(EnemyBomb.LIGHT_IMAGE, self.x, self.y, EnemyBomb.LIGHT_RADIUS, 0.6)
  self.light.color = self.color

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 1000)
  ps:setPosition(x, y)
  ps:setSpread(math.tau / 16)
  ps:setDirection((angle + math.tau / 2) % math.tau)
  ps:setLinearDamping(5, 10)
  ps:setColors(243/255, 11/255, 159/255, 1, 243/255, 11/255, 159/255, 0.7, 243/255, 11/255, 159/255, 0)
  ps:setParticleLifetime(0.8, 1.2)
  ps:setSizes(1, 0.8)
  ps:setSizeVariation(0.5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(100)
  ps:setSpeed(300)
  ps:start()
  self.smokePS = ps

  ps = love.graphics.newParticleSystem(assets.images.tinyParticle, 500)
  ps:setPosition(x, y)
  ps:setSpread(math.tau / 16)
  ps:setDirection((angle + math.tau / 2) % math.tau)
  ps:setLinearDamping(1, 1.5)
  ps:setColors(243/255, 11/255, 159/255, 1, 243/255, 11/255, 159/255, 0.7, 243/255, 11/255, 159/255, 0)
  ps:setParticleLifetime(0.5, 2.5)
  ps:setSizes(1.2, 1, 0.5)
  ps:setSizeVariation(0.5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(60)
  ps:setTangentialAcceleration(-10, 10)
  ps:setSpeed(100)
  ps:start()
  self.emberPS = ps
end

function EnemyBomb:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newCircleShape(self.radius))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(3, 5)
  self.world:add(self.light)
  EnemyBomb.all:push(self)
end

function EnemyBomb:update(dt)
  self.smokePS:update(dt)
  self.emberPS:update(dt)
  self.smokePS:setPosition(self.x, self.y)
  self.emberPS:setPosition(self.x, self.y)
  self.light.x = self.x
  self.light.y = self.y

  if self.dead then
    if self.smokePS:getCount() == 0 and self.emberPS:getCount() == 0 then
      self.world = nil
    end

    return
  end

  PhysicalEntity.update(self, dt)
  self.velx = self.SPEED * math.cos(self.angle)  
  self.vely = self.SPEED * math.sin(self.angle)  
  self.light.x = self.x
  self.light.y = self.y
end

function EnemyBomb:draw()
  love.graphics.draw(self.smokePS)
  love.graphics.draw(self.emberPS)

  if not self.dead then
    self:drawImage()
  end
end

function EnemyBomb:collided(other)
  if other:isInstanceOf(Player) and not self.dead then
    other:damage(self.DIRECT_DAMAGE, self.angle)
  elseif other:isInstanceOf(Rocket) then
    other:explode()
  end

  self:explode()
end

function EnemyBomb:explode()
  if self.dead then return end
  self.smokePS:setLinearDamping(2,3)
  self.smokePS:setSpread(math.tau)
  self.smokePS:setSpeed(250)
  self.smokePS:setParticleLifetime(1.5, 2.5)
  self.smokePS:emit(800)
  self.smokePS:stop()
  self.emberPS:setSpeed(100, 500)
  self.emberPS:setSpread(math.tau)
  self.emberPS:emit(300)
  self.emberPS:stop()
  self:destroy()
  self.world:remove(self.light)
  EnemyBomb.all:remove(self)

  -- floor highlights
  self.world.floor:addHighlight(self.x, self.y)

  for radiusI = 1, 4 do
    delay(0.06 * radiusI, function()
      for angleI = 0, 39 do
        local angle = math.tau * (angleI / 40)
        local radius = radiusI * TILE_SIZE
        self.world.floor:addHighlight(
          self.x + math.cos(angle) * radius,
          self.y + math.sin(angle) * radius,
          math.min(0.3 + 0.7 * (4 - radiusI) / 3, 1),
          chooseColor(math.random(0, 1) == 0 and 1 or 3)
        )
      end
    end)
  end

  -- shake camera
  local maxShake = 10
  local minShake = 2
  self.world:shake(math.clamp(
    math.scale(math.dist(self.x, self.y, self.world.player.x, self.world.player.y), 20, 300, maxShake, minShake),
    minShake,
    maxShake
  ), 0.7)


  local dist = math.dist(self.x, self.y, self.world.player.x, self.world.player.y)

  if dist < self.SPLASH_RADIUS then
    self.world.player:damage(
      math.min(math.scale(dist, 5, self.SPLASH_RADIUS, self.DIRECT_DAMAGE, self.MIN_DAMAGE), self.DIRECT_DAMAGE),
      math.angle(self.x, self.y, self.world.player.x, self.world.player.y)
    )
  end

  playRandom{"explosion1", "explosion2", "explosion3", "explosion4"}
  self.dead = true
end
