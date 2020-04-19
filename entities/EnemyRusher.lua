EnemyRusher = class("EnemyRusher", Enemy)
EnemyRusher.BASE_HEALTH = 100
EnemyRusher.SPEED = 95
EnemyRusher.MELEE_DAMAGE = 25

EnemyRusher.width = 20
EnemyRusher.height = 10
-- EnemyRusher.image = getRectImage(12, 12, 1, 0, 0)

function EnemyRusher:initialize(x, y)
  Enemy.initialize(self, x, y)
  self.scale = 1.2
  self.map = Spritemap:new(assets.images.rusher, self.width, self.height, self.finishedAttackAnim, self)
  self.map:add("default", { 1, 2, 3, 4, 5, 6, 7, 8 }, 15, true)
  self.map:add("attack", { 9, 10, 11, 12, 13 }, 20)
  self.map:play("default")
end

function EnemyRusher:attackRoutine(dt)
  self.angle = math.angle(self.x, self.y, self.world.player.x, self.world.player.y)
  self.velx = math.cos(self.angle) * self.SPEED
  self.vely = math.sin(self.angle) * self.SPEED
end

function EnemyRusher:finishedAttackAnim()
  self.map:play("default")
end

function EnemyRusher:meleeAttack()
  Enemy.meleeAttack(self)
  self.map:play("attack")
end
