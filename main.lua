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
------------------------------------------------------------------------------------------

--Global objects
local physics = require("physics");
	physics.start();
	physics.setGravity(0, -4);

math.randomseed( os.time() );
math.random( );

local json = require("json");

local garbage = {};
	garbage.display = {};
	garbage.transition = {};
	garbage.timer = {};

local balloon_type = {};

	balloon_type.base = {"b1","b2","b3"};
	balloon_type.special = {"sb1","sb2","sb3","sb4","sb5","sb6"};
	balloon_type.specialname = {"nuke","myst","x2","stone","live","white"};

	balloon_type.pack = {};

	balloon_type.pack.goldenPackName = {"money","x3","gNuke"};
	balloon_type.pack.defensePackName = {"spike", "armor", "metal"};

local score_multiplier = 1;
local balloonPop = audio.loadSound("sounds/balloonPop.wav");
local nukeSound = audio.loadSound("sounds/nukeSound.wav");
local shieldSound = audio.loadSound("sounds/shieldSound.wav");
local score = 0;
local scoreTxt;
local g_tapped_object;
local coins = 0
local lives = 3;

local lives_objects = {};
local saveTable = {};

local version = 2

-- The name of the ad provider. AD stuff
local provider = "admob"

-- Your application ID
local appID = ""

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
	ads.show( adType, { appID = ""} )
end

local function switch(t)
  t.case = function (self,x)
    local f=self[x] or self.default
    if f then
      if type(f)=="function" then
        return f(x,self);
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end

local function scroll(self,event)
    if self.x > screenLeft-self.width/2 then
        self.x = self.x - self.speed
    else
    	
        self.x = screenRight+self.width/2
        self.y = math.random(screenTop+50, screenBottom-100)
    end

end

--Loading the saved file in the documents directory--

local function load()
	local path = system.pathForFile( "properties.txt", system.DocumentsDirectory )
	local contents = ""
    local file = io.open( path, "r" )
 	contents = file:read( "*a" )
 	saveTable = json.decode( contents )
    io.close( file )

    if saveTable == nil then
	    saveTable = {
		    score = 0,
			coin = 0,
			goldenPack = false,
			defensePack = false,
			version = version,
			ad = 3
		}
	elseif saveTable.version == nil or saveTable.version < version then
		saveTable = {
	    	score = saveTable.score,
			coin = saveTable.coin,
			goldenPack = saveTable.goldenPack,
			defensePack = saveTable.defensePack,
			version = version,
			ad=3
		}
    end
end

--Saving the file in the documents directory

local function save(a)
	local path = system.pathForFile( "properties.txt", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	local nB = false
	if saveTable.score < score then
		saveTable.score = score
		saveTable.coin = saveTable.coin + coins
		nB=true
	else
		saveTable.coin = saveTable.coin + coins
	end
		local contents = json.encode( saveTable )
		file:write( contents )
		io.close( file )
	return nB
end

local function makeDriftingText(txt, opts)

    local opts = opts or {}
    local dTime = opts.t or 1000 -- drift time
    local del = opts.del or 0 -- delay time
    local yVal = opts.yVal or -40 -- how far to drift
    local x = opts.x or display.contentCenterX -- initial X location of text
    local y = opts.y or display.contentCenterY -- initial Y location of text
    local fontFace = opts.font or "ROCKEB.TTF" -- font to use
    local fontSize = opts.size or 40 -- font size
 
    local dTxt = display.newText(txt, 0, 0, fontFace, fontSize )
          	dTxt.x = x
          	dTxt.y = y
          if opts.grp then 
   	      	opts.grp:insert(dTxt)
          end
    local function killDTxt(obj)
          display.remove( obj )
          obj = nil
    end
    transition.to( dTxt,  { delay=del, time=dTime, y=y+yVal, alpha=0, onComplete=killDTxt } )
end

--Removes a balloon
local function remove(obj)
	local rand = math.random(1,100);
	local opts = {x = obj.x, y = obj.y};
	if rand <=10 or obj.name == "money" then
		local coin = display.newImageRect( "graphics/coin.png", 75, 85 )
		coin.x = obj.x
		coin.y = obj.y
		coin:scale( .85, .85 )
		
		timer.performWithDelay( 100, function()
			transition.to( coin, {time = 10000, alpha = 0} )
			coin:addEventListener( "tap", function()
				coin:removeSelf( )
				coins = coins + 1
			end)
			
		end )
	end
	obj:removeSelf();
	score = score + score_multiplier;
	scoreTxt.text = score;
	makeDriftingText("+"..score_multiplier, opts);
	audio.play(balloonPop);
end

--Makeshift switch for each type of balloon

a = switch {
  	["nuke"] = function (x)

	  	local nukeScreen = display.newRect( centerX, centerY, screenWidth, screenHeight );
			nukeScreen.fill = {1,1,1};
		audio.play(nukeSound);
		timer.performWithDelay( 500, function()
		physics.start();
		transition.to(nukeScreen, {time = 5000, alpha = 0, onComplete = function()
			nukeScreen:removeSelf();
			end});
		end);
		local count = 0;
		for i = table.getn(garbage.display), 1, -1 do
			if garbage.display[i].health ~= nil then
				display.remove(garbage.display[i]);
				count = count + 1;
			end
		end
		score = score + count * score_multiplier;
		scoreTxt.text = score;
	end,

  	["x2"] = function (x)
  		score_multiplier = 2;
  		timer.performWithDelay( 10000, function()
			score_multiplier = 1
		end);
  	end,

  	["x3"] = function (x) 
  		score_multiplier = 3;
  		timer.performWithDelay( 10000, function()
			score_multiplier = 1
		end);
  	end,

  	["live"] = function (x) 
  		if lives < 3 then
  			lives = lives + 1;
  			lives_objects[lives].alpha = 1;
  		end
  	end,

  	["spike"] = function (x) 

		local grp = display.newGroup()
		for i = 1, 3 do
			local s = display.newImage("graphics/packs/DefensePack/db1Power.png")
			s.x = g_tapped_object.x
			s.y = g_tapped_object.y
			s.name = "spike"
			physics.addBody(s, "dynamic", {density=0.1, friction=1.0, bounce=0.0});
			grp:insert(s)
			s:addEventListener("collision", function(event)
				if event.phase == "ended" then
					if event.other.isBalloon then
						remove(event.other)
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

  	end,

  	["armor"] = function (x) 
  		if lives >= 3 and lives < 5 then
  			lives = lives + 1;
  			lives_objects[lives].alpha = 1;

  		end
  	end,

  	["myst"] = function (x) 
  		local rand = math.random(1,2)
		if rand == 1 then
			physics.pause();
			timer.performWithDelay( 2000, function()
				physics.start();
			end);
		elseif rand == 2 then
			rand = math.random(1,2)
			for i = 1,rand do
				local balloon = display.newImageRect( "graphics/packs/NormalPack/b"..math.random(1,3)..".png", 87, 125 )
				balloon.x = g_tapped_object.x+math.random(10,30)
				balloon.y = g_tapped_object.y-math.random(10,30)
				balloon.xScale = .7
				balloon.yScale = .7
				balloon.name = "normal"

				physics.addBody(balloon, "dynamic", {density=0.1, friction=0.0, bounce=0.5, radius = 35});

				function balloon:touch(event)
					if event.phase == "began" then
						audio.play(balloonPop);
						remove(self);
					end
				end

				balloon:addEventListener("touch", balloon)
				table.insert(garbage.display, 1, balloon)
			end
		end
  	end,

  	["stone"] = function (x) 
  		print(g_tapped_object.health);
  		if g_tapped_object.health == 1 then
  			remove(g_tapped_object);
  		else
  			g_tapped_object.health = g_tapped_object.health - 1;
  			audio.play(shieldSound);
  		end

  		return false;
  	end,

  	["metal"] = function (x)
  		if g_tapped_object.health == 1 then
  			remove(g_tapped_object);
  		else
  			g_tapped_object.health = g_tapped_object.health - 1;
  			audio.play(shieldSound);
  		end
  		return false;
  	end,
  	
  	["gNuke"] = function (x) 
  		local nukeScreen = display.newRect( centerX, centerY, screenWidth, screenHeight );
			nukeScreen.fill = {1,1,1};
		audio.play(nukeSound);
		physics.pause();
		transition.to(nukeScreen, {time = 5000, alpha = 0, onComplete = function()
			nukeScreen:removeSelf();
			physics.start();
		end});
		local count = 0;
		for i = table.getn(garbage.display), 1, -1 do
			if garbage.display[i].health ~= nil and g_tapped_object.name ~= garbage.display[i].name then
				local coin = display.newImageRect( "graphics/coin.png", 75, 85 );
					coin.x = garbage.display[i].x;
					coin.y = garbage.display[i].y;
					coin:scale( .85, .85 );
				transition.to( coin, {time = 10000, alpha = 0} );
					coin:addEventListener( "tap", function()
						coin:removeSelf();
						coins = coins + 1;
					end);
				display.remove(garbage.display[i]);
				count = count + 1;
			end
		end
		score = score + count * score_multiplier;
		scoreTxt.text = score;
  	end
}

--Enterframe for the clouds in the background
local function scroll(self,event)
    if self.x > screenLeft-self.width/2 then
        self.x = self.x - self.speed
    else
    	
        self.x = screenRight+self.width/2
        self.y = math.random(screenTop+50, screenBottom-100)
    end

end

--Loop through tables and delete everything
local function destroy_garbage()
	for i = table.getn(garbage.display), 1, -1 do
		display.remove(garbage.display[i]);
	end
	for i = table.getn(garbage.timer), 1, -1 do
		timer.cancel(garbage.timer[i]);
	end
	for i = table.getn(garbage.transition), 1, -1 do
		transition.cancel(garbage.transition[i]);
	end

	garbage.display = {};
	garbage.timer = {};
	garbage.transition = {};

end

--Spawn Balloon function
local function spawn_balloon()
	local balloonType = math.random(1,100);
	local balloon
	if balloonType <= 90 then
		balloon = display.newImageRect( "graphics/packs/NormalPack/"..balloon_type.base[math.random(1,3)]..".png", 87, 125 )
			balloon.name = "normal"
	elseif balloonType > 90 and balloonType <=95 then
		balloonType = math.random(1,100)
		local num
		if balloonType >=90 then
			num = 1
		elseif balloonType >=60 then
			num = 2
		else
			num = math.random(3,#balloon_type.special)
		end
		balloon = display.newImageRect( "graphics/packs/SpecialPack/"..balloon_type.special[num]..".png", 87, 125 )
			balloon.name = balloon_type.specialname[num]
	else
		if not saveTable.defensePack and not saveTable.goldenPack then
			balloon = display.newImageRect( "graphics/packs/NormalPack/"..balloon_type.base[math.random(1,3)]..".png", 87, 125 )
			balloon.name = "normal"
		else
			local paths = {};
			local active = {};
			if saveTable.goldenPack then
				table.insert(paths, "graphics/packs/GoldenPack/b");
				table.insert(active, "golden");
			end
			if saveTable.defensePack then
				table.insert(paths, "graphics/packs/DefensePack/b");
				table.insert(active, "defense");
			end


			local rand =  math.random(1, #paths);
			local pack = active[rand];

			local r = math.random(1,3);

			balloon = display.newImage( paths[rand]..r..".png");

			if pack == "golden" then
				balloon.name = balloon_type.pack.goldenPackName[r];
			elseif pack == "defense" then
				balloon.name = balloon_type.pack.defensePackName[r];
			end


		end
	end
	if balloon.name == "stone" then
		balloon.health = 2;
	elseif balloon.name == "metal" then
		balloon.health = 3;
	else
		balloon.health = 1;
	end
	balloon.isBalloon = true;
	balloon.x = math.random(50, screenWidth-50)
	balloon.y = math.random(screenBottom+300, screenBottom+1000)
	physics.addBody(balloon, "dynamic", {density=0.1, friction=0.0, bounce=0.5, radius = 80});
	function balloon:touch(event)
		if event.phase == "began" then
			local can_remove = true
			g_tapped_object = self; --Globalize the tapped object
			can_remove = a:case(self.name);
			if can_remove == nil then
				remove(self);
				spawn_balloon();
			end
		end
	end
	balloon:addEventListener("touch", balloon)
	table.insert(garbage.display, 1, balloon);
end

--Figures out how many lives to put on screen
local function load_lives()
	local x_increment = 65;
	local temp = 0;
	local path = "graphics/packs/NormalPack/b3.png";
	if saveTable.defensePack then
		lives = lives + 2;
	end
	for i = 1, lives do
		if i > 3 then
			path = "graphics/packs/DefensePack/b3.png";
		end
		lives_objects[i] = display.newImageRect( path, 50, 60 );
		lives_objects[i].x = screenRight - temp - x_increment;
		lives_objects[i].y = screenTop + 40
		temp = x_increment + temp;
		table.insert(garbage.display, 1, lives_objects[i])
		
	end
end

--Load Game

local function game_start()
	destroy_garbage();
	scoreTxt = display.newText( "", screenLeft + 175, screenTop+40, "ROCKEB.TTF", 60 )
	scoreTxt.text = score
	load_lives()
	spawn_balloon();
	local gameTimer = timer.performWithDelay( 5000, spawn_balloon, -1);
	table.insert(garbage.display, 1, scoreTxt);
	table.insert(garbage.timer, 1, gameTimer);
end



--Load Menu

local function menu()

	function store_function()
		destroy_garbage();
		local coinTxt = display.newText( "", screenRight-50, screenTop, "ROCKEB.TTF", 50)
		coinTxt.anchorY = 0
		coinTxt.anchorX = 1
		table.insert(garbage.display, 1, coinTxt);
		local coin = display.newImageRect( "graphics/coin.png", 35, 35 )
		coin.anchorX = 0
		coin.anchorY = 0
			coin.x = coinTxt.x + 5
			coin.y = coinTxt.y + 10
			table.insert(garbage.display, 1, coin);
		load()

		local function tapListener(self)
			if self.price <= saveTable.coin and self.bought == false then 
				saveTable.coin = saveTable.coin - self.price
				if self.name == "goldenPack" then
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
				if self.name == "goldenPack" then
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
			backBtn:addEventListener( "tap", function()
				save()
				menu()
			end)
		table.insert(garbage.display, 1, backBtn);


		local sb1 = display.newImage( "graphics/packs/GoldenPack/goldenPack.png")
			sb1.x, sb1.y = centerX-160, screenTop+300
			sb1.name = "goldenPack"
			sb1.price = 200
			if saveTable.goldenPack == false then 
				sb1.alpha = .5
			else
				sb1.alpha = 1
			end
			sb1.bought = saveTable.goldenPack
			sb1.tap = tapListener
			sb1:addEventListener( "tap", sb1 )
		table.insert(garbage.display, 1, sb1);

		local sb2 = display.newImage( "graphics/packs/DefensePack/defensePack.png")
			sb2.x, sb2.y = centerX+160, screenTop+300
			sb2.name = "defensePack"
			sb2.price = 200
			if saveTable.defensePack == false then 
				sb2.alpha = .5
			else
				sb2.alpha = 1
			end
			sb2.bought = saveTable.defensePack
			sb2.tap = tapListener
			sb2:addEventListener( "tap", sb2 )

		table.insert(garbage.display, 1, sb2);
	end

	destroy_garbage();

	local title = display.newImage("graphics/title.png");
    	title.x = centerX;
    	title.y = screenTop+50;
    	title.anchorY = 0;
    local bounce_loop = transition.to(title, {time = 10000, y = title.y - 25, onComplete = function()
		    	transition.to(title, {time = 10000, y = title.y + 25, onComplete = bounce})
		    			end});

	local start = display.newImage( "graphics/start.png" );
		start.type = start;
		start.x, start.y = centerX, centerY-75;
		start:addEventListener( "tap", game_start);

	local store = display.newImage( "graphics/store.png" );
		store.x, store.y = start.x, start.y + 200;
		store:addEventListener( "tap", store_function);

 	table.insert(garbage.transition, 1, bounce_loop);
 	table.insert(garbage.display, 1, title);
 	table.insert(garbage.display, 1, start);
 	table.insert(garbage.display, 1, store);


end

--On loss
local function lost()
	load();

	if score >= 10 then
		saveTable.ad = saveTable.ad - 1;
	end

	if score >= 250 then
		saveTable.ad = 0;
	end

	if saveTable.ad == 0 then
		showAd( "interstitial");
		saveTable.ad = 3;
	end

	save();

	lives = 3;

	local overTitle = display.newImage("graphics/overTitle.png")
    		overTitle.x = centerX
    		overTitle.y = screenTop + 50
    		overTitle.anchorY = 0
    table.insert(garbage.display, 1, overTitle);

	local function bounce()
		local bounce_loop = transition.to(overTitle, {time = 10000, y = overTitle.y - 25, onComplete = function()
		    	transition.to(overTitle, {time = 10000, y = overTitle.y + 25, onComplete = bounce});
		end});
		table.insert(garbage.transition, 1, bounce_loop);
	end

	bounce();

	local coinAdded = display.newText( "", centerX, centerY, "ROCKEB.TTF", 50)
	coinAdded.anchorX = 0
	table.insert(garbage.display, 1, coinAdded);

	local coin = display.newImageRect( "graphics/coin.png", 40, 40 )
	coinAdded.text = "+"..coins
	coin.x = coinAdded.x - 60
	coin.y = coinAdded.y
	table.insert(garbage.display, 1, coin);

	local highscoreTxt = display.newText( "", centerX, coinAdded.y - 100, "ROCKEB.TTF", 60 )
	highscoreTxt.text = "Highscore: "..saveTable.score;
	table.insert(garbage.display, 1, highscoreTxt);

	local scoreTxt = display.newText( "", centerX, coinAdded.y-200, "ROCKEB.TTF", 60 )
	scoreTxt.text = "Score: "..score
	table.insert(garbage.display, 1, scoreTxt);

	highscoreTxt:toFront()

	local homeBtn = display.newImage("graphics/home.png");
	homeBtn.x, homeBtn.y = centerX, centerY + 150;
	homeBtn:addEventListener( "tap", menu);
	table.insert(garbage.display, 1, homeBtn);

	local replayBtn = display.newImage("graphics/replay.png");
	replayBtn.x, replayBtn.y = centerX, centerY + 350;
	replayBtn:addEventListener( "tap", game_start);
	table.insert(garbage.display, 1, replayBtn);

	coins = 0;
	score = 0;

end

--Take away life
local function ceiling_hit(event)
	if event.phase == "ended" then 
		if event.other.isBalloon then 
			event.other:removeSelf( );
			lives_objects[lives].alpha = .25;
			lives = lives - 1;
			if lives == 0 then
				destroy_garbage();
				lost()
			end
		end
	end
end

-- Start Up

local function initialize()
	local background = display.newImage( "graphics/sky1.png" );
		background.x = centerX;
		background.y = centerY;
		background.width = screenWidth;
		background.height = screenHeight;
	local leftWall = display.newRect (0, 0, 1, screenHeight)
		leftWall.y=centerY
	local rightWall = display.newRect (screenWidth, 0, 1, screenHeight)
		rightWall.y=centerY
	local ceiling = display.newRect (0, 0, screenWidth, 1)
		ceiling.x = centerX
		ceiling.y = screenTop - 200
		ceiling:addEventListener( "collision", ceiling_hit )

	local c4 = display.newImage( "graphics/cloud1.png" )
    	c4.y = math.random(screenTop + 100, screenBottom-250)
    	c4.x = math.random(screenLeft, screenRight)
		c4.enterFrame = scroll
		c4.speed = .05
		c4.alpha = .5
		c4:scale( .25, .25 )

	local c3 = display.newImage( "graphics/cloud2.png" )
		c3.y = math.random(screenTop + 100, screenBottom-250)
    	c3.x = math.random(screenLeft, screenRight)
		c3.enterFrame = scroll
		c3.speed = .25
		c3:scale( .5, .5 )
		c3.alpha = .75

	local c2 = display.newImage( "graphics/cloud3.png" )
    	c2.y = math.random(screenTop + 100, screenBottom-250)
    	c2.x = math.random(screenLeft, screenRight)
		c2.enterFrame = scroll
		c2.speed = .15
		c2.alpha = .5
		c2:scale( .45, .45 )

	local c1 = display.newImage( "graphics/cloud4.png" )
		c1.y = math.random(screenTop + 100, screenBottom-250)
    	c1.x = math.random(screenLeft, screenRight)
		c1.enterFrame = scroll
		c1.speed = .2
		--c1:scale( .5, .5 )
		c1.alpha = .75

	Runtime:addEventListener("enterFrame", c1)
	Runtime:addEventListener("enterFrame", c2)
	Runtime:addEventListener("enterFrame", c3)
	Runtime:addEventListener("enterFrame", c4)

	physics.addBody (leftWall, "static",  { bounce = 0.1 } )
	physics.addBody (rightWall, "static", { bounce = 0.1 } )
	physics.addBody (ceiling, "static",   { bounce = 0.1 } )

	local path = system.pathForFile( "properties.txt", system.DocumentsDirectory )
	local file = io.open( path, "a+" )
    io.close( file )
    load()
    save()
end

local splash = display.newImage( "graphics/launch.png" )
splash.x = centerX
splash.y = centerY
splash.width = screenWidth
splash.height = screenHeight
splash:addEventListener( "tap", function()
	return true
end )
timer.performWithDelay( 3000, function()
	initialize();
	menu();

	transition.to( splash, {time = 250, alpha=0, onComplete = function()
		splash:removeSelf( )
		end})
end)




