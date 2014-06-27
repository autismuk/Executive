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
--//															Finite state machine class
--- ************************************************************************************************************************************************************************

local FSM = Base:new()

--//	Create a new finite state machine.
--//	@info 	[table]			contains states, built of events, and listener and firstState items.

function FSM:constructor(info)
	info.listeners = info.listeners or "fsmlistener" 											-- default listener is fsmlistener
	info.firstState = info.firstState or "start" 												-- default state is start.
	self.current = info.firstState:lower() 														-- set the current state.
	self.fsm = {}
	for key,value in pairs(info) do 															-- work through all the entries in the info table
		if type(value) == "table" and type(value.target) == "function" then  					-- it table (e.g. it is a state) then add it.
			self:addState(key,value)
		else 
			self.fsm[key:lower()] = value 														-- otherwise copy the value.
		end
	end
	self.fsmStarted = false 																	-- mark as not started
end 

--//	Start an FSM, validating it first
--//	@override 	[string]	Optional override for start state.
--//	@attachedData [table]	Data provided for the state event.
--//	@return 	[FSM]		Self, allowing chaining.

function FSM:start(override,attachedData)
	if attachedData == nil and type(override) == "table" then 									-- one single table parameter provided ?
		attachedData = override 																-- then that is the attached data, use the default start state.
		override = nil 
	end 
	assert(not self.fsmStarted,"Cannot restart fsm")											-- can't start it twice
	self.fsmStarted = true 																		-- mark it started
	for key,value in pairs(self.fsm) do  														-- work through all the states
		if type(value) == "table" then 
			for event,data in pairs(value) do  													-- work through all the events.
				data.target = data.target:lower() 												-- make target L/C, check it exists.
				assert(self.fsm[data.target] ~= nil,"State "..key.." event "..event.." has unknown target "..data.target)
			end 
		end 
	end
	self.current = override or self.current 													-- work out the first state.
	attachedData = attachedData or {} 															-- default empty table for attached data.
	assert(self.fsm[self.current] ~= nil,"Missing first state " .. self.current) 				-- check the first state actually exists.
	self:announce("enter",self.current,nil,nil,attachedData) 									-- announce entering first state.
	return self 																				-- allow chaining.
end 

--//	Add a state to the FSM
--//	@stateName 	[string] 		Text name of state
--//	@stateDef  	[table]			Table of events for that state.

function FSM:addState(stateName,statedef)
	local copy = {} 																			-- copy of the state
	for name,data in pairs(statedef) do  														-- clone the copy, using lower case keys
		copy[name:lower()] = data 
	end 
	assert(self.fsm[stateName:lower()] == nil,"Duplicate state "..stateName)					-- check it doesn't already exist.
	self.fsm[stateName:lower()] = copy 															-- and store it.
end 

--//% 	Send an announcement about a state transition to all listeners
--//	@transaction 	[string]		enter or leave
--//	@state 			[string]		state leaving or entering
--//	@lastState 		[string] 		last state, if entering
--//	@data 			[table] 		associated data from the fsm
--//	@attachedData 	[table] 		Data passed in either start or event.

function FSM:announce(transaction,state,lastState,data,attachedData)
	self:sendMessage(self.fsm.listeners,														-- tell all listener(s) what is being done.
						{ transaction = transaction, state = state, data = data or {}, previousState = lastState, eventData = attachedData or {}})
end

--// 	Send an event to the FSM, causing a possible change of state.
--//	@event 			[string]		event occurring

function FSM:event(event,attachedData)
	assert(self.fsmStarted,"FSM has not been started")											-- check the FSM has been started.
	event = event:lower() 																		-- case independent
	local switch = self.fsm[self.current][event] 												-- get the the switch record
	assert(switch ~= nil,"Unknown event "..event.." in state "..self.current) 					-- if no switch record (bad event) report an error.
	self:announce("leave",self.current)															-- announce leaving a state
	local last = self.current 																	-- remember last state
	self.current = switch.target 																-- make the current state correct.
	self:announce("enter",self.current,last,switch,attachedData) 								-- announce entering state
end 

--//	Get the current state
--//	@return 	[string]			current state.

function FSM:getState() 																	
	return self.current 																		-- return current state.
end 

--//% 	FSM Destructor

function FSM:destructor()
	self.fsm = nil self.current = nil self.fsmStarted = nil										-- null out references.
end

return FSM
