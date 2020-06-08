-- Layers module
local Layers = require 'Layers'

-- CollisionManager module
local CollisionManager = require 'CollisionManager'

local Enemies = {}

function Enemies.Init()
    -- Create new dynamic data layer
    local enemyLayer = map:addCustomLayer(Layers.enemy.name, Layers.enemy.number)

    Enemies.enemies = {}

    -- Commom schedulers
	Enemies.lastShotTime = love.timer.getTime()
	Enemies.nextShotTimeInterval = 1

	-- Get enemies spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "shooterSpawn" then
			Enemies.CreateShooter(object.x, object.y)
        elseif object.name == "patrolSpawn" then
			Enemies.CreatePatrol(object.x, object.y)
        elseif object.name == "quickTimeSpawn" then
			Enemies.CreateQuickTime(object.x, object.y)
        elseif object.name == "bossSpawn" then
			Enemies.CreateBoss(object.x, object.y, scheduler)
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

    Enemies.update = function(dt)
        -- Shoots
        local curTime = love.timer.getTime()
        if curTime > Enemies.lastShotTime + Enemies.nextShotTimeInterval then
            for k, enemy in pairs(Enemies.enemies) do
                if enemy.alive and enemy.shootSchedule then
                    enemy.shootSchedule()
                end
            end
            Enemies.lastShotTime = curTime
            Enemies.nextShotTimeInterval = math.random()
        end
        
    end

    Enemies.stateText = "Enemies Left: " .. tostring(#Enemies.enemies)
    
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
    initializeShots(enemy.shots, 10)

    enemy.alertaPerigo = {}
    enemy.alertaPerigo.cor = {0,0,0,0}
    enemy.alertaPerigo.y = 0

    -- Functions
    enemy.shootSchedule = function()
        if math.random() > 0.3 then
            enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
            enemy.nextShotTimeInterval = math.random(.5,2)
        end
    end

    enemy.update = function (dt)
        if enemy.alive then            
            local curTime = love.timer.getTime()

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
    local enemyRange = createRange(enemy, 300, 100)

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

function Enemies.CreateQuickTime(posX, posY)
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

    -- -- Area quicktime
    local onMatch = function()
        killEnemy(enemy)
        wall.body:setActive(false)
        quickTimeRange.body:setActive(false)
    end
    local quickTimeRange = createQuickRange(enemy, onMatch)

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
            if enemy.sequenceTries ~= nil and i < enemy.sequenceTries then
                love.graphics.setColor(0, 1, 0)
            else 
                love.graphics.setColor(0, 0, 0)
            end

            love.graphics.setNewFont(15)
            love.graphics.print(key, enemy.initX - 30, (enemy.initY - enemy.height) - 20 * (#enemy.sequence - i))
        end

        --range
        love.graphics.setColor(unpack(quickTimeRange.color))
        love.graphics.polygon("fill", quickTimeRange.body:getWorldPoints(quickTimeRange.shape:getPoints()))
    end

    table.insert(Enemies.enemies, enemy)  
end

function Enemies.CreateBoss(posX, posY, scheduler)
	local enemy = {}
	-- Properties
	enemy.tag = "Boss"
	enemy.initX = posX
	enemy.initY = posY
	enemy.width = 80
	enemy.height = 100
    enemy.alive = true
    enemy.shooterColor = {135/255, 0, 168/255}
    enemy.patrolColor = {247/255, 154/255, 22/255}
    enemy.quickTimeColor = {242/255, 130/255, 250/255}
    enemy.currentColor = enemy.shooterColor
    enemy.health = 100
    enemy.state = 1
    enemy.maxState = 3
    enemy.lastChange = love.timer.getTime()
    enemy.TimeToChange = 0.5

    enemy.shots = {}
    enemy.sequence = {
        "up",
        "up",
        "down",
        "down",
        "left",
        "right",
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

    initializeShots(enemy.shots, 40)

    -- Area alcance visao
    local enemyRange = createRange(enemy, 350, 500)

    -- Area quicktime
    local quickTimeRange = createQuickRange(enemy, function()
        enemy.damage(10)
    end)

    -- Functions
    enemy.damage = function(val)
        enemy.health = enemy.health - val

        -- Checa vida
        if enemy.health <= 0 then
            killEnemy(enemy)
        end
    end

    enemy.shootSchedule = function()
        if enemy.state == 1 then
            local ytop = enemy.body:getY() - enemy.height/2
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*1/5})
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*2/5})
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*3/5})
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*4/5})
        end
    end

    enemy.shotHit = function()
        if (enemy.state == 1) or (enemy.state == 2 and enemyRange.color == enemyRange.safeColor) then
            enemy.damage(10)
        end
    end
    
    enemy.resetSequence = function()
        enemy.sequenceTries = 1
        quickTimeRange.color = quickTimeRange.defaultColor
    end

    enemy.update = function()
        -- Change state
        local curTime = love.timer.getTime()
        if curTime > enemy.lastChange + enemy.TimeToChange then
            local next = enemy.state + 1
            enemy.state = next <= enemy.maxState and next or 1
            enemy.lastChange = curTime
        end
    end

    enemy.draw = function()
        --enemyrange
        if enemy.state == 2 then 
            love.graphics.setColor(unpack(enemyRange.color))
            love.graphics.polygon("fill", enemyRange.body:getWorldPoints(enemyRange.shape:getPoints()))
        end

        --quicktime
        if enemy.state == 3 then         
            for i, key in pairs(enemy.sequence) do 
                if enemy.sequenceTries ~= nil and i < enemy.sequenceTries then
                    love.graphics.setColor(0, 1, 0)
                else 
                    love.graphics.setColor(0, 0, 0)
                end
    
                love.graphics.setNewFont(15)
                love.graphics.print(key, enemy.initX - 30, (enemy.initY - enemy.height) - 20 * (#enemy.sequence - i))
            end
    
            --range
            love.graphics.setColor(unpack(quickTimeRange.color))
            love.graphics.polygon("fill", quickTimeRange.body:getWorldPoints(quickTimeRange.shape:getPoints()))
        end
        

        --enemy
		love.graphics.setColor(unpack(enemy.currentColor))
		love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
		love.graphics.setColor(0, 0, 0)
        love.graphics.polygon("line", enemy.body:getWorldPoints(enemy.shape:getPoints()))

        --health
        love.graphics.setColor(1,0,0)
        love.graphics.rectangle("fill", enemy.body:getX() - 50, enemy.body:getY() - enemy.height * 3/4, enemy.health, 10)
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("line", enemy.body:getX() - 50, enemy.body:getY() - enemy.height * 3/4, 100, 10)
        
		-- let's draw our enemy shots
		love.graphics.setColor(0, 0, 0)
        for _, shot in pairs(enemy.shots) do
            if shot.fired then
                love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
            end
        end

    end

    table.insert(Enemies.enemies, enemy)  
end

function killEnemy(enemy)
    table.insert(CollisionManager.enemiesToDisable, enemy)
    enemy.alive = false

    -- Atualiza texto
    local count = 0
    local allDefeated = true
    for k, shot in pairs(Enemies.enemies) do
        if enemy.alive then
            count = count + 1
            allDefeated = false
        end
    end
    
    if allDefeated then
        Enemies.stateText = "CONGRATULATIONS!"
    else
        Enemies.stateText = "Enemies Left: " .. tostring(value)
    end   
end

function initializeShots(tb, count)
    for i=1,count do
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
        table.insert(tb, shot)
    end
end

function enemyShoot(shotsTable, pos)
    for k, shot in pairs(shotsTable) do
        if not shot.fired then
            shot.body:setLinearVelocity(pos[1] > heroPosX and -shot.speed or shot.speed, 0)
            shot.body:setPosition(unpack(pos))
            shot.fired = true
            shot.body:setActive(true)

            break
        end
    end
end

function createRange(enemy, width, height)
    local enemyRange = {}
    enemyRange.tag = "EnemyRange"
    enemyRange.color = {1, 132/255, 0, 0.5}
    enemyRange.outRangeColor = {1, 132/255, 0, 0.5}
    enemyRange.safeColor = {0, 1, 0, 0.5}
    enemyRange.dangerColor = {1, 0, 0, 0.5}
    enemyRange.body = love.physics.newBody(world, enemy.initX, enemy.initY)
    enemyRange.shape = love.physics.newRectangleShape(width, height)
    enemyRange.fixture = love.physics.newFixture(enemyRange.body, enemyRange.shape)
    enemyRange.fixture:setUserData({properties = enemyRange})
    enemyRange.fixture:setSensor(true)

    return enemyRange
end

function createQuickRange(enemy, onMatch)
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
    quickTimeRange.lastMatchTime = love.timer.getTime()
    quickTimeRange.timeToReset = 0
    
    quickTimeRange.playerPressed = function(key)
        if key == "down" or key == "up" or key == "left" or key == "right" and enemy.sequenceTries > 0 then
            if key == enemy.sequence[enemy.sequenceTries] then
                --match
                local dt = love.timer.getTime() - quickTimeRange.lastMatchTime
                if dt < 0.5 or enemy.sequenceTries == 1 then
                    --onTime
                    quickTimeRange.lastMatchTime = love.timer.getTime()
                    quickTimeRange.color = quickTimeRange.matchColor
                    enemy.sequenceTries = enemy.sequenceTries + 1

                    --finished successfully
                    if enemy.sequenceTries == #enemy.sequence+1 then
                        onMatch()
                    end
                else
                    --miss
                    quickTimeRange.missWrong()
                end
            else
                --wrong
                quickTimeRange.missWrong()
            end
        end
    end

	-- Functions    
    enemy.resetSequence = function()
        enemy.sequenceTries = 1
        quickTimeRange.color = quickTimeRange.defaultColor
    end

    quickTimeRange.playerInRange = function()
        enemy.resetSequence()
    end

    quickTimeRange.missWrong = function()
        hero.damage(10)
        quickTimeRange.color = quickTimeRange.wrongColor
        enemy.sequenceTries = -1

        quickTimeRange.timeToReset = 1
        quickTimeRange.shouldReset = true
    end
    
    enemy.update = function (dt)
        quickTimeRange.timeToReset = quickTimeRange.timeToReset - dt
        if quickTimeRange.shouldReset and quickTimeRange.timeToReset < 0 then
            enemy.resetSequence()
            quickTimeRange.shouldReset = false
        end
    end

    return quickTimeRange
end

return Enemies