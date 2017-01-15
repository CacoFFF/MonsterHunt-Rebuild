//**************************************************
// MonsterPlayerData
// Extra player info that works as extension of PRI
// By keeping it a separate actor, won't break VA
// This will also be used for info recovery reasons
class MonsterPlayerData expands ReplicationInfo;

var MonsterPlayerData HashNext;
var MonsterReplicationInfo MRI;
var PlayerReplicationInfo PRI;

//Public stats
var int PlayerID;
var int MonsterKills;
var int BossKills;
var int ObjectivesTaken;
var int Health;
var int Armor;
var int ActiveTime;
var float AccDamage;
var float FullDamage;
var string CountryPrefix;
var Texture CachedFlag;

//Recovery-related stats
var float SavedScore;
var float SavedDeaths;
var string SavedName;
var string FingerPrint;

//Internal data
var bool bAuthenticated;
var byte TeamSkin;
var float SecondTimer;

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		PlayerID;
	reliable if ( Role==ROLE_Authority )
		Health, Armor, MonsterKills, BossKills, FullDamage, CountryPrefix, ActiveTime;
}

//In clients this actor has to find the MRI
simulated event PostNetBeginPlay()
{
	ForEach AllActors (class'MonsterReplicationInfo', MRI)
	{
		MRI.LinkPlayerData( self);
		break;
	}
}

simulated function CacheFlag()
{
}


function Activate( PlayerReplicationInfo NewPRI, string NewFingerPrint)
{
	HashNext = None;
	bAuthenticated = True;
	bAlwaysRelevant = True;
	PRI = NewPRI;
	PlayerID = PRI.PlayerID;
	if ( FingerPrint == "" )
		FingerPrint = NewFingerPrint;
	else
	{
		if ( SavedName != NewPRI.PlayerName )
			BroadcastMessage( "Recovered score for"@NewPRI.PlayerName@"("$SavedName$")", true);
		else
			BroadcastMessage( "Recovered score for"@SavedName, true);
		NewPRI.Score = SavedScore;
		NewPRI.Deaths = SavedDeaths;
	}
	SetOwner( NewPRI.Owner);
	SetTimer( 0.1 + Level.TimeDilation * FRand(), False);
}

simulated function DeActivate()
{
	bAuthenticated = false;
	if ( MRI != None && !MRI.bDeleteMe )
		MRI.UnlinkPlayerData( self);
	//The clients will stop receiving this info and it'll auto-unlink as well (5 second delay)
	if ( Level.NetMode != NM_Client )
		bAlwaysRelevant = false;
}

simulated event Destroyed()
{
	Super.Destroyed();
	if ( bAuthenticated )
		DeActivate();
}

event Tick( float DeltaTime)
{
	if ( (SecondTimer+=DeltaTime) > 0 )
	{
		SecondTimer -= Level.TimeDilation;
		TimerSecond();
	}
}

function TimerSecond()
{
	if ( bAuthenticated )
	{
		ActiveTime++;
	}
}


event Timer()
{
	local Inventory Inv;
	if ( PRI == None || PRI.bDeleteMe || PRI.Owner == None || PRI.Owner.bDeleteMe )
		DeActivate();
	else
	{
		SavedScore = PRI.Score;
		SavedDeaths = PRI.Deaths;
		SavedName = PRI.PlayerName;
		SetTimer( Level.TimeDilation * FRand(), False);
		Health = Max(0,Pawn(PRI.Owner).Health);
		Armor = 0;
		For ( Inv=PRI.Owner.Inventory ; Inv!=None ; Inv=Inv.Inventory )
			if ( Inv.bIsAnArmor )
				Armor += Inv.Charge;
	}
}


event BroadcastMessage( coerce string Msg, optional bool bBeep, optional name Type )
{
	local PlayerReplicationInfo PRI;

	if (Type == '')
		Type = 'Event';

	ForEach AllActors( class'PlayerReplicationInfo', PRI)
		if ( PlayerPawn(PRI.Owner) != None )
			PlayerPawn(PRI.Owner).ClientMessage( Msg, Type, bBeep );
}



defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	PlayerID=-1
	NetUpdateFrequency=2.0
}
