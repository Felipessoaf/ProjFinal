-- Rx libs
local rx = require 'rx'
require 'rx-love'

local Player = {}

function Player.Init(map, layerName, layerNumber, scheduler)
   -- Create new dynamic data layer called "Sprites" as the 8th layer
	local playerLayer = map:addCustomLayer(layerName, layerNumber)

	-- Get player spawn object
	local spawn
	for k, object in pairs(map.objects) do
		if object.name == "spawn" then
			spawn = object
			break
		end
	end
	
	local hero = {}
	playerLayer.hero = hero

    hero.tag = "Hero"
    hero.health = rx.BehaviorSubject.create(100)
    hero.health:debounce(1, scheduler)
               :subscribe(function (val)
                    hero.backHealth = val
                end)
    hero.backHealth = 100
    hero.dir = {1,0}
    hero.initX = spawn.x
    hero.initY = spawn.y
    hero.width = 20
    hero.height = 30
    hero.speed = 150
    hero.shots = {} -- holds our shots
    hero.body = love.physics.newBody(world, hero.initX, hero.initY, "dynamic")
    hero.body:setFixedRotation(true)
    hero.shape = love.physics.newRectangleShape(hero.width, hero.height)
    hero.fixture = love.physics.newFixture(hero.body, hero.shape, 2)
    hero.fixture:setUserData(hero)
    hero.fixture:setCategory(2)
	hero.grounded = true

	-- Draw player
    playerLayer.draw = function(self)
        
        -- love.graphics.setColor(117/255, 186/255, 60/255)
        -- love.graphics.polygon("fill", hero.body:getWorldPoints(hero.shape:getPoints()))

		-- Temporarily draw a point at our location so we know
		-- that our sprite is offset properly
		love.graphics.setPointSize(5)
		love.graphics.points(math.floor(self.hero.body:getX()), math.floor(self.hero.body:getY()))
	end
	
	-- Remove unneeded object layer
	map:removeLayer("spawn")
    
    -- table.insert(objects, hero)

    -- -- shots
    -- rx.Observable.fromRange(1, 5)
    --     :subscribe(function ()
    --         local shot = {}
    --         shot.tag = "Shot"
    --         shot.width = 3
    --         shot.height = 3
    --         shot.fired = false
    --         shot.speed = 180--math.random(10,80)
    --         shot.body = love.physics.newBody(world, 0, 0, "dynamic")
    --         shot.body:setFixedRotation(true)
    --         shot.body:setLinearVelocity(0, 0)
    --         shot.body:setGravityScale(0)
    --         shot.body:setBullet(true)
    --         shot.shape = love.physics.newRectangleShape(0, 0, shot.width, shot.height)
    --         shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
    --         shot.fixture:setUserData(shot)
    --         shot.fixture:setCategory(2)
    --         shot.fixture:setMask(2)
    --         shot.fixture:setSensor(true)
    --         table.insert(hero.shots, shot)
    --     end)

    return hero
end

love.update:subscribe(function (dt)
    
end)

return Player