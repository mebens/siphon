Intro = class("Intro", World)

function Intro:initialize()
  World.initialize(self)
  self.title = Text:new{"S I P H O N", font=assets.fonts.main[160], x=0, y=love.graphics.height - 80, width=love.graphics.width*2, align="center"}
  self.title.color = table.copy(MAGENTA)
  self.title.color[4] = 0

  self.desc1 = Text:new{"Your life is slipping away", font=assets.fonts.main[40], x=0, y=love.graphics.height - 160, width=love.graphics.width*2, align="center"}
  self.desc1.color[4] = 0
  self.desc2 = Text:new{"the horde to keep yourself alive.", font=assets.fonts.main[40], x=0, y=love.graphics.height + 120, width=love.graphics.width*2, align="center"}
  self.desc2.color[4] = 0
  self.desc3 = Text:new{"Press space to continue", font=assets.fonts.main[40], x=0, y=love.graphics.height * 2 - 100, width=love.graphics.width*2, align="center"}
  self.desc3.color[4] = 0
end

function Intro:start()
  tween(self.desc1.color, 0.5, { [4] = 1 }, nil, function()
    delay(0.5, function()
      self:tweenCyan()
      tween(self.title.color, 0.5, { [4] = 1 }, nil, function()
        delay(0.2, function()
          tween(self.desc2.color, 0.5, { [4] = 1 })
          delay(0.8, function()
            tween(self.desc3.color, 1, { [4] = 1 })
          end)
        end)
      end)
    end)
  end)
end

function Intro:tweenCyan()
  tween(self.title.color, 5, CYAN, nil, self.tweenMagenta, self)
end

function Intro:tweenMagenta()
  tween(self.title.color, 5, MAGENTA, nil, self.tweenCyan, self)
end

function Intro:update(dt)
  World.update(self, dt)

  if input.key.pressed.space then
    ammo.world = Level:new("1")
  end
end

function Intro:draw()
  postfx.exclude()
  self.title:draw()
  self.desc1:draw()
  self.desc2:draw()
  self.desc3:draw()
  postfx.include()
end
