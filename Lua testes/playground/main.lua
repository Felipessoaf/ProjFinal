local rx = require 'rx'
require 'rx-love'

-- Maps keys to players and directions
local keyMap = {
  a = -1,
  d = 1
}

local scheduler = rx.CooperativeScheduler.create()

-- Declare initial state of game
love.load:subscribe(function (arg)
    -- the height of a meter our worlds will be 64px
    love.physics.setMeter(64)

    -- create a world for the bodies to exist in with horizontal gravity
    -- of 0 and vertical gravity of 9.81
    world = love.physics.newWorld(0, 9.81*64, true)

    --Collision callbacks:
    world:setCallbacks(bC, eC, preS, postS)

    objects = {} -- table to hold all our physical objects
    mapObjs = {} -- table to hold all our map objects

    --map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map--

    ground1 = {}
    ground1.tag = "Ground"
    ground1.color = {112/250, 72/250, 7/250}
    ground1.body = love.physics.newBody(world, -100, 650)
    ground1.shape = love.physics.newRectangleShape(650, 150)
    -- attach shape to body
    ground1.fixture = love.physics.newFixture(ground1.body, ground1.shape)
    ground1.fixture:setUserData(ground1)

    table.insert(mapObjs, ground1)

    ground2 = {}
    ground2.tag = "Ground"
    ground2.color = {112/250, 72/250, 7/250}
    ground2.body = love.physics.newBody(world, 550, 650)
    ground2.shape = love.physics.newRectangleShape(650, 300)
    -- attach shape to body
    ground2.fixture = love.physics.newFixture(ground2.body, ground2.shape)
    ground2.fixture:setUserData(ground2)

    table.insert(mapObjs, ground2)

    wall1 = {}
    wall1.tag = "Wall"
    wall1.color = {9/250, 84/250, 9/250}
    wall1.body = love.physics.newBody(world, -550, 225)
    wall1.shape = love.physics.newRectangleShape(650, 1000)
    -- attach shape to body
    wall1.fixture = love.physics.newFixture(wall1.body, wall1.shape)
    wall1.fixture:setUserData(wall1)

    table.insert(mapObjs, wall1)

    wall2 = {}
    wall2.tag = "Wall"
    wall2.color = {9/250, 84/250, 9/250}
    wall2.body = love.physics.newBody(world, 1200, 225)
    wall2.shape = love.physics.newRectangleShape(650, 1000)
    -- attach shape to body
    wall2.fixture = love.physics.newFixture(wall2.body, wall2.shape)
    wall2.fixture:setUserData(wall2)

    table.insert(mapObjs, wall2)

    platforms = {{50, 400}, {150, 450}, {500, 450}, {600, 400}}
    
    rx.Observable.fromTable(platforms, pairs, false)
        :subscribe(function(platPos)
            plat = {}
            plat.tag = "Platform"
            plat.color = {0.20, 0.20, 0.20}
            x,y = unpack(platPos)
            plat.body = love.physics.newBody(world, x, y, "kinematic")
            plat.shape = love.physics.newRectangleShape(100, 25)
            -- A higher density gives it more mass.
            plat.fixture = love.physics.newFixture(plat.body, plat.shape, 5)
            plat.fixture:setUserData(plat)

            table.insert(mapObjs, plat)
        end)

    table.insert(objects, mapObjs)

    love.graphics.setBackgroundColor(0.41, 0.53, 0.97)

    --map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map----map--

    --hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero--

    hero = {}
    hero.tag = "Hero"
    hero.health = rx.BehaviorSubject.create(100)
    hero.health:debounce(1, scheduler)
               :subscribe(function (val)
                    hero.backHealth = val
                end)
    hero.backHealth = 100
    hero.dir = {1,0}
    hero.initX = 300
    hero.initY = 450
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
    
    table.insert(objects, hero)

    -- shots
    rx.Observable.fromRange(1, 5)
        :subscribe(function ()
            local shot = {}
            shot.tag = "Shot"
            shot.width = 2
            shot.height = 5
            shot.fired = false
            shot.speed = 180--math.random(10,80)
            shot.body = love.physics.newBody(world, 0, 0, "dynamic")
            shot.body:setFixedRotation(true)
            shot.body:setLinearVelocity(0, 0)
            shot.body:setGravityScale(0)
            shot.shape = love.physics.newRectangleShape(0, 0, shot.width, shot.height)
            shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
            shot.fixture:setUserData(shot)
            shot.fixture:setCategory(2)
            shot.fixture:setMask(2)
            table.insert(hero.shots, shot)
        end)

    --hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero----hero--

    --enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies--

    enemies = {}
    
    local enemy = {}
    enemy.tag = "Enemy"
    enemy.initX = 700
    enemy.initY = 480
    enemy.width = 40
    enemy.height = 20
    enemy.alive = true
    enemy.shots = {}
    enemy.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
    enemy.body:setFixedRotation(true)
    enemy.shape = love.physics.newRectangleShape(enemy.width, enemy.height)
    enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape, 2)
    enemy.fixture:setUserData(enemy)
    enemy.fixture:setCategory(3)
    table.insert(enemies, enemy)  

    rx.Observable.fromRange(1, 10)
        :subscribe(function ()
            local shot = {}
            shot.tag = "EnemyShot"
            shot.width = 3
            shot.height = 3
            shot.fired = false
            shot.speed = 100
            shot.body = love.physics.newBody(world, enemy.initX, enemy.initY, "dynamic")
            shot.body:setFixedRotation(true)
            shot.body:setGravityScale(0)
            shot.body:setSleepingAllowed(true)
            shot.shape = love.physics.newRectangleShape(shot.width, shot.height)
            shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
            shot.fixture:setUserData(shot)
            shot.fixture:setCategory(3)
            shot.fixture:setMask(3)
            table.insert(enemy.shots, shot)
        end)

    scheduler:schedule(function()
            coroutine.yield(1)
            while true do
                rx.Observable.fromTable(enemy.shots, pairs, false)
                    :filter(function(shot)
                        return not shot.fired
                    end)
                    :first()
                    :subscribe(function(shot)
                        shot.body:setLinearVelocity(-shot.speed, 0)
                        shot.body:setPosition(enemy.body:getX(), enemy.body:getY())
                        shot.fired = true
                        shot.body:setActive(true)
                    end)
                coroutine.yield(1)
            end
        end)

    table.insert(objects, enemies)

    --enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies----enemies--

    --colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes----colisoes--

    beginContact = rx.Subject.create()
    endContact = rx.Subject.create()
    preSolve = rx.Subject.create()
    postSolve = rx.Subject.create()

    -- Trata reset do grounded para pulo
    beginContact:filter(function(a, b, coll) return (a:getUserData().tag == "Ground" or a:getUserData().tag == "Platform") and b:getUserData().tag == "Hero" end)
                :subscribe(function() hero.grounded = true end)

    -- Trata colisao de tiro do player
    shotHit = beginContact:filter(function(a, b, coll) return a:getUserData().tag == "Shot" or b:getUserData().tag == "Shot" end)
    shotHitEnemy, shotHitOther = shotHit:partition(function(a, b, coll) return a:getUserData().tag == "Shot" and b:getUserData().tag == "Enemy" end)
    shotHit:subscribe(function(a, b, coll) 
        b:getUserData().fired = false 
        -- b:getUserData().
        -- b:getUserData().body:setPosition(10,10)
        scheduler:schedule(function()
            coroutine.yield(.1)
            b:getUserData().body:setActive(false)
        end)
    end)
    shotHitEnemy:subscribe(function(a, b, coll)
        a:getUserData().fired = false 
        -- print("shotHitEnemy")
        -- a:getUserData().body:setPosition(10000,10000)
        b:getUserData().alive = false
        rx.Observable.fromTable(b:getUserData().shots, pairs, false)
            :subscribe(function(shot)
                shot.body:setActive(false)
            end)
        -- b:getUserData().body:setPosition(10000,10000)
    end)

    -- Trata colisao de tiro do inimigo
    enemyShotHit = beginContact:filter(function(a, b, coll) return a:getUserData().tag == "EnemyShot" or b:getUserData().tag == "EnemyShot" end)
    enemyShotHitHero, enemyShotHitOther = enemyShotHit:partition(function(a, b, coll) return a:getUserData().tag == "Hero" end)
    enemyShotHitOther:subscribe(function(a, b, coll) 
        b:getUserData().fired = false 
        -- b:getUserData().body:setPosition(10000,10000)
        -- print("enemyShotHitOther")
        scheduler:schedule(function()
            coroutine.yield(.1)
            b:getUserData().body:setActive(false)
        end)
    end)
    enemyShotHitHero:subscribe(function(a, b, coll)
        b:getUserData().fired = false 
        -- b:getUserData().body:setPosition(10000,10000)
        -- print("enemyShotHitHero")
        scheduler:schedule(function()
            coroutine.yield(.1)
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
    scheduler:update(dt)
end)

love.draw:subscribe(function ()

    heroPosX, heroPosY = hero.body:getPosition();
    love.graphics.translate(-heroPosX + love.graphics.getWidth()/2, -heroPosY + love.graphics.getHeight() * 3/4)

    -- draw a "filled in" polygon using the mapObjs coordinates
    rx.Observable.fromTable(mapObjs, pairs, false)
        :subscribe(function(obj)
            love.graphics.setColor(unpack(obj.color))
            love.graphics.polygon("fill", obj.body:getWorldPoints(obj.shape:getPoints()))
        end)

    -- let's draw our heros shots
    love.graphics.setColor(255,255,255,255)
    rx.Observable.fromTable(hero.shots, pairs, false)
        -- :filter(function(shot)
        --     return shot.fired
        -- end)
        :subscribe(function(shot)
            love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
        end)

    -- let's draw our hero
    love.graphics.setColor(117/255, 186/255, 60/255)
    love.graphics.polygon("fill", hero.body:getWorldPoints(hero.shape:getPoints()))

    -- let's draw our enemies
    love.graphics.setColor(135/255, 0, 168/255)
    rx.Observable.fromTable(enemies, pairs, false)
        :filter(function(enemy)
            return enemy.alive
        end)
        :subscribe(function(enemy)
            love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))

            -- let's draw our enemy shots
            love.graphics.setColor(0, 0, 0)
            rx.Observable.fromTable(enemy.shots, pairs, false)
                -- :filter(function(shot)
                --     return shot.fired
                -- end)
                :subscribe(function(shot)
                    love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
                end)
        end)

    -- Move camera back to original pos
    love.graphics.translate(-(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4))
    -- Health bar
    love.graphics.setColor(242/255, 178/255, 0)
    love.graphics.rectangle("fill", 20, 20, hero.backHealth, 20)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", 20, 20, hero.health:getValue(), 20)
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("line", 20, 20, 100, 20)
end)