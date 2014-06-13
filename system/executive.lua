--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		executive.lua
---				Purpose :	Executive Object System Core
---				Created:	12th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

local ExecutiveBaseClass 																		-- forward reference to executive base class.

--- ************************************************************************************************************************************************************************
--//	The Executive Class is the main controller and storage system for objects. It also coordinates updates, timers and asynchronous messaging, which are built in. It
--//	uses ObjectLists regularly, which are a table consisting of a count, and a has of objects keyed on references.
--- ************************************************************************************************************************************************************************

local Executive = Base:new()

--//%	The Executive constructor creates all the empty structures used by the various parts of the Executive system and installs an enterFrame listener to drive
--//	updates, timers, and messages.

function Executive:initialise()
	self.m_objects = { objects = {}, count = 0 }												-- the objects member is initially empty, as there are no objects.
	self.m_indices = {} 																		-- create an empty tag index structure (name => listObject)
	self.m_indices["update"] = { objects = {}, count = 0 } 										-- create an 'update' index used for the enter frame update.
	self.m_timerEvents = {} 																	-- empty table of timer events.
	self.m_messageQueue = {} 																	-- empty message queue
	self.e = {} 																				-- reference store.
	self.m_deleteAllRequested = false 															-- used to stop delete all in update
	self.m_inUpdate = false
	Runtime:addEventListener("enterFrame",self) 												-- add the run time event listener.
end

--//%	The Executive destructor deletes all objects, checks all indices and lists are clear, and removes the enterFrame listener.

function Executive:delete()
	if self.m_inUpdate then self.m_deleteAllRequested = true return end 						-- delay delete of everything if in update.
	if self.m_objects == nil then return end 													-- exit if it has already been removed.
	for _,ref in pairs(self.m_objects.objects) do 												-- work through all objects
		ref:delete() 																			-- and delete them
	end 
	assert(self.m_objects.count == 0,"Main object list count non zero")							-- check they have actually been deleted.
	assert(self:tableSize(self.m_objects.objects) == 0,"Main object list not empty.")
	self.m_objects = nil 																		-- erase the object list.
	for name,list in pairs(self.m_indices) do 													-- work through all the indices
		assert(list.count == 0,"Index count non zero "..name) 									-- check they are empty.
		assert(self:tableSize(list.objects) == 0,"Index not empty "..name)
	end 
	self.m_indices = nil 																		-- remove that reference
	Runtime:removeEventListener("enterFrame",self) 												-- remove the event listener.
	self.m_timerEvents = nil 																	-- remove the timer event table.
	self.m_messageQueue = nil 																	-- remove the message queue
	self.m_deleteAllRequested = nil self.m_inUpdate = nil self.e = nil 							-- tidy up.
end

--//%	Utility function which returns the number of items in a table
--//	@table 	[table]				Table to count items of
--//	@return [number]			Number of items in the table.

function Executive:tableSize(table)
	local items = 0
	for _,_ in pairs(table) do items = items + 1 end 
	return items 
end

--//%	Handle enterFrame events and dispatch them via update, process messages and timers.
--//	@eventData [table]			Event data.

function Executive:enterFrame(eventData) 
	self.m_inUpdate = true 																		-- in update - this blocks delete() 
	local current = system.getTimer() 															-- get system time
	local updates = self.m_indices.update 														-- get the updateables list
	if updates.count > 0 then  																	-- are there some updates ?
		local elapsed = math.min(current - (self.m_lastFrame or 0),100) 						-- get elapsed time in ms, max 100.
		self.m_lastFrame = current 																-- update last frame time
		for _,ref in pairs(updates.objects) do 													-- then fire all the updates.
			self:fire(ref,"onUpdate",elapsed/1000,elapsed)  									-- with deltatime/deltaMS
		end 
	end 
	
	while #self.m_timerEvents > 0 and self.m_timerEvents[1].time <= current do 					-- event available and fireable ?
		local event = self.m_timerEvents[1] 													-- get the event.
		self:fire(event.target,"onTimer",event.tag,event.id) 									-- fire the timer event.
		event.count = math.max(event.count - 1,-1) 												-- reduce count, bottom out at minus 1.
		if event.count == 0 then  																-- has it finished.
			table.remove(self.m_timerEvents,1) 													-- then just throw it away.
		else
			event.time = current + event.delay 													-- update the next fire time
			table.sort(self.m_timerEvents,function(a,b) return a.time < b.time end) 			-- sort the timer event table so the earliest ones are first.
		end
	end

	--local newMsg = { to = recipient, from = sender, 											-- create a new message
	--							body = message, time = system.getTimer()+delayTime }

	if #self.m_messageQueue > 0 then 															-- is there something in the message queue ?
		local oldQueue = self.m_messageQueue 													-- make new reference to message queue
		self.m_messageQueue = {} 																-- and empty the message queue.
		for i = 1,#oldQueue do 																	-- work through the messages
			if current >= oldQueue[i].time then 												-- has its send time been reached ?
				self:process(oldQueue[i].to,"onMessage",oldQueue[i].from,oldQueue[i].body)
			else  																				-- time not reached
				self.m_messageQueue[#self.m_messageQueue+1] = oldQueue[i] 						-- so requeue it.
			end 
		end
	end 

	self.m_inUpdate = false 																	-- allow delete again.
	if self.m_deleteAllRequested then 															-- delete executive if requested during update.
		self:delete()
	end 
end 

--//	This creates a class which can be used as a prototype - it is a replacement for the new() method. It returns an instance 
--//	of the ExecutiveBaseClass to be modified, but this instance already has a reference to the executive instance so it can access it.
--//	@baseClass 	[prototype]		Base class to extend from (can be ignored, defaults to ExecutiveBaseClass)
--//	@return 	[object]		Prototype for modification to produce a class/prototype

function Executive:createClass(baseClass)
	baseClass = baseClass or ExecutiveBaseClass  												-- default base to ExecutiveBaseClass
	local newObject = baseClass:new() 															-- create a new class prototype
	newObject.m_executive = self 																-- store a reference to the executive.
	return newObject
end 

--//	Add a mixin object to the system. Some objects may be created by modifying other classes via decoration, these will not inherit
--//	either the executive member or the member functions. This method decorates the mixin with both. Do not use this with game 
--//	objects, which are added automatically by the constructor.
--//	@object 	[object] 		Mixin object to be decorated.
--//	@return 	[object] 		Object that was decorated.

function Executive:addMixinObject(object)
	object.m_executive = self  																	-- add a reference to the executive
	self:attach(object) 																		-- and add the object into the system.
	return object 																				-- chain it.
end 

--//%	Attach the given object to the executive system, decorate it if appropriate, and call the constructor.
--//	@object 	[object]		Object to attach
--//	@data 		[table]			Constructor data

function Executive:attach(object,data)
	assert(self.m_objects.objects[object] == nil,"Object attached twice") 						-- check for duplicate attachment
	self.m_objects.objects[object] = object 													-- add reference to the complete list of objects
	self.m_objects.count = self.m_objects.count + 1 											-- bump the count
	object.m_isAlive = true 																	-- mark object as alive.
	if not self:isGameObjectSubclass(object) then 												-- is this a mixin, e.g. not created by subclassing the Base class ?
		self:decorateMixinObject(object) 														-- if so, decorate it with useful methods.
	end
	if object.constructor ~= nil then 															-- is there a constructor ?
		object.constructor(object,data or {}) 													-- then call it 
	end
end

--//%	Detach the given object from the executive system, calling the destructor first.
--//	@object 	[object]		Object to detach

function Executive:detach(object) 
	assert(self.m_objects.objects[object] == object,"Not attached") 							-- check the object is actually attached.
	if object.destructor ~= nil then 															-- is there a destructor ?
		object.destructor(object) 																-- then call it
	end 
	object.m_isAlive = false 																	-- mark object as dead.
	self.m_objects.objects[object] = nil 														-- remove from the main object list
	self.m_objects.count = self.m_objects.count - 1 											-- fix up main object list count
	for name,list in pairs(self.m_indices) do 													-- look through all the indices
		if list.objects[object] ~= nil then 													-- is this object in that index ?
			list.objects[object] = nil 															-- remove it
			list.count = list.count - 1 														-- fix up the object count for that index 
		end 
	end
	
	for key,ref in pairs(self.e) do 															-- check for reference removal.
		if ref == object then self.e[key] = nil end 											-- if found a reference remove it.
	end
end 

--//%	Check to see if the object is a subclass of the Game Object class, by scanning up through its metatables
--//	@object 	[object]			Object to test
--//	@return 	[boolean]			true if object is a subclass (or is) ExecutiveBaseClass

function Executive:isGameObjectSubclass(object)
	while object ~= nil do 																		-- keep going up the metatable chain
		if object == ExecutiveBaseClass then return true end 									-- found ExecutiveBaseClass as a parent, return true.
		object = getmetatable(object) 															-- go up the chain.
	end
	return false 																				-- reached the top, so it isn't.
end 

Executive.mixinExclusion = { constructor = true, destructor = true, initialise = true } 		-- functions that aren't added into a mixin.

--//%	Decorate a mixin object (e.g. one not created from ExecutiveBaseClass) with the methods of a game object, so in practice
--//	it will behave the same way.

function Executive:decorateMixinObject(object)
	for k,v in pairs(ExecutiveBaseClass) do 													-- scan through the class
		if type(v) == "function" then 															-- only decorate functions.
			if Executive.mixinExclusion[k] == nil then 											-- if it is not in the exclusion list
				object[k] = object[k] or ExecutiveBaseClass[k]  								-- add it in if it isn't there already.
			end
		end
	end 
end 

--//%	Add the tag to the given object
--//	@object 	[object]		game object
--//	@tag 		[string] 		tag to add.

function Executive:addTag(object,tag)
	tag = tag:lower() 																			-- tag is case insensitive.
	if self.m_indices[tag] == nil then 															-- if there is no index for that tag
		self.m_indices[tag] = { objects = {}, count = 0 } 										-- then create one.
	end
	local index = self.m_indices[tag] 															-- get index for that tag.
	if index.objects[object] ~= nil then return end 											-- tag already for that object.
	index.objects[object] = object 																-- add this object to the tag index
	index.count = index.count + 1 																-- and increment the number of items in the index.
end 

--//%	Remove the tag from the given object
--//	@object 	[object]		game object
--//	@tag 		[string] 		tag to remove.

function Executive:removeTag(object,tag)
	tag = tag:lower() 																			-- tag is case insensitive.
	local index = self.m_indices[tag] 															-- get index for that tag.
	assert(index ~= nil and index.objects[object] == object,"Object does not have tag "..tag)	-- check the object has that tag.
	index.objects[object] = nil 																-- remove object from the tag index.
	index.count = index.count - 1 																-- decrement the number of items in the index.
end

--//%	Fire a method on an individual object or a query result (Object List)
--//	@object 	[object/string]	Object to call function/method on or a query.
--//	@method 	[string/func]	Name of method or function to call.
--//	@return 	true 			Methods all fired successfully.

function Executive:process(object,method,...)
	if type(object) == "table" then return self:fire(object,method,...) end  					-- if just an object, then fire it on its own.
	local ok = true 
	local queryResult = self:query(object) 														-- evaluate the query. 
	for _,ref in pairs(queryResult.objects) do 													-- work through all the results.
		ok = ok and self:fire(ref,method,...) 													-- fire a method, set ok false if fails
	end 
	return ok 																					-- return success.
end 

--//%	Fire a method (either function or name) on given object. Also passes any following parameters to the call.
--//	@object 	[object]		Object to call function/method on 
--//	@method 	[string/func]	Name of method or function to call.
--//	@return 	true 			Method fired successfully.

function Executive:fire(object,method,...)
	if not object:isAlive() then return false end  												-- return false if object dead
	if type(method) == "function" then 
		method(object,...)
	else 
		assert(object[method] ~= nil,"Object does not have method "..method)
		object[method](object,...)
	end
	return true
end 

--//	Query the object database for all objects with all the listed tags.
--//	@tagList 		[table] 		table of tags/strings which are required to be all satisfied.
--//	@return 		[objectlist]	table with 2 values, dictionary of objects => objects and count of hits.

function Executive:query(tagList)
	tagList = (tagList or ""):lower():gsub("%s","") 											-- make lower case, remove spaces.
	tagList = self:split(tagList) 																-- split around commas.
	if #tagList == 0 then  																		-- if nothing, then return the whole object list.
		return self.m_objects
	end 
	if #tagList == 1 then 																		-- if one single index value.
		local index = self.m_indices[tagList[1]] 												-- examine the index
		if index == nil then index = { objects = {}, count = 0 } end 							-- if index is empty, then there are no matches
		return index 
	end
	local result = { objects = {}, count = 0 }													-- empty result
	local tags = {}
	for i = 1,#tagList do 																		-- check there is an index for every tag
		tags[i] = self.m_indices[tagList[i]] 													-- put the index in tags[i]
		if tags[i] == nil then return result end 												-- if not, then return the empty result as there can be no matches
	end
	table.sort(tags,function(a,b) return a.count < b.count end) 								-- sort so the smallest index is first, which speeds it up.
	for _,ref in pairs(tags[1].objects) do 														-- work through all objects at the outermost level.
		local isOk = true 																		-- can it be added.
		for j = 2,#tags do 																		-- check all the inner levels.
			if tags[j].objects[ref] == nil then 												-- if object not in that tag index
				isOk = false 																	-- it is not a match
				break 																			-- break out of the for loop.
			end
		end
		if isOk then 																			-- match
			result.count = result.count + 1 													-- bump count
			result.objects[ref] = ref 															-- store object in object list 
		end 
	end
	return result 																				-- return the result set.
end 

Executive.nextFreeTimerID = 1000 																-- static member, next free timer ID.

--//%	Add a timer event.
--//	@delay 			[number]			Milliseconds to delay
--//	@repeatCount 	[number]			Number of times to fire before self cancel (-1 = indefinitely.)
--//	@tag 			[string] 			Tag value to identify event, if required.
--//	@target 		[object]			Object to send the event to.
--//	@return 		[number]			internal ID of timer, can be used for cancellation.

function Executive:addTimer(delay,repeatCount,tag,target)
	local newEvent = { time = delay + system.getTimer(), count = repeatCount, delay = delay, 	-- create a new timer record.
													tag = tag, target = target, id = Executive.nextFreeTimerID }
	self.m_timerEvents[#self.m_timerEvents+1] = newEvent 										-- add event to timer events list
	Executive.nextFreeTimerID = Executive.nextFreeTimerID + 1 									-- bump the next free timer ID
	table.sort(self.m_timerEvents,function(a,b) return a.time < b.time end) 					-- sort the timer event table so the earliest ones are first.
	return newEvent.id  																		-- return timer event ID.
end

--//	Remove a timer with the given timer ID
--//	@timerID 		[number]		ID of timer to remove 

function Executive:removeTimer(timerID)
	local n = 1 																				-- start at the beginning
	while n <= #self.m_timerEvents do 															-- while not reached the end of timer events.
		if self.m_timerEvents[n].id == timerID then 											-- found a matching event ID
			table.remove(self.m_timerEvents,n) 													-- remove it
		else 
			n = n + 1 																			-- otherwise advance to next 
		end 
	end
end

--//	Queue a message to be sent to object or objects.
--//	@recipient 	[object/string]		object or query for recipients of message
--//	@sender 	[object]			object sending the message
--//	@message 	[table]				message body.
--//	@delayTime 	[number]			time message is to be delayed in ms.

function Executive:queueMessage(recipient,sender,message,delayTime)
	local newMsg = { to = recipient, from = sender, 											-- create a new message
								body = message, time = system.getTimer()+delayTime }
	self.m_messageQueue[#self.m_messageQueue+1] = newMsg 										-- add to the message queue (actually unsorted)
end

--//	Name an object, storing a reference to it in executive.e
--//	@name 		[string]			Name to give it in the object reference store (always l/c)
--//	@object 	[object]			Object to attach to that reference.

function Executive:nameObject(name,object) 
	name = name:lower() 																		-- all names are lower case.
	assert(self.e[name] == nil,"Duplicate reference name "..name)								-- check unused.
	self.e[name] = object 																		-- store the reference
end 

--//%	String split around commas, utility function.
--//	@s 		[string]			string to split around commas
--//	@return [table]				array of strings.

function Executive:split(s)
	if s == "" then return {} end 																-- empty string.
	local result = {}																			-- put the result here.
	while s:find(",") ~= nil do 																-- while there is something to split.
		local n = s:find(",") 																	-- find split point
		result[#result+1] = s:sub(1,n-1) 														-- add before bit.
		s = s:sub(n+1) 																			-- rest of split string
	end 
	result[#result+1] = s 																		-- add last one in
	return result
end 

--- ************************************************************************************************************************************************************************
--	This is the base class of game objects that are not created via a mixin. Most of the functionality is passed on to helper functions in the Executive Class, this
--	serves as a base for game objects so they inherit the executive functionality automatically.
--- ************************************************************************************************************************************************************************

ExecutiveBaseClass = Base:new()

--//%	The actual base class constructor. This automatically connects the object to the Executive, and calls the game object constructor
--//	with the provided data table as initialisation data
--//	@data 	[table]			Data for actual constructor

function ExecutiveBaseClass:initialise(data)
	-- print("Instantiate",self,data,self.m_executive)
	if data == nil then return end 																-- if used to prototype, don't initialise the object.
	self.m_executive:attach(self,data) 															-- attach the object and call the constructor.
end 

--//	Constructor for game object. In the base object this is a dummy.
--//	@data 	[table]			Data for constructor

function ExecutiveBaseClass:constructor(data)
	-- print("Constructor",self,data,self.m_executive)
end 

--//	Destructor for game object. In the base object this is a dummy.

function ExecutiveBaseClass:destructor()
	-- print("Destructor",self,self.m_executive)
end 

--//	Delete object from game. This calls the destructor and disconnects the object from the executive 

function ExecutiveBaseClass:delete() 
	if not self.m_isAlive then return end 														-- already deleted, so do nothing.
	self.m_executive:detach(self) 																-- process the detaching.
end 

--//	Check to see if an object is still alive.
--//	@return 	[boolean]	true if object is still alive.

function ExecutiveBaseClass:isAlive() 
	return self.m_isAlive 
end 

--//	Add or remove tags from an object. The parameter is a sequence of tags, seperated by commas, that may be prefixed by '+' or '-' to
--//	add or remove a tag. The default is to add.
--//	@tagChanges 	[string] 		tags to add and remove from an object.

function ExecutiveBaseClass:tag(tagChanges)
	tagChanges = tagChanges:lower():gsub("%s","") 												-- make lower case, remove spaces.
	tagChanges = self.m_executive:split(tagChanges) 											-- split around commas.
	for _,tag in ipairs(tagChanges) do 															-- scan through them.
		if tag:sub(1,1) == "+" then tag = tag:sub(2) end 										-- remove a leading +
		if tag:sub(1,1) == "-" then 															-- if it is remove tag 
			self.m_executive:removeTag(self,tag:sub(2))
		else 																					-- otherwise add it.
			self.m_executive:addTag(self,tag)
		end 
	end
end 

--//	Query the object database for all objects with all the listed tags.
--//	@tagList 		[string] 		list of tags, seperated by commas.
--//	@return 		[objectlist]	table with 2 values, dictionary of objects => objects and count of hits.

function ExecutiveBaseClass:query(tagList) 
	return self.m_executive:query(tagList) 														-- and run the query.
end 

--//	Fire a timer a specific number of times (including until stopped.)
--//	@delay 			[number]		Timer delay in milliseconds.
--//	@repeatCount 	[number]		Number of repeats (1 +, -1 = continuous)
--//	@tag 			[string]		Identifying tag for timer (optional)
--//	@target 		[object] 		Object to receive timer (defaults to self)
--//	@return 		[number]		Timer ID

function ExecutiveBaseClass:addTimer(delay,repeatCount,tag,target)
	return self.m_executive:addTimer(delay,repeatCount,tag or "",target or self)
end 

--//	Fire a timer once only.
--//	@delay 			[number]		Timer delay in milliseconds.
--//	@tag 			[string]		Identifying tag for timer (optional)
--//	@target 		[object] 		Object to receive timer (defaults to self)
--//	@return 		[number]		Timer ID

function ExecutiveBaseClass:addSingleTimer(delay,tag,target)
	return self:addTimer(delay,1,tag,target)
end 

--//	Fire a timer continuously until stopped.
--//	@delay 			[number]		Timer delay in milliseconds.
--//	@tag 			[string]		Identifying tag for timer (optional)
--//	@target 		[object] 		Object to receive timer (defaults to self)
--//	@return 		[number]		Timer ID

function ExecutiveBaseClass:addRepeatingTimer(delay,tag,target)
	return self:addTimer(delay,-1,tag,target)
end 

--//	Remove a timer with the given timer ID
--//	@timerID 		[number]		ID of timer to remove 

function ExecutiveBaseClass:removeTimer(timerID)
	self.m_executive:removeTimer(timerID)
end 

--//	Send a message after an optional display. Note that message sending is asynchronous.
--//	@target 		[query/object]	Object or query to send the message to.
--//	@contents 		[table]			Message contents.
--//	@delay 			[number] 		Message delay time in milliseconds (defaults to immediately)

function ExecutiveBaseClass:sendMessage(target,contents,delay)
	self.m_executive:queueMessage(target,self,contents or {},delay or -1)
end 

--//	Name the current object as a reference in executive.e 
--//	@name 			[string] 		Name to call it.

function ExecutiveBaseClass:name(name)
	self.m_executive:nameObject(name,self)
end 

--//	Get the current executive reference
--//	@return 		[executive]		Executive object controlling this object

function ExecutiveBaseClass:getExecutive()
	return self.m_executive 
end

return Executive 