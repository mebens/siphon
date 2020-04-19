Walls = class("Walls", PhysicalEntity)

function Walls:initialize(width, height)
  PhysicalEntity.initialize(self, 0, 0, "static")
  self.layer = 1
  self.width = width
  self.height = height
  self.map = Tilemap:new(assets.images.tiles, TILE_SIZE, TILE_SIZE, width, height)
end

function Walls:added()
  self:setupBody()

  if self.collisionData then
    for i, rect in ipairs(self.collisionData) do
      local fix = self:addShape(
        love.physics.newRectangleShape(rect.x + rect.width / 2, rect.y + rect.height / 2, rect.width, rect.height)
      )

      fix:setCategory(16)
    end

    self.collisionData = nil
  end
end

function Walls:setTiles(data)
  for y = 0, #data - 1 do
    for x = 0, #data[y + 1] - 1 do
      self.map:set(x, y, data[y + 1][x + 1] + 1)
    end
  end
end

function Walls:setCollision(data)
  self.collisionData = data
end

function Walls:draw()
  love.graphics.setColor(0,0,0)
  self.map:draw(self.x, self.y)
end
