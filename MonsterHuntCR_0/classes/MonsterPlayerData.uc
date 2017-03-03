//**************************************************
// MonsterPlayerData
// Extra player info that works as extension of PRI
// By keeping it a separate actor, won't break VA
// This will also be used for info recovery reasons
class MonsterPlayerData expands ReplicationInfo;

var MonsterPlayerData HashNext;
var MonsterBriefing Briefing;
var PlayerReplicationInfo PRI;


//Public stats
var int PlayerID;
var int MonsterKills;
var int BossKills;
var int ObjectivesTaken;
var int Health;
var int Armor;
var int AccDamage;
var int ActiveMinutes;

//Recovery-related stats
var float SavedScore;
var float SavedDeaths;
var string SavedName;
var string FingerPrint;

//Internal data
var bool bAuthenticated;
var byte TeamSkin;
var float SecondTimer;
var int OldPlayerID;
var int ActiveSeconds;

//IpToCountry
var Actor Ip2C_Actor;
var int Ip2C_CountDown;
var string Ip2C_Prefix;
var Texture Ip2C_Flag;
var bool bFlagCached;

replication
{
	reliable if ( Role==ROLE_Authority )
		PlayerID, Health, Armor, MonsterKills, BossKills, ObjectivesTaken, Ip2C_Prefix, ActiveMinutes;
}


native(3540) final iterator function PawnActors( class<Pawn> PawnClass, out pawn P, optional float Distance, optional vector VOrigin, optional bool bHasPRI, optional Pawn StartAt);
native(3553) final iterator function DynamicActors( class<actor> BaseClass, out actor Actor, optional name MatchTag );

simulated event SetInitialState()
{
	if ( Level.NetMode == NM_Client )
		InitialState = 'Client';
	Super.SetInitialState();
}

//In clients this actor has to find the Briefing
simulated event PostNetBeginPlay()
{
	ForEach AllActors (class'MonsterBriefing', Briefing)
	{
		Briefing.LinkPlayerData( self);
		break;
	}
	bFlagCached = false;
	OldPlayerID = PlayerID;
}

simulated function CacheFlag()
{
	local Texture Tex;

	if ( bFlagCached || Ip2C_Prefix == "" || (Asc(Ip2C_Prefix) == 42) )
		return;

	Ip2C_Flag = Texture(DynamicLoadObject("CountryFlags2."$Ip2C_Prefix, class'Texture', true));
	if ( Ip2C_Flag == None )
		Ip2C_Flag = Texture(DynamicLoadObject("CountryFlags5."$Ip2C_Prefix, class'Texture', true));
	if ( Ip2C_Flag == None )
		Ip2C_Flag = Texture(DynamicLoadObject("CountryFlags3."$Ip2C_Prefix, class'Texture', true));
	bFlagCached = true;
}

function Activate( PlayerReplicationInfo NewPRI, string NewFingerPrint)
{
	if ( bAuthenticated )
		return;
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
	ResolveCountry();
}

simulated function DeActivate()
{
	bAuthenticated = false;
	if ( Briefing != None && !Briefing.bDeleteMe )
		Briefing.UnlinkPlayerData( self);
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
		ActiveMinutes = (++ActiveSeconds) / 60;
		if ( (Ip2C_CountDown > 0) && (--Ip2C_CountDown == 0) )
			ResolveCountry();
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

//If Ip is previously cached then it'll work on first try
//Otherwise let IpToCountry perform a query and try again in 15 seconds for cached version
function ResolveCountry()
{
	local string Temp;

	if ( PlayerPawn(Owner) == None || NetConnection(PlayerPawn(Owner).Player) == None || !FindIpToCountry() )
		return;

	bFlagCached = false;
	if ( Ip2C_Prefix == "" )
	{
		Ip2C_Prefix = "*2";
		Ip2C_CountDown = 15;
QUERY:
		Temp = PlayerPawn(Owner).GetPlayerNetworkAddress();
		Temp = Ip2C_Actor.GetItemName( Left(Temp,InStr(Temp, ":")) );
		if ( Temp ~= "!Disabled" ) //Don't try again
			Ip2C_CountDown = 0;
		else if ( Left( Temp, 1) != "!" )
		{
			Ip2C_Prefix = SelElem( Temp, 5);
			if ( Ip2C_Prefix == "" ) //Unknown country?
				Ip2C_CountDown = 0;
		}
	}
	else if ( Ip2C_Prefix == "*2" )
		Goto QUERY;
}



//******************************
// Utilitary methods
//******************************
final function bool FindIpToCountry()
{
	if ( Ip2C_Actor != None )
		return true;
	ForEach AllActors( class'Actor', Ip2C_Actor, 'IpToCountry')
		return true;
}

final function bool FindIpToCountry_XC()
{
	if ( Ip2C_Actor != None )
		return true;
	ForEach DynamicActors( class'Actor', Ip2C_Actor, 'IpToCountry')
		return true;
}

event BroadcastMessage( coerce string Msg, optional bool bBeep, optional name Type )
{
	local PlayerReplicationInfo PRI;

	if (Type == '')	Type = 'Event';
	ForEach AllActors( class'PlayerReplicationInfo', PRI)
		if ( PlayerPawn(PRI.Owner) != None )
			PlayerPawn(PRI.Owner).ClientMessage( Msg, Type, bBeep );
}

event BroadcastMessage_XC( coerce string Msg, optional bool bBeep, optional name Type )
{
	local PlayerPawn P;

	if (Type == '')	Type = 'Event';
	ForEach PawnActors ( class'PlayerPawn', P,,, true)
		P.ClientMessage( Msg, Type, bBeep);
}

static final function string SelElem(string Str, int Elem)
{
	local int pos;
	while( Elem--> 1 )
		Str=Mid( Str, InStr(Str,":")+1);
	pos = InStr(Str, ":");
	if( pos != -1 )
    	Str = Left( Str, pos);
    return Str;
}


defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	PlayerID=-1
	NetUpdateFrequency=2.0
}
