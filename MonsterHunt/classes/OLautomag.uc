class OLautomag expands UIweapons;

var() int hitdamage;
var float AltAccuracy;
var int ClipCount;
var int ClipCountCL, FiredSinceUpdate;
var const int slaveclipcount;	//Deprecated
var OLautomag slavemag;
var bool isslave;				//Name kept to preserve net compatibility
var bool bSetup;				// used for setting display properties
var bool bBringingUp;


replication
{
	reliable if ( bNetOwner && (Role == ROLE_Authority) )
		isslave, ClipCount, slaveclipcount, slavemag, bBringingUp;
}






simulated function int ClientClipCount()
{
	local int Delta;
	Delta = ClipCount - ClipCountCL;
	ClipCountCL = ClipCount;
	if ( Delta < 0 ) //Server added ammo to clip (reloaded?)
		FiredSinceUpdate = 0;
	else if ( Delta > 3 ) //Massive lag, do not simulate
		return ClipCount;
	else if ( Delta > 0 ) //Server substracted ammo to clip
		FiredSinceUpdate -= Delta;
	return ClipCountCL + FiredSinceUpdate;
}

function bool WeaponSet(Pawn Other)
{
	if ( isslave )
		return false;
	else
		Super.WeaponSet(Other);
}

function Destroyed()
{
	Super.Destroyed();
	if ( slavemag != None )
		slavemag.Destroy();
}

simulated function AnimEnd()
{
	if ( (Level.NetMode == NM_Client) && bBringingUp  && (Mesh != PickupViewMesh) )
	{
		bBringingUp = false;
		PlaySelect();
	}
	else
		Super.AnimEnd();
}

simulated function PlayPostSelect()
{
	bBringingUp = false;
	Super.PlayPostSelect();
}


function DropFrom(vector StartLocation)
{
	if ( !SetLocation(StartLocation) )
		return; 
	if ( slavemag != None )
		slavemag.Destroy();
	AIRating = Default.AIRating;
	slavemag = None;
	Super.DropFrom(StartLocation);
}

function SetDisplayProperties(ERenderStyle NewStyle, texture NewTexture, bool bLighting, bool bEnviroMap )
{
	if ( !bSetup )
	{
		bSetup = true;
		if ( slavemag != None )
			slavemag.SetDisplayProperties(NewStyle, NewTexture, bLighting, bEnviromap);
		bSetup = false;
	}			
	Super.SetDisplayProperties(NewStyle, NewTexture, bLighting, bEnviromap);
}

function SetDefaultDisplayProperties()
{
	if ( !bSetup )
	{
		bSetup = true;
		if ( slavemag != None )
			slavemag.SetDefaultDisplayProperties();
		bSetup = false;
	}			
	Super.SetDefaultDisplayProperties();
}

event float BotDesireability(Pawn Bot)
{
	local OLautomag AlreadyHas;
	local float desire;

	desire = MaxDesireability + Bot.AdjustDesireFor(self);
	AlreadyHas = OLautomag(Bot.FindInventoryType(class));
	if ( AlreadyHas != None )
	{
		if ( (!bHeldItem || bTossedOut) && bWeaponStay )
			return 0;
		if ( AlreadyHas.slavemag != None )
		{
			if ( (RespawnTime < 10)
				&& ( bHidden || (AlreadyHas.AmmoType == None)
					|| (AlreadyHas.AmmoType.AmmoAmount < AlreadyHas.AmmoType.MaxAmmo)) )
				return 0;
			if ( AlreadyHas.AmmoType == None )
				return 0.25 * desire;

			if ( AlreadyHas.AmmoType.AmmoAmount > 0 )
				return FMax( 0.25 * desire, 
						AlreadyHas.AmmoType.MaxDesireability
						 * FMin(1, 0.15 * AlreadyHas.AmmoType.MaxAmmo/AlreadyHas.AmmoType.AmmoAmount) ); 
		}
	}
	if ( (Bot.Weapon == None) || (Bot.Weapon.AIRating <= 0.4) )
		return 2*desire;

	return desire;
}

//Upgrade later
function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local shellcase s;
	local vector realLoc;

	realLoc = Owner.Location + CalcDrawOffset();
	s = Spawn(class'ShellCase',Pawn(Owner), '', realLoc + 20 * X + FireOffset.Y * Y + Z);
	if ( s != None )
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
	if (Other == Level) 
		Spawn(class'WallHitEffect',,, HitLocation+HitNormal*9, Rotator(HitNormal));
	else if ((Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if ( FRand() < 0.2 )
			X *= 5;
		Other.TakeDamage(HitDamage, Pawn(Owner), HitLocation, 3000.0*X, 'shot');
		if ( !Other.IsA('Pawn') && !Other.IsA('Carcass') )
			spawn(class'SpriteSmokePuff',,,HitLocation+HitNormal*9);
	}		
}

function bool HandlePickupQuery( inventory Item )
{
	local Pawn P;
	local Inventory Copy;

	if ( (Item.class == class) && (slavemag == None) ) 
	{
		P = Pawn(Owner);
		// spawn a double
		Copy = Spawn(class, P);
		Copy.BecomeItem();
//		ItemName = DoubleName;
		slavemag = OLautomag(Copy);

		//Ammo fix taken from LCWeapons
		slavemag.PickupAmmoCount = OLautomag(Item).PickupAmmoCount;
		slavemag.AmmoName = AmmoName;
		PickupAmmoCount = slavemag.PickupAmmoCount;

		SetTwoHands();
		AIRating = 0.4;
		slavemag.SetUpSlave( Pawn(Owner).Weapon == self );
		slavemag.SetDisplayProperties(Style, Texture, bUnlit, bMeshEnviromap);
		SetTwoHands();
		P.ReceiveLocalizedMessage( class'PickupMessagePlus', 0, None, None, Self.Class );
		Item.PlaySound(Item.PickupSound);
		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		Item.SetRespawn();
		return true;
	}
	return Super.HandlePickupQuery(Item);
}

function SetUpSlave(bool bBringUp)
{
	isslave = true;
//	ItemName = DoubleName;
	GiveAmmo(Pawn(Owner));
	AmbientGlow = 0;
	if ( bBringUp )
		BringUp();
	else
		GotoState('Idle2');
}

function SetTwoHands()
{
	if ( slavemag == None )
		return;

	if ( (PlayerPawn(Owner) != None) && (PlayerPawn(Owner).Handedness == 2) )
	{
		SetHand(2);
		return;
	}

	if ( Mesh == mesh'AutoMagL' )
		SetHand( 1);
	else
		SetHand(-1);
}

function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		bHideWeapon = true;
		Super.SetHand(Hand);
		return;
	}
	if ( slavemag != None )
	{
		if ( Hand == 0 )
			Hand = -1;
		slavemag.SetHand(-1 * Hand);
	}
	bHideWeapon = false;
	Super.SetHand(Hand);
	if ( Hand == 1 )
		Mesh = mesh'AutoMagL';
	else
		Mesh = mesh'AutoMagR';
}

simulated event RenderOverlays(canvas Canvas)
{
	local PlayerPawn PlayerOwner;
	local int realhand;

	PlayerOwner = PlayerPawn(Owner);
	if ( PlayerOwner != None )
	{
		if ( PlayerOwner.DesiredFOV != PlayerOwner.DefaultFOV )
			return;
		realhand = PlayerOwner.Handedness;
		if (  (Level.NetMode == NM_Client) && (realHand == 2) )
		{
			bHideWeapon = true;
			return;
		}
		if ( !bHideWeapon )
		{
			if ( Mesh == mesh'AutoML' )
				PlayerOwner.Handedness = 1;
			else if ( isslave || (slavemag != None) )
				PlayerOwner.Handedness = -1;
		}
	}
	if ( !bHideWeapon && ( (slavemag != None) || isslave ) )
	{
		Super.RenderOverlays(Canvas);
		if ( slavemag != None )
		{
			if ( slavemag.bBringingUp )
			{
				slavemag.bBringingUp = false;
				slavemag.PlaySelect();
			}
			slavemag.RenderOverlays(Canvas);
		}
	}
	else
		Super.RenderOverlays(Canvas);

	if ( PlayerOwner != None )
		PlayerOwner.Handedness = realhand;
}


function BringUp()
{
	if (slavemag != none ) 
	{
		SetTwoHands();
		slavemag.BringUp();
	}
	bBringingUp = true;
	Super.BringUp();
}

function TraceFire( float Accuracy )
{
	local vector RealOffset;

	RealOffset = FireOffset;
	FireOffset *= 0.35;
	if ( (slavemag != None) || isslave )
		Accuracy = FClamp(3*Accuracy,0.05,3); //Automag is more accurate than enforcer
	Super.TraceFire(Accuracy);
	FireOffset = RealOffset;
}


simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	if ( AnimSequence == 'Sway1' )
	{
		if ( FRand() < 0.1 )
			PlayAnim('Twirl',0.6,0.3);
		else
			PlayAnim('Twiddle',0.6,0.3);
	}
	else
	{
		LoopAnim('Sway1',0.02, 0.3);
		if ( (Level.NetMode == NM_Client) && (Pawn(Owner) != None) && (Pawn(Owner).Weapon == self) )
			GotoState('ClientIdleTemp');
	}
}

simulated function TweenToStill()
{
	if ( HasAnim('Still') )
		TweenAnim('Still', 0.1);
}

simulated state ClientIdleTemp
{
Begin:
	Sleep(3+FRand() );
	if ( FRand() < 0.5 )
		bAnimLoop = false;
	Goto('Begin');
}


state Idle
{
	event BeginState()
	{
		PlayIdleAnim();
	}
	
	function AnimEnd()
	{
		PlayIdleAnim();
	}

	function bool PutDown()
	{
		GotoState('DownWeapon');
		return True;
	}
	
Begin:
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	if ( Pawn(Owner).bFire!=0 ) Global.Fire(0.0);
	if ( Pawn(Owner).bAltFire!=0 ) Global.AltFire(0.0);
AnimTweak:
	Sleep(3+ FRand() );
	if ( FRand() < 0.5 )
		bAnimLoop = false;
	Goto('AnimTweak');
}


//==========================================
// NORMAL FIRE
//============

function Fire(float Value)
{
	if ( AmmoType == None )
		GiveAmmo(Pawn(Owner));
	if ( AmmoType.UseAmmo(1) )
	{
		GotoState('NormalFire');
		bCanClientFire = true;
		bPointing=True;
		ClientFire(value);
		if ( slavemag != None )
			Pawn(Owner).PlayRecoil(2 * FiringSpeed);
		else if ( !isslave )
			Pawn(Owner).PlayRecoil(FiringSpeed);
		TraceFire(0.0);
	}
}

simulated function PlayFiring()
{
	Owner.PlayOwnedSound(FireSound, SLOT_None,2.0*Pawn(Owner).SoundDampening);
	PlayAnim('Shoot0',0.26, 0.04);	
}

simulated function PlayFiringEnd()
{
	PlayAnim('Shoot2',0.8, 0.0);
}

state NormalFire
{
ignores Fire, AltFire, AnimEnd;

	function Timer()
	{
		if ( slavemag != none )
			slavemag.Fire(0);
	}

	function EndState()
	{
		Super.EndState();
		OldFlashCount = FlashCount;
	}

Begin:
	FlashCount++;
	if ( slavemag != none )
		SetTimer(0.20, false);
	FinishAnim();
	if (ClipCount>15)
		Owner.PlayOwnedSound(Misc1Sound, SLOT_None, 3.5*Pawn(Owner).SoundDampening);	
	if ( (AmmoType.AmmoAmount <= 0) || ((Pawn(Owner).bFire == 0) && (Pawn(Owner).bAltFire == 0)) )
	{
		PlayFiringEnd();
		FinishAnim();
	}
	if ( isslave )
		GotoState('Idle');
	else 
		Finish();
}

state ClientFiring
{
/*	simulated function bool ClientAltFire(float Value)
	{
		if ( isslave )
			Global.ClientAltFire(Value);
		return false;
	}*/

	simulated function Timer()
	{
		if ( (slavemag == None) || !slavemag.ClientFire(0) )
			SetTimer(0.5, false);
	}

	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !isslave && !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			if ( AnimSequence == 'Shoot0' && (Pawn(Owner).bFire == 0) )
				PlayFiringEnd();
			else
			{
				PlayIdleAnim();
				GotoState('');
			}
		}
	}

	simulated function BeginState()
	{
		Super.BeginState();
		if ( slavemag != None )
			SetTimer(0.2, false);
		else 
			SetTimer(0.5, false);
	}

	simulated function EndState()
	{
		Super.EndState();
		if ( slavemag != None )
			slavemag.GotoState('');
	}
}

//==========================================
// ALT FIRE
//=========
function AltFire( float Value )
{
	bPointing=True;
	bCanClientFire = true;
	AltAccuracy = 0.4;
	if ( AmmoType == None )
		GiveAmmo(Pawn(Owner));
	if ( AmmoType.AmmoAmount > 0 )
	{
		if ( slavemag != None )
			Pawn(Owner).PlayRecoil(3 * FiringSpeed);
		else if ( !isslave )
			Pawn(Owner).PlayRecoil(1.5 * FiringSpeed);
		ClientAltFire(value);
		GotoState('AltFiring');
	}
}

simulated function PlayAltFiring()
{
	PlayAnim('T1', 1.3, 0.05);
}

simulated function PlayAltRepeaterStart()
{
	PlayAnim('Shot2a', 1.2, 0.05);	
}

simulated function PlayAltRepeater()
{
	Owner.PlayOwnedSound(FireSound, SLOT_None,2.0*Pawn(Owner).SoundDampening);
	PlayAnim('Shot2b', 0.4, 0.05);
}

simulated function PlayAltRepeaterEnd()
{
	PlayAnim('Shot2c', 0.7, 0.05);	
}

state AltFiring
{
ignores Fire, AltFire, AnimEnd;

	function Timer()
	{
		if ( slavemag != none )
			slavemag.AltFire(0);
	}
Begin:
	if ( slavemag != none )
		SetTimer(0.20, false);
	FinishAnim();
	PlayAltRepeaterStart();
	FinishAnim();
Repeater:	
	if (AmmoType.UseAmmo(1)) 
	{
		if ( slavemag != None )
			Pawn(Owner).PlayRecoil(3 * FiringSpeed);
		else if ( !isslave )
			Pawn(Owner).PlayRecoil(1.5 * FiringSpeed);
		TraceFire(AltAccuracy);
		PlayAltRepeater();
		FinishAnim();
	}

	if ( AltAccuracy < 3 ) 
		AltAccuracy += 0.5;
	if ( ClipCount > 15)
		Owner.PlayOwnedSound(Misc1Sound, SLOT_None, 3.5*Pawn(Owner).SoundDampening);		

	if ( isslave )
	{
		if ( (Pawn(Owner).bAltFire!=0) && AmmoType.AmmoAmount>0 )
			Goto('Repeater');
	}
	else if ( bChangeWeapon )
		GotoState('DownWeapon');
	else if ( (Pawn(Owner).bAltFire!=0) && AmmoType.AmmoAmount > 0 )
	{
		if ( PlayerPawn(Owner) == None )
			Pawn(Owner).bAltFire = int( FRand() < AltReFireRate );
		Goto('Repeater');	
	}
	PlayAltRepeaterEnd();
	FinishAnim();
	PlayAnim('T2', 0.9, 0.05);	
	FinishAnim();
	Finish();
}

state ClientAltFiring
{
	simulated function bool ClientFire(float Value)
	{
		if ( isslave )
			Global.ClientFire(Value);
		return false;
	}

	simulated function Timer()
	{
		if ( (slavemag != none) && slavemag.ClientAltFire(0) )
			return;
		SetTimer(0.5, false);
	}
	
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (!isslave && !bCanClientFire) )
		{
			GotoState('');
			return;
		}
		
		if ( AnimSequence == 'T1' )
			PlayAltRepeaterStart();
		else if ( AnimSequence == 'Shot2a' )
			PlayAltRepeater();
		else if ( AnimSequence == 'Shot2b' )
		{
			//Simulate reload here
			if ( (AmmoType.AmmoAmount <= 0) || Pawn(Owner).bAltFire == 0 )
				PlayAltRepeaterEnd();
			else
				PlayAltRepeater();
			if ( ClientClipCount() > 15)
				Owner.PlayOwnedSound(Misc1Sound, SLOT_None, 3.5*Pawn(Owner).SoundDampening);		
		}
		else if ( AnimSequence == 'Shot2c' )
		{
			//And here?
			PlayAnim('T2', 0.9, 0.05);	
		}
		else
		{
			if ( Pawn(Owner).bAltFire != 0 )
				PlayAltFiring();
			else if ( Pawn(Owner).bFire != 0 )
				Global.ClientFire(0);
			else
			{
				PlayIdleAnim();
				GotoState('');
			}
		}
	}
	
	simulated function BeginState()
	{
		Super.BeginState();
		if ( slavemag != None )
			SetTimer(0.2, false);
		else 
			SetTimer(0.5, false);
	}

	simulated function EndState()
	{
		Super.EndState();
		if ( slavemag != None )
			slavemag.GotoState('');
	}
}


state Active
{
	function bool PutDown()
	{
		if ( bWeaponUp || (AnimFrame < 0.75) ) 
			GotoState('DownWeapon');
		else
			bChangeWeapon = true;
		return True;
	}

	function BeginState()
	{
		bChangeWeapon = false;
	}

	function EndState()
	{
		Super.EndState();
		bBringingUp = false;
	}

Begin:
	FinishAnim();
	if ( bChangeWeapon )
		GotoState('DownWeapon');
	bWeaponUp = True;
	bCanClientFire = true;
	if ( !isslave && (Level.Netmode != NM_Standalone) && (Owner != None)
		&& Owner.IsA('TournamentPlayer')
		&& (PlayerPawn(Owner).Player != None)
		&& !PlayerPawn(Owner).Player.IsA('ViewPort') )
	{
		if ( Pawn(Owner).bFire != 0 )
			TournamentPlayer(Owner).SendFire(self);
		else if ( Pawn(Owner).bAltFire != 0 )
			TournamentPlayer(Owner).SendAltFire(self);
		else if ( !bChangeWeapon )
			TournamentPlayer(Owner).UpdateRealWeapon(self);
	} 
	Finish();
}

State ClientActive
{
	simulated function AnimEnd()
	{
		bBringingUp = false;
		if ( !isslave )
		{
			Super.AnimEnd();
			if ( (slavemag != None) && !IsInState('ClientActive') )
			{
				if ( (GetStateName() == 'None') || (GetStateName() == 'OLautomag') )
					slavemag.GotoState('');
				else
					slavemag.GotoState(GetStateName());
			}
		}
	}

	simulated function BeginState()
	{
		Super.BeginState();
		bBringingUp = false;
		if ( slavemag != None )
			slavemag.GotoState('ClientActive');
	}
}

State DownWeapon
{
ignores Fire, AltFire, Animend;

	function BeginState()
	{
		Super.BeginState();
		if ( slavemag != none )
			slavemag.GoToState('DownWeapon');
	}
}





defaultproperties
{
    hitdamage=17	
    WeaponDescription="Classification: Automatic Magnum"
    InstFlash=-0.20
    InstFog=(X=325.00,Y=225.00,Z=95.00),
    AmmoName=Class'UnrealShare.ShellBox'
    PickupAmmoCount=20
    bInstantHit=True
    bAltInstantHit=True
    FiringSpeed=1.50
    FireOffset=(X=0.00,Y=-10.00,Z=-4.00),
    MyDamageType=shot
    shakemag=200.00
    shakevert=4.00
    AIRating=0.20
    RefireRate=0.70
    AltRefireRate=0.90
    FireSound=Sound'UnrealShare.AutoMag.shot'
    AltFireSound=Sound'UnrealShare.AutoMag.shot'
    CockingSound=Sound'UnrealShare.AutoMag.Cocking'
    SelectSound=Sound'UnrealShare.AutoMag.Cocking'
    Misc1Sound=Sound'UnrealShare.flak.Click'
    Misc2Sound=Sound'UnrealShare.AutoMag.Reload'
    DeathMessage="%o got gatted by %k's %w."
    NameColor=(R=200,G=200,B=255,A=0),
    AutoSwitchPriority=2
    InventoryGroup=2
    PickupMessage="You got the AutoMag"
    ItemName="Automag"
    PlayerViewOffset=(X=4.80,Y=-1.70,Z=-2.70),
    PlayerViewMesh=LodMesh'UnrealShare.AutoMagL'
    PickupViewMesh=LodMesh'UnrealShare.AutoMagPickup'
    ThirdPersonMesh=LodMesh'UnrealShare.auto3rd'
    StatusIcon=Texture'Botpack.Icons.UseAutoM'
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    Icon=Texture'Botpack.Icons.UseAutoM'
    Mesh=LodMesh'UnrealShare.AutoMagPickup'
    CollisionRadius=25.00
    CollisionHeight=10.00
    Mass=15.00
}