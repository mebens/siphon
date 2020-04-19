EnemySniper = class("EnemySniper", Enemy)
EnemySniper.BASE_HEALTH = 80
EnemySniper.SPEED = 70
EnemySniper.RETREAT_SPEED = 100
EnemySniper.MELEE_DAMAGE = 5
EnemySniper.IDEAL_RANGE = 100
EnemySniper.RANGE_SPREAD = 30
EnemySniper.SHOOT_DAMAGE = 40
EnemySniper.SHOOT_COOLDOWN = 1.5

EnemySniper.width = 20
EnemySniper.height = 14
-- EnemySniper.image = getRectImage(12, 12, 1, 0.7, 0)

function EnemySniper:initialize(x, y)
  Enemy.initialize(self, x, y)
  self.map = Spritemap:new(assets.images.sniper, self.width, self.height, self.finishedAttackAnim, self)
  self.map:add("moving", { 10, 11, 12, 13, 14, 15, 16, 17 }, 15, true)
  self.map:add("standing", { 1, 2, 3, 4 }, 15, true)
  self.map:add("attack", { 1, 2, 3, 4 }, 30)
  self.map:play("moving")
end

function EnemySniper:attackRoutine(dt)
  local px, py = self.world.player.x, self.world.player.y
  local dist = math.dist(self.x, self.y, px, py)

  -- todo improve this to properly calculate intercept
  local pvAngle = math.atan2(self.world.player.vely, self.world.player.velx)
  local leadTime = dist / EnemyBullet.SPEED
  self.angle = math.angle(self.x, self.y, px + math.cos(pvAngle) * leadTime, py + math.sin(pvAngle) * leadTime)

  local dir = 0

  if dist < EnemySniper.IDEAL_RANGE - EnemySniper.RANGE_SPREAD then
    dir = -1
  elseif dist > EnemySniper.IDEAL_RANGE + EnemySniper.RANGE_SPREAD then
    dir = 1
  elseif self.shootTimer > 0 then
    dir = math.sign(math.round(dist - EnemySniper.IDEAL_RANGE)) -- move to ideal range
  else
    -- should do some sort of visual confirmation, maybe ray cast
    self:shoot()
  end

  if dir == 0 and self.map.current ~= "standing" then
    self.map:play("standing")
  elseif self.map.current ~= "moving" then
    self.map:play("moving")
  end

  local speed = dir < 0 and self.RETREAT_SPEED or self.SPEED
  self.velx = math.cos(self.angle) * speed * dir
  self.vely = math.sin(self.angle) * speed * dir
end

function EnemySniper:shoot()
  self.world:add(EnemyBullet:new(self.x, self.y, self.angle, self.SHOOT_DAMAGE))
  self.shootTimer = self.SHOOT_COOLDOWN
  playRandom{"laser1", "laser2", "laser3"}
  -- self.map:play("attack")
end

function EnemySniper:finishedAttackAnim()
end
