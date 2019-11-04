local Rx = require 'rx'

local subject = Rx.Subject.create()

subject:subscribe(function(x,y)
    if y == nil then
    print('observer a ' .. x)
    else  
    print('observer a ' .. 'x: ' .. x .. 'y: ' .. y)
    end
end)

subject:subscribe(function(x)
  print('observer b ' .. x)
end)

subject:onNext(1)
subject(2,4)
subject:onNext(3)
