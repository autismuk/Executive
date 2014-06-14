--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Executive Object System test
---				Created:	12th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

--- ************************************************************************************************************************************************************************

--require("main_pong")
--require("bully")
require("main_flappy")

--[[
Executive = require("system.executive")

local x = Executive:new()
print(x)
c1 = x:createClass()

function c1:constructor(data)
	self.data = data 
	print("Constructor",data)
end 

function c1:destructor()
	print("Destructor")
end 

function c1:onUpdate(deltaTime,deltaMillisecs)
end 

o1 = c1:new(32)
o2 = c1:new(132)
o3 = c1:new(232)

o1:tag("+update,+z,q,a")
o2:tag("+update,+b")
o3:tag("+update,+b")

--q1 = x:query("update,b")
--print(q1.count)
--print(x:process("update,q,b",function(s) print(s,s.data) end))

--local r1 = o1:addRepeatingTimer(1000,"one")
--local r = o2:addTimer(500,8,"x8")
--o3:addSingleTimer(3000,"kill")

function o1:onTimer(timerID,tag) print("o1",timerID,tag) end
function o2:onTimer(timerID,tag) print("o2",timerID,tag) end
function o3:onTimer(timerID,tag) print("o3",timerID,tag) self:removeTimer(r1) self:removeTimer(r) end

function o1:onMessage(from,message) print(self.data,from,message.name) end 
function o2:onMessage(from,message) print(self.data,from,message.name) end 
function o3:onMessage(from,message) print(self.data,from,message.name) end 

o1:sendMessage("b",{ name = "My message" })


--x:delete()

require("bully")
--]]

-- TODO terminate on failed update.
-- TODO pass system timer on update.