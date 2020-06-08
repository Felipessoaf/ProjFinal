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
love.load:subscribe(function (arg)	
	-- load map
	map, world = MapManager.InitMap()

    hero = Player.Init(scheduler)
    
    enemies = Enemies.Init(scheduler)
    
    movingPlats = MovingPlats.Init(scheduler)
    
    fallingPlats = FallingPlats.Init(scheduler)
    
    shield = Shield.Init(scheduler)

    CollisionManager.Init(scheduler)    
end)

love.update:subscribe(function (dt)
    world:update(dt) -- this puts the world into motion
	scheduler:update(dt)
	
	-- Update world map
	map:update(dt)
end)

love.draw:subscribe(function ()

    heroPosX, heroPosY = hero.body:getPosition();
    local tx,ty = -heroPosX + love.graphics.getWidth()/2, -heroPosY + love.graphics.getHeight() * 3/4;
	
    -- Draw world
	love.graphics.setColor(1, 1, 1)
    map:draw(tx,ty)
    
    -- Texto inimigos
    love.graphics.setColor(0, 0, 0)
    font = love.graphics.setNewFont(20)
    love.graphics.print(Enemies.stateText or "", love.graphics.getWidth()/2 - font:getWidth(Enemies.stateText or "")/2, 20)

	-- Draw Collision Map (useful for debugging)
	-- love.graphics.setColor(1, 0, 0)
	-- map:box2d_draw(tx,ty)

    -- Move camera back to original pos
    -- love.graphics.translate(-(-heroPosX + love.graphics.getWidth()/2), -(-heroPosY + love.graphics.getHeight() * 3/4))
    -- Health bar
    love.graphics.setColor(242/255, 178/255, 0)
    love.graphics.rectangle("fill", 20, 20, hero.backHealth, 20)
    love.graphics.setColor(255,0,0,255)
    love.graphics.rectangle("fill", 20, 20, hero.health:getValue(), 20)
    love.graphics.setColor(0,0,0,255)
    love.graphics.rectangle("line", 20, 20, 100, 20)
end)