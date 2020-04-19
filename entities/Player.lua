Player = class("Player", PhysicalEntity)
Player.SPEED = 1500
Player.DASH_FORCE = 1000
Player.BASE_HEALTH = 100
Player.MAX_HEALTH = 150
Player.RESPAWN_HEALTH = 100
Player.HEALTH_DRAIN = 2

Player.SPOOF_COOLDOWN = 0.8
Player.RAIL_COOLDOWN = 0.8
Player.ROCKET_COOLDOWN = 1.2
Player.VOLLEY_DELAY = 0.15

Player.LS_RATE = 35
Player.LS_CONVERSION = 1
Player.LS_MOVEMENT = 0.1
Player.LS_RANGE = 120
Player.LS_SPREAD = math.tau
Player.LS_COOLDOWN = 2

Player.LS_LIGHT_HEIGHT = 50
Player.LS_LIGHT = Light.createRectImage(Player.LS_RANGE, Player.LS_LIGHT_HEIGHT)
Player.LS_CLIGHT_RADIUS = 120
Player.LS_CLIGHT = Light.createCircularImage(Player.LS_CLIGHT_RADIUS)

Player.width = 12
Player.height = 12
-- Player.image = getRectImage(Player.width, Player.height)


function Player:initialize(x, y, levelName)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 4
  self.image = assets.images.player
  self.legMap = Spritemap:new(assets.images.legs, 11, 12)
  self.legMap:add("run", { 1, 2, 3, 4, 5, 6, 7, 8 }, 18, true)

  -- initial stated
  self.health = self.BASE_HEALTH  

  -- timers
  self:resetStats()
  self:setUpgrades(levelName)

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

  self.lsLight = Light:new(self.LS_LIGHT, self.x, self.y, self.LS_LIGHT_HEIGHT / 2, 0.8)
  self.lsLight.type = "rect"
  self.lsLight.color = CYAN

  self.lsCLight = Light:new(self.LS_CLIGHT, self.x, self.y, self.LS_CLIGHT_RADIUS, 0.8)
  self.lsCLight.color = CYAN

  self.siphonSfx = assets.sfx.siphon:play()
  self.siphonSfx:setLooping(true)
  self.siphonVolume = 0
  self.siphonSfx:setVolume(self.siphonVolume)
end

function Player:resetStats()
  self.railTimer = 0
  self.rocketTimer = 0
  self.lsCooldownTimer = 0
  self.dashTimer = 0
  self.lsTarget = nil

  self.rocketVolley = 1
  self.homingRockets = false
  self.rails = 1
end

function Player:setUpgrades(level)
  ammo.db.log(level)
  level = tonumber(level)

  if level == 3 then
    self.rocketVolley = 2
  elseif level == 4 then
    self.rocketVolley = 2
    self.rails = 2
  elseif level == 5 then
    self.rocketVolley = 3
    self.rails = 2
    self.LS_RATE = 50
  end
end


function Player:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(2)
  self:setMass(1)
  self:setLinearDamping(12)
end

function Player:update(dt)
  self.lsSmokePS:update(dt)
  self.lsWhirlPS:update(dt)

  if self.dead then return end

  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  -- health drain
  self:damage(self.HEALTH_DRAIN * dt)
  -- self.health = self.health - self.HEALTH_DRAIN * dt

  -- movement
  self.angle = math.angle(self.x, self.y, mouseCoords())
  self.moveDirection = self:getDirection()
  if self.moveDirection then
    local speed = self.SPEED
    if self.lsTarget then speed = speed * self.LS_MOVEMENT end
    self:applyForce(speed * math.cos(self.moveDirection), speed * math.sin(self.moveDirection))
  end


  if not self.moveDirection then
    self.legMap.frame = 1
  elseif self.legMap.current ~= "run" then
    self.legMap:play("run")
  end

  self.legMap:update(dt)

  -- dash
  if self.dashTimer > 0 then
    if not self.lsTarget then
      self.dashTimer = self.dashTimer - dt
    end

    if self.dashTimer <= 0 then
      -- playSound("ability4")
    end
  elseif input.down("dash") and self.moveDirection then
    self:pingSpoof(self.moveDirection)
  end

  -- life steal
  if self.lsCooldownTimer > 0 then
    self.lsCooldownTimer = self.lsCooldownTimer - dt

    if self.lsCooldownTimer <= 0 then
      -- playSound("ability3")
    end
  end

  if input.down("lifesteal") then
    self:lifeSteal(dt)
  elseif self.lsTarget then
    self:endLifeSteal()
  end

  -- attack
  if not self.lsTarget then
    if self.railTimer > 0 then
      self.railTimer = self.railTimer - dt

      if self.railTimer <= 0 then
        -- playSound("ability1")
      end
    elseif input.down("railgun") then
      self:attackRailgun()
    end

    if self.rocketTimer > 0 then
      self.rocketTimer = self.rocketTimer - dt

      if self.rocketTimer <= 0 then
        -- playSound("ability2")
      end
    elseif input.down("rocket") then
      self:attackRocket()
    end
  end

  self.siphonSfx:setVolume(self.siphonVolume)
end

function Player:draw()
  -- if self.lsTarget then
  --   love.graphics.line(self.x, self.y, self.lsTarget.x, self.lsTarget.y)
  -- end

  love.graphics.draw(self.lsSmokePS)
  love.graphics.draw(self.lsWhirlPS)

  if not self.dead then
    self.legMap:draw(self.x, self.y, self.moveDirection, 1.6, 1.6, 11 / 2, 12 / 2)
    self:drawImage()
  end
end

function Player:attackRailgun()
  self.world:add(Rail:new(self.x, self.y, self.angle))

  if self.rails == 2 then
    self.world:add(Rail:new(self.x, self.y, self.angle))
  end

  self.railTimer = NO_COOLDOWNS and 0 or self.RAIL_COOLDOWN
  playRandom{"rail1", "rail2"}
end

function Player:attackRocket()
  self.world:add(Rocket:new(self.x, self.y, self.angle))

  if self.rocketVolley > 1 then
    for i = 1, self.rocketVolley - 1 do
      delay(i * self.VOLLEY_DELAY, function()
        self.world:add(Rocket:new(self.x, self.y, self.angle, self.homingRockets))
      end)
    end
  end

  self.rocketTimer = NO_COOLDOWNS and 0 or self.ROCKET_COOLDOWN
  playRandom{"rocket1", "rocket2", "rocket3"}
end

function Player:pingSpoof(angle)
  self:applyLinearImpulse(self.DASH_FORCE * math.cos(angle), self.DASH_FORCE * math.sin(angle))
  self.dashTimer = NO_COOLDOWNS and 0 or self.SPOOF_COOLDOWN
  playRandom{"dash1", "dash2"}
end

function Player:damage(amount, angle)
  self.health = math.clamp(self.health - amount, 0, self.MAX_HEALTH)

  if amount > 5 then
    self.world.hud:playerDamaged()
    playRandom{"hit1", "hit2"}

    if angle then
      self.world:add(BloodSpurt:new(self.x, self.y, angle, 2, 2, 1, CYAN))
    end
  end

  if self.health <= 0 then
    self:die()
  end
end

function Player:die()
  if self.dead then return end
  self.dead = true

  for i = 1, 3 do
    self.world:add(BloodSpurt:new(
      self.x, self.y, math.tau * math.random(), self.DEATH_BLOOD_SCATTER, self.DEATH_BLOOD_SCATTER, 1, CYAN
    ))
  end

  self.siphonSfx:stop()
  self.world:remove(self.lsLight)
  self.world.hud:playerNotHealing()
  playSound("splat")

  delay(1, function()
    if self.world.checkpoint then
      self.world.checkpoint:use()
    else
      ammo.world = Level:new(self.world.name)
    end

    self.world = nil
  end)
end

function Player:lifeSteal(dt)
  if not self.lsTarget and self.lsCooldownTimer <= 0 then
    self:startLifeSteal()
  end

  if self.lsTarget then
    self.lsSmokePS:setPosition(self.lsTarget.x, self.lsTarget.y)
    self.lsSmokePS:setDirection(math.angle(self.lsTarget.x, self.lsTarget.y, self.x, self.y))
    self.lsWhirlAngle = self.lsWhirlAngle + math.tau * 3 * dt 

    local whirlDist = math.scale(self.lsTarget.health, 0, self.lsTarget.BASE_HEALTH, 3, 35)
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
    -- local angDiff = math.abs(math.angle(self.x, self.y, e.x, e.y) - self.angle)
    local dist = math.dist(self.x, self.y, e.x, e.y)
    ammo.db.log(dist, self.x, self.y, e.x, e.y)
    -- if they're in range and we're facing them well enough
    if dist < self.LS_RANGE and not e:isInstanceOf(EnemyTank) then
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
    self.world:add(self.lsLight, self.lsCLight)
    self:updateLSLight()
    self.world.hud:playerHealing()
    self:animate(0.3, {siphonVolume=1})
  end
end

function Player:endLifeSteal()
  if self.lsTarget.dead then
    self.world:shake(10, 0.3)
  end

  self.lsTarget:isNotTarget()
  self.lsTarget = nil
  self.lsCooldownTimer = NO_COOLDOWNS and 0 or self.LS_COOLDOWN
  self.lsSmokePS:stop()
  self.lsWhirlPS:stop()
  self.world:remove(self.lsLight, self.lsCLight)
  self.world.hud:playerNotHealing()
  self:animate(0.6, {siphonVolume=0})
end

function Player:updateLSLight()
  self.lsLight.x = self.x
  self.lsLight.y = self.y
  self.lsLight.angle = math.angle(self.x, self.y, self.lsTarget.x, self.lsTarget.y)
  self.lsLight.length = math.dist(self.x, self.y, self.lsTarget.x, self.lsTarget.y)
  self.lsCLight.x = self.x
  self.lsCLight.y = self.y
  self.lsCLight.alpha = 0.5 + 0.5 * (1 - self.lsTarget.health / self.lsTarget.BASE_HEALTH)
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
