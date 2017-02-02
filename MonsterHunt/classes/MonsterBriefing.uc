//******************************************
// MonsterStats
// Displays map progress status
// Can be used to guide players and bots
// Hold up to 32 events to alleviate load on netcode (server)
class MonsterBriefing expands Info;

var MHI_Base InterfaceEventList;
var MHE_Base MapEventList;
var int CurrentIndex;
var int CurrentTime;
var int IEventCount;
var bool bReady;

//PostNetBeginPlay fails to execute, likely due to Role/NativeReplication code
simulated event PostBeginPlay()
{
	local MHI_Base IEvent;

	if ( Level.NetMode == NM_Client )
	{
		ForEach AllActors( class'MHI_Base', IEvent)
			InsertIEvent( IEvent);
	}
	else
		InitialState = 'Server';
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
		if ( (IEventCount >= 32) && (CurrentTime % 4 == 0) ) //Every 4 seconds
		{
			For ( MHI=InterfaceEventList ; MHI!=None ; MHI=MHI.NextEvent )
			{
				if ( i++ >= 32 )
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
				Spawn( class'MHE_CriticalEvent').RegisterEvent( SE);
	}
	
	function GenerateSpawners()
	{
		local ThingFactory TF;
		ForEach AllActors (class'ThingFactory', TF)
			if ( TF.Prototype != None && ClassIsChildOf(TF.Prototype, Class'ScriptedPawn') && TF.Capacity > 1 )
				Spawn( class'MHE_MonsterSpawner').RegisterFactory( TF);
	}
Begin:
	Sleep( 0.1);
	GenerateCriticalEvents();
	Sleep( 0.1);
	GenerateSpawners();
}




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
	IEventCount++;
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
	IEventCount--;
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

defaultproperties
{
	bAlwaysRelevant=True
	NetUpdateFrequency=1
}
