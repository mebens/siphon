Rocket = class("Rocket", PhysicalEntity)
Rocket.SPEED = 400
Rocket.DIRECT_DAMAGE = 130
Rocket.MIN_DAMAGE = 30
Rocket.SPLASH_RADIUS = 100

Rocket.LIGHT_RADIUS = 200
Rocket.LIGHT_IMAGE = Light.createCircularImage(Rocket.LIGHT_RADIUS, 2)

Rocket.width = 10
Rocket.height = 3

function Rocket:initialize(x, y, angle)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 6
  self.image = assets.images.rocket
  self.angle = angle
  self.dead = false

  self.light = Light:new(Rocket.LIGHT_IMAGE, self.x, self.y, Rocket.LIGHT_RADIUS, 0.8)
  self.light.color = WHITE

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 1000)
  ps:setPosition(x, y)
  ps:setSpread(math.tau / 16)
  ps:setDirection((angle + math.tau / 2) % math.tau)
  ps:setLinearDamping(5, 10)
  ps:setColors(1, 1, 1, 0.6, 1, 1, 1, 0.2, 1, 1, 1, 0)
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

function Rocket:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setCategory(4)
  self.fixture:setMask(2, 4)
  self.world:shake(2, 0.4)
  self.world:add(self.light)
end

function Rocket:update(dt)
  self.smokePS:update(dt)
  self.emberPS:update(dt)
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
  self.smokePS:moveTo(self.x, self.y)
  self.emberPS:moveTo(self.x, self.y)
end

function Rocket:draw()
  love.graphics.draw(self.smokePS)
  love.graphics.draw(self.emberPS)

  if not self.dead then
    self:drawImage()
  end
end

function Rocket:explode()
  -- particles
  self.smokePS:setLinearDamping(2,3)
  self.smokePS:setSpread(math.tau)
  self.smokePS:setSpeed(400)
  self.smokePS:setParticleLifetime(1.5, 2.5)
  self.smokePS:emit(800)
  self.smokePS:stop()
  self.emberPS:setSpeed(100, 500)
  self.emberPS:setSpread(math.tau)
  self.emberPS:emit(300)
  self.emberPS:stop()
  self:destroy()
  self.world:remove(self.light)

  -- floor highlights
  self.world.floor:addHighlight(self.x, self.y, 1, chooseColor(math.random(1, 2)))

  for radiusI = 1, 7 do
    delay(0.06 * radiusI, function()
      for angleI = 0, 39 do
        local angle = math.tau * (angleI / 40)
        local radius = radiusI * TILE_SIZE
        self.world.floor:addHighlight(
          self.x + math.cos(angle) * radius,
          self.y + math.sin(angle) * radius,
          math.min(0.3 + 0.7 * (7 - radiusI) / 5, 1),
          chooseColor(math.random(1, 2))
        )
      end
    end)
  end

  -- shake camera
  local maxShake = 16
  local minShake = 2
  self.world:shake(math.clamp(
    math.scale(math.dist(self.x, self.y, self.world.player.x, self.world.player.y), 30, 300, maxShake, minShake),
    minShake,
    maxShake
  ), 0.7)

  -- damage enemies
  for e in Enemy.all:iterate() do
    local dist = math.dist(self.x, self.y, e.x, e.y)

    if dist < Rocket.SPLASH_RADIUS then
      e:damage(
        math.scale(dist, 5, self.SPLASH_RADIUS, self.DIRECT_DAMAGE, self.MIN_DAMAGE),
        math.angle(self.x, self.y, e.x, e.y)
      )
    end
  end

  -- destroy bombs
  for b in EnemyBomb.all:iterate() do
    local dist = math.dist(self.x, self.y, b.x, b.y)

    if dist < Rocket.SPLASH_RADIUS then
      b:explode()
    end
  end

  playRandom{"explosion1", "explosion2", "explosion3", "explosion4"}
  self.dead = true
end

function Rocket:collided(other)
  self:explode()

  if other:isInstanceOf(Enemy) then
    other:damage(self.DIRECT_DAMAGE, self.angle)
  end
end 
