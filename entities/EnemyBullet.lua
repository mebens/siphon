EnemyBullet = class("EnemyBullet", PhysicalEntity)
EnemyBullet.SPEED = 600

EnemyBullet.width = 16
EnemyBullet.height = 2
EnemyBullet.image = getRectImage(EnemyBullet.width, EnemyBullet.height)

EnemyBullet.CLIGHT_RADIUS = 40
EnemyBullet.RLIGHT_HEIGHT = 30
EnemyBullet.CLIGHT_IMAGE = Light.createCircularImage(EnemyBullet.CLIGHT_RADIUS)
EnemyBullet.RLIGHT_IMAGE = Light.createRectImage(EnemyBullet.width, EnemyBullet.RLIGHT_HEIGHT)
EnemyBullet.color = MAGENTA --{1, 0.8, 0}

function EnemyBullet:initialize(x, y, angle, damage)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 6
  self.angle = angle
  self.damage = damage

  self.clight = Light:new(EnemyBullet.CLIGHT_IMAGE, self.x, self.y, EnemyBullet.CLIGHT_RADIUS, 0.6)
  self.clight.color = self.color
  self.rlight = Light:new(EnemyBullet.RLIGHT_IMAGE, self.x - self.width / 2, self.y - self.height / 2, EnemyBullet.RLIGHT_HEIGHT, 0.6)
  self.rlight.color = self.color
  self.rlight.type = "rect"
  self.rlight.angle = angle

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 300)
  ps:setSpread(math.tau / 32)
  ps:setDirection((angle + math.tau / 2) % math.tau)
  ps:setLinearDamping(0.5)
  -- ps:setColors(1, 0.8, 0, 1, 1, 0.8, 0, 0.7, 1, 0.8, 0, 0)
  ps:setColors(243/255, 11/255, 159/255, 1, 243/255, 11/255, 159/255, 0.7, 243/255, 11/255, 159/255, 0)
  ps:setParticleLifetime(2, 3)
  ps:setSizes(0.5, 0.1)
  ps:setSizeVariation(0.5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(100)
  -- ps:setRadialAcceleration(-math.tau / 2, math.tau / 2)
  ps:setSpeed(5, 100)
  ps:setLinearAcceleration(math.cos(angle) * 10, math.sin(angle) * 10, math.cos(angle) * 50, math.sin(angle) * 50)
  ps:setPosition(x, y)
  self.trailPS = ps
end

function EnemyBullet:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(3, 5)
  self.world:add(self.clight, self.rlight)
end

function EnemyBullet:update(dt)
  self.trailPS:setPosition(self.x, self.y)
  self.trailPS:update(dt)

  if self.dead then
    if self.trailPS:getCount() == 0 then
      self.world = nil
    end

    return
  end

  PhysicalEntity.update(self, dt)
  self.velx = self.SPEED * math.cos(self.angle)  
  self.vely = self.SPEED * math.sin(self.angle)  
  self.clight.x = self.x
  self.clight.y = self.y
  self.rlight.x = self.x - self.width / 2
  self.rlight.y = self.y - self.height / 2
end

function EnemyBullet:draw()
  love.graphics.draw(self.trailPS)

  if not self.dead then
    self:drawImage()
  end
end

function EnemyBullet:collided(other)
  if other:isInstanceOf(Player) and not self.dead then
    other:damage(self.damage)
  elseif other:isInstanceOf(Rocket) then
    other:explode()
  end

  self:die()
end

function EnemyBullet:die()
  self:destroy()
  self.trailPS:stop()
  self.world:remove(self.clight, self.rlight)
  self.dead = true
end
