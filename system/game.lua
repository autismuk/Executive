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

return ExecutiveFactory 																		-- returns the executivefactory base class.
