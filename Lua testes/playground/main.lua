local rx = require 'rx'
require 'rx-love'

-- Maps keys to players and directions
local keyMap = {
  a = {-1},
  d = {1}
}

-- Declare initial state of game
love.load:subscribe(function (arg)
    -- the height of a meter our worlds will be 64px
    love.physics.setMeter(64)

    -- create a world for the bodies to exist in with horizontal gravity
    -- of 0 and vertical gravity of 9.81
    world = love.physics.newWorld(0, 9.81*64, true)

    objects = {} -- table to hold all our physical objects
    objects.ground = {}
    -- remember, the shape (the rectangle we create next) anchors to the
    -- body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.body = love.physics.newBody(world, 650/2, 650-50/2)
    -- make a rectangle with a width of 650 and a height of 50
    objects.ground.shape = love.physics.newRectangleShape(650, 150)
    -- attach shape to body
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)

    -- let's create a ball
    objects.ball = {}
    -- place the body in the center of the world and make it dynamic, so
    -- it can move around
    objects.ball.body = love.physics.newBody(world, 650/2, 650/2, "dynamic")
    -- the ball's shape has a radius of 20
    objects.ball.shape = love.physics.newCircleShape(20)
    -- Attach fixture to body and give it a density of 1.
    objects.ball.fixture = love.physics.newFixture(objects.ball.body, objects.ball.shape, 1)
    objects.ball.fixture:setRestitution(0.9) -- let the ball bounce

    -- let's create a couple blocks to play around with
    objects.block1 = {}
    objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
    objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
    -- A higher density gives it more mass.
    objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5)

    objects.block2 = {}
    objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)
    
    -- initial graphics setup
    -- set the background color to a nice blue
    love.graphics.setBackgroundColor(0.41, 0.53, 0.97)

    objects.hero = rx.BehaviorSubject.create() -- new table for the objects.hero
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

    rx.Observable.fromRange(1, 5)
        :subscribe(function ()
            local shot = {}
            shot.x = 0
            shot.y = 0
            shot.width = 2
            shot.height = 5
            shot.fired = true
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

-- Helper functions
local function move(dt, direction)
    currentVelX, currentVelY = objects.hero.body:getLinearVelocity()
    objects.hero.body:setLinearVelocity(objects.hero.speed*direction, currentVelY)

    objects.hero:onNext()
    
    -- objects.hero:filter(function()
    --         return objects.hero.x < 0
    --     end)
    --     :subscribe(function()
    --         objects.hero.x = 0
    --     end)
    
    -- objects.hero:filter(function()
    --         return objects.hero.x + objects.hero.width > love.graphics.getWidth()
    --     end)
    --     :subscribe(function()
    --         objects.hero.x = love.graphics.getWidth() - objects.hero.width
    --     end)
end

-- Respond to key presses to move players
-- keyboard actions for our objects.hero
for _, key in pairs({'a', 'd'}) do
    love.update
        :filter(function()
            return love.keyboard.isDown(key)
        end)
        :map(function(dt)
            return dt, unpack(keyMap[key])
        end)
        :subscribe(move)
end

love.keyreleased
    :filter(function(key) return key in {'a', 'd'} end)
    :subscribe(function()
        
    end)

love.keypressed
    :filter(function(key) return key == 'space' end)
    :subscribe(function()
        currentVelX, currentVelY = objects.hero.body:getLinearVelocity()
        objects.hero.body:setLinearVelocity(0, currentVelY)
    end)

love.update:subscribe(function (dt)

    world:update(dt) -- this puts the world into motion

    -- here we are going to create some keyboard events
    -- press the right arrow key to push the ball to the right
    if love.keyboard.isDown("right") then
        objects.ball.body:applyForce(400, 0)
    -- press the left arrow key to push the ball to the left
    elseif love.keyboard.isDown("left") then
        objects.ball.body:applyForce(-400, 0)
    -- press the up arrow key to set the ball in the air
    elseif love.keyboard.isDown("up") then
        objects.ball.body:setPosition(650/2, 650/2)
        -- we must set the velocity to zero to prevent a potentially large
        -- velocity generated by the change in position
        objects.ball.body:setLinearVelocity(0, 0)
    end

    -- update the shots
    shotsFired = rx.Observable.fromTable(objects.hero.shots, pairs, false)
        :filter(function(shot)
            return shot.fired
        end)
    
    shotsFired:subscribe(function(shot)
        shot.y = shot.y - dt * 100
    end)
    
    shotsFired
        :filter(function(shot)
            return shot.y < 0
        end)
        :subscribe(function(shot)
            shot.fired = false
        end)

    enemiesAlive = rx.Observable.fromTable(enemies, pairs, false)
        :filter(function(enemy)
            return enemy.alive
        end)

    shotsFired:subscribe(function(shot)
        enemiesAlive
            :filter(function(enemy)
                return CheckCollision(shot.x,shot.y,shot.width,shot.height, enemy.x,enemy.y,enemy.width,enemy.height)
            end)
            :subscribe(function(enemy)
                -- mark that enemy dead
                enemy.alive = false
                -- mark the shot not visible
                shot.fired = false
            end)
        end)

    enemiesAlive
        :filter(function(enemy)
            return enemy.y > 465
        end)
        :subscribe(function()
            -- you lose!!!
            love.load()
        end)

    enemiesAlive
        :subscribe(function(enemy)
            -- let them fall down slowly
            enemy.y = enemy.y + dt * enemy.speed
        end)

end)

love.draw:subscribe(function ()
                            
    -- let's draw a background
    -- love.graphics.setColor(255,255,255,255)

    -- set the drawing color to green for the ground
    love.graphics.setColor(0.28, 0.63, 0.05)
    -- draw a "filled in" polygon using the ground's coordinates
    love.graphics.polygon("fill", objects.ground.body:getWorldPoints(
                            objects.ground.shape:getPoints()))
    
    -- set the drawing color to red for the ball
    love.graphics.setColor(0.76, 0.18, 0.05)
    love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())
    
    -- set the drawing color to grey for the blocks
    love.graphics.setColor(0.20, 0.20, 0.20)
    love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
    love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

    -- let's draw some ground
    -- love.graphics.setColor(0,255,0,255)
    -- love.graphics.rectangle("fill", 0, 465, 800, 150)

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
            love.graphics.rectangle("fill", shot.x, shot.y, shot.width, shot.height)
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
    --filter not fired. first.
    rx.Observable.fromTable(objects.hero.shots, pairs, false)
        :filter(function(shot)
            return not shot.fired
        end)
        :first()
        :subscribe(function(shot)
            shot.x = objects.hero.x+objects.hero.width/2
            shot.y = objects.hero.y
            shot.fired = true
        end)
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
function CheckCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
    local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end
