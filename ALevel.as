package pixelSphere
{
	import Box2D.Collision.b2ContactID;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.Contacts.b2Contact;
	import citrus.objects.Box2DPhysicsObject;
	import citrus.view.starlingview.StarlingCamera;
	import citrus.view.starlingview.StarlingArt;
	import citrus.core.starling.StarlingState;
	import citrus.math.MathVector;
	import game.GameSettingsProxy;
	import level.LevelEnvironmentManager;
	import starling.extensions.filters.FlashlightFilter;
	import starling.extensions.filters.ThresholdFilter;
	//import starling.filters.PixelateFilter;
	import starling.extensions.filters.SpotlightFilter;
	
	import citrus.core.CitrusObject;
	import citrus.core.CitrusEngine;
	import citrus.physics.box2d.Box2D;
	import citrus.physics.box2d.Box2DUtils;
	import citrus.physics.box2d.IBox2DPhysicsObject;
	import citrus.utils.objectmakers.ObjectMakerStarling;
	import citrus.view.starlingview.AnimationSequence;
	
	import citrus.objects.CitrusSprite;
	import citrus.objects.QuickAnimation;
	import citrus.objects.CitrusSpriteBackground;
	
	import citrus.objects.platformer.box2d.Enemy;
	import citrus.objects.platformer.box2d.EnemyTurtle;
	import citrus.objects.platformer.box2d.EnemyBouncer;
	import citrus.objects.platformer.box2d.Hero;
	import citrus.objects.platformer.box2d.Platform;
	import citrus.objects.platformer.box2d.Sensor;
	import citrus.objects.platformer.box2d.Coin;
	import citrus.objects.platformer.box2d.SonicCoin;
	import citrus.objects.platformer.box2d.MusicCoin;
	import citrus.objects.platformer.box2d.MovingPlatform;
	import citrus.objects.platformer.box2d.MovingPlatformElevator;
	import citrus.objects.platformer.box2d.RevolvingPlatform;
	import citrus.objects.platformer.box2d.SwitchBlock;
	import citrus.objects.platformer.box2d.Crate;
	import citrus.objects.platformer.box2d.RotationBlock;
	import citrus.objects.platformer.box2d.Water;
	import citrus.objects.platformer.box2d.BridgeAnchor;
	import citrus.objects.platformer.box2d.Cannon;
	import citrus.objects.platformer.box2d.Ball;
	import citrus.objects.platformer.box2d.BallBounce;
	import citrus.objects.platformer.box2d.Launcher;
	import citrus.objects.platformer.box2d.ObjectSpawner;
	import citrus.objects.platformer.box2d.MusicPuzzleArea;
	import citrus.objects.platformer.box2d.MusicPuzzleRewardBox;
	import citrus.objects.platformer.box2d.RotatingMovingPlatform;
	import citrus.objects.platformer.box2d.Powerup;
	import citrus.objects.platformer.box2d.SignPost;
	import citrus.objects.platformer.box2d.ToneMatrix;
	import citrus.objects.platformer.box2d.ToneTrigger;
	import citrus.objects.platformer.box2d.Spring;
	import citrus.objects.complex.box2dstarling.Car;
	import citrus.objects.complex.box2dstarling.CarWithPassenger;
	import citrus.objects.complex.box2dstarling.PoolPixelsphere;
	import citrus.objects.complex.box2dstarling.BambooFountain;
	import citrus.objects.platformer.box2d.WoodenCrate;
	import citrus.objects.platformer.box2d.MovingCitrusSprite;
	import citrus.objects.platformer.box2d.BreakablePlatform;
	import citrus.objects.platformer.box2d.ChompRock;
	import citrus.objects.platformer.box2d.Teleporter;
	import citrus.objects.platformer.box2d.SoundEmitter;
	import citrus.objects.platformer.box2d.InteractiveGameObject;
	
	import game.ParticleManager;
	import game.feathersUI.GameMenu;
	import game.gameSettingsManager.GameSettingsManager;
	import game.GameSoundManager;
	import game.GameHUD;
	import game.GameRegistry;
	import game.GameProperties;
	import game.StarlingGameHUD;
	
	import level.LevelStatsManager;
	import level.LevelArtManager;
	import level.LevelInteractionManager;
	import level.LevelPhysicsManager;
	
	import starling.core.Starling;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.display.Quad;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent // temporary for mouse wheel zoom
	import flash.events.KeyboardEvent // temporary for keyboard rotate
	import flash.ui.Keyboard; // for checking if hero is moving and adjusting camera
	import flash.utils.clearTimeout; // used for camera zoom timeout when moving. TODO: move this elsewhere
	import flash.utils.setTimeout; // used for camera zoom timeout when moving. TODO: move this elsewhere
	
	import flash.utils.Timer; // used for timer to deactivate objects (enemies)
	import flash.events.TimerEvent; // used for timer to deactivate objects
	
	import org.osflash.signals.Signal;
	import com.eclecticdesignstudio.motion.Actuate;
	
	import game.CameraManager;
	
	import starling.events.ResizeEvent; // for updating camera when res changes
	
	import game.sound.CarSoundGenerator;
	
//	import flash.system.System;
	
	/**
	 * @author Aymeric & Alex
	 */
	public class ALevel extends StarlingState
	{
		public var lvlEnded:Signal; // dispatch this to end the level. Citrus takes care of the rest
		public var restartLevel:Signal; // dispatch this to restart the level. It won't reload the assets I think
		public var initLevelComplete:Signal; // dispatched when a level has init'd, but not neccesarily ready to play. dispatched on reload and first load
		public var initLevelStarted:Signal; // dispatched when a level has started to init. dispatched on reload and first load
		public var levelCompleted:Signal; // dispatched when the player hits the end level marker. Doesn't go to next level until you dispatch lvlEnded
		public var levelReadyToPlay:Signal // dispatched when the curtain lifts.
		
		private var endLevelTriggered:Boolean // set to true on first contact between endLevel and Hero.
		
		public var levelName:String = "a pixelsphere level"; // level name string. Note that these only overrride in subclass if null
		public var levelBounds:Rectangle;
		public var levelIndex:int; // private because its not updated until init. DONT MAKE THIS PUBLIC EVER!  // 5/11/2014 LOLOL did it anyway. public.
		public static var instance:ALevel;
		
		protected var _level:MovieClip;
		protected var _hero:Hero;
		
		protected var _maskDuringLoading:Quad;
		protected var _percentTF:TextField;
		
		public var levelInteractionManager:LevelInteractionManager; // public for respawn baddy
		
		private var levelLoaded:Boolean = false;
		private var box2dReference:Box2D; // used to get a reference to change gravity
		private var worldRotationInDegrees:int = 0;
		private var zoomFactor:Number = 1;
		private var restartingLevel:Boolean = false; // whether or not level is in process of being restarted.
		private var levelHasBeenRestarted:Boolean = false; // whether or not this level has been restarted at least once.
		private var gravity:b2Vec2;
		private var sound:GameSoundManager; // a reference to the GameSoundManager
		private var camera:StarlingCamera;
		private var levelStatsManager:LevelStatsManager;
		private var gm:GraphicsManager;
		
		private var gameMenu:GameMenu;
		
		private var distanceTimer:Timer;
		private var levelData:Array;
		private var levelEnvironmentManager:LevelEnvironmentManager;
		
		//[ALevel, "levels/Island/Island.swf", r( -2448, -512, (4096 + 2048), (4096)), "The Island of Pixelsphere"],
		public var currentLevelData:Array; // this is safe to access right away in any Box2DPhysicsObject
		
		public var allowDebugStuff:Boolean = true; // allow debug stuff like clip, switch to tremolo etc....purposely shitty name
		
	
	/**
	 * ALevel constructor
	 * 
	 * 
	 * 
	 * 
	 */
		public function ALevel(level:MovieClip = null, levelA:MovieClip = null)
		{
			super();
			trace("ALevel: Constructor gets called only when changing levels, not when restarting current level...!");
			// but it does get called if you click the same level on LEVEL SELECT, which is the same as changing levels!
			_level = level;
			lvlEnded = new Signal();
			restartLevel = new Signal();
			initLevelComplete = new Signal();
			initLevelStarted = new Signal();
			levelCompleted = new Signal();
			levelReadyToPlay = new Signal();
			
			// [===========] Register keyboard events [==================]
			if (allowDebugStuff)
			{
				CitrusEngine.getInstance().input.keyboard.addKeyAction("clip", Keyboard.W);
				CitrusEngine.getInstance().input.keyboard.addKeyAction("switch", Keyboard.F);
			}
			
			CitrusEngine.getInstance().input.keyboard.addKeyAction("fire", Keyboard.C);
			
			distanceTimer = new Timer(1000, 0);
			
			// [===========] GameSettings Proxy glues settings [==================]
			var gameSettingsProxy:GameSettingsProxy = GameSettingsProxy.instance;
			
			// [===========] SINGLETON Graphics Manager does this ONCE only for global graphics [==================]
			gm = GraphicsManager.getInstance();
			
			// [===========] SINGLETON Camera Manager [==================]
			CameraManager.getInstance();
			
			// [===========] SINGLETON CarSound Generator  [==================]
			CarSoundGenerator.getInstance();
			CarSoundGenerator.getInstance().stop(); // this isn't good enough. saw bug on laptop when changing level
			
			// [==========] set up a level stats manager [==========]
			levelStatsManager = new LevelStatsManager(this); // need to destroy this only when endLevel/warp level...
			
			// Useful for not forgetting to import object from the Level Editor AS: I have no idea how this works, there are no references to objectsUsed anywhere else in the CitrusEngine's code
			// [====================================================================================]
			var objectsUsed:Array = [Hero, Platform, Enemy, EnemyTurtle, EnemyBouncer, Sensor, CitrusSprite, QuickAnimation, CitrusSpriteBackground, SonicCoin, MusicCoin, Crate, RotationBlock, Water, Cannon, Ball, BallBounce, Launcher, ObjectSpawner, Powerup, SignPost, MovingPlatformElevator, MovingPlatform, RevolvingPlatform, BridgeAnchor, SwitchBlock, MusicPuzzleArea, MusicPuzzleRewardBox, RotatingMovingPlatform, ToneMatrix, ToneTrigger, Car, CarWithPassenger, PoolPixelsphere, BambooFountain, Spring, WoodenCrate, MovingCitrusSprite, BreakablePlatform, ChompRock, Teleporter, SoundEmitter, InteractiveGameObject];
			// [====================================================================================]		
		
		} // end ALEVEL CONSTRUCTOR
		
		/*
		 * Optimization: How this works....
		 * there is a boolean and callback for each physicsObject to extend so that it may handle being enabled.
		 * some physics objects may choose to toggle UpdateCallEnabled, toggle the juggler, or the Box2D _body active
		 * depending on the use of that object. For example enemies disable more things than coins, since coins
		 * are lightweight and less important to begin with...
		 *
		 *
		 * for optimizing platforms this is very dangerous with distance formula, particularly for Long or wide
		 * platforms, as its center point could be anywhere. So we need to do some thresholding so that
		 * large platforms are ALWAYS included in the simulation!
		 * also, we can't just go willy nilly turning on UpdateCallEnabled = true for platforms that never
		 * had update() in the first place...that would be a waste.
		 *
		 * CONSIDERATION: factors could be based on hero move speed, distance moved, or FRAME RATE, rather than
		 * silly time-based functions....
		 *
		 * TODO: BENCHMARK THIS ENTIRE FUNCTION!
		 */
		private function doDistanceCalculation(e:TimerEvent):void
		{
			var totalObjects:Vector.<CitrusObject> = getObjectsByType(CitrusObject);
			//trace ("ALEVEL: TOTAL OBJECTS IS             IS " + totalObjects.length);
			//trace ("ALEVEL: REALSTATE OBJECTS NOT KILLED IS " + _realState.objects.length);
			
			var heroX:Number = _hero.x;
			var heroY:Number = _hero.y;
			var oj:CitrusObject;
			var ojs:Vector.<CitrusObject>;
			var objectCount:int; // TODO: get rid of this...
			var physicsObject:Box2DPhysicsObject;
			var oldSimulationEnabled:Boolean;
			var newSimulationEnabled:Boolean;
			
			// [[[[[ Do Enemies --- this is by far the largest optimization! ]]]]]
			ojs = getObjectsByType(Enemy);
			objectCount = 0;
			for each (oj in ojs)
			{
				physicsObject = Box2DPhysicsObject(oj);
				oldSimulationEnabled = physicsObject.simulationEnabled;
				newSimulationEnabled = (d(physicsObject.x, physicsObject.y, heroX, heroY) < 900) ? true : false;
				physicsObject.simulationEnabled = newSimulationEnabled;
				if (oldSimulationEnabled != newSimulationEnabled)
				{
					physicsObject.updateSimulationEnabledStatus();
				}
			}
			
			// [[[[[ Do SonicCoins! ]]]]]
			ojs = getObjectsByType(SonicCoin);
			objectCount = 0;
			for each (oj in ojs)
			{
				physicsObject = Box2DPhysicsObject(oj);
				oldSimulationEnabled = physicsObject.simulationEnabled;
				objectCount++;
				newSimulationEnabled = (d(physicsObject.x, physicsObject.y, heroX, heroY) < 400) ? true : false;
				physicsObject.simulationEnabled = newSimulationEnabled;
				if (oldSimulationEnabled != newSimulationEnabled)
				{
					physicsObject.updateSimulationEnabledStatus();
				}
			}
		
			// [[[[[ Do Platforms! ]]]]]
			// could experiment with variable radius when the hero is moving very fast...
			// VAIO benchmark didn't respond positively to this, so we'll disable for now.
			// try it again later..I get the feeling VAIO bottleneck is down to STARLING.
		/*ojs = getObjectsByType(Platform);
		   objectCount = 0;
		   for each (oj in ojs) {
		   physicsObject = Box2DPhysicsObject(oj);
		   oldSimulationEnabled = physicsObject.simulationEnabled;
		   objectCount++;
		   newSimulationEnabled = (d(physicsObject.x, physicsObject.y, heroX, heroY) < 600) ? true : false;
		   physicsObject.simulationEnabled = newSimulationEnabled;
		   if (oldSimulationEnabled != newSimulationEnabled) {
		   physicsObject.updateSimulationEnabledStatus();
		   }
		 }*/
		
			//trace ("...Calculating Distance " + objectCount);
		} // end do distance calc
		
		private function d(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			var dx:Number = x1 - x2;
			var dy:Number = y1 - y2;
			var dist:Number = Math.sqrt(dx * dx + dy * dy);
			return dist;
		}
		
		override public function initialize():void
		{
			// is this called when???
			// loading level -- YES
			// restarting level after dying -- YES
			// is there a 3rd way to get into a level?
			
			//trace ("restarting or loading level"); // called when level is LOADED *** OR *** RESTARTED // ALevel: Get here on levelRestart or levelChange
			super.initialize();
			
			// [===============================] Get Level Data [=====================================]
			levelData 			= CitrusEngine.getInstance().levelManager.levels; // array for all level data from MyGameData
			this.levelIndex 	= CitrusEngine.getInstance().levelManager.currentIndex; // level index from array
			this.levelName 		= levelData[this.levelIndex][3]; // [3] --> level name STRING
			this.levelBounds 	= levelData[this.levelIndex][2]; // [2] --> bounds RECT
			currentLevelData 	= levelData[this.levelIndex]; // access this anywhere to get the level data before camera is initialized!
			
			GameRegistry.levelReadyToPlay = false;
			ParticleManager.getInstance().initParticleSystems();
			instance = this;
			initLevelStarted.dispatch();
			var box2d:Box2D = box2dReference = new Box2D("Box2D");
			
			//[[[[ ===================================  SHOW DEBUG ART ===========]]]
			box2d.visible = GameRegistry.showBox2DDebugArt = false;
			//[[[[ ==================================== SHOW DEBUG ART ===========]]]
			
			add(box2d);
			initRotation(); // make sure level and Enemy's static rotation is zero'd out
			restartingLevel = false; // make sure level can be restarted again after a death
			
			// [=====================] Add Mask & Loading Progress [=====================]
			_maskDuringLoading = new Quad(stage.stageWidth, stage.stageHeight);
			_maskDuringLoading.color = 0x000000;
			_maskDuringLoading.x = (stage.stageWidth - _maskDuringLoading.width) / 2;
			_maskDuringLoading.y = (stage.stageHeight - _maskDuringLoading.height) / 2;
			addChild(_maskDuringLoading);
			
			// create a textfield to show the loading %
			_percentTF = new TextField(400, 200, "", "SourceSansProSemibold");
			_percentTF.fontSize = 36;
			_percentTF.color = 0xFFFFFF;
			_percentTF.autoScale = true;
			_percentTF.x = (stage.stageWidth - _percentTF.width) / 2;
			_percentTF.y = (stage.stageHeight - _percentTF.height) / 2;
			addChild(_percentTF);
			
			// when the loading is completed...
			view.loadManager.onLoadComplete.addOnce(_handleLoadComplete);
			
			// [=====================] Add GameMenu [=====================]
			gameMenu = GameMenu.instance;
			addChild(gameMenu);
			gameMenu.hideMenu();
			
			if (GameRegistry.forReleaseMode)
				gameMenu.visible = false;
			
			if (GameRegistry.gameMenuHasBeenSetUp == false)
			{ // do this set up only once //gameMenu.visible = true;
				gameMenu.setContentPosition(50, 50);
				gameMenu.setMenuButtonPosition(50, 0);
				gameMenu.registerSettingChangedSignal(GameSettingsManager.instance.outgoingSettingChangeSignal);
				GameSettingsManager.instance.registerSettingChangedSignal(gameMenu.settingChanged);
				GameSettingsManager.instance.readSettingsFromDisk();
				GameRegistry.gameMenuHasBeenSetUp = true;
			}
			
			// [=====================] Create Level Objects from SWF [=====================]
			ObjectMakerStarling.FromMovieClip(_level, gm.levelArtTextureAtlas, true, levelHasBeenRestarted);
			
			// [=====================] Do GameArt Management [=====================]
			LevelArtManager.setUpArt(this);
			LevelPhysicsManager.setUpPhysics(this);
			
			// [=====================] Set Art on Hero [=====================]
			
			_hero = Hero(getFirstObjectByType(Hero));
			_hero.view = new AnimationSequence(gm.heroArtTextureAtlas, ["run", "duck", "idle", "jump", "hurt", "climb", "swim", "float", "hang", "attack", "death", "airborne"], "idle", 21, false, "none", [20, // run
				04, // duck
				04, // idle
				12, // jump
				12, // hurt
				19, // climb
				11, // swim
				06, // float
				04, // hang
				16, // attack
				10, // die (the new one)
				12 // airborne (same frames as jump without the "step off 2 frame"
				]); // was 11 on 2/2/14 -- probably 21 or 22 for new hero
			StarlingArt.setLoopAnimations(["walk", "climb", "swim", "run", "idle", "hang", "float", "trem", "airborne", "duck"]);
			
			_hero.viewA = _hero.view;
			_hero = Hero(getFirstObjectByType(Hero));
			_hero.viewB = new AnimationSequence(gm.heroA_ArtTextureAtlas, ["run", "duck", "idle", "jump", "hurt", "climb", "swim", "float", "hang", "attack", "death", "airborne"], "idle", 21, false, "none", [20, // run
				04, // duck
				04, // idle
				12, // jump
				12, // hurt
				19, // climb
				11, // swim
				06, // float
				04, // hang
				16, // attack
				10, // die (the new one)
				12 // airborne (same frames as jump without the "step off 2 frame"
				]); // was 11 on 2/2/14 -- probably 21 or 22 for new hero
			StarlingArt.setLoopAnimations(["walk", "climb", "swim", "run", "idle", "hang", "float", "trem", "airborne", "duck"]);
			
			// [===============================] Set Gravity [=====================================]
			gravity = new b2Vec2(0, 5.82); // been using 6.2 for a while. //5.05 to match mario 9:21 pm
			box2d.gravity = gravity;
			
			// [===============================] Add HUDs [=====================================]
			_ce.addChild(GameHUD.getInstance()); // add classic display list HUD
			var starlingGameHUD:StarlingGameHUD = StarlingGameHUD.getInstance(); // add starling HUD
			this.addChild(starlingGameHUD);
			
			// [===============================] Growl Debug Message [=====================================]
			//starlingGameHUD.growl("Stage size=" + this.stage.stageWidth + "," + this.stage.stageHeight + "\n" + "ALevel.as: " + Starling.current.context.driverInfo  + ",StarlingErrorCheck=" + Starling.current.context.enableErrorChecking);
			
			// [===============================] Start Music & Get Sound Manager [=====================================]
			sound = GameSoundManager.getInstance();
			sound.playMusic(levelIndex); // music starts playing before level load complete
			
			// [=============] Set up Level Interaction Manager (non essential level interaction) [==================]
			// [==========] At this point, hero, GameHud, etc.. have already been created
			levelInteractionManager = new LevelInteractionManager(this, _hero, levelStatsManager);
			
			// [====================] 		Add Essential Level Interaction 	[==============================]
			// [====================] 		EndLevel, isDeath, RotationBlocks 	[==============================]
			var endLevel:Sensor = Sensor(getObjectByName("endLevel"));
			if (endLevel != null)
				endLevel.onBeginContact.add(handleEndLevelSensor); // don't addOnce dummy. other non-hero objects could touch it!
			
			var sensors:Vector.<CitrusObject> = getObjectsByType(Sensor);
			var sensor:Sensor
			for each (sensor in sensors)
			{
				if (sensor.isDeath)
					sensor.onBeginPhysicsCollision.add(handleKillUnit); // selectively kills objects, heros, balls, etc...
				if (sensor.isRotation)
					sensor.onBeginPhysicsCollision.add(handleRotationSensor); // large area sensors that force rotation
				if (sensor.isBallDeath)
					sensor.onBeginPhysicsCollision.add(handleKillBall); // this type kills only balls, not hero
			}
			
			var rotationBlocks:Vector.<CitrusObject> = getObjectsByType(RotationBlock);
			for each (var rotationBlock:RotationBlock in rotationBlocks)
				rotationBlock.onSwitch.add(onRotationBlockContact);
			
			// [===============================] Create & Set up Camera [=====================================]
			zoomFactor = 2.0;
			camera = StarlingCamera(view.camera);
			CameraManager.getInstance().camera = camera;
			camera.allowZoom = true;
			camera.allowRotation = true;
			camera.zoomEasing = 1; // would look nice if there wasn't an initial zoom...
			camera.rotationEasing = 0.07; // 10.12.13 was 0.054;
			camera.zoom(zoomFactor);
			
			// [===============================] Set up CAMERA based on Level Data [=====================================]
			
			var cameraMovementEasing:MathVector = new MathVector(GameProperties.cameraEasingX, GameProperties.cameraEasingY);
			var cameraLevelBounds:Rectangle = currentLevelData[2]; // [2] is lens data. format is new Rectangle( -1000, -1000, 3500, 3048);
			var cameraOffset:MathVector = new MathVector(stage.stageWidth / 2, stage.stageHeight / 2 - 32);
			view.camera.setUp(_hero, cameraOffset, cameraLevelBounds, cameraMovementEasing);
			
			Starling.current.stage.addEventListener(ResizeEvent.RESIZE, resizeHandler);
			
			resizeHandler(); // call this once to make sure Starling.contentScaleFactor is factored in
			
			// [===============================] Add ENVIRONMENTAL FX!! (under the hud??) [==============================]
			levelEnvironmentManager = new LevelEnvironmentManager(camera.viewRoot, this.levelBounds, this.levelIndex);
			
			// [===============================] Add KB & Mouse Listeners [=====================================]
			Main.stageRef.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			Main.stageRef.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Main.stageRef.addEventListener(KeyboardEvent.KEY_DOWN, onKeyUp);
			
			// [===============================] Level is pretty much complete loading! :) [=====================================]
			initLevelComplete.dispatch();
			Hero.getInstance().controlsEnabled = true;
			
			// [===============================] Do some optimization [=====================================]
			// [===============================] This actually needs to be moved to when all Art is created... [=====================================]
			var art:StarlingArt;
			var oj:CitrusObject;
			
			var ojs:Vector.<CitrusObject> = getObjectsByType(Coin);
			for each (oj in ojs)
			{
				art = StarlingArt(_ce.state.view.getArt(oj));
				art.updateArtEnabled = false;
			}
			
			ojs = getObjectsByType(CitrusSprite);
			for each (oj in ojs)
			{
				art = StarlingArt(_ce.state.view.getArt(oj));
				art.updateArtEnabled = true; // 2/23/14 NO IDEA WHAT THIS DOES????? commenting it out does nothing? didnt test much
					//trace ("found a CE SPRITE");
			}
			
			// [===============================] Start the Distance Timer [=====================================]
			distanceTimer.addEventListener(TimerEvent.TIMER, doDistanceCalculation);
			distanceTimer.start();
		
			//this.filter = new SpotlightFilter(500,500, 1, 0.5, 0.15, false);
			//this.filter = new FlashlightFilter(500, 500, 25);
		
		} // end public function initialize()
		
		private function resizeHandler(e:ResizeEvent = null):void
		{
			view.camera.cameraLensWidth = Main.stageRef.stageWidth / Starling.contentScaleFactor; // this was dirty dog. got this from comment OMG fixes everything!
			view.camera.cameraLensHeight = Main.stageRef.stageHeight / Starling.contentScaleFactor; // dirty dog this was it!! YES!
		}
		
		private function initRotation():void
		{
			worldRotationInDegrees = 0;
			Enemy.worldRotation = 0; // get rid of this here & in Enemy!
			GameRegistry.worldRotation = worldRotationInDegrees;
		}
		
		/*private function levelWarpHandler(level:int):void {
		   CitrusEngine.getInstance().levelManager.gotoLevel(level+1);
		 }*/
		
		// [============================] Handlers and more [==================================]
		private function onRotationBlockContact(o:RotationBlock):void
		{
			setWorldRotation(o.rotationAngle);
			sound.rotate();
		}
		
		private function onKeyUp(e:KeyboardEvent):void
		{
			if (!allowDebugStuff)
				return;
			if (GameRegistry.forReleaseMode)
				GameRegistry.allowRotation = false;
			if (e.keyCode == 90 && GameRegistry.debugMode && GameRegistry.allowRotation)
			{
				rotateWorld(-90);
			}
			else if (e.keyCode == 88 && GameRegistry.debugMode && GameRegistry.allowRotation)
			{
				rotateWorld(90);
			}
			else if (e.keyCode == 65 && GameRegistry.debugMode && GameRegistry.allowRotation)
			{
				rotateWorld(180);
			}
			else if (e.keyCode == 27)
			{ // ESC
				/*if (gameMenu) gameMenu.toggleMenuVisibility();
				 if (Main.mainRef.levelSelect) Main.mainRef.levelSelect.toggleActive(); // hack*/
			}
		}
		
		private function setWorldRotation(targetAngle:int):void
		{
			if (targetAngle == worldRotationInDegrees)
				return;
			if (worldRotationInDegrees == 270 && targetAngle == 0)
				rotateWorld(90);
			if (worldRotationInDegrees == 0 && targetAngle == 270)
				rotateWorld(-90);
			else
				rotateWorld(targetAngle - worldRotationInDegrees);
		}
		
		private function rotateWorld(rotationDirection:int = 90):void
		{
			if (rotationDirection == -90)
				worldRotationInDegrees -= 90;
			if (rotationDirection == 90)
				worldRotationInDegrees += 90;
			if (rotationDirection == 180)
				worldRotationInDegrees += 180;
			if (rotationDirection == -180)
				worldRotationInDegrees -= 180;
			worldRotationInDegrees = (worldRotationInDegrees + 360) % 360;
			var worldRotationInRadians:Number = worldRotationInDegrees / 180 * Math.PI;
			var rotationInterval:Number = rotationDirection / 180 * Math.PI;
			camera.rotate(rotationInterval); // comment this out to have camera not follow rotation!
			var newGravity:b2Vec2 = gravity.clone();
			newGravity = newGravity.rotate(-worldRotationInRadians); // rotate the gravity
			_hero.setHeroRotation(-worldRotationInRadians);
			Enemy.worldRotation = worldRotationInDegrees;
			GameRegistry.worldRotation = worldRotationInDegrees;
			box2dReference.gravity = newGravity;
		}
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			if (e.shiftKey && e.keyCode == 69)
			{ // SHIFT+E (couldn't get CTRL or ALT modifiers working...)
				GameHUD.getInstance().debugMode = !GameHUD.getInstance().debugMode;
			}
		}
		
		private function onMouseWheel(e:MouseEvent):void
		{
			if (!allowDebugStuff)
				return;
			var zoomStep:Number = 0.15;
			zoomFactor += (e.delta > 0) ? zoomStep : -zoomStep;
			if (zoomFactor < 0.1)
				zoomFactor = 0.1;
			camera.setZoom(zoomFactor);
			//camera.setZoom = zoomFactor;
		}
		
		protected function handleKillUnit(o:IBox2DPhysicsObject, s:Sensor):void
		{
			if (o is Hero)
				this.killHero();
			else if (!s.isDeathForHeroOnly)
			{ // Some death is for hero only, and doesn't kill crates (so crates can stack on death sensor for safe passage)
				if (o is Enemy)
					Enemy(o).kill = true;
				if (o is Crate)
					Crate(o).explode(); // Covers crate, ball, but not bullet.
			}
		}
		
		protected function handleKillBall(o:IBox2DPhysicsObject, s:Sensor):void
		{
			if (o is Ball)
				Ball(o).explode(); // HACK THIS FUNCTION PICKS UP ENEMIES, BALLS, ETC...
			if (o is ChompRock)
				ChompRock(o).explode();
		}
		
		protected function handleRotationSensor(o:IBox2DPhysicsObject, s:Sensor):void
		{
			if (o is Hero)
			{
				var angle:int = s.rotationAngle;
				setWorldRotation(angle);
			}
		}
		
		public function killHero():void
		{
			if (!restartingLevel)
			{
				_hero.killHero();
				sound.playSound("heroDeath", 0.3);
				sound.stopMusic();
				prepareToRestartLevel();
			}
		}
		
		protected function prepareToRestartLevel():void
		{
			CarSoundGenerator.getInstance().stop();
			if (!restartingLevel)
				Actuate.timer(1).onComplete(doRestartLevel);
			_hero.controlsEnabled = false;
			worldRotationInDegrees = 0; // important becaz if he gets killed rotated, you wont be able to rotate again!
			restartingLevel = true;
		}
		
		protected function doRestartLevel():void
		{
			//restartingLevel = false;
			levelHasBeenRestarted = true;
			distanceTimer.stop();
			
			restartLevel.dispatch();
		}
		
		protected function handleEndLevelSensor(contact:b2Contact):void
		{
			if (endLevelTriggered)
				return; // prevent redundant triggers. 
			/// TODO: you know, it would have made more sense to just remove the signal listener rather than add this bool :)
			if (Box2DUtils.CollisionGetOther(Sensor(getObjectByName("endLevel")), contact) is Hero)
			{
				endLevel();
			}
			distanceTimer.stop();
		}
		
		public function endLevel():void
		{
			if (endLevelTriggered)
				return; // prevent redundant triggers. 
			endLevelTriggered = true;
			levelCompleted.dispatch(); // 8/10/13 todo: WHY CALLING THIS SO EARLY?
			camera.zoomEasing = 0.01;
			camera.setZoom(0.8);
			Hero.getInstance().controlsEnabled = false;
			StarlingGameHUD.getInstance().statsScreenComplete.addOnce(handleStatsScreenComplete);
			sound.stopMusic();
			sound.tone2();
		}
		
		private function handleStatsScreenComplete():void
		{
			lvlEnded.dispatch();
			levelStatsManager.destroy();
			levelStatsManager = null;
		}
		
		protected function _handleLoadComplete():void
		{
			removeChild(_percentTF, true); // AS 4/19/2013, added 2nd param to dispose!
			removeChild(_maskDuringLoading, true); // AS 4/19/2013, added 2nd param to dispose!
			levelLoaded = true;
			GameRegistry.levelReadyToPlay = true;
			levelReadyToPlay.dispatch();
		
			//CarSoundGenerator.getInstance().start();
		
		/*if (!GameRegistry.soundsHaveBeenPreloaded) {
		   GameRegistry.soundsHaveBeenPreloaded = true;
		
		   trace ("ALevel.as: BIG DEAL >>> canceled preloading of sounds!!! was crashing SoundManager when starting level 11!!!");
		   //GameSoundManager.getInstance().preloadSounds();
		 }*/
		}
		
		override public function update(timeDelta:Number):void
		{
			super.update(timeDelta);
	
			if (levelLoaded) 
				return; // returns most of the time!
			var percent:uint = view.loadManager.bytesLoaded / view.loadManager.bytesTotal * 100;
			if (percent < 99)
				_percentTF.text = "Loading Level " + String(this.levelIndex) + " - " + percent.toString() + "%" + "\n" + this.levelName;
		}
		
		override public function destroy():void { // gets called on destruction AND <<< LEVEL RESTART >>>....
			if (levelInteractionManager != null) levelInteractionManager.destroy(); // important to destroy puzzles
			if (levelEnvironmentManager != null) levelEnvironmentManager.destroy();
				
			Main.stageRef.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			Main.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Main.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyUp);
			distanceTimer.removeEventListener(TimerEvent.TIMER, doDistanceCalculation);
			Starling.current.stage.removeEventListener(ResizeEvent.RESIZE, resizeHandler);
			super.destroy();
		}
	}
}
