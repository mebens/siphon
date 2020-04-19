EnemyTank = class("EnemyTank", Enemy)
EnemyTank.BASE_HEALTH = 1200
EnemyTank.SPEED = 30
EnemyTank.MELEE_DAMAGE = 10
EnemyTank.SHOOT_WINDUP = 1
EnemyTank.SHOOT_COOLDOWN = 3.2
EnemyTank.SHOOT_BOMBS = 4
EnemyTank.SHOOT_INTERVAL = 0.08
EnemyTank.SHOOT_MAX_RANGE = 250
EnemyTank.AREA_COOLDOWN = 2
EnemyTank.AREA_DAMAGE = 30
EnemyTank.AREA_RANGE = 40
EnemyTank.DEATH_BLOOD = 5
EnemyTank.DEATH_BLOOD_SCATTER = 12

EnemyTank.width = 19
EnemyTank.height = 27
-- EnemyTank.image = getRectImage(EnemyTank.width, EnemyTank.height, 0.2, 1, 0.2)

EnemyTank.GUN_ANGLE = -math.angle(8, EnemyTank.height / 2, 5, 22)
EnemyTank.GUN_DIST = math.dist(8, EnemyTank.height / 2, 5, 22)

function EnemyTank:initialize(x, y)
  Enemy.initialize(self, x, y)
  self.originX = 8
  self.areaTimer = 0
  self.windupTimer = 0
  self.map = Spritemap:new(assets.images.tank, 27, 32)
  self.map:add("moving", { 1, 2, 3, 4 }, 7, true)
  self.map:add("attacking", { 6, 7, 8, 9, 10 }, 15)
  self.map:play("moving")
end

function EnemyTank:update(dt)
  Enemy.update(self, dt)

  if self.areaTimer > 0 then
    self.areaTimer = self.areaTimer - dt
  end

  if self.windupTimer > 0 then
    self.windupTimer = self.windupTimer - dt

    if self.windupTimer <= 0 then
      self:fireBombs()
    end
  end
end

function EnemyTank:attackRoutine(dt)
  local px, py = self.world.player.x, self.world.player.y
  local dist = math.dist(self.x, self.y, px, py)

  -- todo improve this to properly calculate intercept
  local pvAngle = math.atan2(self.world.player.vely, self.world.player.velx)
  local leadTime = dist / EnemyBomb.SPEED + self.SHOOT_WINDUP
  self.angle = math.angle(self.x, self.y, px + math.cos(pvAngle) * leadTime, py + math.sin(pvAngle) * leadTime)

  -- no other action while winding up to shoot
  if self.windupTimer <= 0 then
    if dist < self.AREA_RANGE and self.areaTimer <= 0 then
      self:areaAttack()
    elseif dist < self.SHOOT_MAX_RANGE and self.shootTimer <= 0 then
      self:shoot()
    else
      self.velx = math.cos(self.angle) * self.SPEED
      self.vely = math.sin(self.angle) * self.SPEED
    end
  else
    self.velx = 0
    self.vely = 0
  end
end

function EnemyTank:shoot()
  self.windupTimer = self.SHOOT_WINDUP
  self.shootTimer = self.SHOOT_COOLDOWN
  self.map:play("attacking")
  playRandom{"windup1", "windup2"}
end

function EnemyTank:fireBombs()
  local fireAngle = self.angle

  for i = 0, self.SHOOT_BOMBS - 1 do
    local relAngle = i % 2 == 0 and self.GUN_ANGLE or -self.GUN_ANGLE
    local x = self.x + math.cos(self.angle + relAngle) * self.GUN_DIST
    local y = self.y + math.sin(self.angle + relAngle) * self.GUN_DIST

    if i == 0 then
      self.world:add(EnemyBomb:new(x, y, fireAngle))
      playRandom{"tankFire1", "tankFire2"}
    else
      delay(i * self.SHOOT_INTERVAL, function()
        if self.world then
          self.world:add(EnemyBomb:new(x, y, fireAngle))
          playRandom{"tankFire1", "tankFire2"}
        end

        if i == self.SHOOT_BOMBS - 1 then
          self.map:play("moving")
        end
      end)
    end
  end
end

function EnemyTank:areaAttack()
  -- self.world.player:damage(self.AREA_DAMAGE)
  self.areaTimer = self.AREA_COOLDOWN
end
