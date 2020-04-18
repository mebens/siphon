Player = class("Player", PhysicalEntity)
Player.SPEED = 3000 * 60
Player.BASE_HEALTH = 100
Player.HEALTH_DRAIN = 2

Player.LS_RATE = 35
Player.LS_CONVERSION = 0.5
Player.LS_MOVEMENT = 0.1
Player.LS_RANGE = 100
Player.LS_SPREAD = math.tau * 0.4
Player.LS_COOLDOWN = 2

Player.width = 12
Player.height = 12
Player.image = getRectImage(Player.width, Player.height)

Player.WEAPONS = {
  {index=1, name="Railgun", attackTime=0.8, swapTime=0.4, class=Rail},
  {index=2, name="Rocket", attackTime=1.2, swapTime=0.5, class=Rocket},
  -- {index=3, name="Blade", attackTime=0.5, swapTime=0.5, damage=60},
}

Player.LS_LIGHT_HEIGHT = 50
Player.LS_LIGHT = Light.createRectImage(Player.LS_RANGE, Player.LS_LIGHT_HEIGHT)

function Player:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 4

  -- initial state
  self.health = self.BASE_HEALTH
  self:swapWeapon(1)

  -- timers
  self.swapTimer = 0
  self.attackTimer = 0
  self.lsCooldownTimer = 0

  -- particles
  local ps = love.graphics.newParticleSystem(assets.images.smoke, 500)
  ps:setSpeed(100, 150)
  ps:setEmitterLifetime(-1)
  ps:setParticleLifetime(0.5, 0.7)
  ps:setColors(63/255, 209/255, 232/255, 1, 63/255, 209/255, 232/255, 0.8, 63/255, 209/255, 232/255, 0.2)
  ps:setSizes(0.6, 1.2, 2)
  ps:setSpread(0)
  ps:setEmissionRate(80)
  ps:setEmissionArea("normal", 4, 4)
  ps:stop()
  self.lsSmokePS = ps

  ps = love.graphics.newParticleSystem(assets.images.tinyParticle, 1000)
  ps:setSpeed(0)
  ps:setTangentialAcceleration(2)
  ps:setParticleLifetime(2, 3)
  ps:setEmissionArea("normal", 2, 2)
  ps:setEmissionRate(150)
  ps:setColors(63/255, 209/255, 232/255, 1, 63/255, 209/255, 232/255, 0.8, 63/255, 209/255, 232/255, 0.2)
  ps:setSizes(0.6, 1, 0.6)
  ps:setSpread(math.tau)
  ps:setRadialAcceleration(-10)
  ps:stop()
  self.lsWhirlPS = ps
  self.lsWhirlAngle = 0

  self.lsLight = Light:new(self.LS_LIGHT, self.x, self.y, self.LS_LIGHT_HEIGHT / 2)
  self.lsLight.type = "rect"
  self.lsLight.color = CYAN
  self.lsLight.flicker = 0.8
end

function Player:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(2)
  self:setMass(1)
  self:setLinearDamping(12)
end

function Player:update(dt)
  PhysicalEntity.update(self, dt)
  self.lsSmokePS:update(dt)
  self.lsWhirlPS:update(dt)
  self:setAngularVelocity(0)

  -- movement
  self.angle = math.angle(self.x, self.y, mouseCoords())
  local dir = self:getDirection()
  if dir then
    local speed = self.SPEED
    if self.lsTarget then speed = speed * self.LS_MOVEMENT end
    self:applyForce(speed * math.cos(dir) * dt, speed * math.sin(dir) * dt)
  end

  -- health drain
  self:damage(self.HEALTH_DRAIN * dt)
  -- self.health = self.health - self.HEALTH_DRAIN * dt

  -- life steal
  if self.lsCooldownTimer > 0 then
    self.lsCooldownTimer = self.lsCooldownTimer - dt
  end

  if input.down("lifesteal") then
    self:lifeSteal(dt)
  elseif self.lsTarget then
    self:endLifeSteal()
  end

  -- weapon swap
  if input.pressed("nextwep") then
    self:swapWeapon(self.weapon.index + 1)
  elseif input.pressed("prevwep") then
    self:swapWeapon(self.weapon.index - 1)
  end

  if self.swapTimer > 0 then
    self.swapTimer = self.swapTimer - dt
    return -- can't do anything else if swapping
  end

  -- attack
  if not self.lsTarget then
    if self.attackTimer > 0 then
      self.attackTimer = self.attackTimer - dt
    elseif input.down("shoot") then
      self:attack(dt)
    end
  end
end

function Player:draw()
  if self.lsTarget then
    love.graphics.line(self.x, self.y, self.lsTarget.x, self.lsTarget.y)
  end

  love.graphics.draw(self.lsSmokePS)
  love.graphics.draw(self.lsWhirlPS)
  self:drawImage()
end

function Player:attack(dt)
  if self.weapon.class then
    self.world:add(self.weapon.class:new(self.x, self.y, self.angle))
  end

  self.attackTimer = self.weapon.attackTime
end

function Player:damage(amount)
  self.health = self.health - amount

  if self.health <= 0 then
    self:die()
  end
end

function Player:die()
  DEBUG = "oh shid"
end

function Player:lifeSteal(dt)
  if not self.lsTarget and self.lsCooldownTimer <= 0 then
    self:startLifeSteal()
  end

  if self.lsTarget then
    self.lsSmokePS:setPosition(self.lsTarget.x, self.lsTarget.y)
    self.lsSmokePS:setDirection(math.angle(self.lsTarget.x, self.lsTarget.y, self.x, self.y))
    self.lsWhirlAngle = self.lsWhirlAngle + math.tau * 3 * dt 

    local whirlDist = math.scale(self.lsTarget.health, 0, Enemy.BASE_HEALTH, 3, 35)
    self.lsWhirlPS:setPosition(
      self.x + math.cos(self.lsWhirlAngle) * whirlDist,
      self.y + math.sin(self.lsWhirlAngle) * whirlDist
    )

    self:updateLSLight()

    self.lsTarget:damage(self.LS_RATE * dt)
    self.health = self.health + self.LS_RATE * self.LS_CONVERSION * dt
    self.world:shake(1)

    if self.lsTarget.dead then
      self:endLifeSteal()
    end
  end
end

function Player:startLifeSteal()
  local closest = nil
  local closetDist = nil

  for e in Enemy.all:iterate() do
    local angDiff = math.abs(math.angle(self.x, self.y, e.x, e.y) - self.angle)
    local dist = math.dist(self.x, self.y, e.x, e.y)

    -- if they're in range and we're facing them well enough
    if angDiff < self.LS_SPREAD / 2 and dist < self.LS_RANGE then
      if (closestDist ~= nil and dist < closestDist) or closest == nil then
        closest = e
        closestDist = dist
      end
    end
  end

  if closest then
    self.lsTarget = closest
    closest:isTarget()
    self.lsSmokePS:start()
    self.lsWhirlPS:start()
    self.world:add(self.lsLight)
    self:updateLSLight()
  end
end

function Player:endLifeSteal()
  if self.lsTarget.dead then
    self.world:shake(10, 0.3)
  end

  self.lsTarget:isNotTarget()
  self.lsTarget = nil
  self.lsCooldownTimer = self.LS_COOLDOWN
  self.lsSmokePS:stop()
  self.lsWhirlPS:stop()
  self.world:remove(self.lsLight)
end

function Player:updateLSLight()
  self.lsLight.x = self.x
  self.lsLight.y = self.y
  self.lsLight.angle = math.angle(self.x, self.y, self.lsTarget.x, self.lsTarget.y)
  self.lsLight.length = math.dist(self.x, self.y, self.lsTarget.x, self.lsTarget.y)
end

function Player:swapWeapon(index)
  if index < 1 then
    index = #self.WEAPONS
  elseif index > #self.WEAPONS then
    index = 1
  end

  self.weapon = self.WEAPONS[index]
  self.swapTimer = self.weapon.swapTime
  self.attackTimer = 0
end

function Player:getDirection()
  local xAxis = input.axisDown("left", "right")
  local yAxis = input.axisDown("up", "down")
  
  local xAngle = xAxis == 1 and 0 or (xAxis == -1 and math.tau / 2 or nil)
  local yAngle = yAxis == 1 and math.tau / 4 or (yAxis == -1 and math.tau * 0.75 or nil)
  
  if xAngle and yAngle then
    -- x = 1, y = -1 is a special case the doesn't fit
    if xAxis == 1 and yAxis == -1 then xAngle = math.tau end
    return (xAngle + yAngle) / 2
  else
    return xAngle or yAngle
  end
end
