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
        elseif object.name == "patrolSpawn" then
			Enemies.CreatePatrol(object.x, object.y)
        elseif object.name == "quickTimeSpawn" then
			Enemies.CreateQuickTime(object.x, object.y, scheduler)
        end
	end
    
    -- Draw enemies
    -- TODO: Separar em tabelas diferentes enemies alive vs not alive
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
	enemy.fixture:setUserData({properties = enemy})
	enemy.fixture:setCategory(3)

	rx.Observable.fromRange(1, 10)
		:subscribe(function ()
			local shot = {}
			shot.tag = "EnemyShot"
			shot.width = 3
			shot.height = 3
			shot.fired = false
			shot.speed = 100
			shot.body = love.physics.newBody(world, -8000, -8000, "dynamic")
			shot.body:setActive(false)
			shot.body:setFixedRotation(true)
			shot.body:setGravityScale(0)
			shot.body:setSleepingAllowed(true)
			shot.body:setBullet(true)
			shot.shape = love.physics.newRectangleShape(shot.width, shot.height)
			shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
			shot.fixture:setUserData({properties = shot})
			shot.fixture:setCategory(3)
			shot.fixture:setMask(3)
            shot.fixture:setSensor(true)
            shot.reset = function()
                shot.fired = false 
                scheduler:schedule(function()
                    coroutine.yield(.01)
                    shot.body:setActive(false)
                end)
            end
			table.insert(enemy.shots, shot)
		end)

	-- Atira
	scheduler:schedule(function()
			coroutine.yield(1)
			while true and enemy.alive do
				enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
				coroutine.yield(math.random(.5,2))
			end
		end)

   	-- Checa alerta perigo
    local alertaPerigo = {}
    alertaPerigo.cor = {0,0,0,0}
    alertaPerigo.y = 0
    local enemiesShotsPos = rx.Subject.create()
    local enemyShotsAlertRange = enemiesShotsPos:filter(function(pos)
            local rightSide = hero.body:getX() + love.graphics.getWidth()/2
            return pos[1] > rightSide and pos[1] < rightSide + 150
        end)

    enemyShotsAlertRange:subscribe(function (pos)
        alertaPerigo.cor = {1,0,0,1}
        alertaPerigo.y = pos[2]
    end)

    enemyShotsAlertRange:debounce(.2, scheduler)
        :subscribe(function (pos)
            alertaPerigo.cor = {0,0,0,0}
        end)

    -- Atualiza pos dos tiros
    scheduler:schedule(function()
            coroutine.yield(1)
            while true and enemy.alive do
                rx.Observable.fromTable(enemy.shots, pairs, false)
                    :filter(function(shot)
                        return shot.fired
                    end)
                    :subscribe(function(shot)
                        enemiesShotsPos:onNext({shot.body:getPosition()})
                    end)
                coroutine.yield(.3)
            end
        end)

	-- Functions
	enemy.draw = function()
		love.graphics.setColor(135/255, 0, 168/255)
		love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
		love.graphics.polygon("line", enemy.body:getWorldPoints(enemy.shape:getPoints()))

		-- let's draw our enemy shots
		love.graphics.setColor(0, 0, 0)
		rx.Observable.fromTable(enemy.shots, pairs, false)
			:filter(function(shot)
				return shot.fired
			end)
			:subscribe(function(shot)
				love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
			end)

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(enemy.body:getX()), math.floor(enemy.body:getY()))
            
        -- Alerta perigo
        local offsetX, offsetY = -(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4)
        love.graphics.setColor(unpack(alertaPerigo.cor))
        love.graphics.rectangle("line", love.graphics.getWidth()-20 + offsetX, alertaPerigo.y -heroPosY + love.graphics.getHeight() * 3/4 + offsetY, 20, 20)
	end

   table.insert(Enemies.enemies, enemy)  
end

function Enemies.CreatePatrol(posX, posY)
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
	enemy.fixture:setUserData({properties = enemy})
	enemy.fixture:setCategory(3)

    -- -- Area alcance visao
    local enemyRange = {}
    enemyRange.tag = "EnemyRange"
    enemyRange.color = {1, 132/255, 0, 0.5}
    enemyRange.outRangeColor = {1, 132/255, 0, 0.5}
    enemyRange.safeColor = {0, 1, 0, 0.5}
    enemyRange.dangerColor = {1, 0, 0, 0.5}
    enemyRange.body = love.physics.newBody(world, enemy.initX, enemy.initY)
    enemyRange.shape = love.physics.newRectangleShape(300, 100)
    -- attach shape to body
    enemyRange.fixture = love.physics.newFixture(enemyRange.body, enemyRange.shape)
    enemyRange.fixture:setUserData({properties = enemyRange})
    enemyRange.fixture:setSensor(true)

	-- Functions
	enemy.draw = function()
		love.graphics.setColor(247/255, 154/255, 22/255)
		love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
		love.graphics.polygon("line", enemy.body:getWorldPoints(enemy.shape:getPoints()))

        love.graphics.setColor(unpack(enemyRange.color))
        love.graphics.polygon("fill", enemyRange.body:getWorldPoints(enemyRange.shape:getPoints()))
	end

   table.insert(Enemies.enemies, enemy)  
end

function Enemies.CreateQuickTime(posX, posY, scheduler)
	local enemy = {}
	-- Properties
	enemy.tag = "Enemy"
	enemy.initX = posX
	enemy.initY = posY
	enemy.width = 40
	enemy.height = 20
    enemy.alive = true

    enemy.shots = {}
    enemy.sequence = {
        "down",
        "up",
        "left",
        "right"
    }

	-- Physics
	enemy.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
	enemy.body:setFixedRotation(true)
	enemy.shape = love.physics.newRectangleShape(enemy.width, enemy.height)
	enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 2)
	enemy.fixture:setUserData({properties = enemy})
    enemy.fixture:setCategory(3)

    --Wall
    local wall = {}
	wall.body = love.physics.newBody(world, enemy.initX + 50, enemy.initY, "static")
	wall.body:setFixedRotation(true)
	wall.shape = love.physics.newRectangleShape(enemy.width, enemy.height*30)
	wall.fixture = love.physics.newFixture(wall.body, wall.shape, 2)
	wall.fixture:setUserData({properties = wall})
	wall.fixture:setCategory(3)

    -- -- Area alcance visao
    local quickTimeRange = {}
    quickTimeRange.tag = "QuickTimeRange"
    quickTimeRange.defaultColor = {64/255, 86/255, 1, 0.3}
    quickTimeRange.color = quickTimeRange.defaultColor
    quickTimeRange.matchColor = {0, 1, 0, 0.5}
    quickTimeRange.wrongColor = {1, 0, 0, 0.5}
    quickTimeRange.body = love.physics.newBody(world, enemy.initX, enemy.initY)
    quickTimeRange.shape = love.physics.newRectangleShape(300, 100)
    quickTimeRange.fixture = love.physics.newFixture(quickTimeRange.body, quickTimeRange.shape)
    quickTimeRange.fixture:setUserData({properties = quickTimeRange})
    quickTimeRange.fixture:setSensor(true)
    quickTimeRange.playerPressed = rx.BehaviorSubject.create()
    quickTimeRange.playerInRange = rx.BehaviorSubject.create()
    quickTimeRange.playerInRange
        :filter(function(value)
            return value ~= nil
        end)
        :subscribe(function()
            enemy.resetSequence()
        end)
    quickTimeRange.enterSequence = rx.BehaviorSubject.create()

	-- Functions
    enemy.draw = function()
        --enemy
		love.graphics.setColor(242/255, 130/255, 250/255)
		love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
        love.graphics.polygon("line", enemy.body:getWorldPoints(enemy.shape:getPoints()))
        
        --wall
		love.graphics.setColor(125/255, 92/255, 0)
		love.graphics.polygon("fill", wall.body:getWorldPoints(wall.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
        love.graphics.polygon("line", wall.body:getWorldPoints(wall.shape:getPoints()))
        
        for i, key in pairs(enemy.sequence) do 
            love.graphics.setNewFont(15)
            love.graphics.print(key, enemy.initX - 30, (enemy.initY - enemy.height) - 20 * (#enemy.sequence - i))
        end

        --range
        love.graphics.setColor(unpack(quickTimeRange.color))
        love.graphics.polygon("fill", quickTimeRange.body:getWorldPoints(quickTimeRange.shape:getPoints()))
    end
    
    enemy.resetSequence = function()
        enemy.sequenceTries = 0
        quickTimeRange.color = quickTimeRange.defaultColor

        local right, wrong = quickTimeRange.playerPressed
            :filter(function(key)
                return key == "down" or key == "up" or key == "left" or key == "right" and enemy.sequenceTries >= 0
            end)
            :zip(rx.Observable.fromTable(enemy.sequence, pairs, false))
            :partition(function(try, step)
                return try == step
            end)

        right
            :execute(function()
                quickTimeRange.color = quickTimeRange.matchColor
                enemy.sequenceTries = enemy.sequenceTries + 1
            end)
            :filter(function()
                return enemy.sequenceTries == #enemy.sequence
            end)
            :subscribe(function(try, step)
                print("YEAH")
            end)

        wrong
            :execute(function()
                quickTimeRange.color = quickTimeRange.wrongColor
                enemy.sequenceTries = -1
            end)
            :delay(1, scheduler)
            :subscribe(function(try, step)
                enemy.resetSequence()
            end)
    end

    table.insert(Enemies.enemies, enemy)  
end

return Enemies