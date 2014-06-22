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

function ObjectManagerClass:constructor()
	self.m_factoryObjects = {}																		-- empty list of factory instances
	self:name("objectManager") 																		-- make object available to executive
end 

function ObjectManagerClass:addFactoryObject(state,factoryInstance)
	state = state:lower() 																			-- lower case references
	assert(self.m_factoryObjects[state] == nil)														-- shouldn't happen !
	self.m_factoryObjects[state] = factoryInstance 													-- store factory instance
end 

function ObjectManagerClass:destructor()
	for state,ref in pairs(self.m_factoryObjects) do 												-- when deleting the game class, we clean all the factory instances
		ref:clean() 																				-- which is effectively garbage collecting everything.
	end 
	self.m_factoryObjects = nil 																	-- lose the reference
end 

function ObjectManagerClass:getFactoryInstance(state)
	local inst = self.m_factoryObjects[state:lower()] 												-- get the instance
	assert(inst ~= nil,"No factory instance for state "..state) 									-- check it was found
	return inst 
end 

--- ************************************************************************************************************************************************************************
-- 													Executive object which listens to FSM and responds to changes.
--- ************************************************************************************************************************************************************************

local GameManagerClass = Executive:createClass()

function GameManagerClass:constructor(info)
	self:tag("+fsmlistener")
	self.m_managerLocked = false 																	-- set when in transition and event will not work.
end

function GameManagerClass:onMessage(sender,message) 												-- listen for FSM Changes
	--print("FSM Message : ",message.transaction,message.state,message.previousState,message.data.target)
	assert(not self.m_managerLocked,"Sending state changes during transition to ",message.state)
	if message.transaction == "enter" then 															-- only interested in entering classes
		local factory = self:getExecutive().e.objectManager:getFactoryInstance(message.state) 		-- was there a previous class.
		if message.previousState == nil then  														-- if not, then go straight into the first state
			factory:preOpen() 																		-- do pre-open to set up
			factory:open() 																			-- and open to start.
			self.m_currentFactoryInstance = factory
			-- TODO: transition in ?
		else  																						-- we are transitioning from one state to another.
			self.m_newStateInstance = self:getExecutive().e.objectManager:getFactoryInstance(message.state)
			self.m_newStateInstance:preOpen()
			self.m_currentFactoryInstance:close()
			self.m_managerLocked = true
			Transition:execute("slideRight",self,self.m_currentFactoryInstance:getExecutive():getGroup(),self.m_newStateInstance:getExecutive():getGroup(),1400)
		end
	end
end

function GameManagerClass:transitionCompleted()
	self.m_currentFactoryInstance:postClose()
	self.m_newStateInstance:open()
	self.m_currentFactoryInstance = self.m_newStateInstance 
	self.m_newStateInstance = nil
	self.m_managerLocked = false
end 

--- ************************************************************************************************************************************************************************
-- 																		Game Class
--- ************************************************************************************************************************************************************************

local Game = Executive:new() 																		-- this is a game class.

function Game:initialise() 
	GameManagerClass:new(self) 																		-- listens for fsm events
	ObjectManagerClass:new(self) 																	-- manage scene factory instances
	self:addLibraryObject("system.fsm"):name("fsm") 												-- the fsm - named to be accessed
end 

function Game:start(overrideState)
	self.e.fsm:start(overrideState) 																-- start the fsm.
end 

function Game:addState(stateName,executiveFactoryInstance,stateDefinition)
	self.e.fsm:addState(stateName,stateDefinition) 													-- add definition to the fsm
	self.e.objectManager:addFactoryObject(stateName:lower(),executiveFactoryInstance) 				-- tell the scene factory manager about the scene factory instance.
end 

function Game:getState() 
	return self.e.fsm:getState()  																	-- return current state
end

function Game:event(eventName) 
	self.e.fsm:event(eventName) 																	-- switch to a new event.
end 

_G.Game = Game:new() 																				-- make a global instance.

--[[

-- memory stuff
-- get transition from FSM, with defaults.

--]]

return ExecutiveFactory 																		-- returns the executivefactory base class.
