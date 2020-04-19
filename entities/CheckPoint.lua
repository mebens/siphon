CheckPoint = class("CheckPoint", PhysicalEntity) 

function CheckPoint:initialize(id, x, y, width, height)
  PhysicalEntity.initialize(self, x + width / 2, y + height / 2, "static")
  self.id = id
  self.width = width
  self.height = height
end

function CheckPoint:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setMask(1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) -- all except 2, player
  ammo.db.log("Added checkpoint ", self.id)
end

function CheckPoint:register()
  self.registered = true
  -- self.enemies = {}

  -- for e in Enemy.all:iterate() do
  --   if not e.dead then
  --     self.enemies[#self.enemies + 1] = {e=e, x=e.initialX, y=e.initialY, class=e.class}
  --   end
  -- end

  self.world.checkpoint = self
  ammo.db.log("Registered checkpoint ", self.id)
end

function CheckPoint:use()
  if not self.registered then return end

  -- Enemy.killAll()

  -- for i, v in ipairs(self.enemies) do
  --   self.world:add(v.class:new(v.x, v.y))
  -- end

  for e in Enemy.all:iterate() do
    if not e.dead then
      e.x = e.initialX
      e.y = e.initialY
      e.health = e.BASE_HEALTH
      e.activated = false
    end
  end

  self.world.player = Player:new(self.x, self.y)
  self.world:add(self.world.player)
end


function CheckPoint:collided(other)
  if other:isInstanceOf(Player) and not self.registered then
    self:register()
  end
end
