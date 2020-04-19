local RailLight = class("RailLight", Light)
RailLight.SPEED = 2500
RailLight.RADIUS = 120
RailLight.IMAGE = Light.createCircularImage(RailLight.RADIUS, 0, 1.05)

function RailLight:initialize(x, y, angle)
  Light.initialize(self, self.IMAGE, x, y, self.RADIUS)
  self.startX = x
  self.startY = y
  self.angle = angle
  self.velx = self.SPEED * math.cos(angle)
  self.vely = self.SPEED * math.sin(angle)
  self.color = CYAN
end

function RailLight:update(dt)
  Light.update(self, dt)

  if math.dist(self.startX, self.startY, self.x, self.y) >= Rail.LENGTH then
    self.world = nil
  end
end


Rail = class("Rail", Entity)
Rail.LENGTH = 1000
Rail.CAST_TIMES = 5
Rail.CAST_DELAY = 0.01
Rail.DAMAGE = 100
Rail.LIGHT_TIME = 0.05
Rail.EFFECT_TIME = 0.1
Rail.LIGHT_HEIGHT = 100
Rail.LIGHT_IMAGE = Light.createRectImage(Rail.LENGTH / 2, Rail.LIGHT_HEIGHT, -2)

function Rail:initialize(x, y, angle)
  Entity.initialize(self, x, y)
  self.layer = 6
  self.angle = angle
  self.endX = x + math.cos(angle) * self.LENGTH
  self.endY = y + math.sin(angle) * self.LENGTH
  self.tagged = {}
  self.castTimer = 0
  self.castCount = Rail.CAST_TIMES
  self.effectTimer = self.EFFECT_TIME
  self.lightTimer = 0
  self.light = Light:new(self.LIGHT_IMAGE, self.x, self.y, Rail.LIGHT_HEIGHT / 2)
  self.light.type = "rect"
  self.light.angle = self.angle
  self.light.color = CYAN
  self.light.alpha = 0.7

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 1000)
  ps:setSpread(math.tau / 32)
  ps:setDirection((angle + math.tau / 2) % math.tau)
  ps:setLinearDamping(0.5)
  -- ps:setColors(243/255, 11/255, 159/255, 1, 243/255, 11/255, 159/255, 0.7, 243/255, 11/255, 159/255, 0)
  ps:setColors(63/255, 209/255, 232/255, 1, 63/255, 209/255, 232/255, 0.7, 63/255, 209/255, 232/255, 0)
  ps:setParticleLifetime(2, 3)
  ps:setSizes(0.5, 0.1)
  ps:setSizeVariation(0.5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(100)
  -- ps:setRadialAcceleration(-math.tau / 2, math.tau / 2)
  ps:setSpeed(5, 100)
  ps:setLinearAcceleration(math.cos(angle) * 10, math.sin(angle) * 10, math.cos(angle) * 50, math.sin(angle) * 50)

  for i = 1, 50 do
    ps:setPosition(x + math.cos(angle) * i * 10, y + math.sin(angle) * i * 10)
    ps:emit(10)
  end

  ps:setPosition(x, y)
  self.backPS = ps
end

function Rail:added()
  self.world:shake(4, 0.5)
  self.world:add(self.light)
end

function Rail:update(dt)
  self.backPS:update(dt)

  if self.effectOver then
    if self.backPS:getCount() == 0 then
      self.world = nil
    end

    return
  end

  if self.castCount > 0 then
    if self.castTimer > 0 then
      self.castTimer = self.castTimer - dt
    end

    if self.castTimer <= 0 then
      self:cast()
      self.castTimer = self.castTimer + Rail.CAST_DELAY
      self.castCount = self.castCount - 1
    end
  end

  if self.lightTimer > 0 then
    self.lightTimer = self.lightTimer - dt
  else
    self.world:add(RailLight:new(self.x, self.y, self.angle))
    self.lightTimer = self.LIGHT_TIME
  end

  self.effectTimer = self.effectTimer - dt

  if self.effectTimer <= 0 then
    self.light:fadeOut(0.6)
    self.backPS:stop()
    self.effectOver = true
  end
end

function Rail:cast()
  for i = -5, 5 do
    local dx = math.cos(self.angle + math.tau / 4) * i
    local dy = math.sin(self.angle + math.tau / 4) * i
    self.world:rayCast(
      self.x + dx, self.y + dy, self.endX + dx, self.endY + dy,
      function(fixture, x, y, xn, yn, fraction)
        local entity = fixture:getUserData()

        if type(entity) == "table" then
          if entity:isInstanceOf(Enemy) then
            if entity._rail ~= self then
              entity._rail = self
              entity:damage(self.DAMAGE, self.angle)
            end

            return 1
          elseif entity:isInstanceOf(Walls) then
            -- add some sort of termination effect here
            self.endX = x + math.cos(self.angle) * 10
            self.endY = y + math.sin(self.angle) * 10
            return 0
          end
        end

        return 1
      end
    )
  end
end

function Rail:haveTagged(enemy)
  for i, v in ipairs(self.tagged) do
    if v == enemy then
      return true
    end
  end

  return false
end

function Rail:draw()
  love.graphics.draw(self.backPS)

  if not self.effectOver then
    love.graphics.setColor(CYAN)
    love.graphics.setLineWidth(4)
    love.graphics.line(self.x, self.y, self.endX, self.endY)
    love.graphics.setColor(1,1,1)
  end
end
