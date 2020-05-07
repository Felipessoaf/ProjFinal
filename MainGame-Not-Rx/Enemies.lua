-- Layers module
local Layers = require 'Layers'

-- CollisionManager module
local CollisionManager = require 'CollisionManager'

local Enemies = {}

function Enemies.Init()
   -- Create new dynamic data layer
   local enemyLayer = map:addCustomLayer(Layers.enemy.name, Layers.enemy.number)

   Enemies.enemies = {}

	-- Get enemies spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "shooterSpawn" then
			Enemies.CreateShooter(object.x, object.y)
        elseif object.name == "patrolSpawn" then
			Enemies.CreatePatrol(object.x, object.y)
        end
	end
    
	-- Draw enemies
    enemyLayer.draw = function(self)
        for k, enemy in pairs(Enemies.enemies) do
            if enemy.alive then
                enemy.draw()
            end
        end
   end

   -- Remove unneeded object layer
--    map:removeLayer("shooterSpawn")
--    map:removeLayer("patrolSpawn")
   
   return Enemies.enemies
end

function Enemies.CreateShooter(posX, posY)
	local enemy = {}
	-- Properties
	enemy.tag = "Enemy"
	enemy.initX = posX
	enemy.initY = posY
	enemy.width = 40
	enemy.height = 20
	enemy.alive = true
	enemy.lastShotTime = love.timer.getTime()
	enemy.nextShotTimeInterval = 1
	enemy.lastDangerResetTime = love.timer.getTime()
	enemy.dangerTimeMax = 1
	enemy.lastDangerAlertTime = love.timer.getTime()
	enemy.dangerAlertTimeInterval = 0.3

	-- Physics
	enemy.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
	enemy.body:setFixedRotation(true)
	enemy.shape = love.physics.newRectangleShape(enemy.width, enemy.height)
	enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 2)
	enemy.fixture:setUserData({properties = enemy})
	enemy.fixture:setCategory(3)

	enemy.shots = {}

    for i=1,10 do
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
            table.insert(CollisionManager.enemyShotsToDisable, shot)
        end
        table.insert(enemy.shots, shot)
    end

    enemy.alertaPerigo = {}
    enemy.alertaPerigo.cor = {0,0,0,0}
    enemy.alertaPerigo.y = 0

    -- Functions
    enemy.enemyShoot = function (shotsTable, pos)   
        for k, shot in pairs(shotsTable) do
            if not shot.fired then
                shot.body:setLinearVelocity(-shot.speed, 0)
                shot.body:setPosition(unpack(pos))
                shot.fired = true
                shot.body:setActive(true)

                break
            end
        end
    end

    enemy.update = function (dt)
        if enemy.alive then
            -- Shoots
            local curTime = love.timer.getTime()
            if curTime > enemy.lastShotTime + enemy.nextShotTimeInterval then
                enemy.lastShotTime = curTime
                enemy.enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
                enemy.nextShotTimeInterval = math.random(.5,2)
            end

            -- Calculate dangerAlert
            if curTime > enemy.lastDangerAlertTime + enemy.dangerAlertTimeInterval then
                enemy.lastDangerAlertTime = curTime
                for _, shot in pairs(enemy.shots) do
                    local rightSide = hero.body:getX() + love.graphics.getWidth()/2
                    local posX, posY = shot.body:getPosition()
                    if posX > rightSide and posX < rightSide + 150 then
                        enemy.alertaPerigo.cor = {1,0,0,1}
                        enemy.alertaPerigo.y = posY
                    end
                end
            end

            -- Reset alert
            if curTime > enemy.lastDangerResetTime + enemy.dangerTimeMax then
                enemy.lastDangerResetTime = curTime
                enemy.alertaPerigo.cor = {0,0,0,0}
            end
        end
    end

	enemy.draw = function()
		love.graphics.setColor(135/255, 0, 168/255)
		love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
		love.graphics.polygon("line", enemy.body:getWorldPoints(enemy.shape:getPoints()))

		-- let's draw our enemy shots
		love.graphics.setColor(0, 0, 0)
        for _, shot in pairs(enemy.shots) do
            if shot.fired then
                love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
            end
        end

        -- Temporarily draw a point at our location so we know
        -- that our sprite is offset properly
        -- love.graphics.setPointSize(5)
        -- love.graphics.points(math.floor(enemy.body:getX()), math.floor(enemy.body:getY()))
            
        -- Alerta perigo
        local offsetX, offsetY = -(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4)
        love.graphics.setColor(unpack(enemy.alertaPerigo.cor))
        love.graphics.rectangle("line", love.graphics.getWidth()-20 + offsetX, enemy.alertaPerigo.y -heroPosY + love.graphics.getHeight() * 3/4 + offsetY, 20, 20)
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
    enemy.update = function (dt)
        
    end

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

return Enemies