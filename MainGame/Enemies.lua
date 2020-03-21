-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- Layers module
local Layers = require 'Layers'

local Enemies = {}

function Enemies.Init(scheduler)
   -- Create new dynamic data layer
   local enemyLayer = map:addCustomLayer(Layers.enemy.name, Layers.enemy.number)

   Enemies.enemies = {}

	-- Get enemies spawn objects
	for k, object in pairs(map.objects) do
		if object.name == "shooterSpawn" then
			Enemies.CreateShooter(object.x, object.y, scheduler)
			break
		end
	end
    
	-- Draw enemies
   enemyLayer.draw = function(self)
      local enemiesAlive = rx.Observable.fromTable(Enemies.enemies, pairs, false)
                              :filter(function(enemy)
                                    return enemy.alive
                              end)
      
      enemiesAlive:subscribe(function(enemy)
               enemy.draw()
            end)
   end
   
   return Enemies.enemies
end

function Enemies.CreateShooter(posX, posY, scheduler)
   local enemy = {}
   -- Properties
   enemy.tag = "Enemy"
   enemy.initX = posX
   enemy.initY = posY
   enemy.width = 40
   enemy.height = 20
   enemy.alive = true

   enemy.shots = {}

   -- Physics
   enemy.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
   enemy.body:setFixedRotation(true)
   enemy.shape = love.physics.newRectangleShape(enemy.width, enemy.height)
   enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 2)
   enemy.fixture:setUserData(enemy)
   enemy.fixture:setCategory(3)

   -- Functions
   enemy.draw = function()
      love.graphics.setColor(135/255, 0, 168/255)
      love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
      love.graphics.setColor(0, 0, 0)
      love.graphics.polygon("line", enemy.body:getWorldPoints(enemy.shape:getPoints()))

      -- let's draw our enemy shots
      -- love.graphics.setColor(0, 0, 0)
      -- rx.Observable.fromTable(enemy.shots, pairs, false)
      --    :filter(function(shot)
      --          return shot.fired
      --    end)
      --    :subscribe(function(shot)
      --          love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
      --    end)

		-- Temporarily draw a point at our location so we know
		-- that our sprite is offset properly
		love.graphics.setPointSize(5)
		love.graphics.points(math.floor(enemy.body:getX()), math.floor(enemy.body:getY()))
   end

   -- rx.Observable.fromRange(1, 10)
   --     :subscribe(function ()
   --         local shot = {}
   --         shot.tag = "EnemyShot"
   --         shot.width = 3
   --         shot.height = 3
   --         shot.fired = false
   --         shot.speed = 100
   --         shot.body = love.physics.newBody(world, -8000, -8000, "dynamic")
   --         shot.body:setActive(false)
   --         shot.body:setFixedRotation(true)
   --         shot.body:setGravityScale(0)
   --         shot.body:setSleepingAllowed(true)
   --         shot.body:setBullet(true)
   --         shot.shape = love.physics.newRectangleShape(shot.width, shot.height)
   --         shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
   --         shot.fixture:setUserData(shot)
   --         shot.fixture:setCategory(3)
   --         shot.fixture:setMask(3)
   --         shot.fixture:setSensor(true)
   --         table.insert(enemy.shots, shot)
   --     end)

   -- Atira
   -- scheduler:schedule(function()
   --         coroutine.yield(1)
   --         while true and enemy.alive do
   --             enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
   --             coroutine.yield(math.random(.5,2))
   --         end
   --     end)

   table.insert(Enemies.enemies, enemy)  
end

return Enemies