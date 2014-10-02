package level {
	/**
	 * ...
	 * @author Alex
	 * 
	 * This class handles non-essential interactions, such as adding sound effects and making objects move.
	 * We know about the hero and operate directly from signals passed from platformer objects
	 * If this class does not add things, the game should continue to function but will be impossible to play because platforms will not move and objects will 
	 * not interact properly.
	 * 
	 * The idea is to be able to temporarily exclude this class for easier upgrading to future CitrusEngines
	 * 
	 */
	import Box2D.Common.Math.b2Vec2
	import citrus.objects.platformer.box2d.InteractiveGameObject;
	import flash.utils.Timer; 		// for respawn
	import flash.events.TimerEvent; // for respawn

	import citrus.physics.box2d.IBox2DPhysicsObject;
	import Box2D.Dynamics.Contacts.b2Contact;
	import citrus.physics.box2d.Box2DUtils;
	
	import citrus.objects.platformer.box2d.Launcher;
	import citrus.objects.platformer.box2d.Powerup;
	
	import citrus.core.IState
	import citrus.core.CitrusObject
	
	import citrus.objects.Box2DPhysicsObject
	import citrus.objects.platformer.box2d.Hero
	 
	import citrus.objects.platformer.box2d.Enemy

	import citrus.objects.platformer.box2d.Platform;
	import citrus.objects.platformer.box2d.Sensor;
	import citrus.objects.platformer.box2d.Coin;
	import citrus.objects.platformer.box2d.RewardBox;
	import citrus.objects.platformer.box2d.MovingPlatform;
	import citrus.objects.platformer.box2d.MusicCoin;
	import citrus.objects.platformer.box2d.MusicPuzzleRewardBox;
	import citrus.objects.platformer.box2d.MusicPuzzleArea;
	import citrus.objects.platformer.box2d.SonicCoin;
	import citrus.objects.platformer.box2d.IPickupObject;
	import citrus.objects.platformer.box2d.ACoin;
	import citrus.objects.platformer.box2d.Cannon;
	import citrus.objects.platformer.box2d.Crate;
	import citrus.objects.platformer.box2d.SwitchBlock;
	import citrus.objects.platformer.box2d.RotatingMovingPlatform;
	import citrus.objects.platformer.box2d.MovingPlatformElevator;
	import citrus.objects.platformer.box2d.ToneTrigger;
	import citrus.objects.platformer.box2d.SignPost;
	import citrus.objects.platformer.box2d.BreakablePlatform;
	import citrus.objects.platformer.box2d.Teleporter; // for adding spriteHoverIndicator to doors
	import citrus.objects.CitrusSpriteHoverIndicator;
	
	import game.CameraManager;
	import game.EmitterFactory;
	import game.ParticleManager;
	import game.MusicPuzzleMaker;
	import game.MusicPuzzle;
	import game.GameSoundManager;
	import game.GameRegistry;
	import game.GameHUD;
	import game.StarlingGameHUD;
	import pixelSphere.ALevel;
	
	public class LevelInteractionManager { // GET MY INSTANCE THROUGH ALEVEL....
		
		private var s:IState
		private var hero:Hero;
		private var hud:StarlingGameHUD; //reference to main HUD
		private var sound:GameSoundManager;
		private var stats:LevelStatsManager;
		private var respawnQueue:Array = [];
		private var respawnTimer:Timer;
		private var interactionHoverIndicator:CitrusSpriteHoverIndicator;
		
		public function LevelInteractionManager(stateRef:IState, heroRef:Hero, levelStatsManager:LevelStatsManager) {
			s 		= stateRef;
			hero 	= heroRef;
			hud		= StarlingGameHUD.getInstance();
			sound	= GameSoundManager.getInstance();
			stats 	= levelStatsManager;
			init();
		}
		
		public function addBaddyToRespawnQueue(baddy:Enemy):void {			
			respawnQueue.push(baddy);
		}
		
		private function respawnTimerHandler(e:TimerEvent):void {
			//trace ("respawn handler");
			for each (var baddy:Enemy in respawnQueue) {
				//trace(baddy.timeLeftBeforeRespawn--);
				if (baddy.timeLeftBeforeRespawn < 1) {
					addBaddyHandlers(baddy);
					LevelArtManager.getArtForBaddy(baddy);
					s.add(baddy);
					respawnQueue.splice(respawnQueue.indexOf(baddy), 1);
				}
			}
		}
		
		private function init():void {
			respawnTimer = new Timer(1000, 0);
			respawnTimer.addEventListener(TimerEvent.TIMER, respawnTimerHandler);
			respawnTimer.start();
			
			// [==================] Create HoverIndicators [====================]
			interactionHoverIndicator = new CitrusSpriteHoverIndicator("Hover Indicator For Doors etc...");
			
			// [==================] Restore All Health [====================]
			hud.restoreHealth();
			
			// [==================] Add handlers to Baddies [====================]
			var baddies:Vector.<CitrusObject> = s.getObjectsByType(Enemy);
			for each (var baddy:Enemy in baddies) {
				addBaddyHandlers(baddy);
			}
			// [==================] Add handlers to Cannons [====================]
			var cannons:Vector.<CitrusObject> = s.getObjectsByType(Cannon);
			for each (var cannon:Cannon in cannons) cannon.onFire.add(onFireCannon); // NICE! These events are cleaned up in Cannon.as!
			
			// [==================] Add handlers to SignPosts [====================]
			var signPosts:Vector.<CitrusObject> = s.getObjectsByType(SignPost);
			for each (var signPost:SignPost in signPosts) {
				signPost.onMessage.add(onSignPostMessage);
				//trace ("ADDED SIGNPOST LISTENR");
				if (signPost.isSecret) stats.addSecret();
				else  stats.addSignPost();
			}
			
			var breakablePlatforms:Vector.<CitrusObject> = s.getObjectsByType(BreakablePlatform);
			for each (var breakablePlatform:BreakablePlatform in breakablePlatforms) {
				breakablePlatform.onHeroContact.add(onBreakablePlatformBeginContact);
			}
			
		
			// [========================= Give Doors, etc.. a hover indicator =======================]
			var doors:Vector.<CitrusObject> = s.getObjectsByType(Teleporter);
			for each (var door:Teleporter in doors) {
				door.beginContactDoor.add(onDoorBeginContact);
				door.endContactDoor.add(onDoorEndContact);
			}
			
			var igos:Vector.<CitrusObject> = s.getObjectsByType(InteractiveGameObject);
			for each (var igo:InteractiveGameObject in igos) {
				igo.beginContactIGO.add(onIGOBeginContact);
				igo.endContactIGO.add(onIGOEndContact);
				
			}
			
			// [==================] Add handlers to Music Sensors[====================]
			var sensors:Vector.<CitrusObject> = s.getObjectsByType(Sensor);
			for each (var sensor:Sensor in sensors) {
				if (sensor.isTrigger) {
					sensor.onBeginContact.add(function(o:Object):void
					{
						//var p:Point;
						//var x:Number = e.other.GetBody().GetUserData().x;
						//var y:Number = e.other.GetBody().GetUserData().y;
						//EmitterFactory.emitParticles2(x, y, 3);
					});
				}
				
				if (sensor is ToneTrigger) {
					ToneTrigger(sensor).onTone.add(function(collider:IBox2DPhysicsObject, t:ToneTrigger):void
					{
						
						
						//trace (t.tone);
						//var other:Box2DPhysicsObject = Box2DPhysicsObject(ContactEvent(e).other.GetBody().GetUserData());
						//if (other is Hero) return;
						
							
						
						if (distanceToHero(collider.x, collider.y) < 410) {
							
							if (t.isNote) {
								if (t.patch == 0) {
									sound.playNote(t.tone);
								} else if (t.patch == 8) {
									sound.tone8Sequence();
								} else if (t.patch == 9) {
									sound.tone9();
								} else if (t.patch == 10) {
									sound.tone10();
								}  else if (t.patch == 11) {
									sound.tone11();
								} else if (t.patch == 12) {
									sound.tone12Sequence();
								} else if (t.patch == 13) {
									sound.tone13();
								} else if (t.patch == 14) {
									sound.tone7();
								} else if (t.patch == 15) {
									sound.tone15();
								} else if (t.patch == 16) {
									sound.tone16();
								} else if (t.patch == 17) {
									sound.tone17();
								} else if (t.patch == 99) {
									sound.musicBox();
								}
								
								
							}
							else if (!t.isToneSequence) {
								switch(t.tone) {
									case 0:
										sound.tone0();
										break;
									case 1:
										sound.tone();
										break;
									case 2:
										sound.tone2();
										break;
									case 3:
										sound.tone3();
										break;
									case 4:
										sound.tone4();
										break;
									case 5:
										sound.tone5();
										break;
									case 6:
										sound.tone6();
										break;
									case 7:
										sound.tone7();
										break;
									default:
										//trace ("Level Interaction Manager.as: tone not found!");
								}
							} else {
								sound.sequence(t.toneIndex);
								ParticleManager.getInstance().addParticles("blue", t.x, t.y);
							}
							
							var points:int = 10;
							stats.collect(LevelGameObject.SCORE, points);
							//EmitterFactory.emitScore(collider.x - collider.width/2, collider.y - collider.height/2, points);
						}
					});
				}
				
				
				/*if (sensor is Launcher) {
					sensor.onBeginContact.add(function(e:ContactEvent):void
					{
						var other:Box2DPhysicsObject = Box2DPhysicsObject(ContactEvent(e).other.GetBody().GetUserData());
						if (distanceToHero(other.x, other.y) < 800) {
							GameSoundManager.getInstance().tone2();
							var points:int = 10;
							GameRegistry.score += points;
							EmitterFactory.emitScore(other.x - other.width/2, other.y - other.height/2, points);
						}
					});
				}*/
				
				
			} // end for each sensor
			
			
			// [===============================] Handle SoundFX on Hero events [=====================================]
			//hero.onJump.add(sound.jump);
			
			hero.onTakeDamage.add(function():void
				{
					sound.hurt();
					hurtHero();
				});
			hero.onBreachWater.add(sound.splash);
			
			
			hero.onSpring.add(sound.spring);
			
			// [===============================] Platforms [=====================================]
			var platforms:Vector.<CitrusObject> = s.getObjectsByType(Platform);
			for each (var platform:Platform in platforms) {
				if (platform.isTrigger) {
					platform.onTriggered.add(onObjectInteraction);
				}
			}
			
			// [===============================] Add listeners to CE objects [=====================================]
			var switchBlocks:Vector.<CitrusObject> = s.getObjectsByType(SwitchBlock);
			for each (var switchBlock:SwitchBlock in switchBlocks) {
				switchBlock.onSwitch.add(onObjectInteraction);
			}
			
			var gameObjects:Vector.<CitrusObject>;
			
			// AS: Add listeners on all the MusicCoins (using add once)
			var mcs:Vector.<CitrusObject> = s.getObjectsByType(MusicCoin);
			for each (var mc:MusicCoin in mcs)
				mc.onCollected.addOnce(onObjectInteraction);
			
			// Add listeners to all IPickupObject objects (using add once since IPickupObject's can only be collected once)
			gameObjects = s.getObjectsByType(IPickupObject);
			for each (var ipo:IPickupObject in gameObjects) {
				ipo.onCollectSignal.addOnce(onObjectInteraction);
				stats.addPickupItem(ipo);
			}
			
			/**
			 * Add all MusicPuzzleRewardBoxes to create puzzles from them
			 * then add the puzzleHitAreas to reveal the puzzle when you get near it.
			 */
			
			MusicPuzzleMaker.init();
			var mpbs:Vector.<CitrusObject> = s.getObjectsByType(MusicPuzzleRewardBox);
			for each (var mpb:MusicPuzzleRewardBox in mpbs) {
				MusicPuzzleMaker.addPuzzleObject(mpb);
				mpb.onSuccess.addOnce(onObjectInteraction);
			}
			MusicPuzzleMaker.renderPuzzles(); // when all objects have been added to the puzzles, render them
			
			var musicPuzzleHitAreas:Vector.<CitrusObject> = s.getObjectsByType(MusicPuzzleArea);
			for each (var mpa:MusicPuzzleArea in musicPuzzleHitAreas)
			{
				MusicPuzzleMaker.addMusicPuzzleArea(mpa); // trace ("ALevel.as: Added a MusicPuzzleArea");
			}
			
			for each (var mpuz:MusicPuzzle in MusicPuzzleMaker.puzzles)
			{
				mpuz.onSolved.addOnce(onMusicPuzzleSolved);
			}
		} // end init
		
		
		// ===================================== HANDLE DOOR CONTACTS ====================================
		private function onDoorEndContact(c:Box2DPhysicsObject):void {
			interactionHoverIndicator.fadeOut();
		}
		
		private function onDoorBeginContact(c:Box2DPhysicsObject):void {
			interactionHoverIndicator.fadeIn();
			interactionHoverIndicator.x = c.x - 12	;
			interactionHoverIndicator.y = c.y - (c.height + c.height / 2);
			interactionHoverIndicator.updateAnimationPosition();
		}
		
		
		// ===================================== HANDLE InteractiveGameObject CONTACTS ====================================
		private function onIGOEndContact(c:Box2DPhysicsObject):void {
			interactionHoverIndicator.fadeOut();
		}
		
		private function onIGOBeginContact(c:Box2DPhysicsObject):void {
			interactionHoverIndicator.fadeIn();
			interactionHoverIndicator.x = c.x - 12	;
			interactionHoverIndicator.y = c.y - (c.height + c.height / 2) - 36;
			interactionHoverIndicator.updateAnimationPosition();
		}
		
		
		
		// ===================================== ADD BADDY CONTACTS ====================================
		private function addBaddyHandlers(baddy:Enemy):void {
				if (baddy.enemyType == "fish") 			baddy.onHurt.add(baddyFishOnHurt);
				if (baddy.enemyType == "yellowFish") 	baddy.onKill.add(baddyFishOnHurt);
				if (baddy.enemyType == "yellowFish") 	baddy.onHurt.add(baddyFishOnHurt);
				if (baddy.enemyType == "yellowFish") 	baddy.onKill.add(baddyFishOnHurt);
				
				if (baddy.enemyType == "alien") 		baddy.onKill.add(baddyAlienOnKill);
				
				if (baddy.enemyType == "ladybug") 		baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "ladybug") 		baddy.onHurt.add(baddyOnHurt);
				
				
				if (baddy.enemyType == "ladyBeetle") 	baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "greenLizard") 	baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "bee") 			baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "fly") 			baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "beetle") 		baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "redBeetle") 	baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "purpleBeetle") 	baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "treeGoblin") 	baddy.onKill.add(baddyOnKill);
				if (baddy.enemyType == "turtleLarge") 	baddy.onKill.add(baddyOnKill);
				
				if (baddy.enemyType == "snail") 		baddy.onHurt.add(baddyOnHurt);
				if (baddy.enemyType == "snail") 		baddy.onKill.add(baddyOnKill);
				
				if (baddy.enemyType == "turtle") 		baddy.onHurt.add(baddyTurtleOnHurt);
				if (baddy.enemyType == "turtle") 		baddy.onKill.add(baddyTurtleOnKill);
				if (baddy.enemyType == "turtleSmall") 	baddy.onHurt.add(baddyTurtleOnHurt);
				if (baddy.enemyType == "turtleSmall") 	baddy.onKill.add(baddyTurtleOnKill);
			
		}
		
		private function onBreakablePlatformBeginContact(bp:BreakablePlatform):void {
			var po:Box2DPhysicsObject = Box2DPhysicsObject(bp);
			if (bp.isDoor) {
				var canOpenThisDoor:Boolean;
				
				switch (bp.color) {
					case "red":
						canOpenThisDoor = stats.collect(LevelGameObject.KEY_RED, -1);
						ParticleManager.getInstance().addParticles("redSquares", po.x, po.y);
						break;
						
					case "yellow":
						canOpenThisDoor = stats.collect(LevelGameObject.KEY_YELLOW, -1);
						break;
				}
				
				if (canOpenThisDoor) {
					sound.randomArp();
					bp.explode();
				}
				
			} // end isDoor
			
			
		}
		
		
		private function onMusicPuzzleSolved(bonusScore:int):void {
			if (bonusScore > 0){
				EmitterFactory.emitTimeBonus(hero.x, hero.y, bonusScore); // puzzle solved in time + bonus
				stats.collect(LevelGameObject.SCORE, bonusScore);
			} else {
				EmitterFactory.emitScore(hero.x, hero.y - 5, 1000); // puzzle not solved within time
				stats.collect(LevelGameObject.SCORE, 1000);
			}
		}
		
		// [===============================] onObjectInteraction [=====================================]
		// handle signals for various objects. Note that if objects inherit from the same parent
		// then case the subclass first (for example if SwitchBlock else if MusicPuzzleRewardBox)
		protected function onObjectInteraction(o:Box2DPhysicsObject, targetID:int = 0):void
		{ 
			if (o is SwitchBlock) {
				//trace("ALevel.as: hit a switchblock!");
				sound.switchBlock();
				var movingPlatforms:Vector.<CitrusObject> = s.getObjectsByType(MovingPlatform);
				
				var colorsToEnable:Array 	= SwitchBlock(o).colorsToEnable;
				var colorsToDisable:Array 	= SwitchBlock(o).colorsToDisable;
				var thisSwitchBlock:SwitchBlock = SwitchBlock(o);
				
				var color:String = "unknown color";
				
				for each (var movingplatform:MovingPlatform in movingPlatforms)
				{
					for each (color in colorsToEnable) {
						if (movingplatform.color == color) {
							if (thisSwitchBlock.targetID == movingplatform.targetID) {
								movingplatform.enabled = true;
							}
						}
					}
					
					for each (color in colorsToDisable) {
						if (movingplatform.color == color) {
							if (thisSwitchBlock.targetID == movingplatform.targetID) {
								movingplatform.enabled = false;
							}
						}
					}
				}
				
				// reset other switch blocks --- doesn't work very well and is confusing
				/*var switchBlocks:Vector.<CitrusObject> = getObjectsByType(SwitchBlock);
				for each (var switchBlock:SwitchBlock in switchBlocks) {
					if (switchBlock != o) switchBlock.setColor(colorsToEnable[0]);
				}*/
				
			} else if (o is MusicPuzzleRewardBox) //used a MusicPuzzleRewardBox and got the correct note
			{
				//trace ("ALevel.as: you used a MusicPuzzleRewardBox and got the correct note");
				EmitterFactory.emitParticles2(o.x, o.y, 3);
				EmitterFactory.emitScore(o.x, o.y - o.height, 25);
				stats.collect(LevelGameObject.SCORE, 25);
			} else if (o is Platform) {
				trace ("LevelInteractionManager: got id " + Platform(o).targetID);
				movingPlatforms = s.getObjectsByType(MovingPlatform);
				
				for each (movingplatform in movingPlatforms)
				{
					if (Platform(o).targetID == movingplatform.targetID) {
						movingplatform.enabled = true; // should be ITriggerable. we'll trigger more things here like other objectspawners
					}
				}
				
				
			}
			
			
			if (o is IPickupObject) {
				//trace ("ALevel.as: you picked up an IPickupObject");
				var ipo:IPickupObject = IPickupObject(o); // cast to IPickupObject to access sound and points value
				var po:Box2DPhysicsObject = Box2DPhysicsObject(o); // cast to PhysicsObject to access x and y coordinates
				
				// add points
				stats.collect(LevelGameObject.SCORE, ipo.pointsValue);
				
				EmitterFactory.emitScore(po.x, po.y - po.height, ipo.pointsValue);
				// create emitter. These emitters are set to clean up after themselves
				if (o is SonicCoin) {
					EmitterFactory.emitParticles1(po.x, po.y, 6);
					switch (SonicCoin(o).sound) {
						case "red": 
							//sound.coin1();
							//sound.sfx();
							trace (ALevel.instance.levelIndex);
							if (ALevel.instance.levelIndex == 22) {
								sound.sfx();
							} else if (ALevel.instance.levelIndex == 21) {
								sound.playToneB(po.x, po.y);
							} else {
								sound.coin();
							}
							
							
							
							stats.collect(LevelGameObject.GEM_RED);
							ParticleManager.getInstance().addParticles("red", po.x, po.y);
							ParticleManager.getInstance().addParticles("glow", po.x, po.y);
							break;
						case "blue": 
							//sound.coin1();
							sound.tone2();
							stats.collect(LevelGameObject.GEM_BLUE);
							ParticleManager.getInstance().addParticles("glow1", po.x, po.y);
							break;
						case "yellow": 
							sound.tone3();
							stats.collect(LevelGameObject.GEM_YELLOW);
							ParticleManager.getInstance().addParticles("glow1", po.x, po.y);
							break;
						case "ring": 
							sound.tone0();
							stats.collect(LevelGameObject.GEM_GREEN);
							ParticleManager.getInstance().addParticles("glow1", po.x, po.y);
							break;
						default: // case for older levels SonicCoin's which did not have a 'sound' property.
							sound.coin();
							stats.collect(LevelGameObject.GEM_GREEN);
							ParticleManager.getInstance().addParticles("glow1", po.x, po.y);
					}
					stats.collect(LevelGameObject.GEM_ANY); // counts all gems
				} // end o is SonicCoin
				
				else if (o is MusicCoin) {
					EmitterFactory.emitParticles(po.x, po.y + 10, 6);
					ParticleManager.getInstance().addParticles("glow1", po.x, po.y);
					stats.collect(LevelGameObject.MUSIC_BOX);
				} // end o is MusicCoin
				
				else if (o is Powerup) {
					switch (Powerup(o).powerupType) {
						case "heart":
							EmitterFactory.emitParticles(po.x, po.y + 10, 6);
							sound.tone3();
							stats.collect(LevelGameObject.HEART);
							ParticleManager.getInstance().addParticles("glow1", po.x, po.y+20);
							hud.changeHealthBy(20);
							break;
						case "bullets":
							sound.tone3();
							ParticleManager.getInstance().addParticles("glow1", po.x, po.y+20);
							stats.collect(LevelGameObject.BULLET, 3);
							break;
						case "key_yellow":
							EmitterFactory.emitParticles(po.x, po.y + 10, 6);
							sound.randomArp();
							stats.collect(LevelGameObject.KEY_YELLOW);
							ParticleManager.getInstance().addParticles("flame", po.x, po.y+17);
							break;
						case "key_red":
							EmitterFactory.emitParticles(po.x, po.y + 10, 6);
							sound.randomArp();
							stats.collect(LevelGameObject.KEY_RED);
							ParticleManager.getInstance().addParticles("flame", po.x, po.y+17);
							break;
						default:
							//trace ("LevelInteractionManager.as: Invalid Powerup!"); // NO TRACE...CAUSES STACK UNDERFLOW :)
					}
				}
			}
		}
		
		
		
		
		// [==================] Functions to handle interactions [====================]
		
		private function baddyOnHurt(x:Number, y:Number):void { // generic baddy HURT
			sound.tone9();
			trace ("LEVELINTERACTIONMANAGER: baddy hurt!")
		}
		
		private function baddyOnKill(x:Number, y:Number):void { // generic baddy KILL
			sound.tone3();
			stats.collect(LevelGameObject.SCORE, 50);
			stats.collect(LevelGameObject.BADDY_KILL);
			EmitterFactory.emitScore(hero.x, hero.y, 50);
			ParticleManager.getInstance().addParticles("squares", x, y + 40);
		}
		
			private function baddyOnKillAlt(x:Number, y:Number):void { // generic baddy
			sound.tone3();
			sound.tone2();
			stats.collect(LevelGameObject.SCORE, 50);
			stats.collect(LevelGameObject.BADDY_KILL);
			EmitterFactory.emitScore(hero.x, hero.y, 50);
			ParticleManager.getInstance().addParticles("squares", x, y + 40);
		}
		
		private function baddyAlienOnKill(x:Number, y:Number):void {
			//sound.tone0();
			sound.randomArp();
			EmitterFactory.emitScore(hero.x, hero.y, 500);
			stats.collect(LevelGameObject.BADDY_KILL);
			ParticleManager.getInstance().addParticles("squares", x, y + 35);
		}
		
		private function baddyTurtleOnHurt(x:Number, y:Number):void {
			sound.tone5();
			stats.collect(LevelGameObject.SCORE, 100);
			EmitterFactory.emitScore(hero.x, hero.y, 100);
		}
		
		private function baddyTurtleOnKill(x:Number, y:Number):void {
			sound.tone6();
			stats.collect(LevelGameObject.SCORE, 500);
			stats.collect(LevelGameObject.BADDY_KILL);
			EmitterFactory.emitScore(hero.x, hero.y, 500);
		}
		
		private function baddyFishOnHurt(x:Number, y:Number):void {
			sound.tone5();
			stats.collect(LevelGameObject.SCORE, 1000);
			stats.collect(LevelGameObject.BADDY_KILL);
			EmitterFactory.emitScore(hero.x, hero.y, 1000); // bug -- should emit from the fish!
		}
		
		private function onFireCannon(o:Cannon):void {
			var dist:int = distance(o.x, o.y, hero.x, hero.y);
			if (dist < 400) {
				var volume:Number = 1 - (dist / 400) + 0.25;
				var normalVolume:Number = (volume < 1) ? volume : 1;
				sound.shoot(normalVolume);
			}
		}
		
		private function onSignPostMessage(s:String, hasBeenCollected:Boolean, isSecret:Boolean):void {
			// yeah this is triggered twice -- find out why probably in the sensor code
			if (!hasBeenCollected && !isSecret) { // first time hitting a soundpost
				stats.collect(LevelGameObject.SIGNPOST);
				sound.tone7Arp();
			} else if (!hasBeenCollected && isSecret) { // first time hitting a secret
				stats.collect(LevelGameObject.SECRET);
				sound.tone7();
			} else { // second time hitting a signpost
				sound.tone7Arp();
			}
		}
		
		private function distanceToHero(x:Number, y:Number):Number {
			return distance(x, y, hero.x, hero.y);
		}
		
		private function distance(x1:Number, y1:Number, x2:Number, y2:Number):Number {
			var dx:Number = x1 - x2;
			var dy:Number = y1 - y2;
			var dist:Number = Math.sqrt(dx * dx + dy * dy);
			return dist;
		}
		
		protected function hurtHero():void { // CALLED ON HERO SIGNAL, SO ANY PAIN WILL GET HERE.
			hud.changeHealthBy( -20);
			if (hud.health <= 0) ALevel.instance.killHero(); // killHero() already has protection for repeat calls
			CameraManager.getInstance().shake();
		}
		
		public function destroy():void {
			MusicPuzzleMaker.resetAll(); // reset the maker so you don't get puzzles from this level next time
			hero.onJump.removeAll();
			hero.onBreachWater.removeAll();
			stats = null;
			for each (var baddy:Enemy in respawnQueue) { // should cleanup stray baddies. i dont think they were added to the state yet. we'll see.
				baddy.kill = true;
			}
			respawnTimer.removeEventListener(TimerEvent.TIMER, respawnTimerHandler);
			respawnTimer.stop();
			
			
			//trace ("LEVELINTEACTIONMANAGER GETTING DESTROYED!");
		}
		
	}

}
