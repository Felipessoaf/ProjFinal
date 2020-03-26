-- Include Simple Tiled Implementation into project
local sti = require "sti"

function love.load()
	-- Load map file
	map = sti("Maps/test1.lua")

	-- Create new dynamic data layer called "Sprites" as the 8th layer
	local layer = map:addCustomLayer("Sprites", 3)

	-- Get player spawn object
	local spawnPos
	for k, object in pairs(map.objects) do
		if object.name == "spawn" then
			spawnPos = object
			break
		end
	end

	-- Create player object
	local sprite = love.graphics.newImage("player.png")
	layer.player = {
		sprite = sprite,
		x      = spawnPos.x,
		y      = spawnPos.y,
		ox     = sprite:getWidth() / 2,
		oy     = sprite:getHeight() / 1.35
	}

	-- Add controls to player
	layer.update = function(self, dt)
		-- 96 pixels per second
		local speed = 96 * dt

		-- Move player up
		if love.keyboard.isDown("w", "up") then
			self.player.y = self.player.y - speed
		end

		-- Move player down
		if love.keyboard.isDown("s", "down") then
			self.player.y = self.player.y + speed
		end

		-- Move player left
		if love.keyboard.isDown("a", "left") then
			self.player.x = self.player.x - speed
		end

		-- Move player right
		if love.keyboard.isDown("d", "right") then
			self.player.x = self.player.x + speed
		end
	end

	-- Draw player
	layer.draw = function(self)
		love.graphics.draw(
			self.player.sprite,
			math.floor(self.player.x),
			math.floor(self.player.y),
			0,
			1,
			1,
			self.player.ox,
			self.player.oy
		)

		-- Temporarily draw a point at our location so we know
		-- that our sprite is offset properly
		love.graphics.setPointSize(5)
		love.graphics.points(math.floor(self.player.x), math.floor(self.player.y))
	end

	-- Remove unneeded object layer
	map:removeLayer("spawn")
end

function love.update(dt)
	-- Update world
	map:update(dt)
end

function love.draw()
	-- Draw world
	map:draw()
end