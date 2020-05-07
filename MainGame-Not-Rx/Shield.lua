-- Layers module
local Layers = require 'Layers'

local Shield = {}

function Shield.Init()
    -- Create new dynamic data layer
    local shieldLayer = map:addCustomLayer(Layers.shield.name, Layers.shield.number)

	-- Get plats spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "shield" then
			Shield.Create(object.x, object.y)
        end
	end
    
    -- Draw plats
    shieldLayer.draw = function(self)
        Shield.shield.draw()
    end
   
    return Shield.shield
end

function Shield.Create(posX, posY, scheduler)
	local shield = {}
	-- Properties
	shield.tag = "shield"
	shield.initX = posX
	shield.initY = posY
	shield.radius = 10
    shield.initRadius = 25
    shield.activatedTimeStamp = -1
    shield.touchedShotTimeStamp = -1
    shield.touchedShotObj = nil
    
	-- Physics
	shield.body = love.physics.newBody(world, shield.initX, shield.initY, "kinematic")
    shield.body:setFixedRotation(true)
    shield.body:setGravityScale(0)
    shield.body:setLinearVelocity(0, 0)
	shield.shape = love.physics.newCircleShape(shield.initRadius)
    shield.fixture = love.physics.newFixture(shield.body, shield.shape, 2)
    shield.fixture:setFriction(1)
	shield.fixture:setUserData({properties = shield})
    shield.fixture:setSensor(true)
    shield.shape:setRadius(shield.radius)

	-- Functions
    shield.draw = function()
        local cx, cy = shield.body:getWorldPoints(shield.shape:getPoint())
		love.graphics.setColor(1, 247/255, 0)
		love.graphics.circle("fill", cx, cy, shield.shape:getRadius())
		love.graphics.setColor(0, 0, 0)
		love.graphics.circle("line", cx, cy, shield.shape:getRadius())

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        -- love.graphics.setColor(1, 1, 1)
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(plat.body:getX()), math.floor(plat.body:getY()))
    end

    local function checkActivation()
        if shield.activatedTimeStamp > 0 and 
        shield.touchedShotTimeStamp > 0 and 
        math.abs(shield.activatedTimeStamp - shield.touchedShotTimeStamp) < 0.5 and
        shield.touchedShotObj ~= nil then
            shield.touchedShotObj.reset()
            shield.touchedShotObj = nil
        end
    end

    shield.touchedPlayer = function()
        shield.shape:setRadius(shield.initRadius)
    end

    shield.playerPressed = function(key)
        if key == "f" then
            shield.activatedTimeStamp = love.timer.getTime()
        end

        checkActivation()
    end

    shield.touchedShot = function(shot)
        shield.touchedShotTimeStamp = love.timer.getTime()
        shield.touchedShotObj = shot

        checkActivation()
    end

    Shield.shield = shield 
end


return Shield