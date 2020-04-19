Level = class("Level", PhysicalWorld)

function Level:initialize(levelName)
  PhysicalWorld.initialize(self)
  Enemy.resetList()
  self.name = levelName
  self.shakeTimer = 0

  self:setupLayers{
    [0] = {0, pre=postfx.exclude, post=postfx.include}, -- hud
    [1] = 1, -- lighting
    [2] = 1, -- walls
    [3] = 1, -- particles
    [4] = 1, -- player
    [5] = 1, -- enemies
    [6] = 1, -- projectiles
    [7] = 1, -- objects
    [8] = 1, -- body decals
    [9] = 1, -- blood decals
    [10] = 1, -- floor
  }

  levelName = levelName or "1"
  local fileContent = love.filesystem.read("assets/levels/" .. levelName .. ".json")
  self.data = json.decode(fileContent)

  self.width = self.data.width
  self.height = self.data.height
  self.camera:setBounds(0, 0, self.width, self.height)
  self:addTiles()
  self:addLighting(40)
  self:addEntities()
  self.floorBlood = FloorBlood:new(self.width, self.height)
  self.hud = HUD:new()
  self:add(self.hud, self.floorBlood)
  self.layer = 0
end

function Level:addTiles()
  self.walls = Walls:new(self.width, self.height)
  self.walls:setTiles(self:getLayerData("Walls"))
  self.walls:setCollision(self:getLayerData("Collision"))
  self.floor = Floor:new(self.width, self.height)
  -- self.floor:setTiles(self:getLayerData("Floor"))
  self:add(self.walls, self.floor)
end

function Level:addLighting()
  self.lighting = Lighting:new()
  self:add(self.lighting)

  for i, light in ipairs(self:getLayerData("Lighting")) do
    self:add(Light.fromData(light))
  end
end

function Level:addEntities()
  local checkpoints = 0

  for i, entity in ipairs(self:getLayerData("Entities")) do
    if entity.name == "Player" and not self.player then
      self.player = Player:new(entity.x, entity.y)
      self:add(self.player)
    elseif entity.name == "Enemy" then
      self:add(Enemy.fromData(entity))
    elseif entity.name == "CheckPoint" then
      checkpoints = checkpoints + 1
      self:add(CheckPoint:new(checkpoints, entity.x, entity.y, entity.width, entity.height))
    elseif entity.name == "EndPoint" then
      self:add(EndPoint:new(entity.x, entity.y, entity.width, entity.height, entity.values.link))
    end
  end
end

function Level:getLayerData(name)
  for i, layer in ipairs(self.data.layers) do
    if layer.name == name then
      return layer.entities or layer.data2D
    end
  end

  error("No layer named: " .. name)
end

function Level:update(dt)
  PhysicalWorld.update(self, dt)

  -- camera and shake
  if self.shakeTimer > 0 then
    local amount = self.shakeEasing(self.shakeTimer / self.shakeTime) * self.shakeAmount * 0.8 + self.shakeAmount * 0.2
    self.shakeX = amount * (1 - 2 * math.random(0, 1))
    self.shakeY = amount * (1 - 2 * math.random(0, 1))
    self.shakeTimer = self.shakeTimer - dt
  else
    self.shakeX = 0
    self.shakeY = 0
  end

  self.camera.x = self.player.x
  self.camera.y = self.player.y
  self.camera:bind()
  self.camera.x = self.camera.x + self.shakeX
  self.camera.y = self.camera.y + self.shakeY
end

function Level:shake(amount, time, easing)
  self.shakeAmount = amount
  time = time or 1
  self.shakeTimer = time
  self.shakeTime = time
  self.shakeEasing = easing or ease.quadIn
end
