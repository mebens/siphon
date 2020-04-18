HUD = class("HUD", Entity)

function HUD:initialize()
  Entity.initialize(self)
  self.layer = 0
  self.health = Text:new{x=0, y=0, width=love.graphics.width * 2, padding=5, font=assets.fonts.main[24], shadow=true}
  self.weapon = Text:new{x=0, y=0, width=love.graphics.width * 2, padding=5, font=assets.fonts.main[24], shadow=true, align="right"}
end

function HUD:update(dt)
  self.health.text = math.ceil(self.world.player.health)

  if self.world.player.swapTimer > 0 then
    self.weapon.text = "..."
  else
    self.weapon.text = self.world.player.weapon.name
  end
end

function HUD:draw()
  self.health:draw()
  self.weapon:draw()
end
