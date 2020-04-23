-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- Layers module
local Layers = require 'Layers'

local MovingPlats = {}

function MovingPlats.Init()
   -- Create new dynamic data layer
   local movingPlatsLayer = map:addCustomLayer(Layers.movingPlats.name, Layers.movingPlats.number)

   MovingPlats.movingPlats = {}

	-- Get plats spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "verticalPlat" then
			MovingPlats.Create(object.x, object.y, true, object.properties)
        elseif object.name == "horizontalPlat" then
			MovingPlats.Create(object.x, object.y, false, object.properties)
        end
	end
    
    -- Draw plats
    movingPlatsLayer.draw = function(self)
        rx.Observable.fromTable(MovingPlats.movingPlats, pairs, false)
            :subscribe(function(plat)
                plat.draw()
            end)
   end
   
   return MovingPlats.movingPlats
end

function MovingPlats.Create(posX, posY, isVertical, properties)
	local plat = {}
	-- Properties
	plat.tag = "movingPlat"
	plat.initX = posX
	plat.initY = posY
	plat.width = 40
	plat.height = 20
    plat.vertical = isVertical
    plat.velocity = plat.vertical and -50 or 50
    plat.canInvert = false
    plat.Ground = true

	-- Physics
	plat.body = love.physics.newBody(world, plat.initX, plat.initY, "kinematic")
    plat.body:setFixedRotation(true)
    plat.body:setGravityScale(0)
    plat.body:setLinearVelocity(plat.vertical and 0 or plat.velocity, plat.vertical and plat.velocity or 0)
	plat.shape = love.physics.newRectangleShape(plat.width, plat.height)
    plat.fixture = love.physics.newFixture(plat.body, plat.shape, 2)
    plat.fixture:setFriction(1)
	plat.fixture:setUserData({properties = plat})

	-- Functions
	plat.draw = function()
		love.graphics.setColor(194/255, 156/255, 4/255)
		love.graphics.polygon("fill", plat.body:getWorldPoints(plat.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
		love.graphics.polygon("line", plat.body:getWorldPoints(plat.shape:getPoints()))

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        -- love.graphics.setColor(1, 1, 1)
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(plat.body:getX()), math.floor(plat.body:getY()))
    end
    
    plat.insidePath = function()
        if plat.vertical then
            return (plat.body:getY() > (plat.initY - 50)) and (plat.body:getY() < (plat.initY + 50))
        else
            return (plat.body:getX() > (plat.initX - 50)) and (plat.body:getX() < (plat.initX + 50))
        end
    end
    
    plat.update = function()
        if plat.insidePath() then
            plat.canInvert = true
        end
        
        if not plat.insidePath() and plat.canInvert then
            plat.velocity = plat.velocity * -1
            plat.body:setLinearVelocity(plat.vertical and 0 or plat.velocity, plat.vertical and plat.velocity or 0)
            plat.canInvert = false
        end
    end

   table.insert(MovingPlats.movingPlats, plat)  
end


return MovingPlats