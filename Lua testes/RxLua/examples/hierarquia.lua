local Rx = require 'rx'

-- local subject = Rx.Subject.create()

-- subject:subscribe(function(x,y)
--     if y == nil then
--     print('observer a ' .. x)
--     else  
--     print('observer a ' .. 'x: ' .. x .. 'y: ' .. y)
--     end
-- end)

-- subject:subscribe(function(x)
--   print('observer b ' .. x)
-- end)

-- subject:onNext(1)
-- subject(2,4)
-- subject:onNext(3)
local scheduler = Rx.CooperativeScheduler.create()

-- local observable = Rx.Observable.fromCoroutine(function()
--     for i = 2, 8, 2 do
--       coroutine.yield(i)
--     end
  
--     return 'who do we appreciate'
--   end, scheduler)

local tableTest = {}
tableTest.teste = 1
tableTest.teste2 = 3
local tableObservable = Rx.Observable.fromTable(tableTest)
tableObservable:delay(1000,scheduler):dump('valor ')
tableTest.teste2 = 2

repeat
    scheduler:update()
until scheduler:isEmpty()