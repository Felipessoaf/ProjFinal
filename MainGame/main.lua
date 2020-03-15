local rx = require 'rx'
require 'rx-love'

local sti = require "sti"

-- Maps keys to players and directions
local keyMap = {
  a = -1,
  d = 1
}

local scheduler = rx.CooperativeScheduler.create()

-- Declare initial state of game
love.load:subscribe(function (arg)
    local HERO_CATEGORY = 3
    local HERO_SHOT_CATEGORY = 4
    local ENEMY_CATEGORY = 5
	local ENEMY_SHOT_CATEGORY = 6
	
	-- load map
	map = sti("Maps/test1.lua", { "box2d" })

    -- the height of a meter our worlds will be 64px
    love.physics.setMeter(64)

    -- create a world for the bodies to exist in with horizontal gravity
    -- of 0 and vertical gravity of 9.81
    world = love.physics.newWorld(0, 9.81*64, true)
    
	-- Prepare collision objects
	map:box2d_init(world)

    -- --Collision callbacks:
    -- world:setCallbacks(bC, eC, preS, postS)

    -- objects = {} -- table to hold all our physical objects
    -- mapObjs = {} -- table to hold all our map objects

    -- --map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map--

    -- ground1 = {}
    -- ground1.tag = "Ground"
    -- ground1.color = {112/255, 72/255, 7/255}
    -- ground1.body = love.physics.newBody(world, -100, 650)
    -- ground1.shape = love.physics.newRectangleShape(650, 150)
    -- -- attach shape to body
    -- ground1.fixture = love.physics.newFixture(ground1.body, ground1.shape)
    -- ground1.fixture:setUserData(ground1)

    -- table.insert(mapObjs, ground1)

    -- ground2 = {}
    -- ground2.tag = "Ground"
    -- ground2.color = {112/255, 72/255, 7/255}
    -- ground2.body = love.physics.newBody(world, 550, 650)
    -- ground2.shape = love.physics.newRectangleShape(650, 300)
    -- -- attach shape to body
    -- ground2.fixture = love.physics.newFixture(ground2.body, ground2.shape)
    -- ground2.fixture:setUserData(ground2)

    -- table.insert(mapObjs, ground2)

    -- wall1 = {}
    -- wall1.tag = "Wall"
    -- wall1.color = {9/255, 84/255, 9/255}
    -- wall1.body = love.physics.newBody(world, -550, 225)
    -- wall1.shape = love.physics.newRectangleShape(650, 1000)
    -- -- attach shape to body
    -- wall1.fixture = love.physics.newFixture(wall1.body, wall1.shape)
    -- wall1.fixture:setUserData(wall1)

    -- table.insert(mapObjs, wall1)

    -- wall2 = {}
    -- wall2.tag = "Wall"
    -- wall2.color = {9/255, 84/255, 9/255}
    -- wall2.body = love.physics.newBody(world, 1200, 225)
    -- wall2.shape = love.physics.newRectangleShape(650, 1000)
    -- -- attach shape to body
    -- wall2.fixture = love.physics.newFixture(wall2.body, wall2.shape)
    -- wall2.fixture:setUserData(wall2)

    -- table.insert(mapObjs, wall2)

    -- platforms = {{50, 400}, {150, 450}, {500, 450}, {600, 400}}
    
    -- rx.Observable.fromTable(platforms, pairs, false)
    --     :subscribe(function(platPos)
    --         plat = {}
    --         plat.tag = "Platform"
    --         plat.color = {0.20, 0.20, 0.20}
    --         x,y = unpack(platPos)
    --         plat.body = love.physics.newBody(world, x, y, "kinematic")
    --         plat.shape = love.physics.newRectangleShape(100, 25)
    --         -- A higher density gives it more mass.
    --         plat.fixture = love.physics.newFixture(plat.body, plat.shape, 5)
    --         plat.fixture:setUserData(plat)

    --         table.insert(mapObjs, plat)
    --     end)

    -- table.insert(objects, mapObjs)

    -- love.graphics.setBackgroundColor(0.41, 0.53, 0.97)

    -- --map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map--

    -- --hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero--

	-- Create new dynamic data layer called "Sprites" as the 8th layer
	local playerLayer = map:addCustomLayer("Player", 3)

	-- Get player spawn object
	local spawn
	for k, object in pairs(map.objects) do
		if object.name == "spawn" then
			spawn = object
			break
		end
	end
	
	hero = {}
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

    -- --hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero--

    -- --enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies--

    -- enemies = {}
    
    -- local enemy = {}
    -- enemy.tag = "Enemy"
    -- enemy.initX = 700
    -- enemy.initY = 480
    -- enemy.width = 40
    -- enemy.height = 20
    -- enemy.alive = true
    -- enemy.shots = {}
    -- enemy.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
    -- enemy.body:setFixedRotation(true)
    -- enemy.shape = love.physics.newRectangleShape(enemy.width, enemy.height)
    -- enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 2)
    -- enemy.fixture:setUserData(enemy)
    -- enemy.fixture:setCategory(3)
    -- table.insert(enemies, enemy)  
        
    -- table.insert(objects, enemies)

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

    -- -- Atira
    -- scheduler:schedule(function()
    --         coroutine.yield(1)
    --         while true and enemy.alive do
    --             enemyShoot(enemy.shots, {enemy.body:getX(), enemy.body:getY()})
    --             coroutine.yield(math.random(.5,2))
    --         end
    --     end)

    -- -- Checa alerta perigo
    -- alertaPerigo = {}
    -- alertaPerigo.cor = {0,0,0,0}
    -- alertaPerigo.y = 0
    -- enemiesShotsPos = rx.Subject.create()
    -- enemyShotsAlertRange = enemiesShotsPos:filter(function(pos)
    --         local rightSide = hero.body:getX() + love.graphics.getWidth()/2
    --         return pos[1] > rightSide and pos[1] < rightSide + 150
    --     end)

    -- enemyShotsAlertRange:subscribe(function (pos)
    --     alertaPerigo.cor = {1,0,0,1}
    --     alertaPerigo.y = pos[2]
    -- end)

    -- enemyShotsAlertRange:debounce(.2, scheduler)
    --     :subscribe(function (pos)
    --         alertaPerigo.cor = {0,0,0,0}
    --     end)

    -- -- Atualiza pos dos tiros
    -- scheduler:schedule(function()
    --         coroutine.yield(1)
    --         while true and enemy.alive do
    --             rx.Observable.fromTable(enemy.shots, pairs, false)
    --                 :filter(function(shot)
    --                     return shot.fired
    --                 end)
    --                 :subscribe(function(shot)
    --                     enemiesShotsPos:onNext({shot.body:getPosition()})
    --                 end)
    --             coroutine.yield(.3)
    --         end
    --     end)

    -- -- Area alcance visao
    -- enemyRange = {}
    -- enemyRange.tag = "EnemyRange"
    -- enemyRange.color = {1, 132/255, 0, 0.5}
    -- enemyRange.outRangeColor = {1, 132/255, 0, 0.5}
    -- enemyRange.safeColor = {0, 1, 0, 0.5}
    -- enemyRange.dangerColor = {1, 0, 0, 0.5}
    -- enemyRange.body = love.physics.newBody(world, enemy.initX, enemy.initY)
    -- enemyRange.shape = love.physics.newRectangleShape(300, 100)
    -- -- attach shape to body
    -- enemyRange.fixture = love.physics.newFixture(enemyRange.body, enemyRange.shape)
    -- enemyRange.fixture:setUserData(enemyRange)
    -- enemyRange.fixture:setSensor(true)

    -- table.insert(objects, enemyRange)


    --enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies--

    --colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes--

    beginContact = rx.Subject.create()
    endContact = rx.Subject.create()
    preSolve = rx.Subject.create()
    postSolve = rx.Subject.create()

    -- Trata reset do grounded para pulo
    beginContact:filter(function(a, b, coll) return (a:getUserData().tag == "Ground" or a:getUserData().tag == "Platform") and b:getUserData().tag == "Hero" end)
                :subscribe(function() hero.grounded = true end)

    -- Trata colisao player com enemyRange
    enterRange = beginContact
        :filter(function(a, b, coll) 
            return a:getUserData().tag == "Hero" and b:getUserData().tag == "EnemyRange" 
        end)
        :map(function ()
            return "enter"
        end)

    exitRange = endContact
        :filter(function(a, b, coll) 
            return a:getUserData().tag == "Hero" and b:getUserData().tag == "EnemyRange" 
        end)
        :map(function ()
            return "exit"
        end)

    rangeState = enterRange:merge(exitRange)

    enterRange:subscribe(function ()
        enemyRange.color = enemyRange.dangerColor
    end)

    exitRange:subscribe(function ()
        enemyRange.color = enemyRange.outRangeColor
    end)

    -- inRange = enterRange:flatMap(function (value)
    --     return rx.Observable.replicate(true)
    -- end)
    -- inRange:subscribe(function() 
    --     -- print("inrange")
    -- end)
    -- enterRange:subscribe(function() 
    -- end)

    --combineLatest
    cPressed = love.keypressed
        :filter(function(key) return key == 'c' end)
        :map(function ()
            return "pressed"
        end)
    cReleased = love.keyreleased
        :filter(function(key) return key == 'c' end)
        :map(function ()
            return "not pressed"
        end)

    cPressState = cPressed:merge(cReleased)

    heroRangeState = rangeState
        :combineLatest(cPressState, function (a, b)
            return a,b-- == "enter" and b == "pressed"
        end)

    heroSafe = heroRangeState:filter(function(a,b)
        return a == "enter" and b == "pressed"
    end)
    heroNotSafe = heroRangeState:filter(function(a,b)
        return a == "enter" and b == "not pressed"
    end)
    
    heroSafe:subscribe(function() 
        enemyRange.color = enemyRange.safeColor
    end)
    
    heroNotSafe:subscribe(function() 
        enemyRange.color = enemyRange.dangerColor
    end)


    -- heroSafe = enterRange
    --     :merge(exitRange)
    --     :subscribe(function(state) 
    --         print("state: "..state)
    --     end)

    -- Trata colisao de tiro do player
    shotHit = beginContact:filter(function(a, b, coll) return a:getUserData().tag == "Shot" or b:getUserData().tag == "Shot" end)
    shotHitEnemy, shotHitOther = shotHit:partition(function(a, b, coll) return a:getUserData().tag == "Shot" and b:getUserData().tag == "Enemy" end)
    shotHit:subscribe(function(a, b, coll) 
        local shot = {}
        if a:getUserData().tag == "Shot" then
            shot = a:getUserData()
        else
            shot = b:getUserData()
        end

        shot.fired = false 
        scheduler:schedule(function()
            coroutine.yield(.01)
            shot.body:setActive(false)
            shot.body:setPosition(-8000,-8000)
        end)
    end)
    shotHitEnemy:subscribe(function(a, b, coll)
        a:getUserData().fired = false
        scheduler:schedule(function()
            coroutine.yield(.01)
            a:getUserData().body:setActive(false)
            a:getUserData().body:setPosition(-8000,-8000)
        end)
        killEnemy(b:getUserData()) 
    end)

    -- Trata colisao de tiro do inimigo
    enemyShotHit = beginContact:filter(function(a, b, coll) return a:getUserData().tag == "EnemyShot" or b:getUserData().tag == "EnemyShot" end)
    enemyShotHitHero, enemyShotHitOther = enemyShotHit:partition(function(a, b, coll) return a:getUserData().tag == "Hero" end)
    enemyShotHitOther:subscribe(function(a, b, coll) 
        b:getUserData().fired = false 
        scheduler:schedule(function()
            coroutine.yield(.01)
            b:getUserData().body:setActive(false)
        end)
    end)
    enemyShotHitHero:subscribe(function(a, b, coll)
        b:getUserData().fired = false 
        scheduler:schedule(function()
            coroutine.yield(.01)
            b:getUserData().body:setActive(false)
        end)
            
        a:getUserData().health:onNext(hero.health:getValue() - 10)
    end)

    --colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes--
end)

--Collision callbacks 
function bC(a, b, coll)   
    beginContact:onNext(a, b, coll)
end
function eC(a, b, coll)
    endContact:onNext(a, b, coll)
end
function preS(a, b, coll)
    preSolve:onNext(a, b, coll)
end
function postS(a, b, coll, normalimpulse, tangentimpulse)
    postSolve:onNext(a, b, coll, normalimpulse, tangentimpulse)
end

-- Helper functions
local function move(direction)
    currentVelX, currentVelY = hero.body:getLinearVelocity()
    hero.body:setLinearVelocity(hero.speed*direction, currentVelY)
    hero.dir = {direction, 0}
end

local function stopHorMove()
    currentVelX, currentVelY = hero.body:getLinearVelocity()
    hero.body:setLinearVelocity(0, currentVelY)
end

local function jump()
    hero.body:applyLinearImpulse(0, -100)
    hero.grounded = false
end

function shoot()
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

function killEnemy(enemy)
    print("killEnemy: "..enemy)
    enemy.alive = false
    rx.Observable.fromTable(enemy.shots, pairs, false)
        :subscribe(function(shot)
            shot.body:setActive(false)
            shot.fixture:setMask(2,3)
            print("shot: "..shot)
        end)
    enemy.shots = {}
    enemy.body:setActive(false)
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
        :subscribe(move)
end

love.keyreleased
    :filter(function(key) return key == 'a' or  key == 'd' end)
    :subscribe(function()
        stopHorMove()
    end)

love.keypressed
    :filter(function(key) return key == 'space' end)
    :subscribe(function()
        shoot()
        currentVelX, currentVelY = hero.body:getLinearVelocity()
        hero.body:setLinearVelocity(0, currentVelY)
    end)

love.keypressed
    :filter(function(key) return key == 'w' and hero.grounded end)
    :subscribe(function()
        jump()
    end)

love.update:subscribe(function (dt)
    world:update(dt) -- this puts the world into motion
	-- scheduler:update(dt)
	
	-- Update world map
	map:update(dt)
end)

love.draw:subscribe(function ()

    heroPosX, heroPosY = hero.body:getPosition();
    local tx,ty = -heroPosX + love.graphics.getWidth()/2, -heroPosY + love.graphics.getHeight() * 3/4;
    -- love.graphics.translate(tx,ty)
	
    -- Draw world
	love.graphics.setColor(1, 1, 1)
	map:draw(tx,ty)

	-- Draw Collision Map (useful for debugging)
	love.graphics.setColor(1, 0, 0)
	map:box2d_draw(tx,ty)


    -- -- draw a "filled in" polygon using the mapObjs coordinates
    -- rx.Observable.fromTable(mapObjs, pairs, false)
    --     :subscribe(function(obj)
    --         love.graphics.setColor(unpack(obj.color))
    --         love.graphics.polygon("fill", obj.body:getWorldPoints(obj.shape:getPoints()))
    --     end)

    -- -- let's draw our heros shots
    -- love.graphics.setColor(255,255,255,255)
    -- rx.Observable.fromTable(hero.shots, pairs, false)
    --     :filter(function(shot)
    --         return shot.fired
    --     end)
    --     :subscribe(function(shot)
    --         love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
    --     end)

    -- -- let's draw our hero
    -- love.graphics.setColor(117/255, 186/255, 60/255)
    -- love.graphics.polygon("fill", hero.body:getWorldPoints(hero.shape:getPoints()))

    -- -- let's draw our enemies
    -- love.graphics.setColor(135/255, 0, 168/255)
    -- local enemiesAlive = rx.Observable.fromTable(enemies, pairs, false)
    --                         :filter(function(enemy)
    --                             return enemy.alive
    --                         end)
    
    -- enemiesAlive:subscribe(function(enemy)
    --         love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))

    --         -- let's draw our enemy shots
    --         love.graphics.setColor(0, 0, 0)
    --         rx.Observable.fromTable(enemy.shots, pairs, false)
    --             :filter(function(shot)
    --                 return shot.fired
    --             end)
    --             :subscribe(function(shot)
    --                 love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
    --             end)
    --     end)

    -- love.graphics.setColor(unpack(enemyRange.color))
    -- love.graphics.polygon("fill", enemyRange.body:getWorldPoints(enemyRange.shape:getPoints()))

    -- -- Move camera back to original pos
    -- love.graphics.translate(-(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4))
    -- -- Health bar
    -- love.graphics.setColor(242/255, 178/255, 0)
    -- love.graphics.rectangle("fill", 20, 20, hero.backHealth, 20)
    -- love.graphics.setColor(255,0,0,255)
    -- love.graphics.rectangle("fill", 20, 20, hero.health:getValue(), 20)
    -- love.graphics.setColor(0,0,0,255)
    -- love.graphics.rectangle("line", 20, 20, 100, 20)

    -- -- Alerta perigo
    -- love.graphics.setColor(unpack(alertaPerigo.cor))
    -- love.graphics.rectangle("line", love.graphics.getWidth()-20, alertaPerigo.y -heroPosY + love.graphics.getHeight() * 3/4, 20, 20)
end)