
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
-- Include physics module
local physics = require("physics")
physics.start()
physics.setGravity( 0, 9.8 )
physics.setDrawMode( "normal" )

local sheetData = require("spritesheet.aw3spriteSheet")
local heroSheet = graphics.newImageSheet( "assets/img/aw3spriteSheet.png", sheetData.getSheet() )

-- Initialize variables
local lives = 3
local score = 0
local died = false

local foesTable = {}
local alpha = 0.5
local cw
local ch
local ground
local hero
local gameLoopTimer
local livesText
local scoreText
local xScale = 0.3
local yScale = 0.3
local musicTrack
local hitFoeSound
local takeDamageSound
local jumpSound

local backGroup
local mainGroup
local uiGroup

-- Animation Sequence data
local sequenceData = {
	{ name = "left-iddle", frames = {17} },
	{ name = "right-iddle", frames = {18} },
	{ name = "right-walk", start = 13, count = 4, time = 300, loopCount = 0 },
	{ name = "left-walk", start = 9, count = 4, time = 300, loopCount = 0 },
	{ name = "left-attack", frames = {5, 1, 17}, time = 400, loopCount = 1 },
	{ name = "right-attack", frames = {7, 2, 18}, time = 400, loopCount = 1 },
	{ name = "left-jump", start = 5, count = 2, time = 2000, loopCount = 0 },
	{ name = "right-jump", start = 7, count = 2, time = 2000, loopCount = 0 },
	{ name = "HeroTakingDamage", frames = {3, 4} }
	}


-- Function to update Lives and Score
local function updateText()
	livesText.text = "Lives: " .. lives
	scoreText.text = "Score: " .. score
end

-- Function to create a foe
local function createFoe()

	newFoe = display.newImageRect( mainGroup, heroSheet, 17, 121, 116)
	table.insert( foesTable, newFoe )
	newFoe.x = display.contentCenterX
	newFoe.y = display.contentHeight - 160
	-- newfoe.xScale = xScale
	-- newFoe.yScale = yScale
	physics.addBody( newFoe, "dynamic", { density=1.0, bounce=0.0 }, -- Main body element
	{ box={ halfWidth=30, halfHeight=10, x=0, y=60 }, isSensor=true }) -- Foot sensor element

	newFoe.isFixedRotation = true
	newFoe.sensorOverlaps = 0
	newFoe.myName = "foe"

	local whereFrom = math.random( 2 )

		if ( whereFrom == 1 ) then
			-- From the left
			newFoe.x = -60
			newFoe:setLinearVelocity( math.random( 5,100 ), 0)
		elseif ( whereFrom == 2 ) then
			-- From the right
			newFoe.x = display.contentWidth + 60
			newFoe:setLinearVelocity( math.random( -100,-5 ), 0)
		end

end

local function atk()
  -- audio.play( punchTrack )
  if (  ( hero.sequence == "right-iddle") or
    hero.sequence == "right-walk" or hero.sequence == "right-attack" ) then
    hero:setSequence( "right-attack" )  -- switch to "attackRight" sequence
    hero:play()  -- play the new sequence
  else
    hero:setSequence( "left-attack" )  -- switch to "attackLeft" sequence
    hero:play()  -- play the new sequence
  end
end

local function moveRight( event )
  if ( "began" == event.phase ) then
    -- audio.play( moveTrack )
    hero:setSequence( "right-walk" )
		hero:play()
    -- start moving hero
    hero:applyLinearImpulse( 80, 0, hero.x, hero.y )
  elseif ( "ended" == event.phase ) then
    hero:setSequence( "right-iddle" )
    hero:setFrame(18)
    -- stop moving hero
    hero:setLinearVelocity( 0,0 )
  end
end

local function moveLeft( event )
  if ( "began" == event.phase ) then
    -- audio.play( moveTrack )
    hero:setSequence( "left-walk" )
    hero:play()
    hero:applyLinearImpulse( -80, 0, hero.x, hero.y )
  elseif ( "ended" == event.phase ) then
    hero:setSequence( "left-iddle" )
    hero:setFrame(9)
    hero:setLinearVelocity( 0,0 )
  end
end

local function Jump( event )

	if ( event.phase == "began" and hero.sensorOverlaps > 0 ) then
		-- Jump procedure here
		local vx, vy = hero:getLinearVelocity()
		hero:setLinearVelocity( vx, 0 )
		hero:applyLinearImpulse( nil, -75, hero.x, hero.y )
	end
end

-- local function dragHero( event )
--
-- 	local ship = event.target
-- 	local phase = event.phase
--
-- 	if ( "began" == phase ) then
-- 		-- Set touch focus on the ship
-- 		display.currentStage:setFocus( hero )
-- 		-- Store initial offset position
-- 		hero.touchOffsetX = event.x - hero.x
--
-- 	elseif ( "moved" == phase ) then
-- 		-- Move the ship to the new touch position
-- 		hero.x = event.x - hero.touchOffsetX
--
-- 	elseif ( "ended" == phase or "cancelled" == phase ) then
-- 		-- Release touch focus on the ship
-- 		display.currentStage:setFocus( nil )
-- 	end
--
-- 	return true  -- Prevents touch propagation to underlying objects
-- end

local function gameLoop()
	-- Create new foe
	createFoe()

	-- Remove Foes which have drifted off screen
	for i = #foesTable, 1, -1 do
		local thisFoe = foesTable[i]

		if ( thisFoe.x < -100 or
			 thisFoe.x > display.contentWidth + 100 or
			 thisFoe.y < -100 or
			 thisFoe.y > display.contentHeight + 100 )
		then
			display.remove( thisFoe )
			table.remove( foesTable, i )
		end
	end
end

local function restoreHero()

	hero.isBodyActive = false
	hero.x = display.contentCenterX
	hero.y = display.contentHeight - 160

	-- Fade in the hero
	transition.to( hero, { alpha=1, time=4000,
		onComplete = function()
			hero.isBodyActive = true
			died = false
		end
	} )
end

local function endGame()

	composer.setVariable( "finalScore", score )
	composer.gotoScene( "highscores", { time=800, effect="crossFade" } )

end

local function onCollision( event )

	if ( event.phase == "began" ) then

		local obj1 = event.object1
		local obj2 = event.object2

		if ( ( obj1.myName == "atk" and obj2.myName == "foe" ) or
			 ( obj1.myName == "foe" and obj2.myName == "atk" ) )
		then
			-- Remove both the hero and foe
			display.remove( obj1 )
			display.remove( obj2 )

			for i = #foesTable, 1, -1 do
				if ( foesTable[i] == obj1 or foesTable[i] == obj2 ) then
					table.remove( foesTable, i )
					break
				end
			end

			-- Increase score
			score = score + 100
			scoreText.text = "Score: " .. score

		elseif ( ( obj1.myName == "hero" and obj2.myName == "foe" ) or
				 ( obj1.myName == "foe" and obj2.myName == "hero" ) )
		then
			if ( died == false ) then
				died = true

				-- Update lives
				lives = lives - 1
				livesText.text = "Lives: " .. lives

				if ( lives == 0 ) then
					display.remove( hero )
					timer.performWithDelay( 2000, endGame )
				else
					hero.alpha = 0
					timer.performWithDelay( 1000, restoreHero )
				end
			end
		end
	end
end

-- Colision handler - Hero and ground
local function sensorCollide( self, event )
	-- Confirm that the colliding elements are the foot sensor and a ground object
	if ( event.selfElement == 2 and event.other.objType == "ground" ) then
		-- Foot sensor has entered (overlapped) a ground object
		if ( event.phase == "began" ) then
			self.sensorOverlaps = self.sensorOverlaps + 1
			-- Foot sensor has exited a ground object
		elseif ( event.phase == "ended" ) then
			self.sensorOverlaps = self.sensorOverlaps - 1
		end
	end
end



-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	physics.pause() -- Temporarily pause the physics engine

	-- Set up display groups
	backGroup = display.newGroup() -- Display group for the background image
	sceneGroup:insert( backGroup ) -- Insert into the scene's view group

	mainGroup = display.newGroup() -- Display group for the hero, foes, atks, etc.
	sceneGroup:insert( mainGroup ) -- Insert into the scene's view group

	uiGroup = display.newGroup()   -- Display group for UI objects like the score
	sceneGroup:insert( uiGroup )   -- Insert into the scene's view group

	-- Load the background
	local background = display.newImageRect( backGroup, "assets/img/bg1.png", display.contentWidth, display.contentHeight)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	-- Create ground object
	cw, ch = display.actualContentWidth, display.actualContentHeight
	ground = display.newRect( mainGroup, display.contentCenterX, ch-64, cw, 64 )
	ground.alpha = 0.0001
	ground.objType = "ground"
	physics.addBody( ground, "static", { bounce=0.0, friction=0.3 } )

	-- Load hero
	hero = display.newSprite( mainGroup, heroSheet, sequenceData)
	hero.x = display.contentCenterX
	hero.y = display.contentHeight - 160
	physics.addBody( hero, "dynamic", { density=1.0, bounce=0.0 }, -- Main body element
	{ box={ halfWidth=30, halfHeight=10, x=0, y=60 }, isSensor=true }) -- Foot sensor element
	hero.sequenceData = "right-iddle"
	hero.isFixedRotation = true
	hero.sensorOverlaps = 0
	hero.myName = "hero"


	-- Associate collision handler function with hero
	hero.collision = sensorCollide
	hero:addEventListener( "collision" )


	-- Display lives and score
	livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36 )
	livesText:setFillColor(0, 0, 0)
	scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36 )
	scoreText:setFillColor(0, 0, 0)


musicTrack = audio.loadStream( "assets/audio/AW_02_Level_1.mp3")
hitFoeSound = audio.loadSound( "assets/audio/AW_02_Level_1.mp3" )
takeDamageSound = audio.loadSound( "assets/audio/AW_02_Level_1.mp3" )
jumpSound = audio.loadSound
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		system.activate( "multitouch" )
		physics.start()
		Runtime:addEventListener( "collision", onCollision )
		gameLoopTimer = timer.performWithDelay( 1300, gameLoop, 0 )
		--Runtime:addEventListener( "touch", touchAction )
		--hero:addEventListener( "touch", dragHero )

		-- Initialize widget
		widget = require("widget")

		-- Load gamepad start
		atk_button = widget.newButton( {
			-- The id can be used to tell you what button was pressed in your button event
			id = "atk_button",
			-- Size of the button
			width = 80,
			height = 80,
			-- This is the default button image
			defaultFile = "assets/img/atk_button.png",
			-- This is the pressed button image
			overFile = "assets/img/atk_button_on_press.png",
			-- Position of the button
			left = display.contentCenterX + 350,
			top = display.contentCenterY + 250,
			-- This tells it what function to call when you press the button
			onPress = atk
		} )

		jumpButton = widget.newButton( {
			id = "jumpButton",
			width = 50,
			height = 50,
			-- defaultFile = "assets/img/jump-button.png",
			-- overFile = "assets/img/jump-button-pressed.png",
			left = display.contentCenterX + 300,
			top = display.contentCenterY + 200,
			onPress = jump
		} )

		right_button = widget.newButton( {
			id = "right_button",
			width = 80,
			height = 80,
			defaultFile = "assets/img/right_button.png",
			overFile = "assets/img/right_button_on_press.png",
			left = 120,
			top = display.contentCenterY + 250,
			onEvent = moveRight
		} )

		left_button = widget.newButton( {
			id = "left_button",
			width = 80,
			height = 80,
			defaultFile = "assets/img/left_button.png",
			overFile = "assets/img/left_button_on_press.png",
			left = 10,
			top = display.contentCenterY + 250,
			onEvent = moveLeft
		} )

		atk_button.alpha = alpha;
		-- jumpButton.alpha = alpha;
		right_button.alpha = alpha;
		left_button.alpha = alpha;

		uiGroup:insert( atk_button )
		uiGroup:insert( jumpButton )
		uiGroup:insert( right_button )
		uiGroup:insert( left_button )
		-- Load gamepad end



		-- Start the music!
		audio.play( musicTrack, { channel=1, loops=-1 } )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		timer.cancel( gameLoopTimer )
	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		Runtime:removeEventListener( "collision", onCollision )
		physics.pause()
		audio.stop( )
		composer.removeScene( "game" )
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
