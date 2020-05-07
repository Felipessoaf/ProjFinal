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

function Player.Init()
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
    hero.health = 100
    hero.backHealth = 100
    hero.lastDamageTime = -1
    hero.dir = {1,0}
    hero.initX = spawn.x
    hero.initY = spawn.y
    hero.width = 20
    hero.height = 30
    hero.speed = 150
    hero.jumpCount = 2
    hero.item = {}
    
	-- Physics
    hero.body = love.physics.newBody(world, hero.initX, hero.initY, "dynamic")
    hero.body:setFixedRotation(true)
    hero.shape = love.physics.newRectangleShape(hero.width, hero.height)
    hero.fixture = love.physics.newFixture(hero.body, hero.shape, 2)
    hero.fixture:setUserData({properties = hero})
    hero.fixture:setCategory(2)
    hero.fixture:setFriction(1)

    -- shots
    hero.shots = Shot.Init()    
    for i=1,5 do
        Shot.Create()
    end
    
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
        for k, shot in pairs(hero.shots) do
            if not shot.fired then
                dirX, dirY = unpack(hero.dir)
                shot.body:setLinearVelocity(dirX * shot.speed, dirY * shot.speed)
                shot.body:setPosition(hero.body:getX(), hero.body:getY())
                shot.fired = true
                shot.fixture:setMask(2)
                shot.body:setActive(true)

                break
            end
        end
    end
    
    hero.damage = function (value)
        hero.health = hero.health - 10
        hero.lastDamageTime = love.timer.getTime()
    end

    hero.update = function (dt)
        -- keyboard actions for our hero
        for _, key in pairs({'a', 'd'}) do
            if love.keyboard.isDown(key) then
                hero.move(keyMap[key])
            end
        end

        if hero.body:getY() > 1500 or hero.health <= 0 then
            love.load()
        end

        if hero.lastDamageTime > 0 then
            if love.timer.getTime() > hero.lastDamageTime + 1 then
                hero.lastDamageTime = -1
                hero.backHealth = hero.health
            end
        end
    end

    hero.keypressed = function (key)
        if key == 'space' then
            hero.shoot()
            currentVelX, currentVelY = hero.body:getLinearVelocity()
            hero.body:setLinearVelocity(0, currentVelY)
        elseif key == 'w' and hero.jumpCount > 0 then
            hero.jump()
        elseif key == "c" and hero.inEnemyRange ~= nil then
            hero.inEnemyRange.color = hero.inEnemyRange.safeColor
        end

        hero.item.playerPressed(key)
    end

    hero.keyreleased = function (key)
        if key == 'a' or  key == 'd' then
            hero.stopHorMove()
        elseif key == "c" and hero.inEnemyRange ~= nil then
            hero.inEnemyRange.color = hero.inEnemyRange.dangerColor
        end
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
    
	-- Remove unneeded object layer
	map:removeLayer("spawn")

    return hero
end

return Player