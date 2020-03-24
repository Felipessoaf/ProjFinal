-- Rx libs
local rx = require 'rx'
require 'rx-love'

local CollisionManager = {}

function CollisionManager.Init(scheduler)

    -- --Collision callbacks:
    world:setCallbacks(bC, eC, preS, postS)

    beginContact = rx.Subject.create()
    endContact = rx.Subject.create()
    preSolve = rx.Subject.create()
    postSolve = rx.Subject.create()

    -- Trata reset do grounded para pulo
    beginContact
        :filter(function(a, b, coll) 
            print(a:getUserData().properties.Ground)
            return (a:getUserData().properties.Ground == true or a:getUserData().properties.tag == "Platform") and b:getUserData().properties.tag == "Hero" 
        end)
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

return CollisionManager