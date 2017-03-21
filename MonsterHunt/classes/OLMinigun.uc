class OLMinigun expands UIweapons;

var bool bFiredShot;
var float ShotAccuracy;

simulated function PlayFiring()
{	
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	PlayAnim('Shoot1',0.8, 0.05);
	AmbientGlow = 250;
	AmbientSound = FireSound;
	bSteadyFlash3rd = true;
}

simulated function PlayAltFiring()
{
	PlayFiring();
}

simulated function PlayUnwind()
{
	if ( Owner != None )
	{
		PlayOwnedSound(Misc1Sound, SLOT_Misc, 3.0*Pawn(Owner).SoundDampening);  //Finish firing, power down		
		PlayAnim('UnWind',1.5, 0.05);
	}
}

simulated function TweenToStill()
{
	if ( HasAnim('Still') )
		TweenAnim('Still', 0.1);
}


function Fire( float Value )
{
	Enable('Tick');
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		SoundVolume = 255*Pawn(Owner).SoundDampening;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		bCanClientFire = true;
		bPointing=True;
		ShotAccuracy = 0.2;
		ClientFire(value);
		GotoState('NormalFire');
	}
	else GoToState('Idle');
}

function AltFire( float Value )
{
	Enable('Tick');
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		bPointing=True;
		bCanClientFire = true;
		ShotAccuracy = 0.95;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		SoundVolume = 255*Pawn(Owner).SoundDampening;		
		ClientAltFire(value);	
		GoToState('AltFiring');		
	}
	else GoToState('Idle');	
}

function float RateSelf( out int bUseAltMode )
{
	local float dist;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	dist = VSize(Pawn(Owner).Enemy.Location - Owner.Location); 
	bUseAltMode = 1;
	if ( dist > 1200 )
	{
		if ( dist > 1700 )
			bUseAltMode = 0;
		return (AIRating * FMin(Pawn(Owner).DamageScaling, 1.5) + FMin(0.0001 * dist, 0.3)); 
	}
	AIRating *= FMin(Pawn(Owner).DamageScaling, 1.5);
	return AIRating;
}

function GenerateBullet()
{
    LightType = LT_Steady;
	bFiredShot = true;
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
	if ( AmmoType.UseAmmo(1) ) 
		TraceFire(ShotAccuracy);
	else
		GotoState('FinishFire');
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local int rndDam;

	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	
	if (Other == Level) 
		Spawn(class'LightWallHitEffect',,, HitLocation+HitNormal*9, Rotator(HitNormal));
	else if ( (Other!=self) && (Other!=Owner) && (Other != None) ) 
	{
		if ( !Other.IsA('Pawn') && !Other.IsA('Carcass') )
			spawn(class'SpriteSmokePuff',,,HitLocation+HitNormal*9);
		if ( Other.IsA('ScriptedPawn') && (FRand() < 0.2) )
			Pawn(Other).WarnTarget(Pawn(Owner), 500, X);
		rndDam = 8 + Rand(6);
		if ( FRand() < 0.2 )
			X *= 2;
		Other.TakeDamage(rndDam, Pawn(Owner), HitLocation, rndDam*500.0*X, 'shot');
	}
}


state ClientFinish
{
	simulated function bool ClientFire(float Value)
	{
		bForceFire = bForceFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceFire;
	}
	simulated function bool ClientAltFire(float Value)
	{
		bForceAltFire = bForceAltFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceAltFire;
	}

	simulated function AnimEnd()
	{
		if ( bCanClientFire && (PlayerPawn(Owner) != None) && (AmmoType.AmmoAmount > 0) )
		{
			if ( bForceFire || (Pawn(Owner).bFire != 0) )
			{
				Global.ClientFire(0);
				return;
			}
			else if ( bForceAltFire || (Pawn(Owner).bAltFire != 0) )
			{
				Global.ClientAltFire(0);
				return;
			}
		}			
		GotoState('');
		Global.AnimEnd();
	}

	simulated function EndState()
	{
		bSteadyFlash3rd = false;
		bForceFire = false;
		bForceAltFire = false;
		AmbientSound = None;
	}

	simulated function BeginState()
	{
		bSteadyFlash3rd = false;
		bForceFire = false;
		bForceAltFire = false;
	}
}

state ClientFiring
{
	simulated event AnimEnd()
	{
		if ( (AnimSequence == 'Shoot1') && (Pawn(Owner).bFire + Pawn(Owner).bAltFire == 0) )
		{
			PlayUnwind();
			AmbientSound = None;
		}
		else
			Super.AnimEnd();
	}
}

simulated state ClientAltFiring
{
	simulated function BeginState()
	{
		bSteadyFlash3rd = true;
		AmbientSound = FireSound;
		SetTimer( 0.13, true); //Fire rate on normal fire
	}

	simulated function EndState()
	{
		bSteadyFlash3rd = false;
		SetTimer( 0, false);
		Super.EndState();
	}
	
	simulated event Timer()
	{
		if ( AnimSequence == 'Shoot2' ) //Change to alt-fire rate
			TimerRate = 0.08;
		//Force quick unwind after release
		if ( Pawn(Owner).bAltFire == 0 )
			AnimEnd();
	}
	
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (AmmoType.AmmoAmount <= 0) )
		{
			PlayUnwind();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bAltFire != 0 )
		{
			if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
			{	
				AmbientSound = AltFireSound;
				SoundVolume = 255*Pawn(Owner).SoundDampening;
				LoopAnim('Shoot2',1.9);
			}
			else if ( AmbientSound == None )
				AmbientSound = FireSound;

			if ( Affector != None )
				Affector.FireEffect();
			if ( PlayerPawn(Owner) != None )
				PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
		}
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else
		{
			PlayUnwind();
			bSteadyFlash3rd = false;
			GotoState('ClientFinish');
		}
	}
}





////////////////////////////////////////////////////////
state FinishFire
{
	function Fire(float F) {}
	function AltFire(float F) {}

	function ForceFire()
	{
		bForceFire = true;
	}

	function ForceAltFire()
	{
		bForceAltFire = true;
	}

	function BeginState()
	{
		PlayUnwind();
	}

Begin:
	FinishAnim();
	Finish();
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

state NormalFire
{
	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			AmbientSound = None;
	}

	function AnimEnd()
	{
		if (Pawn(Owner).Weapon != self)
			GotoState('');
		else if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0)
		{
			if ( (PlayerPawn(Owner) != None) || (FRand() < ReFireRate) )
				Global.Fire(0);
			else 
			{
				Pawn(Owner).bFire = 0;
				GotoState('FinishFire');
			}
		}
		else if ( Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0)
			Global.AltFire(0);
		else 
			GotoState('FinishFire');
	}

	function BeginState()
	{
		AmbientGlow = 250;
		AmbientSound = FireSound;
		bSteadyFlash3rd = true;
		Super.BeginState();
	}	

	function EndState()
	{
		bSteadyFlash3rd = false;
		AmbientGlow = 0;
		LightType = LT_None;
		AmbientSound = None;
		Super.EndState();
	}

Begin:
	Sleep(0.13);
	GenerateBullet();
	Goto('Begin');
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		if (Owner==None) 
		{
			AmbientSound = None;
			GotoState('Pickup');
		}			

		if	( bFiredShot && (pawn(Owner).bAltFire==0) ) 
			GoToState('FinishFire');
	}

	function AnimEnd()
	{
		if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
		{  
			AmbientSound = AltFireSound;
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			LoopAnim('Shoot2',0.5);
		}
		else if ( AmbientSound == None )
			AmbientSound = FireSound;
		if ( Affector != None )
			Affector.FireEffect();
	}

	function BeginState()
	{
		Super.BeginState();
		AmbientSound = FireSound;
		AmbientGlow = 250;
		bFiredShot = false;
		bSteadyFlash3rd = true;
	}	

	function EndState()
	{
		bSteadyFlash3rd = false;
		AmbientGlow = 0;
		LightType = LT_None;
		AmbientSound = None;
		Super.EndState();
	}

Begin:
	Sleep(0.13);
	GenerateBullet();
	if ( AnimSequence == 'Shoot2' )
		Goto('FastShoot');
	Goto('Begin');
FastShoot:
	Sleep(0.08);
	GenerateBullet();
	Goto('FastShoot');
}


state Idle
{
Begin:
	if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0)
		Fire(0.0);
	if (Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0)
		AltFire(0.0);  
	PlayAnim('Still');
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	Disable('AnimEnd');
	PlayIdleAnim();    
}



defaultproperties
{
	PriorityName=minigun2
    WeaponDescription="Classification: Gatling Gun"
    AmmoName=Class'UnrealShare.ShellBox'
    PickupAmmoCount=50
    bInstantHit=True
    bAltInstantHit=True
    FireOffset=(X=0.00,Y=-5.00,Z=-4.00),
    shakemag=135.00
    shakevert=8.00
    AIRating=0.60
    RefireRate=0.90
    AltRefireRate=0.93
    FireSound=Sound'UnrealI.Minigun.RegF1'
    AltFireSound=Sound'UnrealI.Minigun.AltF1'
    SelectSound=Sound'UnrealI.Minigun.MiniSelect'
    Misc1Sound=Sound'UnrealI.Minigun.WindD2'
    DeathMessage="%k's %w turned %o into a leaky piece of meat."
    AutoSwitchPriority=10
    InventoryGroup=10
    PickupMessage="You got the Minigun"
    ItemName="Minigun"
    PlayerViewOffset=(X=5.60,Y=-1.50,Z=-1.80),
    PlayerViewMesh=LodMesh'UnrealI.minigunM'
    PickupViewMesh=LodMesh'UnrealI.minipick'
    ThirdPersonMesh=LodMesh'UnrealI.SMini3'
    StatusIcon=Texture'Botpack.Icons.UseMini'
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    Icon=Texture'Botpack.Icons.UseMini'
    Mesh=LodMesh'UnrealI.minipick'
    SoundRadius=64
    SoundVolume=255
    CollisionRadius=28.00
    CollisionHeight=8.00
    LightEffect=13
    LightBrightness=250
    LightHue=28
    LightSaturation=32
    LightRadius=6
}
