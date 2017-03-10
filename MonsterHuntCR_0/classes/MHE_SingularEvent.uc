// Trigger/Button handler
class MHE_SingularEvent expands MHE_Base;

var(Debug) Actor MarkedMechanism;
var int AnalyzeDepth;
var(Debug) bool bIsSlave; //Do not create interface
var(Debug) bool bNotifyTriggerEnable;
var(Debug) bool bNotifyTriggerHit;
var(Debug) bool bTriggersMover;
var(Debug) bool bTriggersDoor;
var(Debug) bool bUnlocksStructure;
var(Debug) bool bUnlocksRoutes;
var(Debug) bool bTriggersCounter;
var(Debug) bool bTriggersPawn;
var(Debug) bool bTriggersFactory;
var(Debug) string EventChain;

//Trigger: bTriggerOnceOnly
//Mover (BumpOpenTimed/BumpButton): bTriggerOnceOnly || StayOpenTime > 9999

// Need to implement bDamageTriggered one of these days


function RegisterMechanism( Actor Other)
{
	MarkedMechanism = Other;
	SetTimer( 1 + FRand() * 0.2, true);
	if ( Other.IsA('Trigger') )
		GotoState('TriggerState');
	else if ( Other.IsA('Mover') )
		GotoState('ButtonState');
}

function SetAttraction();

state TriggerState
{
	event BeginState()
	{
		AnalyzeEvent( MarkedMechanism.Event);
		FindDeferPoint( MarkedMechanism);
		SetAttraction();
	}
	function SetAttraction()
	{
		local Trigger T;
		T = Trigger(MarkedMechanism);
		if ( T == None || T.bDeleteMe || !T.bCollideActors )
			Destroy();
		bAttractBots = (DeferTo != None) && T.bInitiallyActive && (bUnlocksStructure || bTriggersCounter || bUnlocksRoutes);
	}
}

//This is a simple bumpable button that triggers something
state ButtonState
{
	event BeginState()
	{
		local Mover M;
		M = Mover(MarkedMechanism);
		AnalyzeEvent( M.Event);
		AnalyzeEvent( M.BumpEvent);
		AnalyzeEvent( M.PlayerBumpEvent);
		Tag = M.Event;
		SetCollisionSize( 0, 0);
		FindDeferPoint( MarkedMechanism);
		SetAttraction();
	}
	function SetAttraction()
	{
		local Mover M;
		
		M = Mover(MarkedMechanism);
		bCompleted = bCompleted || (!M.bInterpolating && (M.KeyNum == M.NumKeys-1)); //Set completed just in case
		bAttractBots = (DeferTo != None) && !bCompleted && (bUnlocksStructure || bTriggersCounter || bUnlocksRoutes);
	}
	event Trigger( Actor Other, Pawn EventInstigator)
	{
		if ( Other == MarkedMechanism )
		{
			if ( !bDiscovered )
				Discover();
			bCompleted = true;
			SetAttraction();
		}
	}
}

state ShootTrigger
{
}

state ShootWall
{
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
	
	if ( aEvent == '' || aEvent == 'None' || (AnalyzeDepth > 20) || HasEvent(aEvent) )
		return;
	AddEvent(aEvent);
	
	AnalyzeDepth++;
	ForEach AllActors( class'Actor', A, aEvent)
	{
		if ( A.IsA('Mover') )
		{
			if ( InStr(A.InitialState,"Trigger") != -1 ) 
			{
				bTriggersMover = true;
				M = Mover(A);
				AnalyzeEvent( M.Event); //Identify this Mover's event as caused by self
				if ( M.bTriggerOnceOnly )
					bUnlocksStructure = true;
			}
		}
		else if ( A.IsA('Counter') )
		{
			bTriggersCounter = true;
		}
		else if ( A.bIsPawn )
		{
			bTriggersPawn = true;
		}
		else if ( A.IsA('ThingFactory') )
		{
			bTriggersFactory = true;
		}
		else if ( A.IsA('NavigationPoint') )
		{
			bUnlocksRoutes = true;
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
		return;
	}
	
	SetAttraction();
	if ( !bDiscovered  )
	{
		SetLocation( MarkedMechanism.Location);
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

defaultproperties
{
	DeferToMode=DTM_InCollision
	EventChain=";"
}
