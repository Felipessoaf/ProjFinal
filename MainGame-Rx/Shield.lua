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
    shield.touchedPlayer = rx.BehaviorSubject.create()

    shield.touchedPlayer
        -- :execute(function(val)
        --     shield.shape:setRadius(20)
        -- end)
        -- :flatMap(function(val)
        --     return rx.Observable.replicate(val, 10)
        -- end)
        :subscribe(function(val)
            shield.shape:setRadius(20)
            -- print(val:getPosition())
            -- shield.body:setPosition(val:getPosition())
        end)

	-- Physics
	shield.body = love.physics.newBody(world, shield.initX, shield.initY, "kinematic")
    shield.body:setFixedRotation(true)
    shield.body:setGravityScale(0)
    shield.body:setLinearVelocity(0, 0)
	shield.shape = love.physics.newCircleShape(shield.radius)
    shield.fixture = love.physics.newFixture(shield.body, shield.shape, 2)
    shield.fixture:setFriction(1)
	shield.fixture:setUserData({properties = shield})
    shield.fixture:setSensor(true)

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