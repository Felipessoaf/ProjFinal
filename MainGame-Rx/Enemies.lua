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
        
    Enemies.scheduler = scheduler

    -- Commom Observables/schedulers
    Enemies.shootScheduler = rx.Subject.create()

	scheduler:schedule(function()
        coroutine.yield(1)
        while true do
            Enemies.shootScheduler:onNext()
            coroutine.yield(math.random())
        end
    end)

	-- Get enemies spawn objects
	for k, object in pairs(map.objects) do
        if object.name == "shooterSpawn" then
			Enemies.CreateShooter(object.x, object.y, scheduler)
        elseif object.name == "patrolSpawn" then
			Enemies.CreatePatrol(object.x, object.y)
        elseif object.name == "quickTimeSpawn" then
			Enemies.CreateQuickTime(object.x, object.y, scheduler)
        elseif object.name == "bossSpawn" then
			Enemies.CreateBoss(object.x, object.y, scheduler)
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
	enemy.fixture:setUserData({properties = enemy})
	enemy.fixture:setCategory(3)

    initializeShots(enemy.shots, 10, scheduler)

    -- Atira
    Enemies.shootScheduler
        :filter(function()
            return enemy.alive and math.random() > 0.3
        end)
        :subscribe(function()
            enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
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
    --todo: como seria pra adicionar um timer pra dar erro se passar o tempo (0.5) sem apertar nada
    --todo: tentar implementação mais simples
    
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
    quickTimeRange.sequence = rx.BehaviorSubject.create()
    -- quickTimeRange.acceptedKeys = {
    --     down = true,
    --     up = true,
    --     left = true,
    --     right = true
    -- }

    local trySequence = quickTimeRange.playerPressed
        :filter(function(key)
            --todo: transformar em tabela {"key"=true...}
            return key == "down" or key == "up" or key == "left" or key == "right" and enemy.sequenceTries > 0
            -- return quickTimeRange.acceptedKeys[key] and enemy.sequenceTries > 0
        end)
    
    trySequence
        :subscribe(function()
            quickTimeRange.sequence:onNext(enemy.sequence[enemy.sequenceTries])
        end)

    local match, wrong = trySequence
        :zip(quickTimeRange.sequence)
        :partition(function(try, answer)
            -- print(try, answer)
            return try == answer
        end)

    local miss = match
        :TimeInterval(scheduler)
        :filter(function(dt, try, answer)
            -- print(dt, try, answer)
            return dt > 0.5 and enemy.sequenceTries > 1
        end)

    local onTime = match
        :TimeInterval(scheduler)
        :filter(function(dt, try, answer)
            return dt < 0.5 or enemy.sequenceTries == 1
        end)

    miss
        :merge(wrong)
        :execute(function()
            hero.health:onNext(hero.health:getValue() - 10)
            quickTimeRange.color = quickTimeRange.wrongColor
            enemy.sequenceTries = -1
        end)
        :delay(1, scheduler)
        :subscribe(function(try, step)
            enemy.resetSequence()
        end)

    onTime
        :execute(function()
            quickTimeRange.color = quickTimeRange.matchColor
            enemy.sequenceTries = enemy.sequenceTries + 1
        end)
        :filter(function()
            return enemy.sequenceTries == #enemy.sequence+1
        end)
        :subscribe(function()
            killEnemy(enemy)            
            wall.body:setActive(false)
            quickTimeRange.body:setActive(false)
        end)

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
    
    enemy.resetSequence = function()
        enemy.sequenceTries = 1
        quickTimeRange.color = quickTimeRange.defaultColor
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

    enemy.shots = {}

	-- Physics
	enemy.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
	enemy.body:setFixedRotation(true)
	enemy.shape = love.physics.newRectangleShape(enemy.width, enemy.height)
	enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 2)
	enemy.fixture:setUserData({properties = enemy})
    enemy.fixture:setCategory(3)

    initializeShots(enemy.shots, 40, scheduler)

    -- -- Area alcance visao
    local enemyRange = {}
    enemyRange.tag = "EnemyRange"
    enemyRange.color = {1, 132/255, 0, 0.5}
    enemyRange.outRangeColor = {1, 132/255, 0, 0.5}
    enemyRange.safeColor = {0, 1, 0, 0.5}
    enemyRange.dangerColor = {1, 0, 0, 0.5}
    enemyRange.body = love.physics.newBody(world, enemy.initX, enemy.initY)
    enemyRange.shape = love.physics.newRectangleShape(350, 500)
    enemyRange.fixture = love.physics.newFixture(enemyRange.body, enemyRange.shape)
    enemyRange.fixture:setUserData({properties = enemyRange})
    enemyRange.fixture:setSensor(true)

    -- Change state
    scheduler:schedule(function()
        while true do
            coroutine.yield(3)
            local next = enemy.state + 1
            enemy.state = next <= enemy.maxState and next or 1
        end
    end)

    -- Atira
    Enemies.shootScheduler
        :filter(function()
            return enemy.alive and enemy.state == 1
        end)
        :subscribe(function()
            local ytop = enemy.body:getY() - enemy.height/2
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*1/5})
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*2/5})
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*3/5})
            enemyShoot(enemy.shots, {enemy.body:getX(), ytop + enemy.height*4/5})
        end)
    
    -- Functions
    enemy.damage = function(val)
        enemy.health = enemy.health - val
    end

    enemy.draw = function()
        --enemyrange
        if enemy.state == 2 then 
            love.graphics.setColor(unpack(enemyRange.color))
            love.graphics.polygon("fill", enemyRange.body:getWorldPoints(enemyRange.shape:getPoints()))
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
		rx.Observable.fromTable(enemy.shots, pairs, false)
			:filter(function(shot)
				return shot.fired
			end)
			:subscribe(function(shot)
				love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
			end)

    end

    table.insert(Enemies.enemies, enemy)  
end

function killEnemy(enemy)
    Enemies.scheduler:schedule(function()
        coroutine.yield(.01)
        rx.Observable.fromTable(enemy.shots, pairs, false)
            :subscribe(function(shot)
                shot.body:setActive(false)
                shot.fixture:setMask(2,3)
            end)
        enemy.shots = {}
        enemy.body:setActive(false)
    end)
    enemy.alive = false
end

function initializeShots(tb, count, scheduler)
    rx.Observable.fromRange(1, count)
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
			table.insert(tb, shot)
		end)
end

function enemyShoot(shotsTable, pos)
    rx.Observable.fromTable(shotsTable, pairs, false)
        :filter(function(shot)
            return not shot.fired
        end)
        :first()
        :subscribe(function(shot)
            shot.body:setLinearVelocity(-shot.speed, 0)
            shot.body:setPosition(unpack(pos))
            shot.fired = true
            shot.body:setActive(true)
        end)
end

return Enemies