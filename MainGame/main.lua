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
	map, world = MapManager.InitMap()

    -- --Collision callbacks:
    world:setCallbacks(bC, eC, preS, postS)

    hero = Player.Init(scheduler)
    
    enemies = Enemies.Init(scheduler)

    --colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes--

    beginContact = rx.Subject.create()
    endContact = rx.Subject.create()
    preSolve = rx.Subject.create()
    postSolve = rx.Subject.create()

    -- Trata reset do grounded para pulo
    beginContact:filter(function(a, b, coll) return (a:getUserData().properties.Ground == true or a:getUserData().properties.tag == "Platform") and b:getUserData().properties.tag == "Hero" end)
                :subscribe(function() hero.grounded = true end)

    -- Trata colisao player com enemyRange
    enterRange = beginContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" 
        end)
        :map(function ()
            return "enter"
        end)

    exitRange = endContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" 
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
    shotHit = beginContact:filter(function(a, b, coll) return a:getUserData().properties.tag == "Shot" or b:getUserData().properties.tag == "Shot" end)
    shotHitEnemy, shotHitOther = shotHit:partition(function(a, b, coll) return a:getUserData().properties.tag == "Shot" and b:getUserData().properties.tag == "Enemy" end)
    shotHit:subscribe(function(a, b, coll) 
        local shot = {}
        if a:getUserData().properties.tag == "Shot" then
            shot = a:getUserData().properties
        else
            shot = b:getUserData().properties
        end

        shot.fired = false 
        scheduler:schedule(function()
            coroutine.yield(.01)
            shot.body:setActive(false)
            shot.body:setPosition(-8000,-8000)
        end)
    end)
    shotHitEnemy:subscribe(function(a, b, coll)
        a:getUserData().properties.fired = false
        scheduler:schedule(function()
            coroutine.yield(.01)
            a:getUserData().properties.body:setActive(false)
            a:getUserData().properties.body:setPosition(-8000,-8000)
        end)
        killEnemy(b:getUserData().properties) 
    end)

    -- Trata colisao de tiro do inimigo
    enemyShotHit = beginContact:filter(function(a, b, coll) return a:getUserData().properties.tag == "EnemyShot" or b:getUserData().properties.tag == "EnemyShot" end)
    enemyShotHitHero, enemyShotHitOther = enemyShotHit:partition(function(a, b, coll) return a:getUserData().properties.tag == "Hero" end)
    enemyShotHitOther:subscribe(function(a, b, coll) 
        b:getUserData().properties.fired = false 
        scheduler:schedule(function()
            coroutine.yield(.01)
            b:getUserData().properties.body:setActive(false)
        end)
    end)
    enemyShotHitHero:subscribe(function(a, b, coll)
        b:getUserData().properties.fired = false 
        scheduler:schedule(function()
            coroutine.yield(.01)
            b:getUserData().properties.body:setActive(false)
        end)
            
        a:getUserData().properties.health:onNext(hero.health:getValue() - 10)
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
	scheduler:update(dt)
	
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

    -- Move camera back to original pos
    -- love.graphics.translate(-(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4))
    -- Health bar
    love.graphics.setColor(242/255, 178/255, 0)
    love.graphics.rectangle("fill", 20, 20, hero.backHealth, 20)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", 20, 20, hero.health:getValue(), 20)
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("line", 20, 20, 100, 20)
end)