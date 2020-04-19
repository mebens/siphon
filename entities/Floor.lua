Floor = class("Floor", Entity)
Floor.HIGHLIGHT_ALPHA = 0.6
Floor.HIGHLIGHT_DECAY = 0.6
Floor.HIGHLIGHT_RADIUS = 50
Floor.HIGHLIGHT_LIGHT = Light.createCircularImage(Floor.HIGHLIGHT_RADIUS, -4)
Floor.HIGHLIGHT_TIME = 0.01

function Floor:initialize(width, height)
  PhysicalEntity.initialize(self, 0, 0, "static")
  self.layer = 10
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(width, height)
  self.canvas:renderTo(function() love.graphics.clear(1, 1, 1) end)

  -- self.map = Tilemap:new(assets.images.tiles, TILE_SIZE, TILE_SIZE, width, height)
  -- self.map:setRect(0, 0, self.map.rows, self.map.columns, 1)
  self.highlights = LinkedList:new()
  self.hlMap = {}
  self.highlightTimer = 0
end

function Floor:setTiles(data)
  for y = 0, #data - 1 do
    for x = 0, #data[y + 1] - 1 do
      self.map:set(x, y, data[y + 1][x + 1] + 1)
    end
  end
end

function Floor:update(dt)
  for h in self.highlights:iterate() do
    h.alpha = h.alpha - self.HIGHLIGHT_DECAY * dt
    h.light.alpha = h.alpha

    if h.alpha <= 0 then
      self.highlights:remove(h)
      self.hlMap[self:getHLMapCoords(h.x, h.y)] = false
      self.world:remove(h.light)
    end
  end

  if self.highlightTimer > 0 then
    self.highlightTimer = self.highlightTimer - dt
  else
    self:addHighlight(
      math.random(self.world.player.x - love.graphics.width * 0.7, self.world.player.x + love.graphics.width * 0.7),
      math.random(self.world.player.y - love.graphics.height * 0.7, self.world.player.y + love.graphics.height * 0.7)
    )
    self.highlightTimer = self.HIGHLIGHT_TIME
  end
end

function Floor:addHighlight(x, y, alphaScale, color)
  local current = self.hlMap[self:getHLMapCoords(x, y)]
  alphaScale = alphaScale or 1

  if current then
    current.alpha = math.max(current.alpha, alphaScale * self.HIGHLIGHT_ALPHA)
    current.light.alpha = current.alpha
    return current
  else
    local x, y = math.floor(x / TILE_SIZE) * TILE_SIZE, math.floor(y / TILE_SIZE) * TILE_SIZE
    local light = Light:new(
      self.HIGHLIGHT_LIGHT,
      x + TILE_SIZE / 2,
      y + TILE_SIZE / 2,
      self.HIGHLIGHT_RADIUS
    )

    local h = {x=x, y=y, color=color or chooseColor(), alpha=self.HIGHLIGHT_ALPHA * alphaScale, light=light}
    light.alpha = h.alpha
    light.color = h.color

    self.world:add(light)
    self.highlights:push(h)
    self.hlMap[self:getHLMapCoords(x, y)] = h
    return h
  end
end

function Floor:getHLMapCoords(x, y)
  return math.floor(x / TILE_SIZE) * math.ceil(self.world.height / TILE_SIZE) + math.floor(y / TILE_SIZE)
end

function Floor:draw()
  love.graphics.setColor(0.4, 0.4, 0.4)
  love.graphics.draw(self.canvas)
  -- self.map:draw(self.x, self.y)

  for h in self.highlights:iterate() do
    love.graphics.setColor(h.color[1], h.color[2], h.color[3], h.alpha)
    love.graphics.rectangle("fill", h.x, h.y, TILE_SIZE, TILE_SIZE)
  end
end
