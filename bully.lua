--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		bully.lua
---				Purpose :	Executive Object System Core - bullying test.
---				Created:	12th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local exec = Executive:new() 																	-- create executive object 
local WorkingClass = exec:createClass() 														-- create class for working with.

function WorkingClass:constructor(data)
	self.name = data.name
end 

local objectCount = 50 																			-- Number of objects.
local tagCount = 100 																			-- Number of tags

local objects = {} 																				-- Object references.
local tagNames = {}
local tagUsage = {} 																			-- Tag Number => [Number => boolean]

function checkTagCorrect(objectID)
	for tagID = 1,tagCount do 																	-- for each tag.
		local isUsed = false 
		local index = exec.m_indices[tagNames[tagID]]
		if index ~= nil then
			isUsed = index.objects[objects[objectID]] ~= nil
		end 
		assert(isUsed == tagUsage[tagID][objectID])
	end 
end

math.randomseed(57) 																			-- preseed randomiser.

for i = 1,objectCount do  																		-- create untagged objects.
	objects[i] = WorkingClass:new({ name = "name"..i })
end
for i = 1,tagCount do 																			-- create tag names
	tagNames[i] = "tag"..i 
	tagUsage[i] = {} 																			-- and which objects use them. 
	for j = 1,objectCount do tagUsage[i][j] = false end 
end 

for i = 1,10*100 do 

	if i % 1000 == 0 then print(i) end 

	local objID = math.random(1,objectCount) 													-- change this object
	local tagID = math.random(1,tagCount)  														-- and this tag. 

	if tagUsage[tagID][objID] then 																-- is it already using it ?
		tagUsage[tagID][objID] = false 															-- then stop using it.
		objects[objID]:tag("-"..tagNames[tagID])
	else 
		tagUsage[tagID][objID] = true 															-- otherwise start using it.
		objects[objID]:tag("+"..tagNames[tagID])
	end

	for i = 1,objectCount do 																	-- for all objects
		checkTagCorrect(i) 																		-- check the tags are correct.
	end
end

exec:delete()
print("Bully test complete.")