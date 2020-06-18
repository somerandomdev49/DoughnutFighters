local gui = require("lib.gui")
local menu = {}

function menu.load()
  gui.gfx = menu.gfx
  menu.gfx.logoScale = 4
end
local ts = 2

function menu.init()
  menu.transition = false
  menu.transitionAlpha = 0
  menu.playButton = gui.newButton(love.graphics.getWidth()/2-48*menu.gfx.gui.scale/2, 120, "Play", menu.gfx.fontMedium)
  menu.logoY = -menu.gfx.logo:getHeight()*menu.gfx.logoScale
  menu.logoV = 0
  menu.logoS = 5
  menu.logoFalling = true
  menu.shakeTime = 0
  menu.shakeDuration = 0.2
  
  menu.clouds = {}
  menu.cloudTime = 0
  menu.cloudDelay = 2
  ts = 2
end

function menu.draw()
  love.graphics.draw(menu.gfx.backgroundImage, 0, 0)
  if menu.shaking then
    local dx = math.random(-5, 5)
    local dy = math.random(-5, 5)
    love.graphics.translate(dx, dy)
  end
  
  for i, v in ipairs(menu.clouds) do
    menu.main.drawCloud(v) 
  end
  
  love.graphics.draw(
    menu.gfx.logo,
    love.graphics.getWidth()/2-menu.gfx.logo:getWidth()/2*menu.gfx.logoScale, menu.logoY,
    0, menu.gfx.logoScale, menu.gfx.logoScale
  )
  
  if not menu.logoFalling then
    love.graphics.setColor(69/256, 40/256, 60/256)
    love.graphics.setFont(menu.gfx.fontMedium)
    love.graphics.printf(
      "[space] - play",
      0, 256,
      love.graphics.getWidth(), "center")
    love.graphics.printf(
      "[h] - help",
      0, 256+24+8,
      love.graphics.getWidth(), "center")
    love.graphics.printf(
      "[esc] - exit",
      0, 256+24+8+8+24,
      love.graphics.getWidth(), "center")
    love.graphics.printf(
      "Made by somerandomdev49 for Mini Jam 56 (Sky)",
      0, love.graphics.getHeight()-menu.gfx.fontMedium:getHeight()*2.2-20,
      love.graphics.getWidth(), "center")
    love.graphics.printf(
      "Made with LÖVE2D 11.2",
      0, love.graphics.getHeight()-menu.gfx.fontMedium:getHeight()*1.6-20,
        love.graphics.getWidth(), "center")
    love.graphics.printf(
      "Music: https://opengameart.org/content/ch-ay-na (CC0)",
      0, love.graphics.getHeight()-menu.gfx.fontMedium:getHeight()-20,
      love.graphics.getWidth(), "center")
    love.graphics.setColor(1, 1, 1)
  end
  
  if menu.shaking then
    love.graphics.origin()
  end
  if menu.transition then
    love.graphics.setColor(0, 0, 0, menu.transitionAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
  end
end
function menu.update(dt)
  if menu.shaking and menu.shakeTime >= menu.shakeDuration then
    menu.shaking = false
    menu.shakeTime = 0
  elseif menu.shaking then
    menu.shakeTime = menu.shakeTime + dt
  end
  
  for i, v in ipairs(menu.clouds) do
    menu.main.updateCloud(v, dt, menu.clouds, i)
  end
  
  if menu.cloudTime >= menu.cloudDelay then
    table.insert(menu.clouds, menu.main.newCloud())
    menu.cloudTime = 0
  else
    menu.cloudTime = menu.cloudTime + dt
  end
  
  if menu.logoFalling then
    menu.logoV = menu.logoV + menu.logoS * dt
    menu.logoY = menu.logoY + menu.logoV
    if menu.logoY >= 10 then
      menu.shaking = true
      menu.logoFalling = false
      menu.sfx.music:setLooping(true)
      menu.sfx.music:play()
      menu.sfx.explodeSound:play()
    end
    return
  end
  if menu.transitionAlpha >= 1 then
    menu.main.switchState(ts)
    menu.transition = false
    menu.transitionAlpha = 0
    ts = 2
  end
  if menu.transition then
    menu.transitionAlpha = menu.transitionAlpha + dt * 6
    return
  end
  -- gui.update(menu.playButton, dt)
  if love.keyboard.isDown("space") then -- menu.playButton.data.pressed
    menu.transition = true
  end
  if love.keyboard.isDown("escape") then love.event.quit(0) end
  if love.keyboard.isDown("h") then
    menu.transition = true
    ts = 4
  end
end

return menu
