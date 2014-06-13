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

local Executive = require("system.executive")

local exec = Executive:new() 																	-- create executive object 
local WorkingClass = exec:createClass() 														-- create class for working with.

function WorkingClass:constructor(data)
	self.name = data.name
end 

local objectCount = 50 																			-- Number of objects.
local tagCount = 100 																			-- Number of tags
local queryMaxSize = 5 																			-- Max query size.

local objects = {} 																				-- Object references.
local tagNames = {}
local tagUsage = {} 																			-- Tag Number => [Number => boolean]
local queryParts = {} 																			-- keep a list of the tags used in a query.

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

function checkQueryResult(result,c) 
	local passCount = 0
	for objID = 1,objectCount do 																-- check result for every object.
		local matches = true  																	-- work through each part
		for i = 1,#queryParts do 
			matches = matches and tagUsage[queryParts[i]][objID] 								-- check tag present for all.
		end 
		if matches then  																		-- if matches
			assert(result.objects[objects[objID]] ~= nil) 										-- check in result
			passCount = passCount + 1 															-- bump count
		end 

	end 
	assert(passCount == result.count)															-- check result sizes match.
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

for c = 1,1000*10 do 

	if c % 1000 == 0 then print(c) end 

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

	local query = ""
	queryParts = {}
	for i = 1,math.random(1,queryMaxSize) do 													-- build up a query.
		local tag = math.random(1,tagCount)														-- this tag is part of it.
		queryParts[i] = tag 																	-- save the tag number.
		if query ~= "" then query = query .. "," end 
		query = query .. tagNames[tag]
	end 
	local qr = objects[1]:query(query) 															-- evaluate the query
	checkQueryResult(qr,c)
end

exec:delete()
print("Bully test complete.")