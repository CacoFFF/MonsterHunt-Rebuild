// Trigger/Button handler
class MHE_SingularEvent expands MHE_Base;

var(Debug) Actor MarkedMechanism;
var int AnalyzeDepth;
var bool bRecheckEvents;
var(Debug) bool bTriggersMover;
var(Debug) bool bUnlocksStructure;
var(Debug) bool bUnlocksRoutes;
var(Debug) bool bTriggersCounter;
var(Debug) bool bTriggersPawn;
var(Debug) bool bTriggersFactory;
var(Debug) bool bTogglesTriggers;
var(Debug) bool bModifiesTriggers; //Important
var(Debug) bool bUnlocksAttractor; //MHE_SingularEvent chainer
var(Debug) bool bMultiHit;
var(Debug) bool bShoot;
var(Debug) string EventChain;

//Trigger: bTriggerOnceOnly
//Mover (BumpOpenTimed/BumpButton): bTriggerOnceOnly || StayOpenTime > 9999

// Need to implement bDamageTriggered one of these days


function RegisterMechanism( Actor Other)
{
	MarkedMechanism = Other;
	SetLocation( Other.Location);
	SetTimer( 1 + FRand() * 0.2, true);
	if ( Other.IsA('Trigger') )
		GotoState('TriggerState');
	else if ( Other.IsA('Mover') )
		GotoState('ButtonState');
}

function SetAttraction();
function BuildEventList();

function bool ShouldAttractBots()
{
	return (bUnlocksStructure || bTriggersCounter || bUnlocksRoutes || bModifiesTriggers || bUnlocksAttractor);
}

state TriggerState
{
	event BeginState()
	{
		bMultiHit = !Trigger(MarkedMechanism).bTriggerOnceOnly;
		BuildEventList();
		if ( bDeleteMe )
			return;
		SetCollisionSize( MarkedMechanism.CollisionRadius, MarkedMechanism.CollisionHeight);
		FindDeferPoint( MarkedMechanism);
		SetAttraction();
	}
	
	function BuildEventList()
	{
		local Trigger T;
		Tag = MarkedMechanism.Tag;
		ResetEvents();
		AnalyzeEvent( MarkedMechanism.Event);
		bRecheckEvents = false;
		T = Trigger(MarkedMechanism);
		if ( T.bInitiallyActive )
			Tag = MarkedMechanism.Event;
		else if ( (T.ReTriggerDelay > 0) && (Level.TimeSeconds - T.TriggerTime < T.ReTriggerDelay) )
			bRecheckEvents = true;
		ClearIfUseless();
	}

	function SetAttraction()
	{
		local Trigger T;
		local bool bReady;
		
		T = Trigger(MarkedMechanism);
		if ( T == None || T.bDeleteMe || !T.bCollideActors )
			Destroy();
		bReady = T.bInitiallyactive && ((T.ReTriggerDelay <= 0) || (Level.TimeSeconds - T.TriggerTime >= T.ReTriggerDelay));
		bAttractBots = (DeferTo != None) && bReady && ShouldAttractBots();
	}
	
	function name RequiredEvent()
	{
		local Trigger T;
		T = Trigger(MarkedMechanism);
		if ( T != None )
		{	
			if ( T.IsInState('OtherTriggerTurnsOff') )
			{
				if ( T.bInitiallyActive )
					return T.Tag;
			}
			else if ( !T.bInitiallyActive )
				return T.Tag;
		}
	}
	
	//The trigger has been touched
	event Trigger( Actor Other, Pawn EventInstigator)
	{
		if ( Tag == MarkedMechanism.Tag ) //The trigger is being enabled
		{
			if ( !bDiscovered )
				Discover();
			if ( Trigger(MarkedMechanism).bInitiallyActive )
				Tag = MarkedMechanism.Event;
		}
		else //The trigger has been touched
		{
			bRecheckEvents = true;
			if ( bAttractBots && !bCompleted && !NearbyMonsterWP() )
				IncreaseObjectiveCounter( EventInstigator);
			bCompleted = !MarkedMechanism.bCollideActors;
		}
		SetAttraction();
	}
}

//This is a simple bumpable button that triggers something
state ButtonState
{
	event BeginState()
	{
		local Actor A;
		local vector HL, HN;

		//Can be hit multiple times
		bMultiHit = !Mover(MarkedMechanism).bTriggerOnceOnly && (Mover(MarkedMechanism).StayOpenTime <= 9999);
		BuildEventList();
		if ( bDeleteMe )
			return;
			
		SetCollisionSize( 0, 0);
		FindDeferPoint( MarkedMechanism);
		//This MHE should be inside the world!
		//Also, carefully adjust position of target
		if ( DeferTo != None )	
		{
			ForEach TraceActors( class'Actor', A, HL, HN, Location, DeferTo.Location)
				if ( (A==MarkedMechanism) || (A==Level) )
				{
					SetLocation( HL);
					break;
				}
			SetLocation( Location );
			if ( FastTrace( Location - vect(0,0,30)) )
				SetLocation( Location - vect(0,0,10) );
			SetCollisionSize( 10, 30);
		}
		SetAttraction();
	}

	function BuildEventList()
	{
		Tag = '';
		ResetEvents();
		AnalyzeEvent( MarkedMechanism.Event);
		AnalyzeEvent( Mover(MarkedMechanism).BumpEvent);
		AnalyzeEvent( Mover(MarkedMechanism).PlayerBumpEvent);
		bRecheckEvents = false;
		Tag = MarkedMechanism.Event;
		ClearIfUseless();
	}
	
	function SetAttraction()
	{
		local Mover M;
		
		M = Mover(MarkedMechanism);
		bCompleted = (bCompleted && !bMultiHit) || (!M.bInterpolating && (M.KeyNum == M.NumKeys-1)); //Set completed just in case
		bAttractBots = (DeferTo != None) && !bCompleted && ShouldAttractBots();
	}

	//The button has finished interpolating
	event Trigger( Actor Other, Pawn EventInstigator)
	{
		if ( Other == MarkedMechanism )
		{
			if ( !bDiscovered )
				Discover();
			if ( bAttractBots && !bCompleted && !NearbyMonsterWP() )
				IncreaseObjectiveCounter( EventInstigator);
			bCompleted = true;
			SetAttraction();
			bRecheckEvents = true;
			if ( !bMultiHit )
				Destroy();
		}
	}
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

function ResetEvents()
{
	bTriggersMover = false;
	bUnlocksStructure = false;
	bTriggersCounter = false;
	bTriggersPawn = false;
	bTriggersFactory = false;
	bUnlocksRoutes = false;
	bTogglesTriggers = false;
	bModifiesTriggers = false;
	EventChain = ";";
}

function ClearIfUseless()
{
	if ( !bMultiHit || bTriggersMover || bUnlocksStructure || bTriggersCounter || bTriggersPawn || bTriggersFactory || bUnlocksRoutes || bUnlocksAttractor )
		return;
	Destroy();
}

function AnalyzeEvent( name aEvent)
{
	local Actor A;
	local Mover M;
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
				bTriggersMover = true;
				M = Mover(A);
				if ( !M.bInterpolating && (M.KeyNum == 0) )
				{
					AnalyzeEvent( M.Event); //Identify this Mover's event as caused by self
					if ( M.bTriggerOnceOnly || (M.StayOpenTime > 9999) )
						bUnlocksStructure = true;
				}
			}
		}
		else if ( A.IsA('Triggers') )
		{
			if ( A.IsA('Counter') )
			{
				if ( Counter(A).NumToCount > 0 )
					bTriggersCounter = true;
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
						if ( Trigger(A).bTriggerOnceOnly )
							bModifiesTriggers = true;
					}
					else if ( (A.IsInState('OtherTriggerTurnsOn') && !Trigger(A).bInitiallyActive)
							|| (A.IsInState('OtherTriggerTurnsOff') && Trigger(A).bInitiallyActive) )
						bModifiesTriggers = true;
				}
			}
			else if ( A.IsA('MHE_SingularEvent') && (A != self) ) //Detect chained doors
			{
				if ( MHE_SingularEvent(A).ShouldAttractBots() || MHE_SingularEvent(A).bTriggersMover )
					bUnlocksAttractor = true;
			}
		}
		else if ( A.bIsPawn )
		{
			bTriggersPawn = true;
		}
		else if ( A.IsA('ThingFactory') )
		{
			if ( ThingFactorY(A).Capacity > 0 )
				bTriggersFactory = true;
		}
		else if ( A.IsA('NavigationPoint') )
		{
			if ( (BlockedPath(A) == None) || (BlockedPath(A).ExtraCost > 0) )
				bUnlocksRoutes = true;
		}
		else if ( A.IsA('ExplodingWall') )
		{
			AnalyzeEvent( A.Event);
		}
	}
	AnalyzeDepth--;
}

event Timer()
{
	local Pawn P;
	local vector Vec;
	
	if ( MarkedMechanism == None || MarkedMechanism.bDeleteMe )
	{
		SetTimer(0,false);
		//Destroy()
		return;
	}
	
	if ( bRecheckEvents || FRand() < 0.1 )
		BuildEventList();
	SetAttraction();
	if ( !bDiscovered  )
	{
//		SetLocation( MarkedMechanism.Location);
		Vec.X = MarkedMechanism.CollisionRadius;
		Vec.Y = MarkedMechanism.CollisionHeight;
		Vec.Z = 200;
		ForEach RadiusActors( class'Pawn', P, VSize(Vec) )
			if ( P.bIsPlayer && P.PlayerReplicationInfo != None && P.bCollideActors )
			{
				Discover();
				return;
			}
	}
}

function bool NearbyMonsterWP()
{
	local Triggers TT;
	ForEach RadiusActors( class'Triggers', TT, 200)
		if ( TT.IsA('MonsterWaypoint') && MHS.static.ActorsTouching( self, TT, 10, 10) )
			return true;
}


defaultproperties
{
	DeferToMode=DTM_InCollision
	EventChain=";"
}
