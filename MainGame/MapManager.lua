-- Simple Tiled Implementation lib
local sti = require "sti"

local MapManager = {}

function MapManager.InitMap()
   
   -- the height of a meter our worlds will be 64px
   love.physics.setMeter(64)

   return sti("Maps/mainMap.lua", { "box2d" })
end

return MapManager