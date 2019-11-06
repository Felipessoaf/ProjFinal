local rx = require 'rx'
require 'rx-love'

-- Maps keys to players and directions
local keyMap = {
  a = {-1},
  d = {1},
  left = {-1},
  right = {1}
}

-- Declare initial state of game
love.load:subscribe(function (arg)
    hero = rx.BehaviorSubject.create() -- new table for the hero
    hero.x = 300 -- x,y coordinates of the hero
    hero.y = 450
    hero.width = 30
    hero.height = 15
    hero.speed = 150
    hero.shots = {} -- holds our shots

    rx.Observable.fromRange(1, 5)
        :subscribe(function ()
            local shot = {}
            shot.x = 0
            shot.y = 0
            shot.width = 2
            shot.height = 5
            shot.fired = true
            table.insert(hero.shots, shot)    
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
    hero.x = hero.x + hero.speed*dt*direction

    hero:onNext()
end

-- Respond to key presses to move players
-- keyboard actions for our hero
for _, key in pairs({'a', 'd', 'left', 'right'}) do
    love.update
        :filter(function()
            return love.keyboard.isDown(key)
        end)
        :map(function(dt)
            return dt, unpack(keyMap[key])
        end)
        :subscribe(move)
end

love.keypressed
    :filter(function(key) return key == 'space' end)
    :subscribe(function()
        shoot()
    end)

love.update:subscribe(function (dt)
    hero:filter(function()
            return hero.x < 0
        end)
        :subscribe(function()
            hero.x = 0
        end)

    -- update the shots
    shotsFired = rx.Observable.fromTable(hero.shots, pairs, false)
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
    love.graphics.setColor(255,255,255,255)

    -- let's draw some ground
    love.graphics.setColor(0,255,0,255)
    love.graphics.rectangle("fill", 0, 465, 800, 150)

    -- let's draw our hero
    love.graphics.setColor(255,255,0,255)
    love.graphics.rectangle("fill", hero.x, hero.y, hero.width, hero.height)

    -- let's draw our heros shots
    love.graphics.setColor(255,255,255,255)
    rx.Observable.fromTable(hero.shots, pairs, false)
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
    rx.Observable.fromTable(hero.shots, pairs, false)
        :filter(function(shot)
            return not shot.fired
        end)
        :first()
        :subscribe(function(shot)
            shot.x = hero.x+hero.width/2
            shot.y = hero.y
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
