// Higor rebuild
class OLstinger expands UIweapons;

var bool bAlreadyFiring, bWindup;

function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;
	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	EnemyDist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
	bUseAltMode = int( 600 * FRand() > EnemyDist - 140 );

	if ( Pawn(Owner).Enemy.CollisionRadius < 10 ) //Higor: the smaller the enemies the less effective
		return AIRating * 0.1 * Pawn(Owner).Enemy.CollisionRadius;
	return AIRating;
}



state NormalFire
{
ignores AnimEnd;
	function Tick( float DeltaTime )
	{
		if ( Owner==None )
			AmbientSound=None;		
		else			
			SetLocation(Owner.Location);
	}

	function EndState()
	{
		if (AmbientSound!=None && Owner!=None)
			Owner.PlayOwnedSound(Misc1Sound, SLOT_Misc,2.0*Pawn(Owner).SoundDampening);		
		AmbientSound = None;		
		bAlreadyFiring = false;
		Super.EndState();
	}

Begin:
	Sleep(0.2);
	SetLocation(Owner.Location);	
	Finish();
}

simulated state ClientFiring
{
	simulated function BeginState()
	{
		bWindup = false;
	}
	
	simulated function bool ClientFire(float Value)
	{
		if ( bWindup )
			return Global.ClientFire( Value);
		return false;
	}

	simulated function bool ClientAltFire(float Value)
	{
		if ( bWindup )
			return Global.ClientAltFire( Value);
		return false;
	}
	
	simulated function AnimEnd()
	{
		if ( !bWindup )
			TweenAnim('Still',0.08);
		else
			Super.AnimEnd();
	}
	
	simulated function EndState()
	{
		bAlreadyFiring = False;
		if (AmbientSound!=None && Owner!=None)
			Owner.PlaySound(Misc1Sound, SLOT_Misc,2.0*Pawn(Owner).SoundDampening);		
		Super.EndState();
	}

Begin:
	Sleep(0.2);
	SetLocation(Owner.Location);
	bWindup = true;
	AnimEnd();
}





state AltFiring
{
	function AnimEnd()
	{
		if ( AnimSequence == 'FireOne' )
			PlayPostAltFireAnim();
		else
			Super.AnimEnd();
	}

	function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
	{
		local Projectile S;
		local int i;
		local vector Start,X,Y,Z;
		local Rotator StartRot, AltRotation;

		S = Global.ProjectileFire(ProjClass, ProjSpeed, bWarn);
		StartRot = S.Rotation;
		Start = S.Location;
		for (i = 0; i< 4; i++)
		{
			if (AmmoType.UseAmmo(1)) 
			{
				AltRotation = StartRot;
				AltRotation.Pitch += FRand()*3000-1500;
				AltRotation.Yaw += FRand()*3000-1500;
				AltRotation.Roll += FRand()*9000-4500;				
				S = Spawn(AltProjectileClass,,, Start - 2 * VRand(), AltRotation);
			}
		}
		StingerProjectile(S).bLighting = True;
	}
}

state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( AnimSequence == 'FireOne' )
			PlayPostAltFireAnim();
		else
			Super.AnimEnd();
	}

	simulated function EndState()
	{
		AmbientSound = None;
	}
}



simulated function PlayFiring()
{
	if ( bAlreadyFiring )
	{
		AmbientSound = sound'StingerTwoFire';
		SoundVolume = Pawn(Owner).SoundDampening*255;
		LoopAnim( 'FireOne', 0.7);		
	}
	else
	{
		Owner.PlaySound(FireSound, SLOT_Misc,2.0*Pawn(Owner).SoundDampening);
		PlayAnim( 'FireOne', 0.7 );		
	}
	bAlreadyFiring = true;
	bWarnTarget = (FRand() < 0.2);
}

simulated function PlayAltFiring()
{
	Owner.PlaySound(AltFireSound, SLOT_Misc,2.0*Pawn(Owner).SoundDampening);		
	PlayAnim( 'FireOne', 0.6 );
}

simulated function PlayIdleAnim()
{
	PlayAnim('Still');
}

simulated function PlayPostAltFireAnim()
{
	TweenAnim('Still', 1);
//	PlayAnim('Still', 1.0 / 30.0); //Attempt to play this as a 1 second anim
}

defaultproperties
{
    WeaponDescription="Classification: Tarydium Shard Launcher"
    AmmoName=Class'UnrealShare.StingerAmmo'
    PickupAmmoCount=40
    bAltWarnTarget=True
	bRapidFire=True
    bSpecialIcon=False
    FireOffset=(X=12.00,Y=-10.00,Z=-15.00),
    ProjectileClass=Class'StingerProjectile'
    AltProjectileClass=Class'StingerProjectile'
    shakemag=120.00
    AIRating=0.40
    RefireRate=0.80
    FireSound=Sound'UnrealShare.Stinger.StingerFire'
    AltFireSound=Sound'UnrealShare.Stinger.StingerAltFire'
    SelectSound=Sound'UnrealShare.Stinger.StingerLoad'
    Misc1Sound=Sound'UnrealShare.Stinger.EndFire'
    DeathMessage="%o was perforated by %k's %w."
    AutoSwitchPriority=3
    InventoryGroup=3
    PickupMessage="You picked up the Stinger"
    ItemName="Stinger"
    PlayerViewOffset=(X=4.20,Y=-3.00,Z=-4.00),
    PlayerViewMesh=LodMesh'UnrealShare.StingerM'
    PlayerViewScale=1.70
    PickupViewMesh=LodMesh'UnrealShare.StingerPickup'
    ThirdPersonMesh=LodMesh'UnrealShare.Stinger3rd'
    Mesh=LodMesh'UnrealShare.StingerPickup'
    SoundRadius=64
    SoundVolume=255
    CollisionRadius=27.00
    CollisionHeight=8.00
}