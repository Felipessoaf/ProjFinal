-- Simple Tiled Implementation lib
local sti = require "sti"

local MapManager = {}

function MapManager.InitMap()
   return sti("Maps/mainMap.lua", { "box2d" })
end

return MapManager