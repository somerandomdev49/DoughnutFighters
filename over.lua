local gui = require("lib.gui")
local over = {}

function over.load()
  gui.gfx = over.gfx
end

function over.init()
  over.transition = false
  over.transitionAlpha = 0
  
  over.cloudTime = 0
  over.cloudDelay = 1
  over.clouds = {}
end

function over.draw()
  love.graphics.draw(over.gfx.backgroundImage, 0, 0)
  
  for i, v in ipairs(over.clouds) do
    over.main.drawCloud(v)
  end
  
  love.graphics.setColor(69/256, 40/256, 60/256)
  love.graphics.setFont(over.gfx.fontBig)
  love.graphics.printf(
    "Score: "..tostring(over.score),
    0, love.graphics.getHeight()/2-over.gfx.fontMedium:getHeight()/2 - 64,
    love.graphics.getWidth(), "center")
    
  love.graphics.setFont(over.gfx.fontMedium)
  love.graphics.printf(
    "[space] - restart",
    0, love.graphics.getHeight()/2-over.gfx.fontMedium:getHeight()/2 + 24,
    love.graphics.getWidth(), "center")
  love.graphics.printf(
    "[esc] - back to main menu",
    0, love.graphics.getHeight()/2-over.gfx.fontMedium:getHeight()/2 + 24*2,
    love.graphics.getWidth(), "center")
  love.graphics.printf(
    over.msg,
    0, love.graphics.getHeight()/2-over.gfx.fontMedium:getHeight()/2,
    love.graphics.getWidth(), "center")
    
  love.graphics.setColor(1, 1, 1)
  if over.transition then
    love.graphics.setColor(0, 0, 0, over.transitionAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function over.update(dt)
  for i, v in ipairs(over.clouds) do
    over.main.updateCloud(v, dt, over.clouds, i)
  end
  
  if over.cloudTime >= over.cloudDelay then
    table.insert(over.clouds, over.main.newCloud())
    over.cloudTime = 0
  else
    over.cloudTime = over.cloudTime + dt
  end
  if over.transitionAlpha >= 1 then over.main.switchState(over.back and 1 or 2) end
  if over.transition then
    over.transitionAlpha = over.transitionAlpha + dt * 6
    return
  end
  if love.keyboard.isDown("space") then over.transition = true end
  if love.keyboard.isDown("escape") then over.transition = true over.back = true end
end

return over
