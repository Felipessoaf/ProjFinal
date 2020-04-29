-- Layers module
local Layers = require 'Layers'

local FallingPlats = {}

function FallingPlats.Init()
   -- Create new dynamic data layer
   local fallingPlatsLayer = map:addCustomLayer(Layers.fallingPlats.name, Layers.fallingPlats.number)

   FallingPlats.fallingPlats = {}

	-- Get plats spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "fallingPlat" then
			FallingPlats.Create(object.x, object.y, true)
        end
	end
    
    -- Draw plats
    fallingPlatsLayer.draw = function(self)
        for k, plat in pairs(FallingPlats.fallingPlats) do
            plat.draw()
        end
   end
   
   return FallingPlats.fallingPlats
end

function FallingPlats.Create(posX, posY)
	local plat = {}
	-- Properties
	plat.tag = "fallingPlat"
	plat.initX = posX
	plat.initY = posY
	plat.width = 40
	plat.height = 20
    plat.velocity = 1000
    plat.canInvert = false
    plat.Ground = true
    plat.timePlayerTouched = -1
    plat.timeToFall = 1
    plat.touchedPlayer = function()
        print("touchedPlayer")
        if plat.timePlayerTouched < 0 then
            plat.timePlayerTouched = love.timer.getTime()
            plat.body:setLinearVelocity(0, plat.velocity)
        end
    end

    -- plat.touchedPlayer
    --     :filter(function(val) 
    --         return plat.timePlayerTouched < 0
    --     end)
    --     :execute(function(val)
    --         plat.timePlayerTouched = love.timer.getTime()
    --     end)   
    --     :delay(plat.timeToFall, scheduler)
    --     :execute(function(val)
    --         plat.body:setLinearVelocity(0, plat.velocity)
    --     end)   
    --     :delay(plat.timeToFall*3, scheduler)
    --     :subscribe(function(val)
    --         plat.timePlayerTouched = -1
    --         plat.body:setLinearVelocity(0, 0)
    --         plat.body:setPosition(plat.initX, plat.initY)
    --     end)

	-- Physics
	plat.body = love.physics.newBody(world, plat.initX, plat.initY, "kinematic")
    plat.body:setFixedRotation(true)
    plat.body:setGravityScale(0)
    plat.body:setLinearVelocity(0, 0)
	plat.shape = love.physics.newRectangleShape(plat.width, plat.height)
    plat.fixture = love.physics.newFixture(plat.body, plat.shape, 2)
    plat.fixture:setFriction(1)
	plat.fixture:setUserData({properties = plat})

	-- Functions
	plat.draw = function()
		love.graphics.setColor(252/255, 53/255, 149/255)
		love.graphics.polygon("fill", plat.body:getWorldPoints(plat.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
		love.graphics.polygon("line", plat.body:getWorldPoints(plat.shape:getPoints()))

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        -- love.graphics.setColor(1, 1, 1)
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(plat.body:getX()), math.floor(plat.body:getY()))
    end
    
    plat.shouldFall = function()
        return false -- love. plat.timePlayerTouched > plat.timeToFall 
    end

   table.insert(FallingPlats.fallingPlats, plat)  
end


return FallingPlats