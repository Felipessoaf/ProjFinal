-- Layers module
local Layers = require 'Layers'

local Shot = {}

function Shot.Init()
   -- Create new dynamic data layer
    local shotLayer = map:addCustomLayer(Layers.shots.name, Layers.shots.number)

    Shot.shots = {}
    
	-- Draw shots
    shotLayer.draw = function(self)
        love.graphics.setColor(255,255,255,255)
        for _, shot in pairs(Shot.shots) do
            if shot.fired then
                love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
            end
        end
    end
    
    return Shot.shots
end

function Shot.Create()
    local shot = {}
    -- Properties
    shot.tag = "Shot"
    shot.width = 3
    shot.height = 3
    shot.fired = false
    shot.speed = 180--math.random(10,80)
    
   -- Physics
    shot.body = love.physics.newBody(world, 0, 0, "dynamic")
    shot.body:setFixedRotation(true)
    shot.body:setLinearVelocity(0, 0)
    shot.body:setGravityScale(0)
    shot.body:setBullet(true)
    shot.shape = love.physics.newRectangleShape(0, 0, shot.width, shot.height)
    shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
    shot.fixture:setUserData({properties = shot})
    shot.fixture:setCategory(2)
    shot.fixture:setMask(2)
    shot.fixture:setSensor(true)

    table.insert(Shot.shots, shot)
end

return Shot