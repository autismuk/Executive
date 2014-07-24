
-- OOP Bit

_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end,initialise = function() end }

local Controls = Base:new() 								-- create a Class or Prototype 'Controls' which inherits from 'Base'

function Controls:initialise(options) 						-- the constructor.

	self.joystickGroup = display.newGroup() 				-- this group is now a member of the object

	-- Properties
	self.name = options.name 								-- the information is stored in the controls objet
	self.maxDist = 50
	self.snapBackSpeed = 0.7


	self.joystickGroup.x = options.x 						-- position the group
	self.joystickGroup.y = options.y


	-- Create the container
    self.joystickBorder = display.newCircle(0,0,48) 		-- this is now a seperate member object
    self.joystickBorder:setFillColor  (0.6,0.6,1.0,0.18)
    self.joystickBorder:setStrokeColor(0.6,0.6,1.0,1)


    -- Create the thumb control
    self.joystickThumb = display.newCircle(0,0,30) 			-- so is this
    self.joystickThumb:setFillColor  (0.6,0.6,1.0,0.38)
    self.joystickThumb:setStrokeColor(0.6,0.6,1.0,1)

    self.thumbx0 = 0 										-- don't store values in controls unless you can help it.
    self.thumby0 = 0

    -- Event listeners
    self.joystickThumb:addEventListener("touch",self) 		-- this sends listener events to this instance, "Controls" sends it to the prototype


    -- Insert parts
   self.joystickGroup:insert(self.joystickBorder)
   self.joystickGroup:insert(self.joystickThumb)

   self.angle = 0 											-- default return value.

end


function Controls:touch(event)
 	local phase = event.phase
	local target = event.target


	local ex = event.x - self.thumbx0
	local ey = event.y - self.thumby0


	if(phase=="began") then

		display.getCurrentStage():setFocus(target,event.id)
		target.isFocus = true
		self.thumbx0 = ex - target.x
		self.thumby0 = ey - target.y
		self.isActive = true
		transition.cancel(target)


	elseif target.isFocus then
		if(phase == "moved") then
			self.distance = math.sqrt (ex*ex + ey*ey)
			if self.distance > self.maxDist then 
				self.distance = self.maxDist
			end

			self.angle = ((math.atan2( ex-0,ey-0 )*180 / math.pi) - 180 ) * -1
			self.percent = self.distance / self.maxDist
			target.x = math.cos( math.rad(self.angle-90) ) * (self.maxDist * self.percent) 
			target.y = math.sin( math.rad(self.angle-90) ) * (self.maxDist * self.percent)


		elseif(phase=="ended" or phase=="cancelled") then
			self.thumbx0 = 0
			self.thumby0 = 0
			target.isFocus = false
			display.getCurrentStage():setFocus(nil,event.id)
			self.isActive = false
			transition.to(target,{ delay = 0,time = 200,x = 0,y = 0 })
		end
	end
end

function Controls:getAngle()
	return self.angle
end

-------------------------------------------------------------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar)

_G.screenWidth = display.contentWidth - (display.screenOriginX*2)
_G.screenHeight = display.contentHeight - (display.screenOriginY*2)
_G.screenTop = 0 + display.screenOriginY
_G.screenRight = display.contentWidth - display.screenOriginX
_G.screenBottom = display.contentHeight - display.screenOriginY
_G.screenLeft = 0 + display.screenOriginX
_G.screenCenterX = display.contentWidth/2
_G.screenCenterY = display.contentHeight/2

joystickMove = Controls:new({name="movement",x=screenLeft+60, y=screenBottom-60}) 				-- create two instances, both using new.
joystickShoot = Controls:new({name="shoot",x=screenRight-60,y=screenBottom-60})

local function doStuff(event)
	if (joystickMove.isActive) then
		print("Angle",joystickMove:getAngle())
 	end
end

Runtime:addEventListener("enterFrame",doStuff)
