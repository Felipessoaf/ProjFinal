-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- Layers module
local Layers = require 'Layers'

-- Shot module
local Shot = require 'Shot'

local Player = {}

-- Maps keys to players and directions
local keyMap = {
  a = -1,
  d = 1
}

function Player.Init(scheduler)
   -- Create new dynamic data layer
    local playerLayer = map:addCustomLayer(Layers.player.name, Layers.player.number)

	-- Get player spawn object
	local spawn
	for k, object in pairs(map.objects) do
		if object.name == "spawn" then
			spawn = object
			break
		end
	end
    
    -- Create hero table
	local hero = {}

	-- Properties
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
    hero.jumpCount = 2
    hero.item = rx.BehaviorSubject.create()

	-- Physics
    hero.body = love.physics.newBody(world, hero.initX, hero.initY, "dynamic")
    hero.body:setFixedRotation(true)
    hero.shape = love.physics.newRectangleShape(hero.width, hero.height)
    hero.fixture = love.physics.newFixture(hero.body, hero.shape, 2)
    hero.fixture:setUserData({properties = hero})
    hero.fixture:setCategory(2)
    hero.fixture:setFriction(1)
    -- hero.collisions = rx.BehaviorSubject.create()

    -- shots
    hero.shots = Shot.Init()
    rx.Observable.fromRange(1, 5)
        :subscribe(function ()
            Shot.Create()
        end)
    
    -- Functions
    hero.move = function (direction)
        local currentVelX, currentVelY = hero.body:getLinearVelocity()
        hero.body:setLinearVelocity(hero.speed*direction, currentVelY)
        hero.dir = {direction, 0}
    end

    hero.stopHorMove = function ()
        currentVelX, currentVelY = hero.body:getLinearVelocity()
        hero.body:setLinearVelocity(0, currentVelY)
    end
    
    hero.jump = function ()
        -- Sets y velocity to 0
        currentVelX, currentVelY = hero.body:getLinearVelocity()
        hero.body:setLinearVelocity(currentVelX, 0)

        -- Applies impulse
        hero.body:applyLinearImpulse(0, -100)

        -- Decrement jumpCount
        hero.jumpCount = hero.jumpCount - 1

        -- Clamp 0..hero.jumpCount
        hero.jumpCount = (hero.jumpCount < 0 and 0 or hero.jumpCount)
    end
    
    hero.shoot = function ()
        rx.Observable.fromTable(hero.shots, pairs, false)
            :filter(function(shot)
                return not shot.fired
            end)
            :first()
            :subscribe(function(shot)
                dirX, dirY = unpack(hero.dir)
                shot.body:setLinearVelocity(dirX * shot.speed, dirY * shot.speed)
                shot.body:setPosition(hero.body:getX(), hero.body:getY())
                shot.fired = true
                shot.fixture:setMask(2)
                shot.body:setActive(true)
            end)
    end

	-- Draw player
    playerLayer.draw = function(self)
        
        love.graphics.setColor(117/255, 186/255, 60/255)
        love.graphics.polygon("fill", hero.body:getWorldPoints(hero.shape:getPoints()))
        love.graphics.setColor(0, 0, 0)
        love.graphics.polygon("line", hero.body:getWorldPoints(hero.shape:getPoints()))

		-- Temporarily draw a point at our location so we know
		-- that our sprite is offset properly
		-- love.graphics.setPointSize(5)
		-- love.graphics.points(math.floor(self.hero.body:getX()), math.floor(self.hero.body:getY()))
	end

    -- keyboard actions for our hero
    for _, key in pairs({'a', 'd'}) do
        love.update
            :filter(function()
                return love.keyboard.isDown(key)
            end)
            :map(function(dt)
                return keyMap[key]
            end)
            :subscribe(function(dir)
                hero.move(dir)
            end)
    end

    love.keyreleased
        :filter(function(key) return key == 'a' or  key == 'd' end)
        :subscribe(function()
            hero.stopHorMove()
        end)

    love.keypressed
        :filter(function(key) return key == 'space' end)
        :subscribe(function()
            hero.shoot()
            currentVelX, currentVelY = hero.body:getLinearVelocity()
            hero.body:setLinearVelocity(0, currentVelY)
        end)

    love.keypressed
        :filter(function(key) return key == 'w' and hero.jumpCount > 0 end)
        :subscribe(function()
            hero.jump()
        end)

    hero.health
        :filter(function(val) return val <= 0 end)
        :subscribe(function()
            love.load()
        end)

    
    -- TODO: consertar isso, o reset tem q destruir td antes de loadar de novo?
    love.update
        :filter(function()
            return hero.body:getY() > 1500
        end)
        :subscribe(function()
            love.load()
        end)
	
    love.update
        :filter(function()
            return hero.item:getValue() ~= nil
        end)
        :subscribe(function()
            hero.item:getValue().body:setPosition(hero.body:getPosition())
        end)

	-- Remove unneeded object layer
	map:removeLayer("spawn")

    return hero
end

return Player