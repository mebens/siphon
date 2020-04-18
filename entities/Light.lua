Light = class("Light", Entity)

function Light.static.createCircularImage(radius, inner, intensity)
  local data = love.image.newImageData(radius * 2, radius * 2)
  inner = inner or 0
  intensity = intensity or 1

  data:mapPixel(function(x, y)
    local dist = math.dist(radius, radius, x, y)
    return 1, 1, 1, ease.circIn((dist <= radius and math.min(1, math.scale(dist, inner, radius, 1 * intensity, 0)) or 0))
  end)
  
  return love.graphics.newImage(data)
end

function Light.static.createRectImage(width, height, innerWidth, intensity)
  local data = love.image.newImageData(width, height)
  innerWidth = innerWidth or 0
  intensity = intensity or 1

  data:mapPixel(function(x, y)
    local dist = math.dist(x, height / 2, x, y)
    return 1, 1, 1, ease.circIn(math.min(1, math.scale(dist, innerWidth, height / 2, 1 * intensity, 0)))
  end)

  return love.graphics.newImage(data)
end

function Light.static.fromData(light)
  local img = Light.createCircularImage(light.values.radius, light.values.innerRadius, light.values.intensity)
  local l = Light:new(img, light.x, light.y, light.values.radius)

  if light.values.setColor == "NONE" then
    local r, g, b, a = levelColorToRGBA(light.values.color)
    l.color = {r, g, b}
    l.alpha = a
  else
    l.color = _G[light.values.setColor]
  end

  return l
end

function Light:initialize(img, x, y, radius)
  Entity.initialize(self, x, y)
  self.visible = false
  self.image = img
  self.imWidth = img:getWidth()
  self.imHeight = img:getHeight()
  self.radius = radius
  self.type = "circle"

  self.angle = 0
  self.velx = 0
  self.vely = 0

  self.color = {1, 1, 1}
  self.alpha = 1
  self.flicker = 0.1
  self.fadeOutRate = nil
end

function Light:added()
  self.world.lighting:add(self)
end

function Light:removed()
  self.world.lighting:remove(self)
end

function Light:update(dt)
  if self.velx then
    self.x = self.x + self.velx * dt
  end

  if self.vely then
    self.y = self.y + self.vely * dt
  end

  if self.fadeOutRate then
    self.alpha = self.alpha - self.fadeOutRate * dt

    if self.alpha <= 0 then
      self.world = nil
    end
  end
end

function Light:fadeOut(time)
  self.fadeOutRate = self.alpha / time
end

function Light:draw()
  love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha - self.flicker / 2 + math.random() * self.flicker)

  if self.type == "rect" then
    local scaleX = 1

    if self.length then
      scaleX = self.length / self.imWidth
    end

    love.graphics.draw(self.image, self.x, self.y, self.angle, scaleX, 1, 0, self.radius)
  else
    love.graphics.draw(self.image, self.x - self.radius, self.y - self.radius)
  end
end
