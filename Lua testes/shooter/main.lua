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
function love.load(arg)
  -- if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
  hero = {} -- new table for the hero
  hero.x = 300 -- x,y coordinates of the hero
  hero.y = 450
  hero.width = 30
  hero.height = 15
  hero.speed = 150
  hero.shots = {} -- holds our fired shots

  enemies = {}
  for i=0,7 do
    local enemy = {}
    enemy.width = 40
    enemy.height = 20
    enemy.x = i * (enemy.width + 60) + 100
    enemy.y = enemy.height + 100
    table.insert(enemies, enemy)
  end
end

-- Helper functions
local function identity(...) return ... end
local function const(val) return function() return val end end
local function dt() return love.update:getValue() end
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

-- function love.update(dt)
--   local remEnemy = {}
--   local remShot = {}

--   -- update the shots
--   for i,v in ipairs(hero.shots) do
--     -- move them up up up
--     v.y = v.y - dt * 100

--     -- mark shots that are not visible for removal
--     if v.y < 0 then
--       table.insert(remShot, i)
--     end

--     -- check for collision with enemies
--     for ii,vv in ipairs(enemies) do
--       if CheckCollision(v.x,v.y,2,5,vv.x,vv.y,vv.width,vv.height) then
--         -- mark that enemy for removal
--         table.insert(remEnemy, ii)
--         -- mark the shot to be removed
--         table.insert(remShot, i)
--       end
--     end
--   end

--   -- remove the marked enemies
--   for i,v in ipairs(remEnemy) do
--     table.remove(enemies, v)
--   end

--   for i,v in ipairs(remShot) do
--     table.remove(hero.shots, v)
--   end

--   -- update those evil enemies
--   for i,v in ipairs(enemies) do
--     -- let them fall down slowly
--     v.y = v.y + dt

--     -- check for collision with ground
--     if v.y > 465 then
--       -- you loose!!!
--     end
--   end
-- end

function love.draw()
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
  for i,v in ipairs(hero.shots) do
    love.graphics.rectangle("fill", v.x, v.y, 2, 5)
  end

  -- let's draw our enemies
  love.graphics.setColor(0,255,255,255)
  for i,v in ipairs(enemies) do
    love.graphics.rectangle("fill", v.x, v.y, v.width, v.height)
  end
end

function shoot()
  if #hero.shots >= 5 then return end
  local shot = {}
  shot.x = hero.x+hero.width/2
  shot.y = hero.y
  table.insert(hero.shots, shot)
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
function CheckCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end
