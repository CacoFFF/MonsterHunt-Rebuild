// Higor rebuild
class OLRifle expands UIweapons;

function float RateSelf( out int bUseAltMode )
{
	if ( AmmoType.AmmoAmount <=0 )
		return -2;
		
	bUseAltMode = 0;
	if ( (Pawn(Owner) != None) && (Pawn(Owner).Enemy != None) && (VSize( Pawn(Owner).Enemy.Location - Owner.Location) > 2000) )
		return AIRating * 1.5;
	return AIRating;
}

simulated function PlayFiring()
{
	PlayOwnedSound( FireSound, SLOT_None, Pawn(Owner).SoundDampening*3.0);
	PlayAnim('Fire', 0.7, 0.05);
}

///////////////////////////////////////////////////////////
simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		PlayAnim('Still',1.0, 0.05);
}


function Finish()
{
	if ( (Pawn(Owner).bFire!=0) && (FRand() < 0.6) )
		Timer();
	Super.Finish();
}

function Timer()
{
	local actor targ;
	local float bestAim, bestDist;
	local vector FireDir;
	local Pawn P;

	bestAim = 0.95;
	P = Pawn(Owner);
	if ( P == None )
	{
		GotoState('');
		return;
	}

	FireDir = vector(P.ViewRotation);
	targ = P.PickTarget(bestAim, bestDist, FireDir, Owner.Location);
	if ( Pawn(targ) != None )
	{
		SetTimer(1 + 4 * FRand(), false);
		bPointing = true;
		Pawn(targ).WarnTarget(P, 200, FireDir);
	}
	else 
	{
		SetTimer(0.4 + 1.6 * FRand(), false);
		if ( (P.bFire == 0) && (P.bAltFire == 0) )
			bPointing = false;
	}
}	



function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local shellcase s;

	if ( PlayerPawn(Owner) != None )
	{
		PlayerPawn(Owner).ClientInstantFlash( -0.4, vect(650, 450, 190));
		if ( PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV )
			bMuzzleFlash++;
	}

	s = Spawn(class'ShellCase',Pawn(Owner), '', Owner.Location + CalcDrawOffset() + 30 * X + (2.8 * FireOffset.Y+5.0) * Y - Z * 1);
	if ( s != None ) 
	{
		s.DrawScale = 2.0;
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
	}
	if (Other == Level) 
		Spawn(class'HeavyWallHitEffect',,, HitLocation+HitNormal*9, Rotator(HitNormal));
	else if ( (Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if ( Other.IsA('Pawn') && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight) 
			&& (instigator.IsA('PlayerPawn') || (instigator.skill > 1)) 
			&& (!Other.IsA('ScriptedPawn') || !ScriptedPawn(Other).bIsBoss) )
			Other.TakeDamage(100, Pawn(Owner), HitLocation, 35000 * X, 'decapitated');
		else
			Other.TakeDamage(45,  Pawn(Owner), HitLocation, 30000.0*X, 'shot');	
		if ( !Other.IsA('Pawn') && !Other.IsA('Carcass') )
			spawn(class'SpriteSmokePuff',,,HitLocation+HitNormal*9);	
	}
}



///////////////////////////////////////////////////////
state Zooming
{
	simulated function Tick(float DeltaTime)
	{
		if ( Pawn(Owner).bAltFire == 0 )
		{
			if ( (PlayerPawn(Owner) != None) && PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).StopZoom();
			SetTimer(0.0,False);
			GoToState('Idle');
		}
	}

	simulated function BeginState()
	{
		if ( Owner.IsA('PlayerPawn') )
		{
			if ( PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).ToggleZoom();
			SetTimer(0.2,True);
		}
		else
		{
			Pawn(Owner).bFire = 1;
			Pawn(Owner).bAltFire = 0;
			Global.Fire(0);
		}
	}
}

simulated function bool ClientAltFire( float Value )
{
	GotoState('Zooming');
	return true;
}

function AltFire( float Value )
{
	ClientAltFire(Value);
}



defaultproperties
{
    PriorityName=SniperRifle
    WeaponDescription="Classification: Long-Range Ballistic"
    AmmoName=Class'UnrealI.RifleAmmo'
    PickupAmmoCount=8
    bInstantHit=True
    bAltInstantHit=True
    FireOffset=(X=0.00,Y=-5.00,Z=-2.00),
    MyDamageType=shot
    AltDamageType=Decapitated
    shakemag=400.00
    shaketime=0.15
    shakevert=8.00
    AIRating=0.70
    RefireRate=0.60
    AltRefireRate=0.30
    FireSound=Sound'UnrealI.Rifle.RifleShot'
    SelectSound=Sound'UnrealI.Rifle.RiflePickup'
    DeathMessage="%k put a bullet through %o's head."
    AutoSwitchPriority=9
    InventoryGroup=9
    PickupMessage="You got the Rifle"
    ItemName="Rifle"
    PlayerViewOffset=(X=3.20,Y=-1.20,Z=-1.70),
    PlayerViewMesh=LodMesh'UnrealI.RifleM'
    PickupViewMesh=LodMesh'UnrealI.RiPick'
    ThirdPersonMesh=LodMesh'UnrealI.Rifle3rd'
    StatusIcon=Texture'Botpack.Icons.UseRifle'
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    Icon=Texture'Botpack.Icons.UseRifle'
    Mesh=LodMesh'UnrealI.RiPick'
    CollisionRadius=28.00
    CollisionHeight=8.00
}
