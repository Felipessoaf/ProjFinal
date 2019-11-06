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
    hero = {} -- new table for the hero
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
        table.insert(enemies, enemy)  
    end)
end)

-- Helper functions
local function move(dt, direction)
    hero.x = hero.x + hero.speed*dt*direction
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
    -- update the shots
    for i,shot in ipairs(hero.shots) do
        if shot.fired then
            -- move them up up up
            shot.y = shot.y - dt * 100
        end

        -- mark shots that are not visible
        if shot.y < 0 then
            shot.fired = false
        end

        -- check for collision with enemies
        for ii,enemy in ipairs(enemies) do
            if enemy.alive then
                if CheckCollision(shot.x,shot.y,shot.width,shot.height,enemy.x,enemy.y,enemy.width,enemy.height) then
                    -- mark that enemy dead
                    enemy.alive = false
                    -- mark the shot not visible
                    shot.fired = false
                end
            end
        end
    end

    -- update those evil enemies
    for i,enemy in ipairs(enemies) do
        if enemy.alive then
            -- let them fall down slowly
            enemy.y = enemy.y + dt

            -- check for collision with ground
            if enemy.y > 465 then
                -- you loose!!!
                love.load()
            end
        end
    end
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
    for i,shot in ipairs(hero.shots) do
        if shot.fired then
            love.graphics.rectangle("fill", shot.x, shot.y, shot.width, shot.height)
        end
    end

    -- let's draw our enemies
    love.graphics.setColor(0,255,255,255)
    for i,enemy in ipairs(enemies) do
        if enemy.alive then
            love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        end
    end
end)

function shoot()
    --filter not fired. first.
    for i,shot in ipairs(hero.shots) do 
        if not shot.fired then
            shot.x = hero.x+hero.width/2
            shot.y = hero.y
            shot.fired = true
            break
        end
    end
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
function CheckCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end
