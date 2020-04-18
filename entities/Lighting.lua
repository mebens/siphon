Lighting = class("Lighting", Entity)

function Lighting:initialize(ambient)
  Entity.initialize(self)
  self.layer = 1
  self.canvas = love.graphics.newCanvas(love.graphics.width, love.graphics.height)
  self.lights = LinkedList:new("_lightNext", "_lightPrev")
  self.ambient = ambient or 0.05
end

function Lighting:draw()
  self.world.camera:unset()

  self.canvas:renderTo(function()
    love.graphics.clear(self.ambient, self.ambient, self.ambient)
  end)

  for light in self.lights:iterate() do
    if light.alpha > 0 then
      self.world.camera:set()
      love.graphics.setCanvas(self.canvas)
      light:draw()
      self.world.camera:unset()
    end
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(postfx.alternate)
  love.graphics.draw(postfx.canvas, 0, 0)
  love.graphics.setBlendMode("multiply", "premultiplied")
  love.graphics.draw(self.canvas, 0, 0)
  love.graphics.setBlendMode("alpha")
  postfx.swap()
  self.world.camera:set()
end

function Lighting:add(light)
  self.lights:push(light)
end

function Lighting:remove(light)
  self.lights:remove(light)
end
