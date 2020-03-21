-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- Enemies module
local Enemies = require 'Enemies'

-- MapManager module
local MapManager = require 'MapManager'

-- Player module
local Player = require 'Player'

local scheduler = rx.CooperativeScheduler.create()

-- Declare initial state of game
love.load:subscribe(function (arg)
    -- local HERO_CATEGORY = 3
    -- local HERO_SHOT_CATEGORY = 4
    -- local ENEMY_CATEGORY = 5
	-- local ENEMY_SHOT_CATEGORY = 6
	
	-- load map
	map = MapManager.InitMap()

    -- create a world for the bodies to exist in with horizontal gravity
    -- of 0 and vertical gravity of 9.81
    world = love.physics.newWorld(0, 9.81*64, true)
    
	-- Prepare collision objects
	map:box2d_init(world)

    -- --Collision callbacks:
    world:setCallbacks(bC, eC, preS, postS)
    
    -- --map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map--

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

    hero = Player.Init(scheduler)

    -- --hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero--

    -- --enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies--

    enemies = Enemies.Init(scheduler)

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
    beginContact:filter(function(a, b, coll) return (a:getUserData().properties.Ground == true or a:getUserData().tag == "Platform") and b:getUserData().tag == "Hero" end)
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

love.update:subscribe(function (dt)
    world:update(dt) -- this puts the world into motion
	-- scheduler:update(dt)
	
	-- Update world map
	map:update(dt)
end)

love.draw:subscribe(function ()

    heroPosX, heroPosY = hero.body:getPosition();
    local tx,ty = -heroPosX + love.graphics.getWidth()/2, -heroPosY + love.graphics.getHeight() * 3/4;
	
    -- Draw world
	love.graphics.setColor(1, 1, 1)
	map:draw(tx,ty)

	-- Draw Collision Map (useful for debugging)
	love.graphics.setColor(1, 0, 0)
	map:box2d_draw(tx,ty)

    -- love.graphics.setColor(unpack(enemyRange.color))
    -- love.graphics.polygon("fill", enemyRange.body:getWorldPoints(enemyRange.shape:getPoints()))

    -- Move camera back to original pos
    love.graphics.translate(-(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4))
    -- Health bar
    love.graphics.setColor(242/255, 178/255, 0)
    love.graphics.rectangle("fill", 20, 20, hero.backHealth, 20)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", 20, 20, hero.health:getValue(), 20)
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("line", 20, 20, 100, 20)

    -- -- Alerta perigo
    -- love.graphics.setColor(unpack(alertaPerigo.cor))
    -- love.graphics.rectangle("line", love.graphics.getWidth()-20, alertaPerigo.y -heroPosY + love.graphics.getHeight() * 3/4, 20, 20)
end)