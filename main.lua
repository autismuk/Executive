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

--require("main_pong")
--require("bully")
--require("main_flappy")
--require("main_fsm")
--[[
local Executive = require("system.executive")
local ex = Executive:new()

local demo = display.newRect(110,110,100,100)


function demo:destructor() self:removeSelf() end

function demo:onMessage(sender,body) print(sender,body.a,body.b) end

function demo:sendMessage(a,b) print("I have a sendMessage()") end

ex:addMixinObject(demo)
demo:tag("fred")
x = demo:query("fred")
print(x.count,x.objects)
for k,v in pairs(x.objects) do v:setFillColor(1,0,0) end
demo:sendMessage("fred",{ a = 1,b = 2})
--demo:delete()
--]]