-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- Layers module
local Layers = require 'Layers'

local Shield = {}

function Shield.Init(scheduler)
    -- Create new dynamic data layer
    local shieldLayer = map:addCustomLayer(Layers.shield.name, Layers.shield.number)

	-- Get plats spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "shield" then
			Shield.Create(object.x, object.y, scheduler)
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
    shield.touchedPlayer = rx.BehaviorSubject.create()
    shield.playerPressed = rx.BehaviorSubject.create()
    shield.touchedShot = rx.BehaviorSubject.create()

    shield.touchedPlayer
        :subscribe(function(val)
            shield.shape:setRadius(shield.initRadius)
        end)

    --ideia: juntar stream q colidiu com shield + keypress em intervalo < x
    local activatedTimeStamp = shield.playerPressed
        :skip(1)
        :filter(function(key)
            return key == "f"
        end)
        :Timestamp(scheduler)
        -- :map(function(time, ...)
        --     return {
        --         time = time,
        --         other = ...
        --     }
        -- end)
        -- :execute(function(info)
        --     print(info.time)
        --     print(info.other)
        -- end)

    local touchedShotTimeStamp = shield.touchedShot:Timestamp(scheduler)
        -- :map(function(time, ...)
        --     return {
        --         time = time,
        --         other = ...
        --     }
        -- end)

    touchedShotTimeStamp
        :combineLatest(activatedTimeStamp, function (shotInfo, activatedInfo)
            -- print(shotInfo.time)
            -- print(shotInfo.other)
            -- print(activatedInfo.time)
            -- print(activatedInfo.other)
            return shotInfo, activatedInfo
        end)
        :filter(function(shotInfo, activatedInfo)
            return math.abs(shotInfo.time - activatedInfo.time) < 0.5
        end)
        :subscribe(function(shotInfo, activatedInfo)
            print("DEFEND")
            shotInfo.other.reset()
            print(shotInfo.time)
            print(shotInfo)
            print(activatedInfo.time)
            print(activatedInfo.other)
        end)

    

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

    Shield.shield = shield 
end


return Shield