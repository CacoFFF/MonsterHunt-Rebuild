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
var int ObjectivesTaken;
var float AccDamage;
var float FullDamage;

//Recovery-related stats
var float SavedScore;
var float SavedDeaths;
var string SavedName;
var string FingerPrint;

//Internal data
var bool bAuthenticated;
var int ActiveTime;
var byte TeamSkin;

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		PlayerID;
	reliable if ( Role==ROLE_Authority )
		MonsterKills, FullDamage;
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

function Activate( PlayerReplicationInfo NewPRI, string NewFingerPrint)
{
	HashNext = None;
	bAuthenticated = True;
	bAlwaysRelevant = True;
	PRI = NewPRI;
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
	SetTimer( Level.TimeDilation * FRand(), False);
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

event Timer()
{
	if ( PRI == None || PRI.bDeleteMe )
		DeActivate();
	else
	{
		SavedScore = PRI.Score;
		SavedDeaths = PRI.Deaths;
		SavedName = PRI.PlayerName;
		SetTimer( Level.TimeDilation * FRand(), False);
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
