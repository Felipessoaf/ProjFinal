local rx = require 'rx'
require 'rx-love'

a = false

love.keypressed
  :filter(function(key) return key == ' ' end)
  :subscribe(function()
    a = true
  end)

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
end

function love.draw()
  if a then 
  love.graphics.setColor(20,255,0,255)
  love.graphics.print("Hello", 100, 100)
  end

  rx.Observable.fromRange(1, 8)
    :filter(function(x) return x % 2 == 0 end)
    :concat(rx.Observable.of('who do we appreciate'))
    :map(function(value) return value .. '!' end)
    :subscribe(love.graphics.print)
end