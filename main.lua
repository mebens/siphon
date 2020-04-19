require("lib.ammo.all")
ammo.db = require("lib.ammo.debug")
require("lib.gfx")

json = require("lib.json.json")

require("utils")
require("modules.noise")
require("modules.bloom")
require("entities.Light")
require("entities.Lighting")
require("entities.Walls")
require("entities.Floor")
require("entities.Enemy")
require("entities.EnemyRusher")
require("entities.EnemySniper")
require("entities.EnemyTank")
require("entities.EnemyBullet")
require("entities.EnemyBomb")
require("entities.Rocket")
require("entities.Rail")
require("entities.Player")
require("entities.HUD")
require("entities.BloodSpurt")
require("entities.FloorBlood")
require("entities.CheckPoint")
require("entities.EndPoint")
require("worlds.Level")

TILE_SIZE = 12
NO_COOLDOWNS = false

function love.load()
  ammo.db.init()
  ammo.db.addInfo("Lights", function() return ammo.world and ammo.world.lighting.lights.length or 0 end)
  ammo.db.addInfo("Enemies", function() return Enemy.all.length end)
  ammo.db.settings.alwaysShowInfo = true
  ammo.db.live = true

  function ammo.db.commands:level(name)
    ammo.world = Level:new(name)
  end

  ammo.db.commands.nocooldowns = function()
    NO_COOLDOWNS = not NO_COOLDOWNS
  end

  love.graphics.setDefaultFilter("nearest", "nearest")

  loadAssets()
  defineInputMappings()
  postfx.init()
  postfx.add(bloom)
  postfx.add(noise)
  postfx.scale = 2

  love.graphics.width = love.graphics.width / 2
  love.graphics.height = love.graphics.height / 2

  ammo.world = Level:new()
  paused = false

  -- dev only
  -- love.window.setPosition(100, 100)

  BG_SOUND = assets.sfx.bg:play()
  BG_SOUND:setLooping(true)
  BG_SOUND:setVolume(1)
end

function love.update(dt)
  if input.released("quit") then
    love.event.quit()
  end

  if not paused then
    ammo.update(dt)
    postfx.update(dt)
  end

  ammo.db.update(dt)
  input.update(dt)
end

function love.draw()
  postfx.start()
  ammo.draw()
  postfx.stop()

  -- print DEBUG message
  if DEBUG then
    love.graphics.setFont(assets.fonts.main[12])
    love.graphics.printf(DEBUG, 5, 5, love.graphics.width - 10, "center")
  end

  ammo.db.draw()
end

function love.keypressed(key, code)
  input.keypressed(key)
  ammo.db.keypressed(key, code)
  if key == "p" then paused = not paused end
  -- if key == "r" then ammo.world = Level:new() end
end

function love.wheelmoved(dx, dy)
  ammo.db.wheelmoved(dx, dy)
  input.wheelmoved(dx, dy)
end

function loadAssets()
  assets.newFont("square.ttf", { 40, 18, 16, 12, 8 }, "main")
  assets.shaders("noise.frag", "bloom.frag")

  assets.images(
    "tiles.png", "rocket.png", "bomb.png", "rusher.png", "sniper.png", "tank.png", "player.png", "legs.png",
    "smoke.png", "tinyParticle.png",
    "railIcon.png", "rocketIcon.png", "lifestealIcon.png", "dashIcon.png"
  )

  assets.sfx(
    "ability1.ogg", "ability2.ogg", "ability3.ogg", "ability4.ogg", 
    "dash1.ogg", "dash2.ogg",
    "explosion1.ogg", "explosion2.ogg", "explosion3.ogg", "explosion4.ogg", 
    "laser1.ogg", "laser2.ogg", "laser3.ogg",
    "rail1.ogg", "rail2.ogg",
    "rocket1.ogg", "rocket2.ogg", "rocket3.ogg",
    "siphon.ogg",
    "splat.ogg",
    "tankFire1.ogg", "tankFire2.ogg",
    "windup1.ogg", "windup2.ogg",
    "bg.ogg"
  )
end

function defineInputMappings()
  input.define("left", "a", "left")
  input.define("right", "d", "right")
  input.define("up", "w", "up")
  input.define("down", "s", "down")
  input.define{"railgun", mouse=1}
  input.define{"rocket", mouse=2}
  input.define("melee", "f")
  input.define("lifesteal", "e")
  input.define("dash", "lshift")

  input.define("quit", "escape")
end

