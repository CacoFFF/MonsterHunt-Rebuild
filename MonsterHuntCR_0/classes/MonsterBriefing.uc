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
var MHE_Base MapEventList, TempEvent; //TempEvent is used during initialization and pathfinding
var MonsterPlayerData DataHash[32];
var MonsterPlayerData InactiveDatas;
var MonsterAuthenticator AuthenticatorList;
var FV_PathBlocker BlockerList;
var int EventQueryTag;
var int PathQueryTag;

var int CurrentIndex;
var int CurrentTime;

var int BossCount, KilledBosses, KilledMonsters;
var Texture HuntersIcon;


replication
{
	reliable if ( ROLE==ROLE_Authority )
		BossCount, KilledBosses, KilledMonsters, HuntersIcon;
}


simulated event PostBeginPlay()
{
	local MHI_Base IEvent;
	local MHCR_HUD MHUD;
	local MHCR_ScoreBoard MB;
	local MonsterPlayerData MPD;

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
		AddtoPackageMap();
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
	
	function GenerateButtons()
	{
		local Trigger T;
		local Mover M;

		ForEach AllActors( class'Trigger', T)
			if ( (T.Class == class'Trigger') )
				Spawn( class'MHE_SingularEvent', self).RegisterMechanism( T);
				
		ForEach AllActors( class'Mover', M)
			if ( (M.InitialState == 'BumpOpenTimed' || M.InitialState == 'BumpButton') || M.InitialState == 'StandOpenTimed' )
			{
				if ( M.Event != '' || M.BumpEvent != '' || M.PlayerBumpEvent != '' )
					Spawn( class'MHE_SingularEvent', self).RegisterMechanism( M);
			}
	}
	
	function GenerateMonsters()
	{
		local ScriptedPawn S;
		local MHE_Monster MHE_B, MHE_C;
		
		ForEach AllActors( class'ScriptedPawn', S)
			if ( S.Event != '' )
			{
				MHE_B = MHE_Monster(MapEventList);
				if ( MHE_B != None )	MHE_C = MHE_B.AvailableForEvent( S.Event);
				if ( MHE_C == None )	MHE_C = Spawn( class'MHE_Monster');
				MHE_C.RegisterMonster( S);
			}
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
			TempEvent = None;
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
	Sleep( 0.01);
	GenerateButtons();
	Sleep( 0.01);
	GenerateMonsters();
	Sleep( 0.01);
	
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
// Server events

function MHE_Base GetNextBotAttractor()
{
	local int Loop;

	EventQueryTag++;
	if ( TempEvent != None )
	{
		if ( TempEvent.bDeleteMe )
			TempEvent = None;
		else
			TempEvent = TempEvent.NextEvent;
	}
	
	//Perform a full round trip
	while ( Loop++ <= 1 )
	{
		while ( (TempEvent != None) && (TempEvent.EventQueryTag != EventQueryTag) )
		{
			TempEvent.EventQueryTag = EventQueryTag;
			if ( TempEvent.bAttractBots && !TempEvent.bCompleted && (TempEvent.DeferTo != None) )
				return TempEvent;
			TempEvent = TempEvent.NextEvent;
		}
		TempEvent = MapEventList;
	}
	TempEvent = None;
}

//Prepare a list of available events (direct triggers and chained triggers)
function EnumerateTriggers( name aEvent, out MHE_Base Events[16], out int EventCount )
{
	local MHE_Base Link;
	local name tmpEvent;
	local int i, LoopCount;

	PathQueryTag++;
	EventCount = 0;
NEXT_TRIGGER: //Trigger scanner
	Link = FindNextTrigger( aEvent, Link);
	if ( (Link != None) && (Link.PathQueryTag != PathQueryTag) )
	{
		Link.PathQueryTag = PathQueryTag;
		if ( !Link.bCompleted && (EventCount < 16) )
			Events[EventCount++] = Link;
		Goto NEXT_TRIGGER;
	}
	if ( LoopCount++ > 50 ) //Triggering each other I see?
		return;
	while ( i<EventCount )
	{
		tmpEvent = Events[i].RequiredEvent();
		if ( (tmpEvent != '') && (tmpEvent != aEvent) ) //This event needs to be enabled
		{
			Events[i] = Events[--EventCount]; //Cache and remove from list
			aEvent = tmpEvent; //Specify new Event to search
			Link = None;
			Goto NEXT_TRIGGER;
		}
		i++;
	}
}

function SortEventsByProximity( vector V, out MHE_Base Events[16], int EventCount)
{
	local MHE_Base Link;
	local float Dist;
	local int i, Top;
	
	//Sort by distance
	For ( Top=1 ; Top<EventCount ; Top++ )
	{
		Link = Events[Top];
		Dist = VSize(Link.Location-V);
		i = Top;
		while ( (i > 0) && (Dist < VSize(Events[i-1].Location-V)) )
			Events[i] = Events[--i];
		Events[i] = Link;
	}
}

function MHE_Base FindNextTrigger( name aEvent, optional MHE_Base LastFound)
{
	local MHE_Base Link;
	if ( LastFound != None )	Link = LastFound.NextEvent;
	else						Link = MapEventList;
	while ( (Link != None) && !Link.CausesEvent(aEvent) )
		Link = Link.NextEvent;
	return Link;
}

function RemoveEvent( MHE_Base MEvent)
{
	local MHE_Base MHE;
	if ( TempEvent == MEvent )
		TempEvent = MEvent.NextEvent;
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
// Triggered path blockers
function FV_PathBlocker GetPathBlocker( name aTag)
{
	local FV_PathBlocker Result;

	if ( BlockerList != None )
		Result = BlockerList.FindByTag( aTag);
	if ( Result == None )
		Result = Spawn(class'FV_PathBlocker', self, aTag);
	return Result;
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
