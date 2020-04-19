HUD = class("HUD", Entity)
HUD.DAMAGED_TIME = 0.5
HUD.ABILITY_RADIUS = 10
HUD.ABILITY_WIDTH = 1
HUD.ABILITY_PADDING = 8
HUD.ICON_WIDTH = 8
HUD.ICON_HEIGHT = 8
HUD.Y_PADDING = 20

function HUD:initialize()
  Entity.initialize(self)
  self.layer = 0
  self.health = Text:new{x=0, width=love.graphics.width * 2, padding=10, font=assets.fonts.main[40], shadow=true}
  self.health.y = love.graphics.height * 2 - self.health.fontHeight - HUD.Y_PADDING
  -- self.weapon = Text:new{x=0, y=0, width=love.graphics.width * 2, padding=5, font=assets.fonts.main[24], shadow=true, align="right"}
  self.damagedTimer = 0
end

function HUD:update(dt)
  self.health.text = math.ceil(self.world.player.health)

  if self.damagedTimer > 0 then
    self:damageWarning()
    self.damagedTimer = self.damagedTimer - dt

    if self.damagedTimer <= 0 then
      self.health.x = 0
      self.health.y = love.graphics.height * 2 - self.health.fontHeight - HUD.Y_PADDING
      self.health.color = {1,1,1,1}
    end
  elseif self.healing then
    self.health.color = CYAN
    self.health.color[4] = 1
  end

  if self.world.player.health < 20 then
    self:damageWarning()
  end
end


function HUD:draw()
self.health:draw()
  -- self.weapon:draw()

  local p = self.world.player
  postfx.include()
  self:drawAbility(1, assets.images.dashIcon, p.dashTimer, p.DASH_COOLDOWN)
  self:drawAbility(2, assets.images.lifestealIcon, p.lsCooldownTimer, p.LS_COOLDOWN)
  self:drawAbility(3, assets.images.rocketIcon, p.rocketTimer, p.ROCKET_COOLDOWN)
  self:drawAbility(4, assets.images.railIcon, p.railTimer, p.RAIL_COOLDOWN)
end

function HUD:damageWarning()
  self.health.x = -1 + math.random() * 2
  self.health.y = love.graphics.height * 2 - self.health.fontHeight - HUD.Y_PADDING - 1 + math.random() * 2
  self.health.color = MAGENTA
  self.health.color[4] = 1
end

function HUD:playerDamaged()
  self.damagedTimer = self.DAMAGED_TIME
end

function HUD:playerHealing()
  self.healing = true
end

function HUD:playerNotHealing()
  self.healing = false
  self.health.color = {1,1,1,1}
end

function HUD:drawAbility(index, img, t, max)
  local x = love.graphics.width - (self.ABILITY_RADIUS + self.ABILITY_PADDING + (index - 1) * (self.ABILITY_RADIUS * 2 + self.ABILITY_PADDING))
  local y = love.graphics.height - self.ABILITY_RADIUS - self.ABILITY_PADDING

  if img then
    -- love.graphics.setColor(CYAN)
    love.graphics.draw(img, x, y, 0, 1, 1, HUD.ICON_WIDTH / 2, HUD.ICON_HEIGHT / 2)
  end

  love.graphics.setLineWidth(self.ABILITY_WIDTH)

  if t <= 0 then
    love.graphics.setColor(CYAN)
    love.graphics.circle("line", x, y, self.ABILITY_RADIUS, 30)
  else
    love.graphics.setColor(WHITE)
    drawArc(x, y, self.ABILITY_RADIUS, 0, math.tau * (1 - t / max), 30)
  end

  love.graphics.setColor(WHITE)
end

