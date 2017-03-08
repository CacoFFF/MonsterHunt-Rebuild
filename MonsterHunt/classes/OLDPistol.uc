//================================================================================
// OLDPistol.
//================================================================================
class OLDPistol extends UIweapons;

var travel int PowerLevel;
var vector WeaponPos;
var float Count,ChargeSize;
var ChargeLight cl1,cl2;
var Pickup Amp;
var Sound PowerUpSound;
var name ShootAnims[5];
var class<DispersionAmmo> DProjectiles[5];

replication
{
	reliable if ( bNetOwner && Role==ROLE_Authority )
		PowerLevel;
	reliable if ( Role==ROLE_Authority )
		ClientPowerup;
}



function float RateSelf( out int bUseAltMode )
{
	local float rating;

	if ( Amp != None )
		rating = 6 * AIRating;
	else 
		rating = AIRating;

	if ( AmmoType.AmmoAmount <=0 )
		return 0.05;
	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return rating * (PowerLevel + 1);
	}
	
	bUseAltMode = int( FRand() < 0.3 );
	return rating * (PowerLevel + 1);
}

// return delta to combat style
function float SuggestAttackStyle()
{
	if ( !Pawn(Owner).bIsPlayer || (PowerLevel > 0) )
		return 0;
	return -0.3;
}

function bool HandlePickupQuery( inventory Item )
{
	if ( Item.IsA('WeaponPowerup') )
	{ 
		AmmoType.AddAmmo(AmmoType.MaxAmmo);
		Pawn(Owner).ClientMessage(Item.PickupMessage, 'Pickup');				
		Item.PlaySound (PickupSound);
		if ( PowerLevel<4 ) 
		{
			ShakeVert = Default.ShakeVert + PowerLevel;
			if ( WeaponPowerUp(Item) != None )
				WeaponPowerUp(Item).ActivateSound = WeaponPowerUp(Item).PowerUpSounds[PowerLevel];
			PowerUpSound = Item.ActivateSound;
			if ( Pawn(Owner).Weapon == self )
			{
				PowerLevel++;
				GotoState('PowerUp');
			}
			else if ( (Pawn(Owner).Weapon != Self) && !Pawn(Owner).bNeverSwitchOnPickup )
			{
				Pawn(Owner).Weapon.PutDown();
				Pawn(Owner).PendingWeapon = self;
				GotoState('PowerUp', 'Waiting');	
			}
			else
				PowerLevel++;
		}
		Item.SetRespawn();
		return true;
	}
	else
		return Super.HandlePickupQuery(Item);
}

function BecomePickup()
{
	Amp = None;
	Super.BecomePickup();
}

simulated function PlayFiring()
{
	local int pl;
	
	AmmoType.GoToState('Idle2');
	Owner.PlaySound(AltFireSound, SLOT_None, 1.8*Pawn(Owner).SoundDampening,,,1.2);
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);	
	pl = Min(PowerLevel,4);
	PlayAnim( ShootAnims[pl], fMax(0.4 - float(pl)*0.1, 0.1), 0.2);
}

///////////////////////////////////////////////////////////
simulated function PlayIdleAnim()
{
	if (PowerLevel==0) LoopAnim('Idle1',0.04,0.2);
	else if (PowerLevel==1) LoopAnim('Idle2',0.04,0.2);
	else if (PowerLevel==2) LoopAnim('Idle3',0.04,0.2);
	else if (PowerLevel==3) LoopAnim('Idle4',0.04,0.2);			
	else if (PowerLevel==4) LoopAnim('Idle5',0.04,0.2);	
}

simulated function TweenToStill()
{
	if ( !HasAnim('Idle1') )
		return;
	if (PowerLevel==0) TweenAnim('Idle1',0.2);
	else if (PowerLevel==1) TweenAnim('Idle2',0.2);
	else if (PowerLevel==2) TweenAnim('Idle3',0.2);
	else if (PowerLevel==3) TweenAnim('Idle4',0.2);			
	else if (PowerLevel==4) TweenAnim('Idle5',0.2);	
}


function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local DispersionAmmo da;
	local float Mult;
	local int pl;

	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	
	if (Amp!=None)
		Mult = Amp.UseCharge(80);
	else
		Mult = 1.0;
	
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, (3.5*FRand()-1<PowerLevel));	

	if ( AmmoType.AmmoAmount >= 10 )
		pl = Min(PowerLevel,4);
	else if ( AmmoType.AmmoAmount <= 1 )
		AmmoType.AmmoAmount = 2;
	if ( AmmoType.UseAmmo(pl) )
		da = Spawn( DProjectiles[pl],,, Start, AdjustedAim);
	if ( (da != None) && (Mult>1.0) )
		da.InitSplash(Mult);
}

function AltFire( float Value )
{
	bPointing=True;
	CheckVisibility();
	GoToState('AltFiring');
}

////////////////////////////////////////////////////////
simulated state ClientAltFiring
{
	simulated event AnimEnd()
	{
		PlayIdleAnim();
	}
	
	simulated event Tick( float DeltaTime)
	{
		if ( Owner == None )
			return;
	
		PlayerViewOffset.X = WeaponPos.X + FRand()*ChargeSize*7;
		PlayerViewOffset.Y = WeaponPos.Y + FRand()*ChargeSize*7;
		PlayerViewOffset.Z = WeaponPos.Z + FRand()*ChargeSize*7;

		ChargeSize += DeltaTime;
		
		if ( Pawn(Owner).bAltFire == 0 || (ChargeSize >= 2.0 + 0.6 * PowerLevel) || (AmmoType != None && AmmoType.AmmoAmount <= 1) )
		{
			Owner.PlaySound(AltFireSound, SLOT_Misc, 1.8*Pawn(Owner).SoundDampening);
			if ( PlayerPawn(Owner) != None )
				PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag*ChargeSize, ShakeVert);
			PlayAnim( ShootAnims[Min(PowerLevel,4)], 0.2, 0.05); //Port to client
			GotoState('ClientFiring');
		}
	}
	
	simulated function EndState()
	{
		PlayerviewOffset = WeaponPos;
	}

	simulated function BeginState()
	{
		PlayIdleAnim();
		WeaponPos = PlayerviewOffset;	
		ChargeSize=0.0;
		Owner.Playsound(Misc1Sound,SLOT_Misc, Pawn(Owner).SoundDampening*4.0);
	}
}


state AltFiring
{
ignores AltFire, AnimEnd;


	function Tick( float DeltaTime )
	{
		if ( Level.NetMode == NM_StandAlone )
		{
			PlayerViewOffset.X = WeaponPos.X + FRand()*ChargeSize*7;
			PlayerViewOffset.Y = WeaponPos.Y + FRand()*ChargeSize*7;
			PlayerViewOffset.Z = WeaponPos.Z + FRand()*ChargeSize*7;
		}	
		ChargeSize += DeltaTime;
		if( (pawn(Owner).bAltFire==0)) GoToState('ShootLoad');
		Count += DeltaTime;
		if (Count > 0.3) 
		{
			Count -= 0.3; //Higor: tickrate independant charge
			If (!AmmoType.UseAmmo(1)) GoToState('ShootLoad');
			AmmoType.GoToState('Idle2');
		}
	}
	
	Function EndState()
	{
		PlayerviewOffset = WeaponPos;
		if (cl1!=None) cl1.Destroy();
		if (cl2!=None) cl2.Destroy();		
	}

	function BeginState()
	{
		WeaponPos = PlayerviewOffset;	
		ChargeSize=0.0;		
	}

Begin:
	if (AmmoType.UseAmmo(1))
	{
		Owner.Playsound(Misc1Sound,SLOT_Misc, Pawn(Owner).SoundDampening*4.0);
		Count = 0.0;		
		Sleep(2.0 + 0.6 * PowerLevel);
		GoToState('ShootLoad');
	}
	else
		GotoState('Idle');
}

		
///////////////////////////////////////////////////////////
state ShootLoad
{
ignores fire, altfire;

	function BeginState()
	{
		local DispersionAmmo d;
		local Vector Start, X,Y,Z;
		local float Mult;
		
		if (Amp!=None)
			Mult = Amp.UseCharge(ChargeSize*50+50);
		else
			Mult=1.0;
		
		Owner.PlaySound(AltFireSound, SLOT_Misc, 1.8*Pawn(Owner).SoundDampening);
		if ( PlayerPawn(Owner) != None )
			PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag*ChargeSize, ShakeVert);
		PlayAnim( ShootAnims[Min(PowerLevel,4)], 0.2, 0.05); //Port to client
		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustAim(AltProjectileSpeed, Start, AimError, True, True);
		d = DispersionAmmo(Spawn(AltProjectileClass,,, Start,AdjustedAim));
		if ( d != None )
		{	
			d.bAltFire = True;
			d.DrawScale = 0.5 + ChargeSize*0.6;
			d.InitSplash(d.DrawScale * Mult * 1.1);
		}
	}
Begin:
	FinishAnim();
	Finish();
}

///////////////////////////////////////////////////////
simulated function ClientPowerup( int NewPowerLevel, Sound NewPowerupSound)
{
	Owner.PlayOwnedSound( NewPowerupSound, SLOT_None, Pawn(Owner).SoundDampening);				
	if (NewPowerLevel==1)		PlayAnim('PowerUp1',0.1, 0.05);	
	else if (NewPowerLevel==2)	PlayAnim('PowerUp2',0.1, 0.05);			
	else if (NewPowerLevel==3)	PlayAnim('PowerUp3',0.1, 0.05);					
	else						PlayAnim('PowerUp4',0.1, 0.05);
	//Apply ping correction to animation later
	if ( Level.NetMode == NM_Client )
		GotoState('ClientFiring');
}

state PowerUp
{
ignores fire, altfire;

	function BringUp()
	{
		bWeaponUp = false;
		PlaySelect();
		GotoState('Powerup', 'Raising');
	}

	function bool PutDown()
	{
		bChangeWeapon = true;
		return True;
	}

	function BeginState()
	{
		bChangeWeapon = false;
	}

Raising:
	FinishAnim();
	PowerLevel++;
Begin:
	if (PowerLevel<5) 
	{
		AmmoType.MaxAmmo += 10;	
		AmmoType.AddAmmo(10);
		if ( Level.NetMode != NM_Standalone )
			ClientPowerup( PowerLevel, PowerupSound);
		if ( PowerLevel < 5 )
			Owner.PlayOwnedSound(PowerUpSound, SLOT_None, Pawn(Owner).SoundDampening);
		if (PowerLevel==1)		PlayAnim('PowerUp1',0.1, 0.05);	
		else if (PowerLevel==2) PlayAnim('PowerUp2',0.1, 0.05);			
		else if (PowerLevel==3) PlayAnim('PowerUp3',0.1, 0.05);					
		else if (PowerLevel==4) PlayAnim('PowerUp4',0.1, 0.05);		
		FinishAnim();
		if ( bChangeWeapon )
			GotoState('DownWeapon');
		Finish();
	}
Waiting:
}


simulated function TweenDown()
{
	if ( GetAnimGroup(AnimSequence) == 'Select' )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
	{
		if (PowerLevel==0) PlayAnim('Down1', 1.0, 0.05);
		else if (PowerLevel==1) PlayAnim('Down2', 1.0, 0.05);
		else if (PowerLevel==2) PlayAnim('Down3', 1.0, 0.05);
		else if (PowerLevel==3) PlayAnim('Down4', 1.0, 0.05);	
		else if (PowerLevel==4) PlayAnim('Down5', 1.0, 0.05);	
	}
}

simulated function TweenSelect()
{
	TweenAnim('Select1',0.001);
}

simulated function PlaySelect()
{
	Owner.PlaySound(SelectSound, SLOT_None, Pawn(Owner).SoundDampening);
	if (PowerLevel==0) PlayAnim('Select1',0.5,0.0);
	else if (PowerLevel==1) PlayAnim('Select2',0.5,0.0);
	else if (PowerLevel==2) PlayAnim('Select3',0.5,0.0);
	else if (PowerLevel==3) PlayAnim('Select4',0.5,0.0);	
	else if (PowerLevel==4) PlayAnim('Select5',0.5,0.0);
}	



defaultproperties
{
    PriorityName=DispersionPistol
	ShootAnims(0)=Shoot1
	ShootAnims(1)=Shoot2
	ShootAnims(2)=Shoot3
	ShootAnims(3)=Shoot4
	ShootAnims(4)=Shoot5
	DProjectiles(0)=DispersionAmmo
	DProjectiles(1)=DAmmo2
	DProjectiles(2)=DAmmo3
	DProjectiles(3)=DAmmo4
	DProjectiles(4)=DAmmo5
    WeaponDescription="Classification: Energy Pistol"
    AmmoName=Class'UnrealShare.DefaultAmmo'
    PickupAmmoCount=50
    bAltWarnTarget=True
    bSpecialIcon=False
    FireOffset=(X=12.00,Y=-8.00,Z=-15.00),
    ProjectileClass=Class'UnrealShare.DispersionAmmo'
    AltProjectileClass=Class'UnrealShare.DispersionAmmo'
    shakemag=200.00
    shaketime=0.13
    shakevert=2.00
    RefireRate=0.85
    AltRefireRate=0.30
    FireSound=Sound'UnrealShare.Dispersion.DispShot'
    AltFireSound=Sound'UnrealShare.Dispersion.DispShot'
    SelectSound=Sound'UnrealShare.Dispersion.DispPickup'
    Misc1Sound=Sound'UnrealShare.Dispersion.PowerUp3'
    DeathMessage="%o was killed by %k's %w.  What a loser!"
    PickupMessage="You got the Dispersion Pistol"
    ItemName="Dispersion Pistol"
    PlayerViewOffset=(X=3.80,Y=-2.00,Z=-2.00),
    PlayerViewMesh=LodMesh'UnrealShare.DPistol'
    PickupViewMesh=LodMesh'UnrealShare.DPistolPick'
    ThirdPersonMesh=LodMesh'UnrealShare.DPistol3rd'
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    Texture=None
    Mesh=LodMesh'UnrealShare.DPistolPick'
    bNoSmooth=False
    CollisionRadius=28.00
    CollisionHeight=8.00
    Mass=15.00
}
