--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Executive Object System test
---				Created:	12th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

--- ************************************************************************************************************************************************************************

--require("main_pong")
--require("bully")
require("main_flappy")
--require("main_fsm")

-- TODO Executive constructor optional parameters.
-- TODO Title page.
-- TODO Flappy FSM
-- TODO Extend FSM to manage scenes
--[[


Attach executives to FSM states.
Manager calls transition as state changes via Transition Manager.

GameState class
===============

- constructor - pre load
- preopen 	- creates executive instance (factory ?), objects, don't actually do anything.
- open 		- starts.
- close  	- stop any objects (does nothing other than transition, normally the responsibility of the executive)
- postclose - delete executive instance.
- destructor  - post load

Game object 
===========

- each state has attached global data ?
- does 

--]]
