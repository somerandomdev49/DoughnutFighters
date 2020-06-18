local gui = require("lib.gui")
local help = {}

function help.load()
  gui.gfx = help.gfx
end

function help.init()
  help.transition = false
  help.transitionAlpha = 0
  
  help.cloudTime = 0
  help.cloudDelay = 1
  help.clouds = {}
end

function help.draw()
  love.graphics.draw(help.gfx.backgroundImage, 0, 0)
  
  for i, v in ipairs(help.clouds) do
    help.main.drawCloud(v)
  end
  
  love.graphics.setColor(69/256, 40/256, 60/256)
  love.graphics.setFont(help.gfx.fontMedium)
  love.graphics.printf(
    "[w]      -  fly upwards\n".. 
    "[s]      -  fly downwards\n".. 
    "[a]      -  fly left\n".. 
    "[d]      -  fly right\n".. 
    "[space]  -  shoot towards mouse\n"..
    "[esc]    -  pause\n"..
    "[q]      -  go back\n"..
    "[g]      -  game over\n"..
    "[0-9]    -  volume 0-90\n"..
    "[-]      -  volume - 10%\n"..
    "[+]      -  volume + 10%\n"..
    "[c]      -  activate shield if it is in collected items\n\n"..
    "Please do not hold buttons for long, because there aren't always delays (eg. when going back from help). this will be fixed in newer versions",
    20, love.graphics.getHeight()/5-help.gfx.fontMedium:getHeight()/2, love.graphics.getWidth())
    
  love.graphics.setColor(1, 1, 1)
  if help.transition then
    love.graphics.setColor(0, 0, 0, help.transitionAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function help.update(dt)
  for i, v in ipairs(help.clouds) do
    help.main.updateCloud(v, dt, help.clouds, i)
  end
  
  if help.cloudTime >= help.cloudDelay then
    table.insert(help.clouds, help.main.newCloud())
    help.cloudTime = 0
  else
    help.cloudTime = help.cloudTime + dt
  end
  if help.transitionAlpha >= 1 then help.main.goBack() end
  if help.transition then
    help.transitionAlpha = help.transitionAlpha + dt * 6
    return
  end
  if love.keyboard.isDown("escape") or love.keyboard.isDown("q") then help.transition = true end
end

return help
