-- Simple Tiled Implementation lib
local sti = require "sti"

local MapManager = {}

function MapManager.InitMap()
   
	-- the height of a meter our worlds will be 64px
	love.physics.setMeter(64)

	local map = sti("Maps/mainMap.lua", { "box2d" })

	-- create a world for the bodies to exist in with horizontal gravity
	-- of 0 and vertical gravity of 9.81
	local world = love.physics.newWorld(0, 9.81*64, true)
    
	-- Prepare collision objects
	map:box2d_init(world)

   	return map, world
end

return MapManager