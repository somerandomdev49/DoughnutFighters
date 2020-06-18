local gui = {}

local function pointInside(px, py, rx, ry, rw, rh)
  return px > rx and px < rx + rw and
         py > ry and py < ry + rh
end

function gui.newComponent(type, x, y, text, font, data)
  return { x=x, y=y, text=text, font=font, type=type, data=data }
end
function gui.newButton(x, y, text, font)
  return gui.newComponent("button", x, y, text, font, { pressed = false, clickTime = 0.3, clickDelay = 0.3 })
end
function gui.newLabel(x, y, text, font)
  return gui.newComponent("label", x, y, text, font)
end

function gui.draw(comp)
  
  if comp.type == "button" then
    if comp.data.pressed then
      love.graphics.draw(gui.gfx.gui.buttonPushImage, comp.x, comp.y, 0, gui.gfx.gui.scale, gui.gfx.gui.scale)
      love.graphics.setFont(comp.font)
      love.graphics.printf(comp.text, comp.x, comp.y+3*gui.gfx.gui.scale, 48*gui.gfx.gui.scale, "center")
    else
      love.graphics.draw(gui.gfx.gui.buttonImage, comp.x, comp.y, 0, gui.gfx.gui.scale, gui.gfx.gui.scale)
      love.graphics.setFont(comp.font)
      love.graphics.printf(comp.text, comp.x, comp.y+2*gui.gfx.gui.scale, 48*gui.gfx.gui.scale, "center")
    end
  end
end

function gui.update(comp, dt)
  if comp.type == "button" then
    if love.mouse.isDown(1) and pointInside(love.mouse.getX(), love.mouse.getY(), comp.x, comp.y, 48*gui.gfx.gui.scale, 16*gui.gfx.gui.scale) then
      -- comp.data.pressed = false
      if comp.data.clickTime >= comp.data.clickDelay then
        comp.data.pressed = true
      end
      comp.data.clickTime = 0
    else
      comp.data.pressed = false
      comp.data.clickTime = comp.data.clickTime + dt
    end
  end
end

return gui
