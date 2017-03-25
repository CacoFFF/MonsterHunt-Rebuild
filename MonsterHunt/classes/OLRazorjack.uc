class OLRazorjack expands UIweapons;


function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;

	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ClientInstantFlash( -0.4, vect(500, 0, 650));
	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Z * Z; 
	AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
	return Spawn(ProjClass,,, Start,AdjustedAim);	
}

simulated function TweenToStill()
{
}

simulated function PlayIdleAnim()
{
	LoopAnim('Idle',0.41);
}

simulated function PlayLoad()
{
	PlayAnim('Load', 0.2, 0.05);	
}

simulated function PlayFiring()
{
	PlayAnim('Fire', 0.7,0.05 );
}

simulated function PlayAltFiring()
{
	PlayAnim('AltFire1', 0.9, 0.05);
}

simulated function PlayAltFiringRepeater()
{
	PlayAnim('AltFire2', 0.4, 0.05);
}

simulated function PlayAltFiringRepeaterEnd()
{
	PlayAnim('AltFire3', 0.9, 0.05);
}

function AltFire( float Value )
{
	if (AmmoType.UseAmmo(1))
	{
		if ( Owner.bHidden )
			CheckVisibility();
		bPointing=True;
		PlayAltFiring();
		GotoState('AltFiring');
	}
}


///////////////////////////////////////////////////////////
state AltFiring
{
ignores AnimEnd;
	function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
	{
		local Vector Start, X,Y,Z;		

		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
		AdjustedAim.Roll += 12768;		
		RazorBlade(Spawn(ProjClass,,, Start,AdjustedAim));
	}

Begin:
	FinishAnim();
Repeater:
	ProjectileFire(AltProjectileClass,AltProjectileSpeed,bAltWarnTarget);
	PlayAltFiringRepeater();
	FinishAnim();
	if ( PlayerPawn(Owner) == None )
	{
		if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) )
		{
			Pawn(Owner).StopFiring();
			Pawn(Owner).SwitchToBestWeapon();
			if ( bChangeWeapon )
				GotoState('DownWeapon');
		}
		else if ( (Pawn(Owner).bAltFire == 0) || (FRand() > AltRefireRate) )
		{
			Pawn(Owner).StopFiring();
			GotoState('Idle');
		}
	}
	if ( (Pawn(Owner).bAltFire!=0) && (Pawn(Owner).Weapon==Self) && AmmoType.UseAmmo(1))
		Goto('Repeater');
	PlayAltFiringRepeaterEnd();
	FinishAnim();
	PlayLoad();
	FinishAnim();	
	if ( Pawn(Owner).bFire!=0 && Pawn(Owner).Weapon==Self) 
		Global.Fire(0);
	else 
		GotoState('Idle');
}


state ClientAltFiring
{
	simulated event AnimEnd()
	{
		if ( AnimSequence == 'AltFire1' )
			PlayAltFiringRepeater();
		else if ( AnimSequence == 'AltFire2' )
		{
			if ( (Pawn(Owner) != None) && (Pawn(Owner).Weapon == self) && (Pawn(Owner).bAltFire != 0)
				&& (AmmoType == None || AmmoType.AmmoAmount > 0) )
				PlayAltFiringRepeater();
			else
				PlayAltFiringRepeaterEnd();
		}
		else if ( AnimSequence == 'AltFire3' )
			PlayLoad();
		else
			Super.AnimEnd();
	}
}


defaultproperties
{
    WeaponDescription="Classification: Skaarj Blade Launcher"
    AmmoName=Class'UnrealI.RazorAmmo'
    PickupAmmoCount=15
    FireOffset=(X=16.00,Y=0.00,Z=-15.00),
    ProjectileClass=Class'RazorBlade'
    AltProjectileClass=Class'RazorBladeAlt'
    shakemag=120.00
    AIRating=0.50
    RefireRate=0.83
    AltRefireRate=0.83
    SelectSound=Sound'UnrealI.Razorjack.beam'
    DeathMessage="%k took a bloody chunk out of %o with the %w."
    AutoSwitchPriority=7
    InventoryGroup=7
    PickupMessage="You got the RazorJack"
    ItemName="Razorjack"
    PlayerViewOffset=(X=2.00,Y=0.00,Z=-0.90),
    PlayerViewMesh=LodMesh'UnrealI.Razor'
    BobDamping=0.97
    PickupViewMesh=LodMesh'UnrealI.RazPick'
    ThirdPersonMesh=LodMesh'UnrealI.Razor3rd'
    StatusIcon=Texture'Botpack.Icons.UseRazor'
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    Icon=Texture'Botpack.Icons.UseRazor'
    Mesh=LodMesh'UnrealI.RazPick'
    CollisionRadius=28.00
    CollisionHeight=7.00
    Mass=17.00
}
