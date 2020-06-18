-- TODO: Fix collected draw. different doughnuts.

local game = {}

local function collides(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 + w1 > x2 and x1 < x2 + w2 and
         y1 + h1 > y2 and y1 < y2 + h2 
end
local function insideX(x1, w1, x2, w2)
  return x1 > x2 and x1 + w1 < x2 + w2
end
local function insideY(y1, h1, y2, h2)
  return y1 > y2 and y1 + h1 < y2 + h2
end
local function inside(x1, y1, w1, h1, x2, y2, w2, h2)
  return insideX(x1, w1, x2, w2) and insideY(y1, h1, y2, h2)
end


local function nextId() 
  game.entityId = game.entityId + 1
  return game.entityId
end

local function deleteWithId(id)
  for i, v in ipairs(game.entities) do
    if v.data.id == id then
      table.remove(game.entities, i)
      return
    end
  end
end

local function gameOver(message)
  game.gameOver(message, game.score)
end

local function newEntity(type, behaviour, x, y, data)
  return { id = nextId(), behaviour = behaviour, x=x, y=y, data=data, type=type }
end



local function animatedBehaviour(e, dt, i)
  if e.data.time >= e.data.speed then
    e.data.i = e.data.i + 1
    if e.data.i > e.data.count then
      if e.data.looping then e.data.i = 0
      else table.remove(game.animated, i) end
    end
    e.data.time = 0
  else
    e.data.time = e.data.time + dt
  end
end

local function newAnimatedEntity(spriteSheet, spriteW, spriteH, x, y, speed, count, loop)
  local quads = {}
  for i=1,count do
    table.insert(quads, love.graphics.newQuad((i-1)*32, 0, spriteW, spriteH, spriteSheet:getWidth(), spriteSheet:getHeight()))
  end
  return newEntity("anim", animatedBehaviour, x, y, {
    spriteSheet=spriteSheet,
    w=spriteW, h=spriteH,
    time=0, speed=speed, looping=loop,
    count=count, i=1, quads=quads
  })
end 
local function newExplosion(x, y)
  return newAnimatedEntity(game.gfx.explosionSpriteSheet, 32, 32, x, y, 0.05, 7, false)
end
local function explode(e)
  table.insert(game.animated, newExplosion(e.x, e.y))
  table.insert(game.animated, newExplosion(e.x + 10 * math.random(0.9, 1.5), e.y + 10 * math.random(0.9, 1.5)))
  table.insert(game.animated, newExplosion(e.x - 10 * math.random(0.9, 1.5), e.y + 10 * math.random(0.9, 1.5)))
  table.insert(game.animated, newExplosion(e.x + 10 * math.random(0.9, 1.5), e.y - 10 * math.random(0.9, 1.5)))
  table.insert(game.animated, newExplosion(e.x - 10 * math.random(0.9, 1.5), e.y - 10 * math.random(0.9, 1.5)))
end
local function collectableBehaviour(e, dt, i)
  e.x = e.x - game.gameRules.collectableSpeed * dt
  if e.x < 0 then table.remove(game.collectables, i) end
  
  if collides(game.plane.x, game.plane.y, game.gfx.plane(game.gfx.planeWidth), game.gfx.plane(game.gfx.planeHeight),
              e.x, e.y, 16*game.gfx.collectableScale, 16*game.gfx.collectableScale) then
    if e.type == "collectable-extra" then game.score = game.score + game.gameRules.extraPoints end
    if e.type == "collectable-shield" then table.insert(game.collected, e.type) end
    if e.type == "collectable-health" then game.plane.data.health = game.gameRules.maxHealth end
    table.remove(game.collectables, i)
  end
end
local function newCollectable(type, x, y)
  return newEntity("collectable-"..type, collectableBehaviour, x, y)
end

local function doughnutBehaviour(e, dt, i)
  e.x = e.x - game.gameRules.planeSpeed * dt
  if e.x < -32*game.gfx.doughnutScale then table.remove(game.doughnuts, i) return end
  
  if e.data.passed then return end
  
  if game.plane.x > e.x + 10 * game.gfx.doughnutScale and game.plane.x < e.x + 20 * game.gfx.doughnutScale and
      game.plane.y + game.gfx.plane(2) > e.y + 9*game.gfx.doughnutScale and
      game.plane.y + game.gfx.plane(10) < e.y + 24*game.gfx.doughnutScale then
    
    game.gfx.doughnutSound:stop()
    game.gfx.doughnutSound:play()
    game.score = game.score + game.gameRules.doughnutPerfectScore -- 9, 9 <-> 10, 13 --
    e.data.passed = true
  elseif game.plane.x > e.x + 60 and game.plane.x < e.x + 80 * game.gfx.doughnutScale and
    game.plane.y + game.gfx.planeHeight*game.gfx.planeScale > e.y
    and game.plane.y < e.y + 30 * game.gfx.doughnutScale then
      -- game.score = game.score + game.gameRules.doughnutFailScore -- 3, 2 <-> 26, 30 --
      e.data.passed = true
  end
end

local function newDoughnut(x, y)
  return newEntity("doughnut", doughnutBehaviour, x, y, { passed = false })
end

local function bulletBehaviour(e, dt, i)
  e.x = e.x - math.cos(e.data.a) * game.gameRules.bulletSpeed * dt
  e.y = e.y - math.sin(e.data.a) * game.gameRules.bulletSpeed * dt
  
  if e.x < 0 or e.x > love.graphics.getWidth() or e.y < 0 or e.y > love.graphics.getHeight() then
    table.remove(game[e.data.name.."Bullets"], i)
  end
  -- for j, v in ipairs(game.enemyBullets) do
  --   if j ~= i then
  --     if collides(e.x, e.y, e.data.s, e.data.s,
  --                 v.x, v.y, v.data.s, v.data.s) and v.type ~= "big-bullet" then
  --       table.remove(game[v.data.name.."Bullets"], j)
  --       table.remove(game[e.data.name.."Bullets"], i)
  --     end
  --   end
  -- end
end
-- 4 2 25 10
local function newBullet(x, y, a, n)
  return newEntity("bullet", bulletBehaviour, x, y, { a = a, name=n, s=8*game.gfx.bulletScale })
end
local function newBigBullet(x, y, a, n)
  return newEntity("big-bullet", bulletBehaviour, x, y, { a = a, name=n, s=16*game.gfx.bulletScale/2 })
end

local function planeBehaviour(e, dt)
  if e.data.gameOver and e.data.gameOverTime >= game.gameRules.gameOverDelay then
    gameOver("Got hit by an enemy bullet!") return
  end
  if e.data.gameOver and e.data.gameOverTime < game.gameRules.gameOverDelay then
    e.data.gameOverTime = e.data.gameOverTime + dt return
  end
  
  if (not e.data.shield) and love.keyboard.isDown(game.controls.shield) and e.data.useTime >= game.gameRules.useDelay then
    for i, v in ipairs(game.collected) do
      if v == "collectable-shield" then
        e.data.shield = true
        table.remove(game.collected, i)
        break
      end
    end
    -- game.gameRules.shieldDuration
    e.data.useTime = 0
    e.data.shieldTime = 0
  else
    e.data.useTime = e.data.useTime + dt
  end
  
  if e.data.shield and e.data.shieldTime < game.gameRules.shieldDuration then
    e.data.shieldTime = e.data.shieldTime + dt
  elseif e.data.shield then
    e.data.shield = false
    e.data.shieldTime = 0
  end
  
  if love.keyboard.isDown(game.controls.fire) and e.data.fireTime >= game.gameRules.fireDelay then
    game.sfx.fireSound:stop()
    game.sfx.fireSound:play()
    local x = e.x+game.gfx.planeWidth*game.gfx.planeScale
    local y = e.y+game.gfx.planeHeight/2*game.gfx.planeScale-8
    local dirX = game.gameRules.shootToMouse and love.mouse.getX() or x+1 -- 
    local dirY = game.gameRules.shootToMouse and love.mouse.getY() or y -- 
    table.insert(
      game.playerBullets,
      newBullet(
        x, y,
        math.atan2((y-dirY), (x-dirX)),
        "player"
      )
    )
    e.data.fireTime = 0
  else
    e.data.fireTime = e.data.fireTime + dt
  end
  
  if love.keyboard.isDown(game.controls.fly) then
    e.y = e.y - game.gameRules.planeForce * dt
  elseif love.keyboard.isDown(game.controls.down) then
    e.y = e.y + game.gameRules.planeForce * dt
  end
  
  if love.keyboard.isDown(game.controls.left) and e.x > 5 then
    e.x = e.x - game.gameRules.planeForce * dt
  elseif love.keyboard.isDown(game.controls.right) and e.x < 405 then
    e.x = e.x + game.gameRules.planeForce * dt
    
  end
  --  e.y = e.y + e.data.v
  -- for i, v in ipairs(game.enemyBullets) do
  --   if collides(e.x, e.y, game.gfx.planeWidth * game.gfx.planeScale, game.gfx.planeHeight * game.gfx.planeScale,
  --               v.x, v.y, v.data.s, v.data.s) then
  --     table.insert(game.collected, v.type)
  --   end
  -- end
  if e.y < -20 then 
    game.gfx.shaking = true
    e.y = 40
    e.data.v = 0
    table.insert(game.animated, newExplosion(e.x, e.y))
    game.sfx.explodeSound:stop()
    game.sfx.explodeSound:play()
    e.data.health = e.data.health - 1
    game.shaking = true
    if e.data.health <= 0 then
      explode(e)
      table.remove(game.enemies, id)
      e.data.gameOver = true
      e.data.gameOverTime = 0
    end
    return
  end
  if e.y > love.graphics.getHeight() then
    game.gfx.shaking = true
    e.y = love.graphics.getHeight() - 40
    e.data.v = 0
    table.insert(game.animated, newExplosion(e.x, e.y))
    game.sfx.explodeSound:stop()
    game.sfx.explodeSound:play()
    game.shaking = true
    e.data.health = e.data.health - 1
    if e.data.health <= 0 then
      explode(e)
      table.remove(game.enemies, id)
      e.data.gameOver = true
      e.data.gameOverTime = 0
    end
    return
  end
  if not e.data.shield then
    for i, v in ipairs(game.bombs) do
      if collides(e.x, e.y, game.gfx.planeWidth * game.gfx.planeScale, game.gfx.planeHeight * game.gfx.planeScale, v.x, v.y, v.data.s, v.data.s) then
        table.remove(game.bombs, i)
        table.insert(game.animated, newExplosion(e.x, e.y))
        game.sfx.explodeSound:stop()
        game.sfx.explodeSound:play()
        e.data.health = e.data.health - 2
        if e.data.health <= 0 then
          explode(e)
          table.remove(game.enemies, id)
          e.data.gameOver = true
          e.data.gameOverTime = 0
        end
      end
    end
    for i, v in ipairs(game.enemyBullets) do
      if collides(e.x, e.y, game.gfx.planeWidth * game.gfx.planeScale, game.gfx.planeHeight * game.gfx.planeScale,
                  v.x, v.y, v.data.s, v.data.s) then
        table.remove(game.enemyBullets, i)
        game.sfx.explodeSound:stop()
        game.sfx.explodeSound:play()
        if v.type == "big-bullet" then e.data.health = e.data.health - 2
        else e.data.health = e.data.health - 1 end
        print(e.data.health)
        if e.data.health <= 0 then
          explode(e)
          table.remove(game.enemies, id)
          e.data.gameOver = true
          e.data.gameOverTime = 0
        end
        table.insert(game.animated, newExplosion(e.x, e.y))
        game.gfx.shaking = true
        if e.data.health == 0 then
          
        end
        -- gameOver("Got hit by an enemy bullet!")
        -- love.event.quit(0)
      end
    end
  end
end

local function newPlane(x, y)
  return newEntity("plane", planeBehaviour, x, y, { v=0, fireTime = 0, health = game.gameRules.maxHealth, useTime = 0 })
end

local function enemyBehaviour(e, dt, id)
  e.x = e.x - game.gameRules.enemySpeed * dt
  if e.x < 0 then
    game.plane.data.health = game.plane.data.health - 3
    table.remove(game.enemies, id)
    return
  end
  for i, v in ipairs(game.playerBullets) do
    if collides(e.x, e.y, game.gfx.planeWidth * game.gfx.planeScale, game.gfx.planeHeight * game.gfx.planeScale,
                v.x, v.y, v.data.s, v.data.s) then
      table.remove(game.playerBullets, i)
      print("ASDSAD")
      game.sfx.explodeSound:stop()
      game.sfx.explodeSound:play()
      game.gfx.shaking = true
      game.score = game.score + (e.data.big and 50 or 10)
      e.data.health = e.data.health - 1
      if e.data.health <= 0 then
        explode(e)
        table.remove(game.enemies, id) return true
      end
      table.insert(game.animated, newExplosion(e.x, e.y))
      return
    end
  end
  
  if e.data.fireTime >= game.gameRules.enemyFireDelay then
    --print("new"..e.data.big.."Bullet")
    local f = newBullet
    if e.data.big then f = newBigBullet end
    local x = e.x
    local y = e.y+game.gfx.planeHeight/2*game.gfx.planeScale-8
    table.insert(
      game.enemyBullets,
      f(
        x, y,
        math.atan2((y-game.plane.y), (x-game.plane.x)),
        "enemy"
      )
    )
    e.data.fireTime = 0
  else
    e.data.fireTime = e.data.fireTime + dt
  end
end

local function newEnemy(x, y, big)
  return newEntity("enemy", enemyBehaviour, x, y, {
    fireTime = 0,
    big = big or false,
    health = big and game.gameRules.bigEnemyMaxHealth or game.gameRules.enemyMaxHealth
  })
end

local function bombBehaviour(e, dt, id)
  e.y = e.y + game.gameRules.bombFallSpeed * dt
  e.x = e.x - game.gameRules.bombSpeed * dt
  
  if e.y > love.graphics.getHeight() then table.remove(game.bombs, id) end
  
  for i, v in ipairs(game.playerBullets) do
    if collides(e.x, e.y, e.data.s, e.data.s, v.x, v.y, v.data.s, v.data.s) then
      table.remove(game.bombs, id)
      table.remove(game.playerBullets, i)
      explode(e)
      game.gfx.shaking = true
      game.sfx.explodeSound:stop()
      game.sfx.explodeSound:play()
    end
  end
end

local function newBomb(x, y)
  return newEntity("bomb", bombBehaviour, x, y, { s=game.gfx.bombScale*16 })
end

function game.load()
  game.gfx.scale = 4
  game.gfx.planeX = 20
  game.gfx.planeBoostX = 40
  game.gfx.planeImage = love.graphics.newImage("gfx/plane-orange.png")
  game.gfx.enemyImage = love.graphics.newImage("gfx/plane-purple.png")
  game.gfx.enemyBigImage = love.graphics.newImage("gfx/plane-purple-big.png")
  game.gfx.heartImage = love.graphics.newImage("gfx/heart.png")
  game.gfx.heartEmptyImage = love.graphics.newImage("gfx/heart-empty.png")
  game.gfx.explosionSpriteSheet = love.graphics.newImage("gfx/explosion.png")
  game.gfx.doughnutBackImage = love.graphics.newImage("gfx/doughnut-back.png")
  game.gfx.doughnutFrontImage = love.graphics.newImage("gfx/doughnut-front.png")
  game.gfx.playerBulletImage = love.graphics.newImage("gfx/bullet-green.png")
  game.gfx.enemyBulletImage = love.graphics.newImage("gfx/bullet-red.png")
  game.gfx.enemyBulletBigImage = love.graphics.newImage("gfx/bullet-big.png")
  game.gfx.collectableExtraImage = love.graphics.newImage("gfx/collectable-extra.png")
  game.gfx.collectableBoostImage = love.graphics.newImage("gfx/collectable-boost.png")
  game.gfx.collectableShieldImage = love.graphics.newImage("gfx/collectable-shield.png")
  game.gfx.bombImage = love.graphics.newImage("gfx/bomb.png")
  game.gfx.shieldImage = love.graphics.newImage("gfx/shield.png")
  game.gfx.planeWidth = 25
  game.gfx.planeHeight = 10
  game.gfx.planeScale = 3
  game.gfx.bulletScale = 4
  game.gfx.shieldScale = 3
  game.gfx.animScale = 3
  game.gfx.bombScale = 3
  game.gfx.doughnutScale = 4
  game.gfx.heartSсale = 4
  game.gfx.collectableScale = 2
  game.gfx.doughnutSpawnX = love.graphics.getWidth() -- 32*game.gfx.doughnutScale
  game.gfx.doughnutMinY = 0
  game.gfx.doughnutMaxY = love.graphics.getHeight() - 32*game.gfx.doughnutScale
  game.gfx.shakeMag = 5
  game.gfx.shakeDuration = 0.5
  game.gfx.shakeTime = 0
  -- game.sfx = {}
  game.sfx.fireSound = love.audio.newSource("sfx/fire.wav", "static")
  game.sfx.clickSound = love.audio.newSource("sfx/click.wav", "static")
  game.gfx.doughnutSound = love.audio.newSource("sfx/pickup.wav", "static")
  
  game.gameRules = {}
  game.gameRules.shootToMouse = false
  game.gameRules.planeSpeed = 150
  game.gameRules.maxHealth = 20
  game.gameRules.enemySpeed = 80
  game.gameRules.planeForce = 280
  game.gameRules.fireDelay = 0.2
  game.gameRules.bombDelay = 5
  game.gameRules.enemyFireDelay = 1
  game.gameRules.useDelay = 1
  game.gameRules.bulletSpeed = 180
  game.gameRules.doughnutFreq = 400
  game.gameRules.enemySpawnRate = 3
  game.gameRules.enemyBigFreq = 5
  game.gameRules.collectableFreq = 3
  game.gameRules.gravity = 10
  game.gameRules.doughnutPerfectScore = 50
  game.gameRules.doughnutNiceScore = 40
  game.gameRules.doughnutFailScore = -50
  game.gameRules.gameOverDelay = 2
  game.gameRules.bigEnemyMaxHealth = 3
  game.gameRules.enemyMaxHealth = 1
  game.gameRules.collectableSpeed = game.gameRules.planeSpeed
  game.gameRules.shieldDuration = 10
  game.gameRules.extraPoints = 100
  game.gameRules.bombFallSpeed = 100
  game.gameRules.bombSpeed = game.gameRules.planeSpeed
end

function game.init()
  
  game.gfx.shaking = false
  function game.gfx.plane(x) return x * game.gfx.planeScale end
  function game.gfx.doughnut(x) return x * game.gfx.doughnutScale end

  game.controls = {}
  game.controls.fly = "w"
  game.controls.fire = "space"
  game.controls.boost = "e"
  game.controls.shield = "c"
  game.controls.down = "s"
  game.controls.left = "a"
  game.controls.right = "d"
  
  game.enemyCount = 0
  game.enemyCount2 = 0
  game.bombTime = 0
  game.doughnutDistance = 0
  game.enemySpawnTime = 0
  game.score = 0
  game.entityId = 0
  game.plane = newPlane(game.gfx.planeX, love.graphics.getHeight()/2)
  game.collected = { "collectable-shield" }
  game.doughnuts = {}
  game.enemies = {}
  game.playerBullets = {}
  game.enemyBullets = {}
  game.animated = {}
  game.collectables = {}
  game.bombs = {}
  -- 3280
  game.clouds = {}
  game.cloudTime = 0
  game.cloudDelay = 1
  
  game.escapeDelay = 0.1
  game.escapeTime = 0
  game.paused = false
end

function game.draw() 
  love.graphics.draw(game.gfx.backgroundImage, 0, 0)
  if game.gfx.shaking then
    local dx = math.random(-game.gfx.shakeMag, game.gfx.shakeMag)
    local dy = math.random(-game.gfx.shakeMag, game.gfx.shakeMag)
    love.graphics.translate(dx, dy)
  end
  
  for i, v in ipairs(game.clouds) do
    game.main.drawCloud(v)
  end
  
  for i, v in ipairs(game.bombs) do
    love.graphics.draw(game.gfx.bombImage, v.x, v.y, 0, 3, 3)
  end
  
  for i, v in ipairs(game.doughnuts) do
    love.graphics.draw(game.gfx.doughnutBackImage, v.x, v.y, 0, game.gfx.doughnutScale, game.gfx.doughnutScale)
  end
  
  for i, v in ipairs(game.collectables) do
    --love.graphics.rectangle("line", v.x, v.y, 16*game.gfx.collectableScale, 16*game.gfx.collectableScale)
    if v.type == "collectable-shield" then
      love.graphics.draw(game.gfx.collectableShieldImage, v.x, v.y, 0, game.gfx.collectableScale, game.gfx.collectableScale)
    elseif v.type == "collectable-boost" then
      love.graphics.draw(game.gfx.collectableBoostImage, v.x, v.y, 0, game.gfx.collectableScale, game.gfx.collectableScale)
    elseif v.type == "collectable-extra" then
      love.graphics.draw(game.gfx.collectableExtraImage, v.x, v.y, 0, game.gfx.collectableScale, game.gfx.collectableScale)
    elseif v.type == "collectable-health" then
      love.graphics.draw(game.gfx.heartImage, v.x, v.y, 0, game.gfx.collectableScale*2, game.gfx.collectableScale*2)
      --love.graphics.rectangle("fill", v.x, v.y, 32, 32)
    end
  end
  
  for i, v in ipairs(game.playerBullets) do
    -- love.graphics.rectangle("line", v.x, v.y, 8 * game.gfx.bulletScale, 8 * game.gfx.bulletScale)
    love.graphics.draw(
      game.gfx.playerBulletImage,
      v.x+8*3, v.y+8*3, v.data.a - math.pi/2,
      3, 3,
      8, 8
    )
  end
  for i, v in ipairs(game.enemyBullets) do
    -- love.graphics.rectangle("line", v.x, v.y, 16 * 3, 16 * 3)
    if v.type == "bullet" then
      love.graphics.draw(
        game.gfx.enemyBulletImage,
        v.x+8*3, v.y+8*3, v.data.a - math.pi/2,
        3, 3,
        8, 8
      )
    elseif v.type == "big-bullet" then
      love.graphics.draw(
        game.gfx.enemyBulletBigImage,
        v.x+8*3, v.y+8*3, v.data.a - math.pi/2,
        3, 3,
        8, 8
      )
    end
  end
  for i, v in ipairs(game.enemies) do
    if v.data.big then
      love.graphics.draw(game.gfx.enemyBigImage, v.x, v.y, 0, game.gfx.planeScale, game.gfx.planeScale)
    else
      love.graphics.draw(game.gfx.enemyImage, v.x, v.y, 0, game.gfx.planeScale, game.gfx.planeScale)
    end
  end
  
  if game.plane.data.gameOver == nil then
    --love.graphics.rectangle(
    --  "line", game.plane.x, game.plane.y, game.gfx.plane(game.gfx.planeWidth), game.gfx.plane(game.gfx.planeHeight))
    love.graphics.draw(game.gfx.planeImage, game.plane.x, game.plane.y, 0, game.gfx.planeScale, game.gfx.planeScale)
  end
  if game.plane.data.shield then
    love.graphics.draw(
      game.gfx.shieldImage,
      game.plane.x-3*game.gfx.shieldScale, game.plane.y-8*game.gfx.shieldScale,
      0, game.gfx.shieldScale, game.gfx.shieldScale
    )
  end
  
  for i, v in ipairs(game.animated) do
    love.graphics.draw(v.data.spriteSheet, v.data.quads[v.data.i], v.x, v.y, 0, game.gfx.animScale, game.gfx.animScale)
  end
  
  for i, v in ipairs(game.doughnuts) do
    love.graphics.draw(game.gfx.doughnutFrontImage, v.x, v.y, 0, game.gfx.doughnutScale, game.gfx.doughnutScale)
  end
  
  if game.gfx.shaking then love.graphics.origin() end
  
  for i=1,game.plane.data.health do
    love.graphics.draw(game.gfx.heartImage, i*8*game.gfx.heartSсale + 5*i, 10, 0, game.gfx.heartSсale, game.gfx.heartSсale)
  end
  for i=game.plane.data.health+1,game.gameRules.maxHealth do
    love.graphics.draw(game.gfx.heartEmptyImage, i*8*game.gfx.heartSсale + 5*i, 10, 0, game.gfx.heartSсale, game.gfx.heartSсale)
  end
  
  for i, v in ipairs(game.collected) do
    love.graphics.draw(game.gfx.collectableShieldImage, 10+32*i,30, 0, game.gfx.collectableScale, game.gfx.collectableScale)
  end
  
  love.graphics.setFont(game.gfx.fontBig)
  love.graphics.setColor(69/256, 40/256, 60/256)
  love.graphics.printf(
    "Score: "..tostring(game.score),
    0, game.gfx.fontMedium:getHeight() + 32, -- love.graphics.getHeight()
    love.graphics.getWidth(), "center")
  love.graphics.setColor(1, 1, 1)
  
  if game.paused then
    love.graphics.setColor(0, 0, 0, 0.5)
    local padding = 0
    love.graphics.rectangle("fill", padding, padding, love.graphics.getWidth()-padding*2, love.graphics.getHeight()-padding*2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(game.gfx.fontMedium)
    love.graphics.printf("Press [space] or [esc] to resume\nPress [q] to go back",
      padding, love.graphics.getHeight()/2-game.gfx.fontMedium:getHeight()/2, love.graphics.getWidth()-padding*2, "center")
  end
end

local function updateGame(dt)
  game.plane.behaviour(game.plane, dt)
  
  for i, v in ipairs(game.doughnuts) do
    v.behaviour(v, dt, i)
  end
  for i, v in ipairs(game.animated) do
    v.behaviour(v, dt, i)
  end
  for i, v in ipairs(game.collectables) do
    v.behaviour(v, dt, i)
  end
  for i, v in ipairs(game.bombs) do
    v.behaviour(v, dt, i)
  end
  
  for i, v in ipairs(game.playerBullets) do
    v.behaviour(v, dt, i)
  end
  for i, v in ipairs(game.enemyBullets) do
    v.behaviour(v, dt, i)
  end
  
  --local function it_enemies()
  for i, v in ipairs(game.enemies) do
    v.behaviour(v, dt, i)
  end
  --end
  
  --while it_enemies() do end
  
  if game.bombTime >= game.gameRules.bombDelay then
    table.insert(game.bombs, newBomb(math.random(100, love.graphics.getWidth()), -game.gfx.bombScale*16))
    game.bombTime = 0
  else
    game.bombTime = game.bombTime + dt
  end
  
  local tmp = {"shield", "shield", "extra", "health"}
  if game.enemyCount2 == game.gameRules.collectableFreq then
    table.insert(
      game.collectables,
      newCollectable(
        tmp[math.random(#tmp)],
        love.graphics.getWidth(),
        math.random(game.gfx.doughnutMinY, game.gfx.doughnutMaxY)
      )
    )
    game.enemyCount2 = 0
  end
  
  if game.enemyCount == game.gameRules.enemyBigFreq then
    table.insert(
      game.enemies,
      newEnemy(
        love.graphics.getWidth(),
        math.random(game.gfx.doughnutMinY, game.gfx.doughnutMaxY),
        true
      )
    )
    game.enemyCount = 0
  end
  
  if game.enemySpawnTime >= game.gameRules.enemySpawnRate then
    table.insert(
      game.enemies,
      newEnemy(
        love.graphics.getWidth(),
        math.random(game.gfx.doughnutMinY, game.gfx.doughnutMaxY)
      )
    )
    game.enemyCount = game.enemyCount + 1
    game.enemyCount2 = game.enemyCount2 + 1
    game.enemySpawnTime = 0
  else
    game.enemySpawnTime = game.enemySpawnTime + dt
  end
  
  if game.gfx.shaking and game.gfx.shakeTime < game.gfx.shakeDuration then
    game.gfx.shakeTime = game.gfx.shakeTime + dt
  end
  if game.gfx.shakeTime >= game.gfx.shakeDuration then
    game.gfx.shaking = false
    game.gfx.shakeTime = 0
  end
  
  if game.doughnutDistance >= game.gameRules.doughnutFreq then
    table.insert(
      game.doughnuts,
      newDoughnut(
        game.gfx.doughnutSpawnX,
        math.random(game.gfx.doughnutMinY, game.gfx.doughnutMaxY)
      )
    )
    game.doughnutDistance = 0
  else
    game.doughnutDistance = game.doughnutDistance + game.gameRules.planeSpeed * dt
  end
end

function game.update(dt)

  if love.keyboard.isDown("h") then
    game.main.switchState(4)
  end

  if game.paused and love.keyboard.isDown("q") then
    game.sfx.music:play()
    game.main.switchState(1)
  end

  if game.paused and (love.keyboard.isDown("escape") or love.keyboard.isDown("space"))  and game.escapeTime >= game.escapeDelay then
    game.paused = false
    game.qPressed = false
    game.sfx.music:play()
    game.escapeTime = 0
  elseif not game.paused then
    if love.keyboard.isDown("escape") and game.escapeTime >= game.escapeDelay then
      game.gfx.shaking = false
      game.paused = true
      game.sfx.music:pause()
      game.escapeTime = 0
    else
      
      updateGame(dt)
      for i, v in ipairs(game.clouds) do
        game.main.updateCloud(v, dt, game.clouds, i)
      end
      
      if game.cloudTime >= game.cloudDelay then
        table.insert(game.clouds, game.main.newCloud())
        game.cloudTime = 0
      else
        game.cloudTime = game.cloudTime + dt
      end
    end
  end game.escapeTime = game.escapeTime + dt
end

--[[

love.graphics.setColor(0, 1, 0)

for i, e in ipairs(game.doughnuts) do
  love.graphics.print("x:"..tostring(e.x).."y:"..tostring(e.y), e.x, e.y+ 15 * game.gfx.doughnutScale)
  
  love.graphics.line(e.x-20, e.y + 9*game.gfx.doughnutScale, e.x-20, e.y+24*game.gfx.doughnutScale)
  love.graphics.rectangle("line",
    e.x,
    e.y + 9*game.gfx.doughnutScale,
    100, 15*game.gfx.doughnutScale)
  
  
  if insideY(e.y + 9*game.gfx.doughnutScale, 15*game.gfx.doughnutScale,
             game.plane.y, game.gfx.planeHeight*game.gfx.planeScale) then
    love.graphics.setColor(1, 1, 0)
  else
    love.graphics.setColor(1, 0, 1)
  end
  
  
  love.graphics.line(game.plane.x, game.plane.y, e.x + 15 * game.gfx.doughnutScale, e.y)
  love.graphics.setColor(0, 1, 0)
end



love.graphics.rectangle("line",
  game.plane.x, game.plane.y,
  game.gfx.planeWidth*game.gfx.planeScale, game.gfx.planeHeight*game.gfx.planeScale)
love.graphics.setColor(1, 1, 1)


--]]


-- ... --
return game
