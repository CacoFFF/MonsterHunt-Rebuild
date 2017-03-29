class OLFlakCannon expands UIweapons;

//-------------------------------------------------------
// AI related functions

function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist, rating;
	local vector EnemyDir;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;
	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}
	EnemyDir = Pawn(Owner).Enemy.Location - Owner.Location;
	EnemyDist = VSize(EnemyDir);
	rating = FClamp(AIRating - (EnemyDist - 450) * 0.001, 0.2, AIRating);
	if ( Pawn(Owner).Enemy.IsA('StationaryPawn') )
	{
		bUseAltMode = 0;
		return AIRating + 0.3;
	}
	if ( EnemyDist > 900 )
	{
		bUseAltMode = 0;
		if ( EnemyDist > 2000 )
		{
			if ( EnemyDist > 3500 )
				return 0.2;
			return (AIRating - 0.3);
		}			
		if ( EnemyDir.Z < -0.5 * EnemyDist )
		{
			bUseAltMode = 1;
			return (AIRating - 0.3);
		}
	}
	else if ( (EnemyDist < 750) && (Pawn(Owner).Enemy.Weapon != None) && Pawn(Owner).Enemy.Weapon.bMeleeWeapon )
	{
		bUseAltMode = 0;
		return (AIRating + 0.3);
	}
	else if ( (EnemyDist < 340) || (EnemyDir.Z > 30) )
	{
		bUseAltMode = 0;
		return (AIRating + 0.2);
	}
	else
		bUseAltMode = int( FRand() < 0.65 );
	return rating;
}

// return delta to combat style
function float SuggestAttackStyle()
{
	return 0.4;
}

function float SuggestDefenseStyle()
{
	return -0.3;
}


//-------------------------------------------------------
 
// Fire chunks
function Fire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn P;

	P = Pawn(Owner);
	if ( AmmoType == None )
		GiveAmmo(P);
	if (AmmoType.UseAmmo(1))
	{
		CheckVisibility();
		bCanClientFire = true;
		bPointing=True;
		Start = Owner.Location + CalcDrawOffset();
		P.PlayRecoil(FiringSpeed);
		Owner.MakeNoise(2.0 * P.SoundDampening);
		AdjustedAim = P.AdjustAim(AltProjectileSpeed, Start, AimError, True, bWarnTarget);
		GetAxes(AdjustedAim,X,Y,Z);
//		Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));		
		Start = Start + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;	
		Spawn( class 'MasterChunk',, '', Start, AdjustedAim);
		Spawn( class 'Chunk2',, '', Start - Z, AdjustedAim);
		Spawn( class 'Chunk3',, '', Start + 2 * Y + Z, AdjustedAim);
		Spawn( class 'Chunk4',, '', Start - Y, AdjustedAim);
		Spawn( class 'Chunk1',, '', Start + 2 * Y - Z, AdjustedAim);
		Spawn( class 'Chunk2',, '', Start, AdjustedAim);
		Spawn( class 'Chunk3',, '', Start + Y - Z, AdjustedAim);
		Spawn( class 'Chunk4',, '', Start + 2 * Y + Z, AdjustedAim);
		ClientFire(Value);
		GoToState('NormalFire');
	}
}

simulated function PlayFiring()
{
	PlayAnim( 'Fire', 0.9, 0.05);
	PlayOwnedSound( FireSound, SLOT_Misc, Pawn(Owner).SoundDampening*4.0);	
}

simulated function PlayAltFiring()
{
	PlayAnim('AltFire', 1.3, 0.05);
	PlayOwnedSound(Misc1Sound, SLOT_None, 0.6*Pawn(Owner).SoundDampening);
	PlayOwnedSound(AltFireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);
}


////////////////////////////////////////////////////////////
simulated function PlayAltLoadAnim()
{
	PlayAnim('Loading',0.65, 0.05);
	PlayOwnedSound(CockingSound, SLOT_None,0.5*Pawn(Owner).SoundDampening);		
}

state AltFiring
{
ignores AnimEnd;
Begin:
	FinishAnim();
	if ( (AmmoType == None) || (AmmoType.AmmoAmount > 0) )
	{
		PlayAltLoadAnim();
		FinishAnim();
	}
	Finish();
}

state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( AnimSequence == 'AltFire' )
			PlayAltLoadAnim();
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
}

/////////////////////////////////////////////////////////////
simulated function PlayEjectAnim()
{
	PlayAnim('Eject',1.5, 0.05);
	PlayOwnedSound(Misc3Sound, SLOT_None,0.6*Pawn(Owner).SoundDampening);	
}

simulated function PlayLoadAnim()
{
	PlayAnim('Loading',1.4, 0.05);
	PlayOwnedSound(CockingSound, SLOT_None,0.5*Pawn(Owner).SoundDampening);		
}

state NormalFire
{
ignores AnimEnd;
Begin:
	FinishAnim();
	PlayEjectAnim();
	FinishAnim();
	if ( (AmmoType == None) || (AmmoType.AmmoAmount > 0) )
	{
		PlayLoadAnim();
		FinishAnim();
	}
	Finish();	
}

state ClientFiring
{
	simulated function AnimEnd()
	{
		if ( AnimSequence == 'Fire' )
			PlayEjectAnim();
		else if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( AnimSequence == 'Eject' )
			PlayLoadAnim();
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
}



simulated function TweenDown()
{
	if ( GetAnimGroup(AnimSequence) == 'Select' )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
	{
		if ( (AmmoType != None) && (AmmoType.AmmoAmount <= 0) )
			PlayAnim('Down2',1.0, 0.05);
		else
			PlayAnim('Down',1.0, 0.05);
	}
}


simulated function PlayPostSelect()
{
	PlayAnim('Loading', 1.3, 0.05);
	PlayOwnedSound( Misc2Sound, SLOT_None,1.3*Pawn(Owner).SoundDampening);	
}

simulated function PlayIdleAnim()
{
	LoopAnim('Sway',0.01,0.30);
}



defaultproperties
{
    PriorityName=UT_FlakCannon
    WeaponDescription="Classification: Heavy Shrapnel"
    AmmoName=Class'UnrealI.FlakBox'
    PickupAmmoCount=10
    bWarnTarget=True
    bAltWarnTarget=True
    bSplashDamage=True
    FireOffset=(X=10.00,Y=-12.00,Z=-15.00),
    ProjectileClass=Class'MasterChunk'
    AltProjectileClass=Class'FlakShell'
    shakemag=350.00
    shaketime=0.15
    shakevert=8.50
    AIRating=0.80
    FireSound=Sound'UnrealShare.flak.shot1'
    AltFireSound=Sound'UnrealShare.flak.Explode1'
    CockingSound=Sound'UnrealI.flak.load1'
    SelectSound=Sound'UnrealI.flak.pdown'
    Misc2Sound=Sound'UnrealI.flak.Hidraul2'
    Misc3Sound=Sound'UnrealShare.flak.Click'
    DeathMessage="%o was ripped to shreds by %k's %w."
    AutoSwitchPriority=6
    InventoryGroup=6
    PickupMessage="You got the Flak Cannon"
    ItemName="Flak Cannon"
    PlayerViewOffset=(X=2.10,Y=-1.50,Z=-1.25),
    PlayerViewMesh=LodMesh'UnrealI.flak'
    PlayerViewScale=1.20
    PickupViewMesh=LodMesh'UnrealI.FlakPick'
    ThirdPersonMesh=LodMesh'UnrealI.Flak3rd'
    StatusIcon=Texture'Botpack.Icons.UseFlak'
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    Icon=Texture'Botpack.Icons.UseFlak'
    Mesh=LodMesh'UnrealI.FlakPick'
    CollisionRadius=27.00
    CollisionHeight=23.00
    LightBrightness=228
    LightHue=30
    LightSaturation=71
    LightRadius=14
}
