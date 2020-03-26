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
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    
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

-- Trata reset do grounded para pulo
function beginContact(a, b, coll)  
    if (a:getUserData().properties.Ground == true or a:getUserData().properties.tag == "Platform") and b:getUserData().properties.tag == "Hero" then
        hero.grounded = true
    elseif a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" then
        local enemy, hero = b:getUserData().properties, a:getUserData().properties
        enemy.enemyRange.color = enemy.enemyRange.dangerColor
        hero.inEnemyRange = enemy
    end
end

function endContact(a, b, coll)
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" then
        local enemy = b:getUserData().properties
        enemy.enemyRange.color = enemy.enemyRange.outRangeColor
        hero.inEnemyRange = nil
    end
end

function preSolve(a, b, coll)
    
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
    
end

function love.keypressed( key )
    if key == "c" and hero.inEnemyRange ~= nil then
        hero.inEnemyRange.enemyRange.color = hero.inEnemyRange.enemyRange.safeColor
    end
 end
  
 function love.keyreleased( key )
    if key == "c" and hero.inEnemyRange ~= nil then
        hero.inEnemyRange.enemyRange.color = hero.inEnemyRange.enemyRange.dangerColor
    end
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