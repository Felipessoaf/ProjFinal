local rx = require 'rx'
require 'rx-love'

-- Maps keys to players and directions
local keyMap = {
  a = -1,
  d = 1
}

-- Declare initial state of game
love.load:subscribe(function (arg)
    -- the height of a meter our worlds will be 64px
    love.physics.setMeter(64)

    -- create a world for the bodies to exist in with horizontal gravity
    -- of 0 and vertical gravity of 9.81
    world = love.physics.newWorld(0, 9.81*64, true)

    --Collision callbacks:
    world:setCallbacks(bC, eC, preS, postS)

    beginContact = rx.Subject.create()
    endContact = rx.Subject.create()
    preSolve = rx.Subject.create()
    postSolve = rx.Subject.create()
    beginContact:filter(function(a, b, coll) return a:getUserData() == "Ground" and b:getUserData() == "Hero" end)
                :subscribe(function() objects.hero.grounded = true end)

    objects = {} -- table to hold all our physical objects
    objects.ground = {}
    -- remember, the shape (the rectangle we create next) anchors to the
    -- body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.body = love.physics.newBody(world, 650/2, 650-50/2)
    -- make a rectangle with a width of 650 and a height of 50
    objects.ground.shape = love.physics.newRectangleShape(650, 150)
    -- attach shape to body
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)
    objects.ground.fixture:setUserData("Ground")

    -- let's create a couple blocks to play around with
    objects.block1 = {}
    objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
    objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
    -- A higher density gives it more mass.
    objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5)
    objects.block1.fixture:setUserData("Block")

    objects.block2 = {}
    objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)
    objects.block2.fixture:setUserData("Block")
    
    -- initial graphics setup
    -- set the background color to a nice blue
    love.graphics.setBackgroundColor(0.41, 0.53, 0.97)

    objects.hero = {} -- rx.BehaviorSubject.create() -- new table for the objects.hero
    objects.hero.initX = 300
    objects.hero.initY = 450
    objects.hero.width = 30
    objects.hero.height = 15
    objects.hero.speed = 150
    objects.hero.shots = {} -- holds our shots
    objects.hero.body = love.physics.newBody(world, objects.hero.initX, objects.hero.initY, "dynamic")
    objects.hero.body:setFixedRotation(true)
    objects.hero.shape = love.physics.newRectangleShape(0, 0, objects.hero.width, objects.hero.height)
    objects.hero.fixture = love.physics.newFixture(objects.hero.body, objects.hero.shape, 2)
    objects.hero.fixture:setUserData("Hero")
    objects.hero.fixture:setCategory(2)
    objects.hero.grounded = true

    rx.Observable.fromRange(1, 5)
        :subscribe(function ()
            local shot = {}
            shot.width = 2
            shot.height = 5
            shot.fired = false
            shot.speed = 50
            shot.body = love.physics.newBody(world, 0, 0, "kinematic")
            shot.body:setFixedRotation(true)
            shot.body:setLinearVelocity(0, 0)
            shot.body:setGravityScale(0)
            shot.shape = love.physics.newRectangleShape(0, 0, shot.width, shot.height)
            shot.fixture = love.physics.newFixture(shot.body, shot.shape, 2)
            shot.fixture:setUserData("Shot")
            shot.fixture:setMask(2)
            table.insert(objects.hero.shots, shot)
        end)

    enemies = {}
    rx.Observable.fromRange(0, 6)
        :subscribe(function (i)
            local enemy = {}
            enemy.width = 40
            enemy.height = 20
            enemy.x = i * (enemy.width + 60) + 100
            enemy.y = enemy.height + 100
            enemy.alive = true
            enemy.speed = 10
            table.insert(enemies, enemy)  
        end)
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
    currentVelX, currentVelY = objects.hero.body:getLinearVelocity()
    objects.hero.body:setLinearVelocity(objects.hero.speed*direction, currentVelY)
end

local function stopHorMove()
    currentVelX, currentVelY = objects.hero.body:getLinearVelocity()
    objects.hero.body:setLinearVelocity(0, currentVelY)
end

local function jump()
    objects.hero.body:applyLinearImpulse(0, -50)
    objects.hero.grounded = false
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
        currentVelX, currentVelY = objects.hero.body:getLinearVelocity()
        objects.hero.body:setLinearVelocity(0, currentVelY)
    end)

love.keypressed
    :filter(function(key) return key == 'w' and objects.hero.grounded end)
    :subscribe(function()
        jump()
    end)

love.update:subscribe(function (dt)

    world:update(dt) -- this puts the world into motion

    enemiesAlive = rx.Observable.fromTable(enemies, pairs, false)
        :filter(function(enemy)
            return enemy.alive
        end)

    enemiesAlive
        :subscribe(function(enemy)
            -- let them fall down slowly
            enemy.y = enemy.y + dt * enemy.speed
        end)

    enemiesAlive
        :filter(function(enemy)
            return enemy.y > 465
        end)
        :subscribe(function()
            -- you lose!!!
            -- love.load()
        end)

end)

love.draw:subscribe(function ()

    heroPosX, heroPosY = objects.hero.body:getPosition();
    love.graphics.translate(-heroPosX + love.graphics.getWidth()/2, -heroPosY + love.graphics.getHeight() * 3/4)

    -- set the drawing color to green for the ground
    love.graphics.setColor(0.28, 0.63, 0.05)
    -- draw a "filled in" polygon using the ground's coordinates
    love.graphics.polygon("fill", objects.ground.body:getWorldPoints(
                            objects.ground.shape:getPoints()))
    
    -- set the drawing color to grey for the blocks
    love.graphics.setColor(0.20, 0.20, 0.20)
    love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
    love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

    -- let's draw our objects.hero
    love.graphics.setColor(255,255,0,255)
    love.graphics.polygon("fill", objects.hero.body:getWorldPoints(objects.hero.shape:getPoints()))

    -- let's draw our objects.heros shots
    love.graphics.setColor(255,255,255,255)
    rx.Observable.fromTable(objects.hero.shots, pairs, false)
        :filter(function(shot)
            return shot.fired
        end)
        :subscribe(function(shot)
            love.graphics.polygon("fill", shot.body:getWorldPoints(shot.shape:getPoints()))
        end)

    -- let's draw our enemies
    love.graphics.setColor(0,255,255,255)
    rx.Observable.fromTable(enemies, pairs, false)
        :filter(function(enemy)
            return enemy.alive
        end)
        :subscribe(function(enemy)
            love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        end)
end)

function shoot()
    rx.Observable.fromTable(objects.hero.shots, pairs, false)
        :filter(function(shot)
            return not shot.fired
        end)
        :first()
        :subscribe(function(shot)
            shot.body:setLinearVelocity(0, -shot.speed)
            shot.body:setPosition(objects.hero.body:getX(), objects.hero.body:getY())
            shot.fired = true
        end)
end
