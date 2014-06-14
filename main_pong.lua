--- ************************************************************************************************************************************************************************
---
---				Name : 		main_pong.lua
---				Purpose :	Executive testing - demented two bat pong game.
---				Created:	7th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************

local Executive = require("system.executive")

local executive = Executive:new()
executive:addLibraryObject("utils.controller","FourWay",{})

--- ************************************************************************************************************************************************************************
--//	Score class. Done via messaging, could be done by directly accessing object equally. This is a mixin class and shows how they are created.
--- ************************************************************************************************************************************************************************

local Score = display.newText("?",display.contentWidth-20,20,native.systemFont,32)				-- Score text on screen

--//	Create a new score

function Score:constructor(data)
	self.anchorX,self.anchorY = 1,0
	self:setFillColor(1,0,1)
	self.score = 0 																				-- actual score
	self:updateScore() 																			-- update it
	self:tag("score") 																			-- tag as score object
end 

--// 	Destroy a score

function Score:destructor()
	self:removeSelf()
end 

--//	Update the score text from the score

function Score:updateScore()
	self.text = ("000000" .. self.score):sub(-6)
end 

--//	Handle a message sent to 'score', the first parameter is tha amount to add
function Score:onMessage(from,message)
	self.score = self.score + tonumber(message.points) 											-- add to score
	self:updateScore() 																			-- update display.
end 

executive:addMixinObject(Score)
																								-- finally call constructor/decorator routine.
--- ************************************************************************************************************************************************************************
--//	Bat class.
--- ************************************************************************************************************************************************************************

local Bat = executive:createClass()

--//	Create a new bat
--//	@info 	[table]			Constructor data. x (Horizontal Pos,32) and height (bat size, 1/4 of screen height)

function Bat:constructor(info)
	self.height = info.height or display.contentHeight / 4 										-- get bat height
	self.bat = display.newRect(0,0,10,self.height) 												-- create bat graphic
	self.bat:setFillColor(1,1,0)
	self.bat.x = info.x or 32 																	-- set horizontal position
	self.bat.y = display.contentHeight/2 														-- vertically centred
	self:tag("update,obstacle")	 																-- it is updated (gets a frame tick) and an obstacle.
end 

--//	Destroy bat

function Bat:destructor()
	self.bat:removeSelf()
end 

--//	Handle bat updates.
--//	@dTime 			[number] 	delta time in seconds
--//	@dmilliTime 	[number] 	delta time in milliseconds

function Bat:onUpdate(dTime,dmilliTime)
	self.bat.y = self.bat.y + 
			self:getExecutive().e.controller:getY() * dTime * display.contentHeight 			-- adjust vertical position - dTime makes it consistent speed.
																								-- note we directly access the controller object here through SOE.e
	self.bat.y = math.max(self.bat.y,self.height/2) 											-- fit into top and bottom.
	self.bat.y = math.min(self.bat.y,display.contentHeight-self.height/2)
end 

--//	Bat message handler. The bat receives a message asking it to check collision between itself and a ball. Probably not the best way of doing it, it would be
--//	better to do it synchronously by applying SOE:process() to a query result. But it is an example.

function Bat:onMessage(sender,message)
	local ball = sender 																		-- the ball sent the message
	if ball:isAlive() then 																		-- it could have died - messages are asynchronous
		if math.abs(ball.ball.x - self.bat.x) < ball.radius and  								-- if the collision occurred, flip the ball direction
								math.abs(ball.ball.y - self.bat.y) < self.height/2 then  		-- note, you couldn't do this with a message because you cannot
			ball:flip((ball.ball.y - self.bat.y)/(self.height/2)) 								-- guarantee its immediacy. 
		end
	end
end 

--]]
--- ************************************************************************************************************************************************************************
--//	Ball class
--- ************************************************************************************************************************************************************************

local Ball = executive:createClass()

--//	Create a ball

function Ball:constructor()
	self.radius = display.contentHeight / 30 													-- ball size
	self.dx = 1 																				-- start direction
	self.dy = math.random(5,10)/10
	self.ball = display.newCircle(0,0,self.radius) 												-- ball graphic
	self.ball:setFillColor(0,1,1) 	
	self.ball.x = math.random(display.contentWidth / 2,display.contentWidth - self.radius) 		-- initial position
	self.ball.y = math.random(self.radius,display.contentHeight-self.radius)
	self.speed = 500 																			-- how fast it goes.
	self:tag("ball") 																			-- tagged as ball type, but not update. This is done by a delayed send 
end 																							-- message so we get a pause at the start.

--//	Destroy a ball

function Ball:destructor()
	self.ball:removeSelf() 
end 

--//	It can receive a message, 'start'

function Ball:onMessage(sender,message)
	self:tag("update")  																		-- add the update tag which will make it move.
end 

--//	Handle ball update.

function Ball:onUpdate(dTime,dMilliTime)
	self.ball.x = self.ball.x + self.dx * self.speed * dTime 									-- using dTime here makes the speed 'pixels per second'
	self.ball.y = self.ball.y + self.dy * self.speed * dTime

	if self.ball.y < self.radius or self.ball.y > display.contentHeight - self.radius then 		-- bounce off top and bottom
		self.dy = -self.dy 
		self.ball.y = self.ball.y + self.dy
	end 
	if self.ball.x > display.contentWidth - self.radius then 									-- bounce off right
		self.dx = -1
		self:sendMessage("score",{ points = 10})
	end 
	if self.ball.x < 0 then  																	-- if off the left
		self:delete() 																			-- delete yourself (e.g. the ball)
		if self:query("ball").count == 0 then self:getExecutive():delete() end 					-- if there are no objects called 'ball' out there then game over 
	else
		self:sendMessage("obstacle") 															-- if moved okay, ask the 'obstacles' about collision.
	end
end 

--//	This is used by 'obstacles' to update ball direction

function Ball:flip(dy) 
	self.dx = -self.dx 
	self.ball.x = self.ball.x + self.dx
	self.dy = dy
end 

--- ************************************************************************************************************************************************************************
--																				Main bit
--- ************************************************************************************************************************************************************************

Bat:new({ x = 32 }) 																			-- create two bats
Bat:new({ x = display.contentWidth/3 })
for i = 1,33 do Ball:new({}) end 																-- and lots of balls.

Ball:sendMessage("ball",{},1000)																-- send message to the balls (starting them) after 1 second.


