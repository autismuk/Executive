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
--require("main_flappy")

-- TODO FSM Design / FSM 
-- TODO Flappy FSM
-- TODO Extend FSM to manage scenes

local Executive = require("system.executive")

local executive = Executive:new()

local ListenerClass = executive:createClass()

function ListenerClass:constructor(info)
	self:tag("+fsmlistener")
end

function ListenerClass:onMessage(sender,message)
	print("FSM Message : ",message.transaction,message.state,message.previousState)
end

ListenerClass:new({})

local fsm = executive:addLibraryObject("system.fsm",{ 

	start = { 
		restart = { target = "start" },
		game = { target = "game" }
	},

	game = { 
		gameover = { target = "start"}
	},

})

fsm:event("restart")
fsm:event("game")
fsm:event("gameover")


