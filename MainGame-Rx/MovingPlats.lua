-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- Layers module
local Layers = require 'Layers'

local MovingPlats = {}

function MovingPlats.Init(scheduler)
   -- Create new dynamic data layer
   local movingPlatsLayer = map:addCustomLayer(Layers.movingPlats.name, Layers.movingPlats.number)

   MovingPlats.movingPlats = {}

	-- Get enemies spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "verticalPlat" then
			MovingPlats.Create(object.x, object.y, scheduler, true)
        elseif object.name == "horizontalPlat" then
			MovingPlats.Create(object.x, object.y, scheduler, false)
        end
	end
    
    -- Draw plats
    movingPlatsLayer.draw = function(self)
        rx.Observable.fromTable(MovingPlats.movingPlats, pairs, false)
            :subscribe(function(plat)
                plat.draw()
            end)
   end
   
   return Enemies.enemies
end

function MovingPlats.CreateShooter(posX, posY, scheduler, isVertical)
	local plat = {}
	-- Properties
	plat.tag = "movingPlat"
	plat.initX = posX
	plat.initY = posY
	plat.width = 40
	plat.height = 20
	plat.vertical = isVertical

	-- Physics
	plat.body = love.physics.newBody(world, plat.initX, plat.initY, "dynamic")
	plat.body:setFixedRotation(true)
	plat.shape = love.physics.newRectangleShape(plat.width, plat.height)
	plat.fixture = love.physics.newFixture(plat.body, plat.shape, 2)
	plat.fixture:setUserData({properties = plat})

	-- Move
	scheduler:schedule(function()
			coroutine.yield(1)
			while true and enemy.alive do
				enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
				coroutine.yield(math.random(.5,2))
			end
		end)

	-- Functions
	plat.draw = function()
		love.graphics.setColor(194/255, 156/255, 4/255)
		love.graphics.polygon("fill", plat.body:getWorldPoints(plat.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
		love.graphics.polygon("line", plat.body:getWorldPoints(plat.shape:getPoints()))

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(enemy.body:getX()), math.floor(enemy.body:getY()))
	end

   table.insert(MovingPlats.movingPlatsLayer, plat)  
end


return MovingPlats