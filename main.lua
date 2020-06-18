math.randomseed(os.time())
local stateGame = require("game")
local stateOver = require("over")
local stateMenu = require("menu")
local stateHelp = require("help")

local currentState = 1
local lastState = -1
local states = { stateMenu, stateGame, stateOver, stateHelp }
local gfx = {}
local sfx = {}

function gameOver(msg, score)
  currentState = 3
  states[currentState].init()
  stateOver.msg = msg
  stateOver.score = score
  -- stateOver.main = { switchState =  }
end

local function switchState(s) 
  lastState = currentState
  currentState = s
  states[currentState].init()
  print(currentState)
end

local function goBack()
  currentState = lastState
  print("back", currentState)
end

function newCloud()
  return { x=love.graphics.getWidth(), y=math.random(0, love.graphics.getHeight()-16), c=math.random(2) }
end

function drawCloud(c)
  love.graphics.draw(gfx.cloudsImage, gfx["cloudQuad"..tostring(c.c)], c.x, c.y)
end

function updateCloud(c, dt, list, listIndex)
  c.x = c.x - 100 * dt
  if c.x < -32 then table.remove(list, listIndex) end
end

function love.load()
  love.filesystem.setIdentity("mygame")
  love.graphics.setDefaultFilter("nearest", "nearest")
  stateGame.gameOver = gameOver
  
  gfx.backgroundImage = love.graphics.newImage("gfx/sky.png")
  gfx.cloudsImage = love.graphics.newImage("gfx/clouds.png")
  gfx.logo = love.graphics.newImage("gfx/logo.png") 
  gfx.fontBig = love.graphics.newFont("gfx/upheavtt.ttf", 36)
  gfx.fontMedium = love.graphics.newFont("gfx/upheavtt.ttf", 24)
  gfx.fontSmall = love.graphics.newFont("gfx/upheavtt.ttf", 8)
  gfx.gui = {}
  gfx.cloudQuad1 = love.graphics.newQuad(0, 0, 32, 16, 32, 32)
  gfx.cloudQuad2 = love.graphics.newQuad(0, 16, 32, 16, 32, 32)
  gfx.gui.scale = 4
  gfx.gui.buttonPushImage = love.graphics.newImage("gfx/button-pushed.png")
  gfx.gui.buttonImage = love.graphics.newImage("gfx/button.png")
  sfx.music = love.audio.newSource("sfx/CH-AY-NA.ogg", "stream") -- https://opengameart.org/content/ch-ay-na
  love.audio.setVolume(0.1)
  sfx.explodeSound = love.audio.newSource("sfx/explode.wav", "static")
  
  for i, v in ipairs(states) do
    v.main = { switchState = switchState, newCloud=newCloud, updateCloud=updateCloud, drawCloud=drawCloud, goBack=goBack }
    v.gfx = gfx
    v.sfx = sfx
    v.load()
  end
  states[currentState].init()
end

function love.draw()
  states[currentState].draw()
end

local function setVolume(v) love.audio.setVolume(v/100) end
local function addVolume(v) love.audio.setVolume(love.audio.getVolume() + v/100) end
local function subVolume(v) love.audio.setVolume(love.audio.getVolume() - v/100) end
local adfknsdf = 0
function love.update(dt)
  if love.mouse.isDown(1) and adfknsdf > 0.5 then
     love.graphics.captureScreenshot(os.time() .. ".png")
     adfknsdf = 0
   end
   adfknsdf = adfknsdf + dt
  if love.keyboard.isDown("0") then setVolume(00) end
  if love.keyboard.isDown("1") then setVolume(10) end
  if love.keyboard.isDown("2") then setVolume(20) end
  if love.keyboard.isDown("3") then setVolume(30) end
  if love.keyboard.isDown("4") then setVolume(40) end
  if love.keyboard.isDown("5") then setVolume(50) end
  if love.keyboard.isDown("6") then setVolume(60) end
  if love.keyboard.isDown("7") then setVolume(70) end
  if love.keyboard.isDown("8") then setVolume(80) end
  if love.keyboard.isDown("9") then setVolume(90) end
  if love.keyboard.isDown("=") then addVolume(10) end
  if love.keyboard.isDown("-") then subVolume(10) end
  
  -- if love.keyboard.isDown("escape") then love.event.quit(0) end
  if love.keyboard.isDown("g") then gameOver("What have you done! D:", 0) end
  
  states[currentState].update(dt)
end
