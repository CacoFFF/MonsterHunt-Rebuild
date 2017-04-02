//******************************
// MHE_Base
// Status indicator of map stuff
class MHE_Base expands Triggers;

const MHS = class'MHCR_Statics';

var(Debug) MonsterBriefing Briefing;
var(Debug) MHE_Base NextEvent;
var(Debug) MHI_Base Interface;
var(Debug) NavigationPoint DeferTo;
//Pointer to net breifing element!
var(Debug) bool bDiscovered;
var(Debug) bool bPostInit;
var(Debug) bool bCompleted; //Disable if the event is temporarily unavailable (ex: interpolating button)
var(Debug) bool bQueriedByBot;
var(Debug) bool bAttractBots; //Never enable if Event cannot yet function or if it doesn't unlock anything (ex: disabled trigger, door trigger)
var(Debug) bool bAwardedPoint;
//Regarding attraction after hitting a door
//The MHE_Base actor's Tag can redirect

var(DebugEvents) bool bSimpleDoorTrigger;
var(DebugEvents) bool bUnlocksStructure;
var(DebugEvents) bool bUnlocksRoutes;
var(DebugEvents) bool bTriggersPlayerStart;
var(DebugEvents) bool bTriggersCounter;
var(DebugEvents) bool bTriggersPawn;
var(DebugEvents) bool bTriggersFactory;
var(DebugEvents) bool bTriggersMover;
var(DebugEvents) bool bTogglesTriggers;
var(DebugEvents) bool bModifiesTriggers; //Important

var(DebugEvents) string EventChain;
var int AnalyzeDepth;


//Query tags are good tools
var int PathQueryTag;
var int EventQueryTag;

var(Debug) enum EDeferToMode
{
	DTM_None,
	DTM_InCollision,
	DTM_Nearest,
	DTM_NearestVisible
} DeferToMode;

native(3553) final iterator function DynamicActors( class<actor> BaseClass, out actor Actor, optional name MatchTag );

function Discover()
{
	bDiscovered = true;
}

function PostInit()
{
	bPostInit = true;
}





//=========================================
//=========================================
// Event handler

function name RequiredEvent(); //If this MHE_Base needs to be enabled, provide a tag

function RequiredForEvent() //Somebody needs to activate this MHE_Base in order to activate an event
{
	bQueriedByBot = true;
}

function ResetEvents()
{
	bSimpleDoorTrigger = false;
	bUnlocksStructure = false;
	bUnlocksRoutes = false;
	bTriggersPlayerStart = false;
	bTriggersCounter = false;
	bTriggersPawn = false;
	bTriggersFactory = false;
	bTriggersMover = false;
	bTogglesTriggers = false;
	bModifiesTriggers = false;
	EventChain = ";";
}

function bool CausesEvent( name aEvent)
{
	return HasEvent( aEvent);
}

final function bool HasEvent( name aEvent)
{
	return InStr( EventChain, ";"$aEvent$";") != -1;
}

final function AddEvent( name aEvent)
{
	EventChain = EventChain $ string(aEvent) $ ";";
}

function AnalyzeEvent( name aEvent)
{
	local Actor A;
	local Mover M;
	local NavigationPoint N;
	local int i;
	//Avoid registering the mechanism's tag if possible
	if ( aEvent == '' || aEvent == 'None' || aEvent == Tag || (AnalyzeDepth > 20) || HasEvent(aEvent) )
		return;
	AddEvent(aEvent);
	
	AnalyzeDepth++;
	ForEach AllActors( class'Actor', A, aEvent)
	{
		if ( A.IsA('Mover') )
		{
			if ( InStr( A.GetStateName(),"Trigger") != -1 ) 
			{
				if ( VSize( A.Location - Location) < 600 )
					bSimpleDoorTrigger = true;
				else
					bTriggersMover = true;
				M = Mover(A);
				if ( !M.bInterpolating && (M.KeyNum == 0) )
				{
					AnalyzeEvent( M.Event); //Identify this Mover's event as caused by self
					if ( !M.IsInState('TriggerToggle') && (M.bTriggerOnceOnly || (M.StayOpenTime > 9999)) )
						bUnlocksStructure = true; //TriggerToggle ignores bTriggerOnceOnly!!!
				}
			}
		}
		else if ( A.IsA('Triggers') )
		{
			if ( A.IsA('Counter') )
			{
				bTriggersCounter = bTriggersCounter || (Counter(A).NumToCount > 0);
			}
			else if ( A.IsA('Dispatcher') )
			{
				For ( i=0 ; i<8 ; i++ )
					AnalyzeEvent( Dispatcher(A).OutEvents[i] );
			}
			else if ( A.IsA('Trigger') )
			{
				if ( A.bCollideActors )
				{
					if ( A.IsInState('TriggerToggle') )
					{
						bTogglesTriggers = true;
						bModifiesTriggers = bModifiesTriggers || Trigger(A).bTriggerOnceOnly;
					}
					else if ( (A.IsInState('OtherTriggerTurnsOn') && !Trigger(A).bInitiallyActive)
							|| (A.IsInState('OtherTriggerTurnsOff') && Trigger(A).bInitiallyActive) )
						bModifiesTriggers = true;
				}
			}
		}
		else if ( A.bIsPawn )
		{
			bTriggersPawn = true;
		}
		else if ( A.IsA('ThingFactory') )
		{
			bTriggersFactory = bTriggersFactory || (ThingFactory(A).Capacity > 0);
		}
		else if ( A.IsA('NavigationPoint') )
		{
			N = NavigationPoint(A);
			bTriggersPlayerStart = bTriggersPlayerStart || N.IsA('PlayerStart');
			bUnlocksRoutes = bUnlocksRoutes || (!N.IsA('PlayerStart') && (!N.IsA('BlockedPath') || (N.ExtraCost > 0)) );
		}
		else if ( A.IsA('ExplodingWall') )
		{
			AnalyzeEvent( A.Event);
		}
	}
	AnalyzeDepth--;
}



//=========================================
//=========================================
// BOT attraction

function bool ShouldAttractBots()
{
	return (bUnlocksStructure || bTriggersCounter || bUnlocksRoutes || bModifiesTriggers || bTriggersPlayerStart || bQueriedByBot);
}


function bool ShouldDefer( Pawn Other)
{
	if ( DeferTo != None )
	{
		if ( DeferToMode == DTM_InCollision ) //If path is touching this, defer
			return true;
		if ( DeferToMode >= DTM_Nearest ) //If path isn't touching, defer if not on the path
		{
			return !( MHS.static.ActorsTouching( Other, DeferTo, 20, 40) && Other.FastTrace(DeferTo.Location));
		}
	}
}

function FindDeferPoint( Actor DeferFor)
{
	local NavigationPoint N, Best;
	local float Weight, BestWeight;
	local vector V, HN;
	local Actor A;
	
	if ( DeferToMode == DTM_None )
		return;
	if ( DeferToMode == DTM_InCollision )
	{
		V.X = CollisionRadius + 17;
		V.Z = CollisionHeight + 39;
		Weight = VSize(V);
		ForEach RadiusActors( class'NavigationPoint', N, Weight)
			if ( MHS.static.ActorsTouching(self,N) && (N.UpstreamPaths[0] != -1) )
			{
				if ( N.IsA('MonsterTriggerMarker') )
				{
					Best = N;
					break;
				}
				if ( (Best == None) || (Best.ExtraCost > N.ExtraCost) )
					Best = N;
			}
		if ( Best == None )
			DeferToMode = DTM_NearestVisible;
	}
	if ( DeferToMode == DTM_NearestVisible )
	{
		ForEach RadiusActors( class'NavigationPoint', N, 1500)
		{
			Weight = 1000 + 500*int(N.IsA('MonsterTriggerMarker')) - VSize( (N.Location - Location) * vect(1,1,3) );
			if ( (Weight > BestWeight) && (N.UpstreamPaths[0] != -1) )
			{	//Make sure trace reaches this actor or DeferFor
				ForEach TraceActors( class'Actor', A, V, HN, Location, N.Location)
				{
					if ( A == self || A == DeferFor )
						break;
					if ( A == Level )
					{
						if ( !MHS.static.InCylinder( V-Location, CollisionRadius, CollisionHeight) )
							N = None;
						break;
					}
				}
				if ( N != None )
				{
					Best = N;
					BestWeight = Weight;
				}
			}
		}
		if ( Best == None ) //Force onto MonsterTriggerMarker actor even if not visible
		{
			ForEach RadiusActors( class'NavigationPoint', N, 500)
			{
				Weight = 150 + 350*int(N.IsA('MonsterTriggerMarker')) - VSize( (N.Location - Location) * vect(1,1,4) );
				if ( (Weight > BestWeight) && (N.UpstreamPaths[0] != -1) )
				{	//Make sure trace reaches this actor or DeferFor
					Best = N;
					BestWeight = Weight;
				}
			}
		}
	}
	if ( DeferToMode == DTM_Nearest )
	{
		ForEach RadiusActors( class'NavigationPoint', N, 1500)
		{
			Weight = 1000 + 500*int(N.IsA('MonsterTriggerMarker')) - VSize( (N.Location - Location) * vect(1,1,4) );
			if ( (Weight > BestWeight) && (N.UpstreamPaths[0] != -1) )
			{	//Make sure trace reaches this actor or DeferFor
				Best = N;
				BestWeight = Weight;
			}
		}
	}
	
	DeferTo = Best;
}


function bool NearbyMonsterWP()
{
	local Triggers TT;
	ForEach RadiusActors( class'Triggers', TT, 200)
		if ( TT.IsA('MonsterWaypoint') && MHS.static.ActorsTouching( self, TT, 10, 10) )
			return true;
}



event PostBeginPlay()
{
	if ( MonsterBriefing(Owner) != None )
		Briefing = MonsterBriefing(Owner);
	else if ( Briefing == None ) //Shouldn't happen
		ForEach AllActors( class'MonsterBriefing', Briefing)
			break;
			
	if ( Briefing != None )
	{
		NextEvent = Briefing.MapEventList;
		Briefing.MapEventList = self;
	}
}

event Destroyed()
{
	if ( Briefing != None )
		Briefing.RemoveEvent( self);
}

//Make MHI_Base inherit Briefing pointer
event GainedChild( Actor Other)
{
	if ( MHI_Base(Other) != None )
		MHI_Base(Other).Briefing = Briefing;
}


function IncreaseObjectiveCounter( Pawn Other)
{
	local MonsterPlayerData MPD;
	
	if ( Other == None || Other.PlayerReplicationInfo == None || bAwardedPoint )
		return;
	Other.PlayerReplicationInfo.Score += 1;
	MPD = Briefing.GetPlayerData( Other.PlayerReplicationInfo.PlayerID);
	if ( MPD != None )
		MPD.ObjectivesTaken++;
	bAwardedPoint = true;
}


defaultproperties
{
	bCollideActors=False
	EventChain=";"
}
