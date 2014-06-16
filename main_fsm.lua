--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		main_fsm.lua
---				Purpose :	Executive Object System - Finite State Machine simple test
---				Created:	12th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

--- ************************************************************************************************************************************************************************

local Executive = require("system.executive")													-- get Executive class
local executive = Executive:new() 																-- create instance

local ListenerClass = executive:createClass() 													-- this class has no purpose other than to echo FSM messages

function ListenerClass:constructor(info)
	self:tag("+fsmlistener")
end

function ListenerClass:onMessage(sender,message) 												-- listen for FSM Changes
	print("FSM Message : ",message.transaction,message.state,message.previousState)
end

ListenerClass:new({}) 																			-- create an instance of it.

local fsm = executive:addLibraryObject("system.fsm",{ 											-- create an FSM

	start = { 																					-- state 'start' with two events.
		restart = { target = "start" },
		game = { target = "game" }
	},

	game = { 																					-- state 'game' with one event
		gameover = { target = "start"}
	},

}):start()

fsm:event("restart") 																			-- fake some stuff happening.
fsm:event("game")
fsm:event("gameover")



