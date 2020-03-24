-- Rx libs
local rx = require 'rx'
require 'rx-love'

local CollisionManager = {}

function CollisionManager.Init()

    CollisionManager.beginContact = rx.Subject.create()
    CollisionManager.endContact = rx.Subject.create()
    CollisionManager.preSolve = rx.Subject.create()
    CollisionManager.postSolve = rx.Subject.create()

    --Collision callbacks 
    CollisionManager.bC = function (a, b, coll)  
        CollisionManager.beginContact:onNext(a, b, coll)
    end
    CollisionManager.eC = function (a, b, coll)
        CollisionManager.endContact:onNext(a, b, coll)
    end
    CollisionManager.preS = function (a, b, coll)
        CollisionManager.preSolve:onNext(a, b, coll)
    end
    CollisionManager.postS = function (a, b, coll, normalimpulse, tangentimpulse)
        CollisionManager.postSolve:onNext(a, b, coll, normalimpulse, tangentimpulse)
    end

    CollisionManager.beginContact
        :filter(function(a, b, coll) 
            return a:getUserData().properties.tag == "Hero"  
        end)
        :subscribe(function(a, b, coll) 
            print(a:getUserData().properties.tag)
            a:getUserData().properties.collisions.onNext(b:getUserData().properties) 
        end)

    CollisionManager.beginContact
        :filter(function(a, b, coll) 
            return b:getUserData().properties.tag == "Hero"  
        end)
        :subscribe(function(a, b, coll) 
            print(a:getUserData().properties.tag)
            -- b:getUserData().properties.collisions.onNext(a:getUserData().properties) 
        end)

    -- --Collision callbacks:
    world:setCallbacks(CollisionManager.bC, CollisionManager.eC, CollisionManager.preS, CollisionManager.postS)
end

return CollisionManager