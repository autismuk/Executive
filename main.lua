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
require("main_flappy")
--require("main_fsm")


--[[
-- TODO: timer knows sender ?
-- TODO: Warning if decoration overrides.

local Executive = require("system.executive")
local ex = Executive:new()
local class = ex:createClass()

function class:constructor(data)
	print("Constructor")
	local id = self:addRepeatingTimer(500,"tag!")
end 

function class:onTimer(tag,id)
	print("Fired",tag,id)
end 

demo = class:new(ex,{})
demo:delete()
--]]