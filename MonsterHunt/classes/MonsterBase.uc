//***************************
// MonsterBase
// MonsterHunt's base mutator
class MonsterBase expands Mutator
	config(MonsterHunt);

var MonsterHunt Game;
var() name UIWeaponName[10];
var() string UIWeaponReplacement[10];


//XC_Engine
native(1718) final function bool AddToPackageMap( optional string PkgName);
native(1719) final function bool IsInPackageMap( optional string PkgName, optional bool bServerPackagesOnly); //Second parameter doesn't exist in 227!


//Deny game breaking mutators
function AddMutator( Mutator M)
{
	if ( M == None || M.bDeleteMe )
		return;
	if ( M.IsA('LowGrav') || M.IsA('JumpMatch') || M.IsA('InstaGibDM') || M.IsA('DMMutator') )
		return;
	Super.AddMutator(M);
}

function PreCacheReferences()
{
	Spawn(class'RockTentacleCarcass');
}

function PostBeginPlay()
{
	SaveConfig();
	Game = MonsterHunt(Level.Game);
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
	//Fix other bugs
	ConsoleCommand("Set Tentacle CarcassType RockTentacleCarcass"); //Fix tentacle carcasses with custom skins
	
	Super.PostBeginPlay();
}

function ValidateWeapons()
{
	local int i, j, iP;
	local string Added[10];

	//If weapon cannot be loaded, remove from list
	For ( i=0 ; i<10 ; i++ )
		if ( DynamicLoadObject( UIWeaponReplacement[i], class'Class') == None )
			UIWeaponReplacement[i] = "";
	if ( (Level.NetMode != NM_Standalone) && (int(ConsoleCommand("GET INI:ENGINE:ENGINE.GAMEENGINE XC_VERSION")) >= 13) )
	{
		For ( i=0 ; i<10 ; i++ )
			if ( UIWeaponReplacement[i] != "" )
			{
				//Don't search for package linkers multiple times
				For ( j=0 ; j<iP ; j++ )
					if ( Added[j] == Left(UIWeaponReplacement[i], Len(Added[j])) )
						Goto NO_ADD;
				//Package not previously added
				Added[iP] = Left( UIWeaponReplacement[i], InStr(UIWeaponReplacement[i],"."));
				AddToPackageMap( Added[iP++] );
				NO_ADD:
			}
	}
}

//MonsterHuntArena sets all weapon/ammo respawn time to 3.0

function bool CheckReplacement( Actor Other, out byte bSuperRelevant)
{
	local Inventory Inv;
	local int i;

	bSuperRelevant = 1;
	if ( Game.bMegaSpeed && Other.bIsPawn && Pawn(Other).bIsPlayer )
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
			if ( (Inv.RespawnTime > 0) && Game.IsA('MonsterHuntArena') )
				Inv.RespawnTime = MonsterHuntArena(Game).WeaponRespawnTime;
			if ( Other.IsA('TournamentWeapon') || !Game.bReplaceUIWeapons )
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
			if ( Other.IsA('Ammo') && (Inv.RespawnTime > 0) && Game.IsA('MonsterHuntArena') )
				Inv.RespawnTime = MonsterHuntArena(Game).AmmoRespawnTime;
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
	UIWeaponReplacement(6)="MonsterHunt.OLRazorJack"
	UIWeaponReplacement(7)="MonsterHunt.OLGESBioRifle"
	UIWeaponReplacement(8)="MonsterHunt.OLRifle"
	UIWeaponReplacement(9)="MonsterHunt.OLMinigun"
}
