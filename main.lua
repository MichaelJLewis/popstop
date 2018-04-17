local version = 1.3

-- Hide status bar
display.setStatusBar(display.HiddenStatusBar)

-- Screen Coordinates

centerX = display.contentCenterX
centerY = display.contentCenterY

screenLeft = display.screenOriginX
screenWidth = display.contentWidth - screenLeft * 2
screenRight = screenLeft + screenWidth
screenTop = display.screenOriginY
screenHeight = display.contentHeight - screenTop * 2
screenBottom = screenTop + screenHeight

display.contentWidth = screenWidth
display.contentHeight = screenHeight

local physics = require("physics")
physics.setDrawMode("normal")
local json = require("json")
math.randomseed( os.time( ) )
math.random( )
math.random( )
Random = math.random

--Forward References
local gameTimer
local leftWall
local rightWall
local ceiling
local balloonGrp
local nukeGrp
local coinGrp
local balloonPop
local nukeSound
local balloonsLost = 0
local score = 0
local scoreTxt
local LostObj_0
local LostObj_1
local LostObj_2
local LostObj_3
local LostObj_4
local c1
local c2

local title 
local b1
local b2
local b3 

local start
local startBtn
local instructionBtn
local instructionPage
local startScreen
local removeBalloons
local makeBalloon
local store
local x2 = false
local x3 = false
local coinCount = 0
local contents = 0
local highscore = 0
local highscoreTxt
local saveTable = {}

local balloonTable = {}
	balloonTable.normal = {"b1","b2","b3"}

	balloonTable.special = {"sb1","sb2","sb3","sb4","sb5","sb6"}
	balloonTable.specialName = {"nuke","myst","x2","stone","live","white"}
	balloonTable.specialScore = {300, 100, 20, 40, 25, 50}

	balloonTable.pack = {}

		balloonTable.pack.goldenPackName = {"money","x3","gNuke"}
		balloonTable.pack.goldenPackScore = {100, 300, 500}

		balloonTable.pack.defensePackName = {"spike", "armor", "metal"}
		balloonTable.pack.defensePackScore = {75, 150, 100}
----------------------------

physics.start()
physics.setGravity(0, -4)


--Randomizing and Scrolling the clouds in the background
local function scroll(self,event)
    if self.x > screenLeft-self.width/2 then
        self.x = self.x - self.speed
    else
    	
        self.x = screenRight+self.width/2
        self.y = math.random(screenTop+50, screenBottom-100)
    end

end

-- The name of the ad provider. AD stuff
local provider = "admob"

-- Your application ID
local appID = "ca-app-pub-6547176312514219/2472580682"

-- Load Corona 'ads' library
local ads = require "ads"

local showAd

-- Set up ad listener.
local function adListener( event )
	-- event table includes:
	-- 		event.provider
	--		event.isError (e.g. true/false )
	local msg = event.response
	-- just a quick debug message to check what response we got from the library
	print("Message received from the ads library: ", msg)
	if event.isError then
		print("error loading ad")
	else
		------------------start()
	end
end

-- Initialize the 'ads' library with the provider you wish to use.
if appID then
	ads.init( provider, appID, adListener )
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

-- initial variables
local sysModel = system.getInfo("model")
local sysEnv = system.getInfo("environment")

-- Shows a specific type of ad
showAd = function( adType )

	if saveTable.ad == 0 then
		ads.show( adType, { appID = "ca-app-pub-6547176312514219/2472580682"} )
		saveTable.ad = 1
	else
		saveTable.ad = saveTable.ad - 1
	end
end

-- if on simulator, let user know they must build for device

--Drifting text on tap of balloon

local isDrifting = 0
 
local function makeDriftingText(txt, opts)
	if x2 == true then
		txt = txt*2
	elseif x3 == true then
		txt = txt*3
	end

    local opts = opts or {}
    local dTime = opts.t or 1000 -- drift time
    local del = opts.del or 0 -- delay time
    local yVal = opts.yVal or -40 -- how far to drift
    local x = opts.x or display.contentCenterX -- initial X location of text
    local y = opts.y or display.contentCenterY -- initial Y location of text
    local fontFace = opts.font or "ROCKEB.TTF" -- font to use
    local fontSize = opts.size or 40 -- font size
 
    local dTxt = display.newText( "+"..txt, 0, 0, fontFace, fontSize )
          	dTxt.x = x
          	dTxt.y = y
          if opts.grp then 
   	      	opts.grp:insert(dTxt)
          end
    local function killDTxt(obj)
          display.remove( obj )
          obj = nil
          isDrifting = isDrifting - 1
    end
    transition.to( dTxt,  { delay=del, time=dTime, y=y+yVal, alpha=0, onComplete=killDTxt } )
    isDrifting = isDrifting + 1
end

---------------

--Mystery Balloon Randomization--

local function mystWheel(obj)
	local rand = Random(1,2)
	if rand == 1 then
		physics.pause( )
		timer.performWithDelay( 2000, function()
			physics.start( )
			end)
	elseif rand == 2 then
		rand = Random(1,2)
		for i = 1,rand do
			local balloon = display.newImageRect( "graphics/packs/NormalPack/b"..Random(1,3)..".png", 87, 125 )
			balloon.x = obj.x+Random(10,30)
			balloon.y = obj.y-Random(10,30)
			balloon.xScale = .7
			balloon.yScale = .7
			balloon.name = "normal"
			balloon.score = 50

			physics.addBody(balloon, "dynamic", {density=0.1, friction=0.0, bounce=0.5, radius = 35});

		function balloon:touch(event)
			if event.phase == "began" then
			audio.play(balloonPop)
			if x2 == true then
				score = score + (self.score*2)
			elseif x3 == true then
				score = score + (self.score*3)
			else
				score = score + self.score
			end
			scoreTxt.text = score
			removeBalloons(self)
		end
		end
		balloon:addEventListener("touch", balloon)
		balloonGrp:insert(balloon)
		end
	end
end

---------------------------------

--Add Life if life balloon is tapped--

local function addLive(armor)
	if armor and ballonsLost == -1 then
		balloonsLost = balloonsLost - 1
		LostObj_4.alpha = 1
	elseif armor and balloonsLost == 0 then
		balloonsLost = balloonsLost - 1
		LostObj_3.alpha = 1
	elseif balloonsLost == 1 then
		balloonsLost = balloonsLost - 1
		LostObj_0.alpha = 1
	elseif balloonsLost == 2 then
		balloonsLost = balloonsLost -1
		LostObj_1.alpha = 1
	end
end	

--Timer for the 2x and 3x balloons--

local function x2Timer()
	if x2 == true then
		x3 = false
		timer.performWithDelay( 10000, function()
			x2 = false
		end)
	else
		x2=false
		timer.performWithDelay( 10000, function()
		x3 = false
		end)
	end
end

--Removes All Balloons on screen--

local function removeAllBalloons()
	timer.cancel(gameTimer)
	while( balloonGrp.numChildren > 0 ) do 
        display.remove( balloonGrp[1] )
    end
end

-----------------------------------------

--Loading the saved file in the documents directory--

local function load()
	local path = system.pathForFile( "highscore.txt", system.DocumentsDirectory )
	local contents = ""
    local file = io.open( path, "r" )
 	local contents = file:read( "*a" )
 	saveTable = json.decode( contents )
    io.close( file )

    if saveTable == nil then
	    	saveTable = {
	    	score = 0,
		coin = 0,
		politicalPack = false,
		goldenPack = false,
		defensePack = false,
		version = version,
		ad = 10}
	elseif saveTable.version == nil or saveTable.version < version then
		saveTable = {
	    	score = saveTable.score,
		coin = saveTable.coin,
		politicalPack = saveTable.politicalPack,
		goldenPack = saveTable.goldenPack,
		defensePack = false,
		version = version,
		ad=5}
    end
end

-------------------------------------

--Saving the file in the documents directory

local function save(a)
	local path = system.pathForFile( "highscore.txt", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	local nB = false
	if saveTable.score < score then
		saveTable.score = score
		saveTable.coin = saveTable.coin + coinCount
		nB=true
	else
		saveTable.coin = saveTable.coin + coinCount
	end
		local contents = json.encode( saveTable )
		file:write( contents )
		io.close( file )
	return nB
end

--If all lives are lost then this function is called--

local function lost()
	load()
	
	--showAd( "interstitial" )
	--ads.load( "interstitial" ) --Loads a full page advertisement--

	save()
	newScreen = false
	local replayBtn
	local homeBtn
	removeAllBalloons()
	LostObj_0:removeSelf( )
	LostObj_1:removeSelf( )
	LostObj_2:removeSelf( )
	if saveTable.defensePack then
		LostObj_3:removeSelf( )
		LostObj_4:removeSelf( )
	end

	while( coinGrp.numChildren > 0 ) do 
        		display.remove( coinGrp[1] )
        		coinCount = coinCount + 1 
    	end
    	while( nukeGrp.numChildren > 0 ) do 
        		display.remove( coinGrp[1] )
    	end

    	local overTitle = display.newImage("graphics/overTitle.png")
    		overTitle.x = centerX
    		overTitle.y = screenTop + 50
    		overTitle.anchorY = 0

    	local function bounce()
    	if not newScreen then
		    transition.to(overTitle, {time = 10000, y = overTitle.y - 25, onComplete = function()
		    	transition.to(overTitle, {time = 10000, y = overTitle.y + 25, onComplete = bounce})
		    end})
		end
	end

	bounce()
	
	local coinAdded = display.newText( "", centerX, centerY, "ROCKEB.TTF", 50)
	coinAdded.anchorX = 0
	local coin = display.newImageRect( "graphics/coin.png", 40, 40 )
	coinAdded.text = "+"..coinCount
	coin.x = coinAdded.x - 60
	coin.y = coinAdded.y

	
		
	highscoreTxt.text = "Highscore: "..saveTable.score
	highscoreTxt.y = coinAdded.y - 100

	scoreTxt.x = centerX
	scoreTxt.y = coinAdded.y-200
	scoreTxt.text = "Score: "..score

	scoreTxt:toFront( )
	highscoreTxt:toFront()

	homeBtn = display.newImage("graphics/home.png")
	homeBtn.x, homeBtn.y = centerX, centerY + 150

		homeBtn:addEventListener( "tap", function()
		balloonsLost = 0
		score = 0
		coinCount = 0
		newScreen = true
		overTitle:removeSelf()
		highscoreTxt:removeSelf( )
		scoreTxt:removeSelf()
		replayBtn:removeSelf( )
		homeBtn:removeSelf( )
		leftWall:removeSelf( )
		rightWall:removeSelf( )
		ceiling:removeSelf( )
		coin:removeSelf()
		coinAdded:removeSelf( )
		startScreen()
		end )
	replayBtn = display.newImage("graphics/replay.png")
	replayBtn.x, replayBtn.y = centerX, centerY + 350
		replayBtn:addEventListener( "tap", function()
		balloonsLost = 0
		score = 0
		coinCount = 0
		newScreen = true
		overTitle:removeSelf()
		scoreTxt:removeSelf()
		replayBtn:removeSelf( )
		highscoreTxt:removeSelf( )
		coin:removeSelf()
		coinAdded:removeSelf( )
		homeBtn:removeSelf( )
		start()
		end )
end

--Updated everytime you lose a balloon--

local function updateLost()
	if balloonsLost == -1 then
		LostObj_4.alpha = .25
	elseif balloonsLost == 0 then
		LostObj_3.alpha = .25
	elseif balloonsLost == 1 then
		LostObj_0.alpha = .25
	elseif balloonsLost == 2 then
		LostObj_1.alpha = .25
	elseif balloonsLost == 3 then
		LostObj_2.alpha = .25
		lost()
	end
end

--Checking if a balloon is past the top of the screen--

local function ceilingHit(event)
	if event.phase == "ended" then 
		event.other:removeSelf( )
		balloonsLost = balloonsLost + 1
		updateLost()
	end
end

--Removes the balloon that was tapped--
local function spike(g)
	timer.performWithDelay(10, function()
		local grp = display.newGroup()
		for i = 1, 3 do
			local s = display.newImage("graphics/packs/DefensePack/db1Power.png")
			s.x = g.x
			s.y = g.y
			s.name = "spike"
			physics.addBody(s, "dynamic", {density=0.1, friction=1.0, bounce=0.0});
			grp:insert(s)
			s:addEventListener("collision", function(event)
					if event.phase == "ended" then
						if event.other.isBalloon then
							removeBalloons(event.other)
							display.remove(event.target)
						end
					end
				end)
			if i == 1 then 
				s:applyForce(200,200, s.x,s.y)
			elseif i == 2 then 
				s:applyForce(-200,200, s.x,s.y)
			else
				s:applyForce(0,200, s.x,s.y)
			end
		end

		timer.performWithDelay(5000, function()
			while( grp.numChildren > 0 ) do 
	       			display.remove( grp[1] )
	   		end
		end)
	end)

end

	

function removeBalloons(obj)
	local rand = Random(1,100)
	if rand <=10 or obj.name == "money" then
		local coin = display.newImageRect( "graphics/coin.png", 75, 85 )
		coin.x = obj.x
		coin.y = obj.y
		coin:scale( .85, .85 )
		
		timer.performWithDelay( 100, function()
			transition.to( coin, {time = 10000, alpha = 0} )
			coinGrp:insert( coin )
			coin:addEventListener( "tap", function()
				coin:removeSelf( )
				coinCount = coinCount + 1
			end)
			
		end )
	end

	opts = {x = obj.x, y = obj.y}

	if obj.name == "nuke" then
		physics.pause( )
		local nukeScreen = display.newRect( centerX, centerY, screenWidth, screenHeight )
			nukeScreen.fill = {1,1,1}
		local function nukeR()
			nukeScreen:removeSelf( )
		end
		audio.play( nukeSound )
		timer.performWithDelay( 500, function()
			physics.start( )
			transition.to( nukeScreen, {time = 5000, alpha = 0, onComplete = nukeR})
		while( balloonGrp.numChildren > 0 ) do 
        	display.remove( balloonGrp[1] )
    	end
		end )	
    elseif obj.name == "x2" then
    	x2 = true
    	x3 = false
    	x2Timer()
    elseif obj.name == "live" then
    	addLive()
    elseif obj.name == "spike" then
    	spike(opts)
    elseif obj.name == "armor" then
    	addLive(true)
    elseif obj.name == "myst" then
    	mystWheel(obj)
    elseif obj.name == "stone" then 
    	obj.tapped = obj.tapped + 1
    	if obj.tapped == 2 then
    		audio.play(balloonPop)
    		obj:removeSelf()
    	end
    elseif  obj.name == "metal" then

    	obj.tapped = obj.tapped + 1
    	if obj.tapped == 3 then

    		audio.play(balloonPop)
    		obj:removeSelf()
    	end
    elseif obj.name == "x3" then
    	x2 = false
    	x3 = true
    	x2Timer()
  
    elseif obj.name == "gNuke" then
		physics.pause( )
		local nukeScreen = display.newRect( centerX, centerY, screenWidth, screenHeight )
			nukeScreen.fill = {1,1,0}
		local function nukeR()
			physics.start( )
			nukeScreen:removeSelf( )
		end
		audio.play( nukeSound )
		timer.performWithDelay( 500, function()
			transition.to( nukeScreen, {time = 2500, alpha = 0, onComplete = nukeR})
			while( balloonGrp.numChildren > 0 ) do
				local coin = display.newImageRect( "graphics/coin.png", 75, 85 )
					coin.x = balloonGrp[1].x
					coin.y = balloonGrp[1].y
					coin:scale( .85, .85 )
			
				timer.performWithDelay( 10, function()
					transition.to( coin, {time = 10000, alpha = 0} )
					coinGrp:insert( coin )
					coin:addEventListener( "tap", function()
						coin:removeSelf( )
						coinCount = coinCount + 1
					end)
					
				end )
	        		display.remove( balloonGrp[1] )
	    		end
		end )	
    end
    makeDriftingText(obj.score,opts) -- Calls to make the text drift--
    if obj.name ~= "metal" and obj.name ~= "stone" then
    	audio.play(balloonPop)
    	obj:removeSelf()
    end
    
end

--Creates a balloon called by a timer--

function makeBalloon()
	local balloonType = Random(1,100)
	local balloon
	if balloonType <= 90 then
		balloon = display.newImageRect( "graphics/packs/NormalPack/"..balloonTable.normal[Random(1,3)]..".png", 87, 125 )
			balloon.name = "normal"
			balloon.score = 10
		
	elseif balloonType > 90 and balloonType <=95 then
		balloonType = Random(1,100)
		local num
		if balloonType >=90 then
			num = 1
		elseif balloonType >=60 then
			num = 2
		else
			num = Random(3,#balloonTable.special)
		end
		balloon = display.newImageRect( "graphics/packs/SpecialPack/"..balloonTable.special[num]..".png", 87, 125 )
			balloon.name = balloonTable.specialName[num]
			balloon.score = balloonTable.specialScore[num]
	else
		if not saveTable.defensePack and not saveTable.goldenPack and not saveTable.politicalPack then
			balloon = display.newImageRect( "graphics/packs/NormalPack/"..balloonTable.normal[Random(1,3)]..".png", 87, 125 )
			balloon.name = "normal"
			balloon.score = 10
		else
			local paths = {}
			local active = {}
			if saveTable.politicalPack then
				table.insert(paths, "graphics/packs/PoliticalPack/b")
				table.insert(active, "political")
			end
			if saveTable.goldenPack then
				table.insert(paths, "graphics/packs/GoldenPack/b")
				table.insert(active, "golden")
			end
			if saveTable.defensePack then
				table.insert(paths, "graphics/packs/DefensePack/b")
				table.insert(active, "defense")
			end


			local rand =  Random(1, #paths)
			local pack = active[rand]

			local r = Random(1,3)

			balloon = display.newImage( paths[rand]..r..".png")

			if pack == "political" then
				balloon.name = "normal"
				balloon.score = 10
			elseif pack == "golden" then
				balloon.name = balloonTable.pack.goldenPackName[r]
				balloon.score = balloonTable.pack.goldenPackScore[r]
			elseif pack == "defense" then
				balloon.name = balloonTable.pack.defensePackName[r]
				balloon.score = balloonTable.pack.defensePackScore[r]
			end
		end

	end

	balloon.x = Random(50, screenWidth-50)
	balloon.y = Random(screenBottom+300, screenBottom+1000)
	balloon.tapped = 0
	physics.addBody(balloon, "dynamic", {density=0.1, friction=0.0, bounce=0.5, radius = 80});
	function balloon:touch(event)
		if event.phase == "began" then
			if x3 then
				score = score + (self.score*3)
			elseif x2 then
				score = score + (self.score*2)
			else
				score = score + self.score
			end
		scoreTxt.text = score
		removeBalloons(self)
		makeBalloon()
		end
	end
	balloon:addEventListener("touch", balloon)
	balloon.isBalloon = true
	balloonGrp:insert(balloon)
end

local function clearMain(self)
	b1:removeSelf( )
	b2:removeSelf( )
	b3:removeSelf( )
	transition.cancel(title)
	title:removeSelf()
	newScreen = true
	if self.func == "start" then
		start()
	elseif self.func == "guide" then
		instructionPage()
	else
		store()
	end
end

--First Load

function start()
	--ads.load( "interstitial" )

	balloonPop = audio.loadSound("sounds/balloonPop.wav")
	nukeSound = audio.loadSound( "sounds/nukeSound.wav" )

	leftWall = display.newRect (0, 0, 1, screenHeight)
		leftWall.y=centerY
	rightWall = display.newRect (screenWidth, 0, 1, screenHeight)
		rightWall.y=centerY
	ceiling = display.newRect (0, 0, screenWidth, 1)
		ceiling.x=centerX
		ceiling.y = screenTop - 200
		ceiling:addEventListener( "collision", ceilingHit )

	physics.addBody (leftWall, "static",  { bounce = 0.1 } )
	physics.addBody (rightWall, "static", { bounce = 0.1 } )
	physics.addBody (ceiling, "static",   { bounce = 0.1 } )

	LostObj_0 = display.newImageRect( "graphics/packs/NormalPack/b3.png", 50, 60 )
	LostObj_0.x = screenRight - 170
	LostObj_0.y = screenTop + 40
	LostObj_1 = display.newImageRect( "graphics/packs/NormalPack/b3.png", 50, 60 )
	LostObj_1.x = screenRight - 110
	LostObj_1.y = screenTop + 40
	LostObj_2 = display.newImageRect( "graphics/packs/NormalPack/b3.png", 50, 60 )
	LostObj_2.x = screenRight - 50
	LostObj_2.y = screenTop + 40
	if saveTable.defensePack then
		LostObj_3 = display.newImageRect( "graphics/packs/DefensePack/b3.png", 50, 60 )
		LostObj_3.x = screenRight - 230
		LostObj_3.y = screenTop + 40
		LostObj_3.alpha =.5

		LostObj_4 = display.newImageRect( "graphics/packs/DefensePack/b3.png", 50, 60 )
		LostObj_4.x = screenRight - 290
		LostObj_4.y = screenTop + 40
		LostObj_4.alpha =.5
	end

	scoreTxt = display.newText( "", screenLeft + 175, screenTop+40, "ROCKEB.TTF", 60 )
	scoreTxt.text = score

	nukeGrp = display.newGroup( )
	balloonGrp = display.newGroup()	
	coinGrp = display.newGroup( )

	makeBalloon()
	gameTimer = timer.performWithDelay( 6000, makeBalloon, -1)
	
    highscoreTxt = display.newText( "", centerX, centerY-200, "ROCKEB.TTF", 60 )
end
function instructionPage()
	local bg = display.newImage( "graphics/instructions.png" )
		bg.x = centerX
		bg.y = centerY
		bg.width = screenWidth
		bg.height = screenHeight
	local backBtn = display.newImage( "graphics/back.png" )
	backBtn.x, backBtn.y = screenRight - 100, screenTop+50
		backBtn:addEventListener( "tap", function()
			backBtn:removeSelf( )
			bg:removeSelf()
			startScreen()
		end )
end
function startScreen()
	local newScreen = false
	local path = system.pathForFile( "highscore.txt", system.DocumentsDirectory )
	local file = io.open( path, "a+" )
    io.close( file )

    load()
    save()

	title = display.newImage("graphics/title.png")
    	title.x = centerX
    	title.y = screenTop+50
    	title.anchorY = 0

    local function bounce()
    	if not newScreen then
		    transition.to(title, {time = 10000, y = title.y - 25, onComplete = function()
		    	transition.to(title, {time = 10000, y = title.y + 25, onComplete = bounce})
		    end})
		end
	end

	bounce()


	b1 = display.newImage( "graphics/start.png" )
		b1.type = start
		b1.tap = clearMain
		b1.x,b1.y = centerX, centerY-75
		b1.func = "start"
		b1:addEventListener( "tap", b1 )
	b2 = display.newImage( "graphics/guide.png" )
		b2.type = "guide"
		b2.tap = clearMain
		b2.x,b2.y = b1.x,b1.y+200
		b2:addEventListener( "tap", b2 )
	b3 = display.newImage( "graphics/store.png" )
		b3.type = "store"
		b3.tap = clearMain
		b3.x,b3.y = b2.x,b2.y + 200
		b3:addEventListener( "tap", b3 )
end

function store()
	local coinTxt = display.newText( "", screenRight-50, screenTop, "ROCKEB.TTF", 50)
	coinTxt.anchorY = 0
	coinTxt.anchorX = 1
	local coin = display.newImageRect( "graphics/coin.png", 35, 35 )
	coin.anchorX = 0
	coin.anchorY = 0
		coin.x = coinTxt.x + 5
		coin.y = coinTxt.y + 10
	load()

	local function tapListener(self)
		if self.price <= saveTable.coin and self.bought == false then 
			saveTable.coin = saveTable.coin - self.price
			if self.name == "politicalPack" then
				saveTable.politicalPack = true
			elseif self.name == "goldenPack" then
				saveTable.goldenPack = true
			elseif self.name == "defensePack" then
				saveTable.defensePack = true
			end
			self.alpha = 1
			self.bought = true
			coinTxt.text = saveTable.coin
			save()
		elseif self.bought == true then
			saveTable.coin = saveTable.coin + (self.price)
			coinTxt.text = saveTable.coin
			self.bought = false
			if self.name == "politicalPack" then
				saveTable.politicalPack = false
			elseif self.name == "goldenPack" then
				saveTable.goldenPack = false
			elseif self.name == "defensePack" then
				saveTable.defensePack = false
			end
			self.alpha = .5
			save()
		end

	end

	coinTxt.text = saveTable.coin
	local backBtn = display.newImage( "graphics/back.png" )
	backBtn.anchorX, backBtn.anchorY = 0,0
	backBtn.x, backBtn.y = screenLeft+25, screenTop+10

	local sb = display.newGroup( )

	local sb1 = display.newImage( "graphics/packs/PoliticalPack/politicalPack.png")
		sb1.x, sb1.y = centerX-160, screenTop+250
		sb1.name = "politicalPack"
		sb1.price = 200
		if saveTable.politicalPack == false then 
			sb1.alpha = .5
		else
			sb1.alpha = 1
		end
		sb1.bought = saveTable.politicalPack
		sb1.tap = tapListener
		sb1:addEventListener( "tap", sb1 )
	sb:insert( sb1 )

	local sb2 = display.newImage( "graphics/packs/GoldenPack/goldenPack.png")
		sb2.x, sb2.y = centerX+160, screenTop+250
		sb2.name = "goldenPack"
		sb2.price = 200
		if saveTable.goldenPack == false then 
			sb2.alpha = .5
		else
			sb2.alpha = 1
		end
		sb2.bought = saveTable.goldenPack
		sb2.tap = tapListener
		sb2:addEventListener( "tap", sb2 )
	sb:insert( sb2 )

	local sb3 = display.newImage( "graphics/packs/DefensePack/defensePack.png")
		sb3.x, sb3.y = centerX-160, screenTop+575
		sb3.name = "defensePack"
		sb3.price = 200
		if saveTable.defensePack == false then
			sb3.alpha = .5
		else
			sb3.alpha = 1
		end
		sb3.bought = saveTable.defensePack
		sb3.tap = tapListener
		sb3:addEventListener( "tap", sb3 )
	sb:insert( sb3 )

	backBtn:addEventListener( "tap", function()
		save()
		coinTxt:removeSelf( )
		coin:removeSelf( )
		backBtn:removeSelf( )
		startScreen()

		while( sb.numChildren > 0 ) do 
       			display.remove( sb[1] )
   		end
	end)
end
	background = display.newImage( "graphics/sky1.png" )
	background.x = centerX
	background.y = centerY
	background.width = screenWidth
	background.height = screenHeight

    c4 = display.newImage( "graphics/cloud1.png" )
    	c4.y = Random(screenTop + 100, screenBottom-250)
    	c4.x = Random(screenLeft, screenRight)
		c4.enterFrame = scroll
		c4.speed = .05
		c4.alpha = .5
		c4:scale( .25, .25 )

	c3 = display.newImage( "graphics/cloud2.png" )
		c3.y = Random(screenTop + 100, screenBottom-250)
    	c3.x = Random(screenLeft, screenRight)
		c3.enterFrame = scroll
		c3.speed = .25
		c3:scale( .5, .5 )
		c3.alpha = .75

	c2 = display.newImage( "graphics/cloud3.png" )
    	c2.y = Random(screenTop + 100, screenBottom-250)
    	c2.x = Random(screenLeft, screenRight)
		c2.enterFrame = scroll
		c2.speed = .15
		c2.alpha = .5
		c2:scale( .45, .45 )

	c1 = display.newImage( "graphics/cloud4.png" )
		c1.y = Random(screenTop + 100, screenBottom-250)
    	c1.x = Random(screenLeft, screenRight)
		c1.enterFrame = scroll
		c1.speed = .2
		--c1:scale( .5, .5 )
		c1.alpha = .75

	Runtime:addEventListener("enterFrame", c1)
	Runtime:addEventListener("enterFrame", c2)
	Runtime:addEventListener("enterFrame", c3)
	Runtime:addEventListener("enterFrame", c4)

startScreen()

local splash = display.newImage( "graphics/launch.png" )
splash.x = centerX
splash.y = centerY
splash.width = screenWidth
splash.height = screenHeight
splash:addEventListener( "tap", function()
	return true
end )
timer.performWithDelay( 3000, function()
	transition.to( splash, {time = 250, alpha=0, onComplete = function()
		splash:removeSelf( )
		end})
end)