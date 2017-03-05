//******************************************
// MonsterBriefing
//
// Main extension of the enhanced MonsterHunt
//
// Holds player data actors, map progress status
// Can be used to guide players and bots
// Hold up to 32 events to alleviate load on netcode (server)
class MonsterBriefing expands Info;

var MHI_Base InterfaceEventList, HintList;
var MHE_Base MapEventList, TempEvent;
var MonsterPlayerData DataHash[32];
var MonsterPlayerData InactiveDatas;
var MonsterAuthenticator AuthenticatorList;

var int CurrentIndex;
var int CurrentTime;

var int BossCount, KilledBosses, KilledMonsters;
var Texture HuntersIcon;


replication
{
	reliable if ( ROLE==ROLE_Authority )
		BossCount, KilledBosses, KilledMonsters, HuntersIcon;
}

//********************
// XC_Core / XC_Engine
native(1718) final function bool AddToPackageMap( optional string PkgName);
native(3540) final iterator function PawnActors( class<Pawn> PawnClass, out pawn P, optional float Distance, optional vector VOrigin, optional bool bHasPRI, optional Pawn StartAt);
native(3560) static final function bool ReplaceFunction( class<Object> ReplaceClass, class<Object> WithClass, name ReplaceFunction, name WithFunction, optional name InState);
native(3561) static final function bool RestoreFunction( class<Object> RestoreClass, name RestoreFunction, optional name InState);


function InitXCGE( int Version)
{
	if ( Version >= 11 )
		AddtoPackageMap();
	if ( Version >= 19 )
	{
		ReplaceFunction( class'MHCR_ScoreBoard', class'MHCR_ScoreBoard', 'GetCycles', 'GetCycles_XC');
		ReplaceFunction( class'MonsterPlayerData', class'MonsterPlayerData', 'FindIpToCountry', 'FindIpToCountry_XC');
		ReplaceFunction( class'MonsterPlayerData', class'MonsterPlayerData', 'BroadcastMessage', 'BroadcastMessage_XC');
		ReplaceFunction( class'MHE_MonsterSpawner', class'MHE_MonsterSpawner', 'CountPawns', 'CountPawns_XC');
		ReplaceFunction( class'MHCR_Statics', class'MHCR_Statics', 'InCylinder', 'InCylinder_XC');
	}
}

simulated event PostBeginPlay()
{
	local MHI_Base IEvent;
	local MHCR_HUD MHUD;
	local MHCR_ScoreBoard MB;
	local MonsterPlayerData MPD;
	local int XC_Ver;

	if ( Level.NetMode == NM_Client )
	{
		InitialState = 'Client';
		ForEach AllActors( class'MHI_Base', IEvent)
		{
			InsertIEvent( IEvent);
			if ( IEvent.bIsHint )
				InsertHint( IEvent);
		}
		//Register on client HUD as soon as it's spawned
		ForEach AllActors( class'MHCR_HUD', MHUD)
		{
			MHUD.Briefing = self;
			break;
		}
		
		//Get the player datas
		ForEach AllActors( class'MonsterPlayerData', MPD)
			LinkPlayerData( MPD);
			
		//Link to scoreboard
		ForEach AllActors( class'MHCR_ScoreBoard', MB)
		{
			MB.Briefing = self;
			break;
		}
	}
	else
	{
		InitialState = 'Server';
		XC_Ver = int(ConsoleCommand("GET INI:ENGINE.ENGINE.GAMEENGINE XC_VERSION"));
		if ( XC_Ver >= 11 )
			InitXCGE( XC_Ver);
	}

}


state Server
{
	event BeginState()
	{
		SetTimer( Level.TimeDilation, true);
	}
	
	event Timer()
	{
		local MHI_Base MHI, Last;
		local int i;
		
		if ( TimerRate != Level.TimeDilation )
			SetTimer( Level.TimeDilation, true);
		CurrentTime++;
		
		//Get rid of excess dormant events
		if ( CurrentTime % 4 == 0 ) //Every 4 seconds
		{
			For ( MHI=InterfaceEventList ; MHI!=None ; MHI=MHI.NextEvent )
			{
				if ( MHI.bDrawEvent && (i++ >= 32) )
				{
					if ( MHI.bDormant ) //Boom
					{
						MHI.Destroy();
						MHI = Last;
					}
				}
				Last = MHI;
			}
		}
	}
	
	function GenerateCriticalEvents()
	{
		local SpecialEvent SE;
		ForEach AllActors (class'SpecialEvent', SE)
			if ( SE.bBroadcast && SE.Message != "" )
				Spawn( class'MHE_CriticalEvent', self).RegisterEvent( SE);
	}
	
	function GenerateSpawners()
	{
		local ThingFactory TF;
		ForEach AllActors (class'ThingFactory', TF)
			if ( TF.Prototype != None && ClassIsChildOf(TF.Prototype, Class'ScriptedPawn') && TF.Capacity > 1 )
				Spawn( class'MHE_MonsterSpawner', self).RegisterFactory( TF);
	}
	
	function GenerateTranslatorEvents()
	{
		local TranslatorEvent TE;
		ForEach AllActors (class'TranslatorEvent', TE)
			if ( TE.Hint != "" || TE.Message != "" || TE.AltMessage != "" )
				Spawn( class'MHE_TranslatorMessage', self).RegisterEvent( TE);
	}
	
	function GenerateCounters()
	{
		local Counter C;
		ForEach AllActors (class'Counter', C)
			Spawn( class'MHE_Counter', self).RegisterCounter( C);
	}
	
	//Post-Init events one by one, if all are inited in a single row, stop
	function bool PostInit()
	{
		local int Initialized, Total;
		
		if ( TempEvent == None || TempEvent.bDeleteMe )
		{
			For ( TempEvent=MapEventList ; TempEvent!=None ; TempEvent=TempEvent.NextEvent )
				if ( !TempEvent.bPostInit )
					Goto INIT_EVENT;
			return true;
		}
		
	INIT_EVENT:
		TempEvent.PostInit();
		TempEvent = TempEvent.NextEvent;
		return false;
	}
	
Begin:
	Sleep( 0.01);
	Level.Game.KillCredit( self); //Generic communication with MonsterHunt
	GenerateCriticalEvents();
	Sleep( 0.01);
	GenerateSpawners();
	Sleep( 0.01);
	GenerateTranslatorEvents();
	Sleep( 0.01);
	GenerateCounters();
	
	While ( !PostInit() )
		Sleep( 0.01);
}

simulated state Client
{
Begin:
	Sleep( Level.TimeDilation+FRand() );
	PlayerDataIntegrity();
	Goto('Begin');
}


//********************************************************
// Player Authenticator methods

function AuthFinished( MonsterAuthenticator MA)
{
	local Pawn P;
	local MonsterPlayerData MPD;

	P = Pawn(MA.Owner);
	if ( P == None || P.PlayerReplicationInfo == None ) //Should never happen
		return;
	
	MPD = AttemptRecover( P.PlayerReplicationInfo, MA);
	if ( MPD == None )
	{
		MPD = SpawnPlayerData( P.PlayerReplicationInfo);
		MPD.Briefing = self;
	}
	MPD.Activate( P.PlayerReplicationInfo, MA.FingerPrint);
	LinkPlayerData( MPD);
	MPD.TeamSkin = MA.TeamSkin;
}



final function MonsterAuthenticator GetAuthenticator( Pawn Other)
{
	local MonsterAuthenticator M;
	For ( M=AuthenticatorList ; M!=None ; M=M.NextAuthenticator )
		if ( M.Owner == Other )
			return M;
	M = SpawnAuthenticator( Other);
	M.Briefing = self;
	M.NextAuthenticator = AuthenticatorList;
	AuthenticatorList = M;
	return M;
}

function MonsterAuthenticator SpawnAuthenticator( Pawn Other)
{
	return Spawn(class'MonsterAuthenticator', Other); //Override authenticator spawn in modifications
}


//********************************************************
// Interface methods

simulated function InsertIEvent( MHI_Base IEvent)
{
	local MHI_Base MHI;
	if ( InterfaceEventList == None || InterfaceEventList.EventIndex < IEvent.EventIndex )
	{
		IEvent.NextEvent = InterfaceEventList;
		InterfaceEventList = IEvent;
	}
	else
	{
		For ( MHI=InterfaceEventList ; MHI!=None ; MHI=MHI.NextEvent )
		{
			if ( MHI.NextEvent == None )
			{
				MHI.NextEvent = IEvent;
				break;
			}
			else if ( MHI.NextEvent.EventIndex < IEvent.EventIndex )
			{
				IEvent.NextEvent = MHI.NextEvent;
				MHI.NextEvent = IEvent;
				break;
			}
		}
	}
}

simulated function RemoveIEvent( MHI_Base IEvent)
{
	local MHI_Base MHI;
	if ( InterfaceEventList == IEvent )
		InterfaceEventList = IEvent.NextEvent;
	else
	{
		For ( MHI=InterfaceEventList ; MHI!=None ; MHI=MHI.NextEvent )
			if ( MHI.NextEvent == IEvent )
			{
				MHI.NextEvent = IEvent.NextEvent;
				break;
			}
	}
	IEvent.NextEvent = None;
}

simulated function InsertHint( MHI_Base Hint)
{
	local MHI_Base MHI;
	For ( MHI=HintList ; MHI!=None ; MHI=MHI.NextHint ) //Critical
		if ( MHI == Hint )
			return;
	Hint.NextHint = HintList;
	HintList = Hint;
	Hint.bIsHint = true;
}

simulated function RemoveHint( MHI_Base Hint)
{
	local MHI_Base MHI;
	Hint.bIsHint = false;
	if ( HintList == Hint )
		HintList = Hint.NextHint;
	else
	{
		For ( MHI=HintList ; MHI!=None ; MHI=MHI.NextHint )
			if ( MHI.NextHint == Hint )
			{
				MHI.NextHint = Hint.NextHint;
				break;
			}
	}
	Hint.NextHint = None;
}

function RemoveEvent( MHE_Base MEvent)
{
	local MHE_Base MHE;
	if ( MapEventList == MEvent )
		MapEventList = MEvent.NextEvent;
	else
	{
		For ( MHE=MapEventList ; MHE!=None ; MHE=MHE.NextEvent )
			if ( MHE.NextEvent == MEvent )
			{
				MHE.NextEvent = MEvent.NextEvent;
				break;
			}
	}
	MEvent.NextEvent = None;
}


//********************************************************
// PlayerData methods

simulated function PlayerDataIntegrity()
{
	local MonsterPlayerData MPD, Last;
	local int i;
	local PlayerReplicationInfo PRI;

	For ( i=0 ; i<32 ; i++ )
		For ( MPD=DataHash[i] ; MPD!=None ; MPD=MPD.HashNext )
		{
			if ( (MPD.PlayerID % 32) != i )
			{
				//Unlink
				if ( Last != None )
					Last.HashNext = MPD.HashNext;
				else
					DataHash[i] = MPD.HashNext;
				//Relink
				LinkPlayerData( MPD);
				break;
			}
			Last = MPD;
		}
}

simulated final function MonsterPlayerData GetPlayerData( int PlayerID)
{
	local MonsterPlayerData MPD;
	For ( MPD=DataHash[PlayerID%32] ; MPD!=None ; MPD=MPD.HashNext )
		if ( MPD.PlayerID == PlayerID )
			return MPD;
}

function MonsterPlayerData SpawnPlayerData( PlayerReplicationInfo aPRI)
{
	return Spawn( class'MonsterPlayerData', aPRI.Owner);
}

final function MonsterPlayerData AttemptRecover( PlayerReplicationInfo aPRI, MonsterAuthenticator MA)
{
	local int i;
	local MonsterPlayerData MPD, Last;

	//Handle a recently authenticated player
	//Look among disconnected players
	For ( MPD=InactiveDatas ; MPD!=None ; MPD=MPD.HashNext )
	{
		if ( MPD.FingerPrint == MA.FingerPrint )
		{
			if ( Last != None )
				Last.HashNext = MPD.HashNext;
			else
				InactiveDatas = MPD.HashNext;
			MPD.Activate( aPRI, MA.FingerPrint );
			break;
		}
		Last = MPD;
	}
	return MPD;
}

simulated final function LinkPlayerData( MonsterPlayerData pData)
{
	local int i;
	i = pData.PlayerID%32;
	pData.HashNext = DataHash[i];
	DataHash[i] = pData;
}

simulated final function UnlinkPlayerData( MonsterPlayerData pData)
{
	local MonsterPlayerData MPD, Last;
	local int i;

	i = pData.PlayerID%32;
	For ( MPD=DataHash[i] ; MPD!=None ; MPD=MPD.HashNext )
	{
		if ( MPD == pData )
		{
			if ( Last != None )
				Last.HashNext = MPD.HashNext;
			else
				DataHash[i] = MPD.HashNext;
			break;
		}
		Last = MPD;
	}
	//Servers need to keep data for recovery
	if ( Level.NetMode != NM_Client )
	{
		MPD.HashNext = InactiveDatas;
		InactiveDatas = MPD;
	}
}


defaultproperties
{
	NetUpdateFrequency=1
	HuntersIcon=Texture'Botpack.Icons.I_TeamN'
	bAlwaysRelevant=True
}