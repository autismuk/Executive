--- ************************************************************************************************************************************************************************
---
---				Name : 		main_flappy.lua
---				Purpose :	Executive testing - flappy errrr... sphere ?
---				Created:	14th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************

display.setStatusBar(display.HiddenStatusBar)													-- hide status bar
local Executive = require("system.executive")													-- acquire executive class
local ExecutiveFactory = require("system.game")													-- acquire Executive Factory Base Class

require("system.fontmanager") 	 																-- load my fontmananger library

--- ************************************************************************************************************************************************************************
--  An example of a class which can be reused - I have abstracted out 'start' and 'stop' messages which add/remove update. This is used in both the bird and the pipes.
--- ************************************************************************************************************************************************************************

local GameObject = Executive:createClass()

function GameObject:onMessage(sender,message)
	if message.event == "start" then 
		self:tag("update")
	end
	if message.event == "stop" then 
		self:tag("-update")
	end
end 

--- ************************************************************************************************************************************************************************
--																		Text Message Objects
--- ************************************************************************************************************************************************************************

local StartMessage = Executive:createClass() 

function StartMessage:constructor()
	self.getReadyText = display.newBitmapText("Get Ready !",									-- arguably, this should be a seperate object
				display.contentWidth/2,display.contentHeight/2,"font2",80)
	self.getReadyText:setTintColor(1,0.5,0) 	 												-- so it looks a bit different
	self:addSingleTimer(1000,"move") 															-- move it after 1000 milliseconds.
	self:insert(self.getReadyText)
end 

function StartMessage:onTimer(timerID,tag)
	transition.to(self.getReadyText, { time = 1000,y = -0,alpha = 0.5, 		 					-- transition the message away
		onComplete = function() self:delete() end})
end 

function StartMessage:destructor()
	self.getReadyText:removeSelf()
end 

local EndMessage = Executive:createClass()

local function spinner(modifier, cPos, info)
	local w = math.floor(info.elapsed/360) % info.length + 1 				
	if info.index == w then  												
		local newScale = 2 * (info.elapsed % 360) / 360 - 1 				
		modifier.xScale = newScale 					
	end
end

function EndMessage:constructor()
	self.gameOverText = display.newBitmapText("Game Over",display.contentWidth/2,display.contentHeight/2,"font2",80)
	self.gameOverText:setModifier(spinner):animate(2)
	self.gameOverText.alpha = 0
	transition.to(self.gameOverText, { time = 2000, alpha = 1})
	self:insert(self.gameOverText)
	self:addSingleTimer(6000)
end 

function EndMessage:onTimer()
	Game:event("gameover")
end 

function EndMessage:destructor()
	self.gameOverText:removeSelf()
end 

--- ************************************************************************************************************************************************************************
--																	Background - sky and ground
--- ************************************************************************************************************************************************************************

local Background = Executive:createClass()

function Background:constructor(info)
	self.groundHeight = display.contentHeight * 0.9 											-- height of ground.
	self.sky = display.newRect(0,0,570,380) 													-- create sky
	self.sky.x,self.sky.y = display.contentWidth/2,display.contentHeight/2
	self.sky:setFillColor(0,1,1)
	local h = display.contentHeight - self.groundHeight 										-- height of ground.
	self.ground = display.newRect(-50,self.groundHeight,display.contentWidth+50,h+50) 			-- create ground
	self.ground.anchorX,self.ground.anchorY = 0,0
	self.ground:setFillColor(0,1,0)
	self.line = display.newLine(-50,self.groundHeight,display.contentWidth+50,self.groundHeight)
	self.line.strokeWidth = 4 self.line:setStrokeColor(0,0,0)
	self.sky:addEventListener("tap",self) 														-- listen for taps.
	self:name("background")																		-- expose background.
	self:insert(self.sky,self.line,self.ground) 												-- add objects to display group.
	self.sky:toBack()
end


function Background:destructor()
	self.sky:removeEventListener("tap",self) 													-- remove listener
	self.ground:removeSelf() 																	-- remove ground
	self.sky:removeSelf() 																		-- remove sky
	self.line:removeSelf()
end

function Background:tap(event)
	self:sendMessage("bird",{ event = "tapped"}) 												-- tell all birds if ground tapped.
end

--- ************************************************************************************************************************************************************************
--																					Score class
--- ************************************************************************************************************************************************************************

local Score = Executive:createClass()

function Score:constructor()
	self.scoreText = display.newBitmapText("XXXX",display.contentWidth-10,10,"font2",60) 		-- create text object
	self.scoreText:setAnchor(1,0)
	self.score = 0 																				-- actual score
	self:updateScore() 																			-- update it with the score
	self:tag("score") 																			-- tag it 'score' so it can receive appropriate messages
	self:insert(self.scoreText)
end 

function Score:onMessage(sender,message)
	if message.event == "add" then  															-- add some number of points
		self.score = self.score + message.points 												-- do it !
		self:updateScore()  																	-- and update.
	end 
end 

function Score:updateScore()
	self.scoreText:setText(("0000"..self.score):sub(-4)) 										-- make text four digit leading zeros.
end 

function Score:destructor()
	self.scoreText:removeSelf()
end 

--- ************************************************************************************************************************************************************************
--																	Bird (well, sphere) class
--- ************************************************************************************************************************************************************************

local Bird = Executive:createClass(GameObject)

function Bird:constructor(info)
	self.radius = display.contentHeight / 16 													-- radius of the flappy sphere
	self.bird = display.newCircle(info.x or display.contentWidth / 8, 							-- flappy sphere display object
				display.contentHeight / 3,
				self.radius)
	self.bird:setFillColor(1,0,0)
	self.bird.strokeWidth = 4
	self.bird:setStrokeColor(0,0,0)
	self.y = 1024 / 3  																			-- logical vertical positions.
	self.vy = 0 																				-- logical vertical velocity.
	self.gravity = info.gravity or 100 															-- gravity effect
	self:tag("bird") 																			-- receives controller messages
	self:tag("gameobject") 																		-- general game object stuff.
	self:insert(self.bird)
end

function Bird:destructor()
	self.bird:removeSelf()
end 

function Bird:onUpdate(deltaTime,deltaMillis,currentTime)
	local t = math.abs(10-math.floor(currentTime/30) % 20) 										-- cause the sphere to contract, it's flappy sphere
	self.bird.yScale = t / 20 + 0.5
	self.vy = self.vy + self.gravity * deltaTime 												-- add gravity
	self.y = self.y + self.vy * deltaTime 														-- add velocity to position (position is logical 0-1023)
	self.bird.y = self.y * display.contentHeight / 1024 										-- position bird at new position.
	if self.bird.y < 0 or self.bird.y > self:getExecutive().e.background.groundHeight then  	-- off the top or bottom - note use of e to get background height
		self:flapOver() 																		-- kill that bird.
	else 
		local obstacleList = self:query("obstacle") 											-- otherwise, get a list of obstacles.
		for _,ref in pairs(obstacleList.objects) do 											-- ask every obstacle if we have collided with it.
			if ref:isAlive() and ref:hasCollided(self.bird.x,self.bird.y,self.radius) then  	-- checking it is alive first
				self:flapOver() 																-- if have collided, then flap is over.
				break
			end
		end
	end
end 

function Bird:onMessage(sender,message)
	GameObject.onMessage(self,sender,message) 													-- we override onMessage, which means calling the parent.
	if message.event == "tapped" then  															-- if received a tap message
		self.vy = self.vy - self.gravity 														-- adjust velocity accordingly.
	end
end

function Bird:flapOver() 
	if not self:isAlive() then return end
	self:getExecutive():addLibraryObject("utils.particle",										-- from the utils.particle library
										 "ShortEmitter", 										-- short emitter
										 { emitter = "bomb",time = 1000, 						-- these constructor parameters
										 		x = self.bird.x,y = self.bird.y })

	self:delete() 																				-- kill the bird.															
	if self:query("bird").count == 0 then 														-- all birds dead ?
		self:sendMessage("gameobject", {event = "stop"}) 										-- stop all game objects.
		EndMessage:new(self:getExecutive(),{})
		--self:getExecutive():delete()
	end
end 

--- ************************************************************************************************************************************************************************
--																					Pipe Class
--- ************************************************************************************************************************************************************************

local Pipe = Executive:createClass(GameObject) 													-- note, we are using GameObject as a base class.

Pipe.gameWidth = display.contentWidth + 100 													-- the horizontal scrolling game space size.
																								-- static values can be stored in the object, rather than using 'e'.
function Pipe:constructor(info)
	local w = display.contentWidth / 12
	self.scrollCount = 0 																		-- number of times scrolled off.
	self.pipeLower = self:createPipe(display.contentHeight,w) 									-- create lower pipe.
	self.pipeUpper = self:createPipe(display.contentHeight,w) 									-- create upper pipe.
	self.pipeUpperTop = self:createPipe(display.contentHeight/14, w * 1.2) 						-- and tops
	self.pipeLowerTop = self:createPipe(display.contentHeight/14, w * 1.2)
	self.pipeUpper.anchorY = 1 self.pipeUpperTop.anchorY = 1 									-- top anchor point is at their bottom
	self:reposition(info.x,info.gap)															-- reposition pipe horizontally.
	self.xv = display.contentWidth / info.speed 												-- calculate pixels per second move.
	self:tag("gameobject,obstacle")
	self:insert(self.pipeLower,self.pipeUpper,self.pipeUpperTop,self.pipeLowerTop)
end 

function Pipe:destructor()
	self.pipeLower:removeSelf() 																-- remove display objects
	self.pipeUpper:removeSelf()
	self.pipeUpperTop:removeSelf()
	self.pipeLowerTop:removeSelf()
end 

function Pipe:createPipe(height,width)
	local obj = display.newRect(0,0,width,height) 												-- create a pipe graphic bit
	obj.anchorX,obj.anchorY = 0.5,0 
	obj:setFillColor(0,0.5,0) obj.strokeWidth = 4 obj:setStrokeColor(0,0,0)
	return obj
end

function Pipe:updatePosition()
	self.pipeLower.x,self.pipeLower.y = self.x, self.y + self.gap / 2  							-- update pipe position from x,y and gap.
	self.pipeLowerTop.x,self.pipeLowerTop.y = self.x, self.y + self.gap / 2 
	self.pipeUpper.x,self.pipeUpper.y = self.x, self.y - self.gap / 2 
	self.pipeUpperTop.x,self.pipeUpperTop.y = self.x, self.y - self.gap / 2 
end

function Pipe:reposition(newX, gapSize)
	self.x = newX  	 																			-- save X and gap size.
	self.gap = gapSize
	local border = display.contentHeight / 8 													-- border for pipes - minimax value.
	self.y = border + math.random(0,display.contentHeight-border * 2 - gapSize)+gapSize/2
	self:updatePosition() 																		-- update the pipe positions
end 

function Pipe:onUpdate(deltaTime,deltaMillis)
	self.x = self.x - deltaTime * self.xv  														-- move pipe to the left
	if self.x < -50 then  																		-- if off left then move to the right.
		self.scrollCount = self.scrollCount + 1 												-- add scrolling count
		local newGap = math.max(self.gap - 4,70)
		self:sendMessage("score",{ event = "add",points = 1 }) 									-- score one point
		self:reposition(self.x + Pipe.gameWidth, newGap) 										-- and reposition
	end
	self:updatePosition() 																		-- update the pipe position.
end 

function Pipe:hasCollided(x,y,r)
	local dx = math.abs(x - self.x) 															-- pipe distance, horizontal
	if dx > r + self.pipeLower.width / 2 then return false end  								-- out of range , return false 
	local dy = math.abs(self.y - y)
	return dy+r/2 >= self.gap/2
end 

--- ************************************************************************************************************************************************************************
--																	Title Screen class and factory class
--- ************************************************************************************************************************************************************************

local TitleScreen = Executive:createClass()

function TitleScreen:constructor()
	self.title = display.newBitmapText("Flappy Sphere",display.contentWidth/2,display.contentHeight/2,"font2",72)
	self.title.yScale = 3
	self.descr = display.newText("A 'Corona Executive' Demo",display.contentWidth / 2,display.contentHeight - 40,system.nativeFont,32)
	self:insert(self.title,self.descr)
end 

function TitleScreen:destructor()
	self.title:removeEventListener( "tap",self)
	self.title:removeSelf()
	self.descr:removeSelf()
end 

function TitleScreen:start()
	self.title:addEventListener( "tap",self)
end 

function TitleScreen:tap(e)
	Game:event("play")
end 

local TitleScreenFactory = ExecutiveFactory:new()

function TitleScreenFactory:preOpen()
	self.title = TitleScreen:new(self:getExecutive())
end 

function TitleScreenFactory:open()
	self.title:start()
end 

--- ************************************************************************************************************************************************************************
-- 																			Flappy Bird Factory Class
--- ************************************************************************************************************************************************************************

local GameFactory = ExecutiveFactory:new()

function GameFactory:preOpen()																	-- before opening, create all the game objects
	local exec = self:getExecutive()
	self.workObject = StartMessage:new(exec)  
	local pipes = 3
	for i = 1,pipes do 
		Pipe:new({ executive = exec,gap = 150, x = ((i-1)/pipes+1)*(Pipe.gameWidth), speed = 12 })
	end
	Background:new({ executive = exec })
	Bird:new(exec,{ gravity = 100*1 })
	Score:new(exec,{})
end 

function GameFactory:open()
	self.workObject:sendMessage("gameobject",{ event = "start"} ,1000) 							-- when transition complete, start.
end


--local fd = GameFactory:new()
--local fd = TitleScreenFactory:new()
-- fd:preOpen() fd:open()
--fd:close() fd:postClose()

--- ************************************************************************************************************************************************************************
--																		Set up main game FSM and start
--- ************************************************************************************************************************************************************************

Game:addState("start",TitleScreenFactory:new(), { play = { target = "game" } })
Game:addState("game",GameFactory:new(), { gameover = { target = "start" } })
Game:start()
