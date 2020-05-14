local CollisionManager = {}

function CollisionManager.Init()
    -- local HERO_CATEGORY = 3
    -- local HERO_SHOT_CATEGORY = 4
    -- local ENEMY_CATEGORY = 5
    -- local ENEMY_SHOT_CATEGORY = 6
    
    -- CollisionManager.scheduler = scheduler

    CollisionManager.shotsToDisable = {}
    CollisionManager.enemyShotsToDisable = {}
    CollisionManager.enemiesToDisable = {}

    CollisionManager.update = function(dt) 
        for k, shot in pairs(CollisionManager.shotsToDisable) do
            shot.body:setActive(false)
            shot.body:setPosition(-8000,-8000)
            CollisionManager.shotsToDisable[k] = nil
        end

        for k, shot in pairs(CollisionManager.enemyShotsToDisable) do
            shot.body:setActive(false)
        end
        
        for k, enemy in pairs(CollisionManager.enemiesToDisable) do
            if enemy.shots ~= nil then
                for i, shot in pairs(enemy.shots) do
                    shot.body:setActive(false)
                    shot.fixture:setMask(2,3)
                end
                enemy.shots = {}
            end
            enemy.body:setActive(false)
        end
    end

    -- --Collision callbacks:
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

end

function beginContact(a, b, coll)  
    -- Trata reset do grounded para pulo
    if ((a:getUserData().properties.Ground == true or a:getUserData().properties.tag == "Platform") and b:getUserData().properties.tag == "Hero" or
        (b:getUserData().properties.Ground == true or b:getUserData().properties.tag == "Platform") and a:getUserData().properties.tag == "Hero") then
        hero.jumpCount = 2
    end

    -- Trata colisao player com falling plat
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "fallingPlat" then
        b:getUserData().properties.touchedPlayer()
    end

    -- Trata colisao player com shield
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "shield" then
        a:getUserData().properties.item = b:getUserData().properties
        b:getUserData().properties.touchedPlayer()
    end

    -- Trata colisao enemyShot com shield
    if a:getUserData().properties.tag == "EnemyShot" and b:getUserData().properties.tag == "shield" then
        b:getUserData().properties.touchedShot(a:getUserData().properties) 
    end

    -- Trata colisao player com enemyRange
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" then
        local enemyRange, hero = b:getUserData().properties, a:getUserData().properties
        enemyRange.color = enemyRange.dangerColor
        hero.inEnemyRange = enemyRange
    end

    -- Trata colisao player com quickTimeRange
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "QuickTimeRange" then
        a:getUserData().properties.quickTimeRange:onNext(b:getUserData().properties)
        b:getUserData().properties.playerInRange:onNext(a:getUserData().properties) 
    end
    
    -- Trata colisao de tiro do player
    if a:getUserData().properties.tag == "Shot" or b:getUserData().properties.tag == "Shot" then
        checkShotHit(a, b)
    end
    
    -- Trata colisao de tiro do inimigo
    if a:getUserData().properties.tag == "EnemyShot" or b:getUserData().properties.tag == "EnemyShot" then
        checkEnemyShotHit(a, b)
    end
end

function endContact(a, b, coll)
    -- Trata colisao player com enemyRange
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "EnemyRange" then
        local enemyRange = b:getUserData().properties
        enemyRange.color = enemyRange.outRangeColor
        hero.inEnemyRange = nil
    end

    -- Trata colisao player com quickTimeRange
    if a:getUserData().properties.tag == "Hero" and b:getUserData().properties.tag == "QuickTimeRange" then
        a:getUserData().properties.quickTimeRange:onNext(nil)
        b:getUserData().properties.playerInRange:onNext(nil) 
    end
end

function preSolve(a, b, coll)
    
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)

end

function checkShotHit(a, b)
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

    if other.tag ~= "EnemyRange" and other.tag ~= "shield" and other.tag ~= "QuickTimeRange" then
        shot.fired = false 
        table.insert(CollisionManager.shotsToDisable, shot)
    end
end

function checkEnemyShotHit(a, b)
    local shot = {}
    local other = {}
    if a:getUserData().properties.tag == "EnemyShot" then
        shot = a:getUserData().properties
        other = b:getUserData().properties
    else
        shot = b:getUserData().properties
        other = a:getUserData().properties
    end

    if a:getUserData().properties.tag == "Hero" then
        a:getUserData().properties.damage(10)
    end

    if other.tag ~= "EnemyRange" and other.tag ~= "shield" and other.tag ~= "QuickTimeRange" then
        b:getUserData().properties.reset()
    end
end

return CollisionManager