-- Rx libs
local rx = require 'rx'
require 'rx-love'

local CollisionManager = {}

function CollisionManager.Init(scheduler)
    -- local HERO_CATEGORY = 3
    -- local HERO_SHOT_CATEGORY = 4
    -- local ENEMY_CATEGORY = 5
    -- local ENEMY_SHOT_CATEGORY = 6
    
    CollisionManager.scheduler = scheduler

    -- --Collision callbacks:
    world:setCallbacks(bC, eC, preS, postS)

    beginContact = rx.Subject.create()
    endContact = rx.Subject.create()
    preSolve = rx.Subject.create()
    postSolve = rx.Subject.create()

    -- Trata reset do jumpCount
    beginContact
        :filter(function(a, b, coll) 
            return ((a:getUserData().properties.Ground == true or a:getUserData().properties.tag == "Platform") and b:getUserData().properties.tag == "Hero" or
                    (b:getUserData().properties.Ground == true or b:getUserData().properties.tag == "Platform") and a:getUserData().properties.tag == "Hero")
        end)
        :subscribe(function() hero.jumpCount = 2 end)

    -- Trata colisao player com falling plat
    beginContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "fallingPlat"
        end)
        :subscribe(function(a, b, coll) b:getUserData().properties.touchedPlayer:onNext(true) end)

    -- Trata colisao player com shield
    beginContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "shield"
        end)
        :subscribe(function(a, b, coll) 
            a:getUserData().properties.item:onNext(b:getUserData().properties)
            b:getUserData().properties.touchedPlayer:onNext(a:getUserData().properties.body) 
        end)

    -- Trata colisao enemyShot com shield
    beginContact
        :filter(function(a, b, coll) 
            return b:getUserData().properties.tag == "shield"
        end)
        :subscribe(function(a, b, coll) 
            print(a:getUserData().properties.tag)
            -- b:getUserData().properties.touchedShot:onNext(a:getUserData().properties) 
        end)

    -- Trata colisao player com enemyRange
    enterRange = beginContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" 
        end)
        :map(function (a, b, coll)
            return {state = "enter", enemyRange = b:getUserData().properties}
        end)

    exitRange = endContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" 
        end)
        :map(function (a, b, coll)
            return {state = "exit", enemyRange = b:getUserData().properties}
        end)

    rangeState = enterRange:merge(exitRange)

    enterRange:subscribe(function (info)
        info.enemyRange.color = info.enemyRange.dangerColor
    end)

    exitRange:subscribe(function (info)
        info.enemyRange.color = info.enemyRange.outRangeColor
    end)

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
            return a,b
        end)

    heroSafe = heroRangeState:filter(function(a,b)
        return a.state == "enter" and b == "pressed"
    end)
    heroNotSafe = heroRangeState:filter(function(a,b)
        return a.state == "enter" and b == "not pressed"
    end)
    
    heroSafe:subscribe(function(a,b) 
        a.enemyRange.color = a.enemyRange.safeColor
    end)
    
    heroNotSafe:subscribe(function(a,b) 
        a.enemyRange.color = a.enemyRange.dangerColor
    end)

    -- Trata colisao de tiro do player
    shotHit = beginContact:filter(function(a, b, coll) return a:getUserData().properties.tag == "Shot" or b:getUserData().properties.tag == "Shot" end)
    shotHitEnemy = rx.BehaviorSubject.create()

    shotHit:subscribe(function(a, b, coll) 
        local shot = {}
        local other = {}
        if a:getUserData().properties.tag == "Shot" then
            shot = a:getUserData().properties
            other = b:getUserData().properties
        else
            shot = b:getUserData().properties
            other = a:getUserData().properties
        end

        if other.tag == "Enemy" then
            killEnemy(other) 
        end

        if other.tag ~= "EnemyRange" then
            shot.fired = false 
            scheduler:schedule(function()
                coroutine.yield(.01)
                shot.body:setActive(false)
                shot.body:setPosition(-8000,-8000)
            end)
        end
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
end

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
    CollisionManager.scheduler:schedule(function()
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

return CollisionManager