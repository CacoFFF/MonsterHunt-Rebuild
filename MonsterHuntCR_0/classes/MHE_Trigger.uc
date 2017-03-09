// Trigger/Button handler
class MHE_Trigger expands MHE_Base;

var Trigger MarkedTrigger;
var Mover MarkedButton;
var int AnalyzeDepth;
var bool bIsSlave; //Do not create interface
var bool bNotifyTriggerEnable;
var bool bNotifyTriggerHit;
var bool bTriggersMover;
var bool bTriggersDoor;
var bool bUnlocksStructure;
var bool bUnlocksRoutes;
var bool bTriggersCounter;
var bool bTriggersPawn;
var bool bTriggersFactory;
var string EventChain;

function RegisterTrigger( Trigger Other)
{
	MarkedTrigger = Other;
	SetTimer( 1 + FRand() * 0.2, true);
	GotoState('TriggerState');
	SetTag();
}
function RegisterButton( Mover Other)
{
	MarkedButton = Other;
	SetTimer( 1 + FRand() * 0.2, true);
	GotoState('ButtonState');
}

function SetAttraction();

state TriggerState
{
	event BeginState()
	{
		AnalyzeEvent( MarkedTrigger.Event);
		SetAttraction();
	}
	function SetAttraction()
	{
		if ( MarkedTrigger == None || (MarkedTrigger.bTriggerOnceOnly && !MarkedTrigger.bCollideActors) )
			Destroy();
		bAttractBots = (DeferTo != None) && (bUnlocksStructure || bTriggersCounter || bUnlocksRoutes);
	}
}

//This is a simple bumpable button that triggers something
state ButtonState
{
	event BeginState()
	{
		AnalyzeEvent( MarkedButton.Event);
		SetAttraction();
	}
	function SetAttraction()
	{
		if ( (MarkedButton.bTriggerOnceOnly && !MarkedTrigger.bCollideActors) )
			Destroy();
		bAttractBots = (DeferTo != None) && (bUnlocksStructure || bTriggersCounter || bUnlocksRoutes);
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

function AnalyzeEvent( name aEvent)
{
	local Actor A;
	local Mover M;
	
	if ( (AnalyzeDepth > 20) || HasEvent(aEvent) )
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
				if ( (M.Event != '') && !HasEvent(M.Event) ) //Identify this Mover's event as caused by self
					AnalyzeEvent( M.Event);
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

function SetTag()
{
	Tag = '';
	if ( MarkedTrigger != None && !MarkedTrigger.bDeleteMe )
	{
		if ( !MarkedTrigger.bInitiallyActive )
		{
			bNotifyTriggerEnable = true;
			Tag = MarkedTrigger.Tag;
		}
		else if ( MarkedTrigger.bTriggerOnceOnly && MarkedTrigger.bCollideActors )
		{
			bNotifyTriggerHit = true;
			Tag = MarkedTrigger.Event;
		}
	}
	else if ( MarkedButton != None )
		Tag = MarkedButton.Event;
}

event Trigger( Actor Other, Pawn EventInstigator)
{
	if ( bNotifyTriggerEnable )
	{
		bNotifyTriggerEnable = false;
		//Do stuff
	}
	if ( bNotifyTriggerHit )
	{
		bNotifyTriggerHit = false;
		//Do stuff
	}
	SetTag();
	SetAttraction();
}

event Timer()
{
	local Pawn P;
	local vector Vec;
	
	if ( bDiscovered || MarkedTrigger == None || MarkedTrigger.bDeleteMe )
	{
		SetTimer(0,false);
		return;
	}
	SetLocation( MarkedTrigger.Location);
	Vec.X = MarkedTrigger.CollisionRadius;
	Vec.Y = MarkedTrigger.CollisionHeight;
	Vec.Z = 200;
	ForEach RadiusActors( class'Pawn', P, VSize(Vec) )
		if ( P.bIsPlayer && P.PlayerReplicationInfo != None && P.bCollideActors )
		{
			Discover();
			return;
		}
}

defaultproperties
{
	DeferToMode=DTM_InCollision
	EventChain=";"
}
