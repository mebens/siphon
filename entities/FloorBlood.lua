FloorBlood = class("FloorBlood", Entity)

function FloorBlood:initialize(width, height)
  Entity.initialize(self)
  self.layer = 9
  self.canvas = love.graphics.newCanvas(width, height)
end

function FloorBlood:draw()
  love.graphics.setColor(160, 160, 160)
  love.graphics.draw(self.canvas)
end

function FloorBlood:bleed(x, y, size, scatter, color)
  self.canvas:renderTo(function()
    love.graphics.setPointSize(size)
    love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7)
    love.graphics.points(x, y)
    love.graphics.setPointSize(1)
    scatter = scatter or 2
    size = size / 2 + scatter
    
    for i = 1, math.random(5, 10) * scatter do
      love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7)
      love.graphics.points(math.random(x - size, x + size), math.random(y - size, y + size))
    end
    
    love.graphics.setColor(color)
    love.graphics.points(x, y)
  end)
  
  love.graphics.setColor(WHITE)
end

function FloorBlood:drawMap(obj)
  self.canvas:renderTo(function()
    obj:drawMap()
  end)
end


