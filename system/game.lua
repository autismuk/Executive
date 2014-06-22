--- ************************************************************************************************************************************************************************
---
---				Name : 		game.lua
---				Purpose :	Executive Based Scene System
---				Created:	18th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************

local Executive = require("system.executive")													-- Needs the Executive class.
local Transition = require("system.transitions")												-- and the transition manager.

--- ************************************************************************************************************************************************************************
--//	This is the base class for the executive factory, which is a factory class which creates and manages executives, each executive being a 'scene' in the game.
--- ************************************************************************************************************************************************************************

local ExecutiveFactory = Base:new()

--//	First call the constructor for long term resources if this hasn't already been done. Check to see if the object has been instantiated, if not create the executive

function ExecutiveFactory:instantiate()
	if self.m_constructorCalled == nil then 													-- are the long term resources loaded
		self:constructor() 																		-- no, call the long term resource loader, constructor
		self.m_constructorCalled = true  														-- mark as having occurred
	end
	if self.m_executive == nil then 															-- created an executive yet for this object
		self.m_executive = Executive:new() 														-- if not, do it.
	end 
end 

--//	Get the current executive for this factory, creating it if necessary.
--//	@return 	[Executive] 		Executive instance.

function ExecutiveFactory:getExecutive()
	self:instantiate() 																			-- Check to see if factory has been started
	return self.m_executive
end 

--//	Pre-open phase. This method will be called when the scene is switched to, but before the transition has started. This should create objects
--//	but not activate them, so the game screen is up but not actually doing anything, so it can be transitioned in.

function ExecutiveFactory:preOpen() 
	self:instantiate() 																			-- Check to see if factory has been started
end 

--//	Open phase. This is called after the transition to this scene has finished, and should start the actual game.

function ExecutiveFactory:open() end 

--//	Close phase. When the running executive has decided that this scene is over, and it is going to end, this method will be called once the 
--//	Game's FSM has decided to switch to another scene. It normally should not be touched - it is usually the responsibility of the executive 
--//	to stop itself from running.

function ExecutiveFactory:close() end 

--//	This is called after the transition to the next screen has occurred, and should normally not be touched - it removes the executive object.
--//	thus removing all the attached objects.

function ExecutiveFactory:postClose() 
	if self.m_executive ~= nil then 															-- do we have an executive ?
		self.m_executive:delete()																-- if so, get rid of it.
		self.m_executive = nil  																-- and null its pointer
	end
end 

--//	The constructor loads long term resources that belong to this executive. It is called when necessary.

function ExecutiveFactory:constructor() end 

--//	The detructor frees long term resources that belong to this executive.

function ExecutiveFactory:destructor() end 

--//	The clean() method allows garbage collection. If an app is running low on memory, it can call this on all scenes but the current one.
--//	It calls the destructor to free up any resources. If they are needed again, they will be reloaded.

function ExecutiveFactory:clean()
	if self.m_constructorCalled then 															-- if the controller has been called
		self:destructor() 																		-- call the destructor
		self.m_constructorCalled = nil  														-- null the pointer so it will be reloaded if needed.
	end 
end

--- ************************************************************************************************************************************************************************
--														Executive object which manages the factory classes.
--- ************************************************************************************************************************************************************************

local ObjectManagerClass = Executive:createClass()

--//	Create an empty object mananger class.

function ObjectManagerClass:constructor()
	self.m_factoryObjects = {}																		-- empty list of factory instances
	self:name("objectManager") 																		-- make object available to executive
end 

--//	Add a factory instance attached to a given state name.
--//	@state 				[string] 		Name of state
--//	@factoryInstance 	[factory]		instance of executive factory.

function ObjectManagerClass:addFactoryObject(state,factoryInstance)
	state = state:lower() 																			-- lower case references
	assert(self.m_factoryObjects[state] == nil)														-- shouldn't happen !
	self.m_factoryObjects[state] = factoryInstance 													-- store factory instance
end 

--//	Tidy up factory instances.

function ObjectManagerClass:destructor()
	for state,ref in pairs(self.m_factoryObjects) do 												-- when deleting the game class, we clean all the factory instances
		ref:clean() 																				-- which is effectively garbage collecting everything.
	end 
	self.m_factoryObjects = nil 																	-- lose the reference
end 

--//	Retrieve factory instance for given named state.
--//	@state 	[string]		Name of state
--//	@return [factory]		Factory instance associated with it.

function ObjectManagerClass:getFactoryInstance(state)
	local inst = self.m_factoryObjects[state:lower()] 												-- get the instance
	assert(inst ~= nil,"No factory instance for state "..state) 									-- check it was found
	return inst 
end 

--- ************************************************************************************************************************************************************************
-- 													Executive object which listens to FSM and responds to changes.
--- ************************************************************************************************************************************************************************

local GameManagerClass = Executive:createClass()

--//	Constructor for Game manager.

function GameManagerClass:constructor(info)
	self:tag("+fsmlistener")
	self.m_managerLocked = false 																	-- set when in transition and event will not work.
end

--//	Game Manager message handler. Receives state changes from the game's FSM.
--//	@sender 	[object] 			where it came from.
--//	@message 	[message]			executive message describing fsm state changes.

function GameManagerClass:onMessage(sender,message) 												-- listen for FSM Changes
	--print("FSM Message : ",message.transaction,message.state,message.previousState,message.data.target)
	assert(not self.m_managerLocked,"Sending state changes during transition to ",message.state) 	-- cannot state change in a transition.
	if message.transaction == "enter" then 															-- only interested in entering classes
		local factory = self:getExecutive().e.objectManager:getFactoryInstance(message.state) 		-- was there a previous class.
		if message.previousState == nil then  														-- if not, then go straight into the first state
			factory:preOpen() 																		-- do pre-open to set up
			factory:open() 																			-- and open to start.
			Transition:execute("fade",self,nil,factory:getExecutive():getGroup(),300)				-- fade it in.
			self.m_currentFactoryInstance = factory 												
		else  																						-- we are transitioning from one state to another.
			self.m_newStateInstance = 																-- get new factory instance
						self:getExecutive().e.objectManager:getFactoryInstance(message.state)
			self.m_newStateInstance:preOpen() 														-- pre-open it.
			self.m_currentFactoryInstance:close() 													-- close the currently opening one
			self.m_managerLocked = true 															-- lock against changes.
			local transition = message.data.transition or {} 										-- get transition, empty default
			Transition:execute(transition.effect or "fade", 										-- start transition, defaults to fade
							   self, 																-- report completion to self.
							   self.m_currentFactoryInstance:getExecutive():getGroup(), 			-- from the current group
							   self.m_newStateInstance:getExecutive():getGroup(), 					-- to the new one
							   transition.time or 500) 												-- get time, default to 0.5s
		end
	end
end

--//	This method is called by the Transaction Manager library when a transaction is completed.

function GameManagerClass:transitionCompleted()
	if not self.m_managerLocked then return end 													-- if not locked it's the starting transition.
	self.m_currentFactoryInstance:postClose() 														-- so, finally close out the old state.
	self.m_newStateInstance:open()	 																-- and open the new one
	self.m_currentFactoryInstance = self.m_newStateInstance  										-- set current instance to new instance
	self.m_newStateInstance = nil 																	-- null out the new instance
	self.m_managerLocked = false 																	-- and we can now change state.
end 

--- ************************************************************************************************************************************************************************
-- 	Game Class. This is a singleton containing a finite state machine representing scene flow, a listener that listens to the FSM and changes scenes accordingly,
--	and an object that stores the executive factory instances, whose preOpen/open/close/preClose/clean methods are called.
--- ************************************************************************************************************************************************************************

local Game = Executive:new() 																		-- this is a game class.

--//	Instantiate the game class.

function Game:initialise() 
	GameManagerClass:new(self) 																		-- listens for fsm events
	ObjectManagerClass:new(self) 																	-- manage scene factory instances
	self:addLibraryObject("system.fsm"):name("fsm") 												-- the fsm - named to be accessed
end 

--//	Start the game.
--//	@overrideState [string]		State to go to first, can override that in the FSM for debugging.

function Game:start(overrideState)
	self.e.fsm:start(overrideState) 																-- start the fsm.
end 

--//	Add a new state to the Game's FSM. Each FSM state has an associated executiveFactory object which manages its executive class.
--//	@stateName 				  [string]				Name of state to add.
--//	@executiveFactoryInstance [factoryInstance]		Executive Factory instance associated with this state.
--//	@stateDefinition 		  [stateDef]			State definition, events -> new states. Also contains transaction information.

function Game:addState(stateName,executiveFactoryInstance,stateDefinition)
	self.e.fsm:addState(stateName,stateDefinition) 													-- add definition to the fsm
	self.e.objectManager:addFactoryObject(stateName:lower(),executiveFactoryInstance) 				-- tell the scene factory manager about the scene factory instance.
end 

--//	Return the current state
--//	@return 	[string] 	state name

function Game:getState() 
	return self.e.fsm:getState()  																	-- return current state
end

--//	Apply an event to the Game's FSM.
--//	@eventName 	[string] 	Event name to apply.

function Game:event(eventName) 
	self.e.fsm:event(eventName) 																	-- switch to a new state, probably.
end 

_G.Game = Game:new() 																				-- make a global instance.

--[[

-- memory stuff

--]]

return ExecutiveFactory 																		-- returns the executivefactory base class.
