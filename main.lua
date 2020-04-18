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
require("entities.Rocket")
require("entities.Rail")
require("entities.Player")
require("entities.HUD")
require("worlds.Level")

TILE_SIZE = 12

function love.load()
  ammo.db.init()
  ammo.db.addInfo("Lights", function() return ammo.world and ammo.world.lighting.lights.length or 0 end)
  ammo.db.settings.alwaysShowInfo = true
  ammo.db.live = true

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
  love.window.setPosition(100, 100)
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
  assets.newFont("square.ttf", { 24, 18, 12, 8 }, "main")
  assets.images("tiles.png", "rocket.png", "smoke.png", "tinyParticle.png")
  assets.shaders("noise.frag", "bloom.frag")
end

function defineInputMappings()
  input.define("left", "a", "left")
  input.define("right", "d", "right")
  input.define("up", "w", "up")
  input.define("down", "s", "down")
  input.define{"shoot", mouse=1}
  input.define("melee", "f")
  input.define("lifesteal", "e")

  input.define{"prevwep", wheel="up"}
  input.define{"nextwep", wheel="down"}

  input.define("quit", "escape")
end

