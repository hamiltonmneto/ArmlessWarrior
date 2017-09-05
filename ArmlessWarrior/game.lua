
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
-- Include physics module
local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )
physics.setDrawMode( "normal" )

-- Configure image sheet
local sheetOptions =
{
	frames = {

			{
					--01 AW_atkLeft2
					x=1,
					y=1,
					width=135,
					height=102,

			},
			{
					--02 AW_atkRight2
					x=1,
					y=105,
					width=135,
					height=102,

			},
			{
					--03 AW_dmgLeft
					x=1,
					y=841,
					width=68,
					height=171,

			},
			{
					--04 AW_dmgRight
					x=71,
					y=841,
					width=68,
					height=171,

			},
			{
					--05 AW_jumpingLeftt1
					x=141,
					y=769,
					width=104,
					height=96,

			},
			{
					--06 AW_jumpingLeftt2
					x=138,
					y=1,
					width=113,
					height=157,

			},
			{
					--07 AW_jumpingRight1
					x=141,
					y=867,
					width=104,
					height=96,

			},
			{
					--08 AW_jumpingRight2
					x=138,
					y=160,
					width=113,
					height=157,

			},
			{
					--09 AW_RunningLeft1
					x=122,
					y=663,
					width=119,
					height=104,

			},
			{
					--10 AW_RunningLeft2
					x=124,
					y=548,
					width=119,
					height=113,

			},
			{
					--11 AW_RunningLeft3
					x=1,
					y=438,
					width=121,
					height=89,

			},
			{
					--12 AW_RunningLeft4
					x=1,
					y=209,
					width=122,
					height=109,

			},
			{
					--13 AW_RunningRight1
					x=1,
					y=735,
					width=119,
					height=104,

			},
			{
					--14 AW_RunningRight2
					x=1,
					y=620,
					width=119,
					height=113,

			},
			{
					--15 AW_RunningRight3
					x=1,
					y=529,
					width=121,
					height=89,

			},
			{
					--16 AW_RunningRight4
					x=125,
					y=319,
					width=122,
					height=109,

			},
			{
					--17 AW_staticLeft
					x=1,
					y=320,
					width=121,
					height=116,

			},
			{
					--18 AW_staticRight
					x=124,
					y=430,
					width=121,
					height=116,

			},
	},
}

local objectSheet = graphics.newImageSheet( "assets/img/aw3spriteSheet.png", sheetOptions )

-- Initialize variables
local lives = 3
local score = 0
local died = false

local foesTable = {}

local hero
local gameLoopTimer
local livesText
local scoreText
local xScale = 0.3
local yScale = 0.3
local musicTrack

local backGroup
local mainGroup
local uiGroup

local function updateText()
	livesText.text = "Lives: " .. lives
	scoreText.text = "Score: " .. score
end

local function createFoe()

	newFoe = display.newImageRect( mainGroup, objectSheet, 17, 121, 116)
	table.insert( foesTable, newFoe )
	newFoe.x = display.contentCenterX
	newFoe.y = display.contentHeight - 160
	-- newfoe.xScale = xScale
	-- newFoe.yScale = yScale
	physics.addBody( newFoe, "dynamic", { radius=40, bounce=0.8 } )
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

local function dragHero( event )

	local ship = event.target
	local phase = event.phase

	if ( "began" == phase ) then
		-- Set touch focus on the ship
		display.currentStage:setFocus( hero )
		-- Store initial offset position
		hero.touchOffsetX = event.x - hero.x

	elseif ( "moved" == phase ) then
		-- Move the ship to the new touch position
		hero.x = event.x - hero.touchOffsetX

	elseif ( "ended" == phase or "cancelled" == phase ) then
		-- Release touch focus on the ship
		display.currentStage:setFocus( nil )
	end

	return true  -- Prevents touch propagation to underlying objects
end

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

	-- Fade in the ship
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
	local background = display.newImageRect( backGroup, "assets/img/bg1.png", 1376, 800)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	hero = display.newImageRect( mainGroup, objectSheet, 18, 121, 116)
	hero.x = display.contentCenterX
	hero.y = display.contentHeight - 160
	physics.addBody( hero, { radius=30, isSensor=true } )
	hero.myName = "hero"

	-- Display lives and score
	livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36 )
	livesText:setFillColor(0, 0, 0)
	scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36 )
	scoreText:setFillColor(0, 0, 0)

hero:addEventListener( "touch", dragHero )

musicTrack = audio.loadStream( "assets/audio/AW_02_Level_1.mp3")
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		physics.start()
		Runtime:addEventListener( "collision", onCollision )
		gameLoopTimer = timer.performWithDelay( 2000, gameLoop, 0 )

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
