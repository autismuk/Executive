--- ************************************************************************************************************************************************************************
---
---				Name : 		fsm.lua
---				Purpose :	Finite State Machine Object for Executive
---				Created:	16 June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

--- ************************************************************************************************************************************************************************
--//															Four way controller class
--- ************************************************************************************************************************************************************************

local FSM = Base:new()

--//	Create a new finite state machine.
--//	@info 	[table]			contains states, built of events, and listener and firstState items.

function FSM:constructor(info)
	self.fsm = info 																			-- save the fsm object
	info.listeners = info.listeners or "fsmlistener" 											-- default listener is fsmlistener
	info.firstState = info.firstState or "start" 												-- default state is start.
	-- TODO process casing and check.
	self.current = info.firstState 																-- set the current state.
	self:announce("enter",info.firstState,nil,nil) 												-- announce entering first state.
end 

function FSM:announce(transaction,state,lastState,data)
	self:sendMessage(self.fsm.listeners,														-- tell all listener(s) what is being done.
						{ transaction = transaction, state = state, data = data, previousState = lastState })
end

function FSM:event(event)
	event = event:lower() 																		-- case independent
	local switch = self.fsm[self.current][event] 												-- get the the switch record
	assert(switch ~= nil,"Unknown event "..event.." in state "..self.current) 					-- if no switch record (bad event) report an error.
	self:announce("leave",self.current)															-- announce leaving a state
	local last = self.current 																	-- remember last state
	self.current = switch.target 																-- make the current state correct.
	self:announce("enter",self.current,last,switch) 											-- announce entering state
end 

function FSM:getState() 																	
	return self.current 																		-- return current state.
end 

function FSM:destructor()
	self.fsm = nil self.current = nil 															-- null out references.
end


return FSM
