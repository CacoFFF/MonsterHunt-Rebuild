//***************************
// MonsterBase
// MonsterHunt's base mutator
class MonsterBase expands Mutator;

var DeathMatchPlus Game;
var() name UIWeaponName[10];
var() string UIWeaponReplacement[10];


//Deny game breaking mutators
function AddMutator( Mutator M)
{
	if ( M == None || M.bDeleteMe )
		return;
	if ( M.IsA('LowGrav') || M.IsA('JumpMatch') || M.IsA('InstaGibDM') || M.IsA('DMMutator') )
		return;
	Super.AddMutator(M);
}


function PostBeginPlay()
{
	Game = DeathMatchPlus(Level.Game);
	//Reduce amount of traces per second on servers
	if ( Level.NetMode != NM_Standalone )
	{
		ConsoleCommand("Set Barrel NetUpdateFrequency 15");
		ConsoleCommand("Set SludgeBarrel NetUpdateFrequency 15");
		ConsoleCommand("Set SteelBarrel NetUpdateFrequency 15");
		ConsoleCommand("Set SteelBox NetUpdateFrequency 15");
		ConsoleCommand("Set StudMetal NetUpdateFrequency 5");
		ConsoleCommand("Set Tree NetUpdateFrequency 5");
		ConsoleCommand("Set Plant1 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant2 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant3 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant4 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant5 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant6 NetUpdateFrequency 5");
		ConsoleCommand("Set Plant7 NetUpdateFrequency 5");
		ConsoleCommand("Set Boulder NetUpdateFrequency 5");
		ConsoleCommand("Set Urn NetUpdateFrequency 10");
		ConsoleCommand("Set Vase NetUpdateFrequency 10");
		ConsoleCommand("Set WoodenBox NetUpdateFrequency 15");
		ConsoleCommand("Set WoodenBox NetUpdateFrequency 15");
		ConsoleCommand("Set TorchFlame NetUpdateFrequency 0.5"); //DMMutator
	}

	Super.PostBeginPlay();
}


//MonsterHuntArena sets all weapon/ammo respawn time to 3.0

function bool CheckReplacement( Actor Other, out byte bSuperRelevant)
{
	local Inventory Inv;
	local int i;

	bSuperRelevant = 1;
	if ( MyGame.bMegaSpeed && Other.bIsPawn && Pawn(Other).bIsPlayer )
	{
		Pawn(Other).GroundSpeed *= 1.4;
		Pawn(Other).WaterSpeed *= 1.4;
		Pawn(Other).AirSpeed *= 1.4;
		Pawn(Other).AccelRate *= 1.4;
	}

	Inv = Inventory(Other);
	if ( Inv != None )
	{
		if ( Other.IsA('Weapon') )
		{
			if ( Other.IsA('TournamentWeapon') )
				return True;
			For ( i=0 ; i<10 ; i++ )
				if ( Other.IsA(UIWeaponName[i]) && (UIWeaponReplacement[i] != "") )
				{
					ReplaceWith( Other, UIWeaponReplacement[i] );
					return False;
				}
			bSuperRelevant = 0;
			return True;
		}
		if ( Other.IsA('Pickup') )
		{
			Pickup(Other).bAutoActivate = True;
			if ( Other.IsA('TournamentPickup') || Other.IsA('TournamentHealth') )
				return True;
			if ( Other.IsA('SCUBAGear') ) //Auto-activate scuba underwater only
				SCUBAGear(Other).bAutoActivate = Other.Region.Zone.bWaterZone;
		}
	}
	bSuperRelevant = 0;
	return True;
}

defaultproperties
{
	UIWeaponName(0)=DispersionPistol
	UIWeaponName(1)=AutoMag
	UIWeaponName(2)=Stinger
	UIWeaponName(3)=ASMD
	UIWeaponName(4)=Eightball
	UIWeaponName(5)=FlakCannon
	UIWeaponName(6)=Razorjack
	UIWeaponName(7)=GESBioRifle
	UIWeaponName(8)=Rifle
	UIWeaponName(9)=Minigun
	UIWeaponReplacement(0)="MonsterHunt.OLDPistol"
	UIWeaponReplacement(1)="MonsterHunt.OLAutoMag"
	UIWeaponReplacement(2)="MonsterHunt.OLStinger"
	UIWeaponReplacement(3)="MonsterHunt.OLASMD"
	UIWeaponReplacement(4)="MonsterHunt.OLEightball"
	UIWeaponReplacement(5)="MonsterHunt.OLFlakCannon"
	UIWeaponReplacement(6)="MonsterHunt.OLRajorjack"
	UIWeaponReplacement(7)="MonsterHunt.OLGESBioRifle"
	UIWeaponReplacement(8)="MonsterHunt.OLRifle"
	UIWeaponReplacement(9)="MonsterHunt.OLMinigun"
}
