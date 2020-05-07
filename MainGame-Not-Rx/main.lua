-- Rx libs
local rx = require 'rx'
require 'rx-love'

-- MapManager module
local MapManager = require 'MapManager'

-- CollisionManager module
local CollisionManager = require 'CollisionManager'

-- Player module
local Player = require 'Player'

-- Enemies module
local Enemies = require 'Enemies'

-- MovingPlats module
local MovingPlats = require 'MovingPlats'

-- FallingPlats module
local FallingPlats = require 'FallingPlats'

-- Shield module
local Shield = require 'Shield'

local scheduler = rx.CooperativeScheduler.create()

-- Declare initial state of game
function love.load()
	-- load map
	map, world = MapManager.InitMap()

    hero = Player.Init()
    
    enemies = Enemies.Init()
    
    movingPlats = MovingPlats.Init()
    
    fallingPlats = FallingPlats.Init()
    
    shield = Shield.Init(scheduler)

    CollisionManager.Init()
end

function love.update(dt)
    world:update(dt) -- this puts the world into motion
	scheduler:update(dt)
	
	-- Update world map
    map:update(dt)
    
    -- Updates Player
    hero.update(dt)
    
    -- Updates Enemies
    for _, enemy in pairs(enemies) do
        enemy.update(dt)
    end
    
    -- Updates movingPlats
    for _, movingPlat in pairs(movingPlats) do
        movingPlat.update(dt)
    end
    
    -- Updates fallingPlats
    for _, fallingPlat in pairs(fallingPlats) do
        fallingPlat.update(dt)
    end

    -- Update collisions
    CollisionManager.update(dt)
end

function love.keyreleased(key)
    -- Sends to Player
    hero.keyreleased(key)
end

function love.keypressed(key)
    -- Sends to Player
    hero.keypressed(key)
end

function love.draw()

    heroPosX, heroPosY = hero.body:getPosition();
    local tx,ty = -heroPosX + love.graphics.getWidth()/2, -heroPosY + love.graphics.getHeight() * 3/4;
	
    -- Draw world
	love.graphics.setColor(1, 1, 1)
	map:draw(tx,ty)

	-- Draw Collision Map (useful for debugging)
	-- love.graphics.setColor(1, 0, 0)
	-- map:box2d_draw(tx,ty)

    -- Move camera back to original pos
    -- love.graphics.translate(-(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4))
    -- Health bar
    love.graphics.setColor(242/255, 178/255, 0)
    love.graphics.rectangle("fill", 20, 20, hero.backHealth, 20)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", 20, 20, hero.health, 20)
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("line", 20, 20, 100, 20)
end