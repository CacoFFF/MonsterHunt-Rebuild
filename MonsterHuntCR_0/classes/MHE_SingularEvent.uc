// Trigger/Button handler
class MHE_SingularEvent expands MHE_Base;

var(Debug) Actor MarkedMechanism;
var bool bRecheckEvents;
var(Debug) bool bMultiHit;
var(Debug) bool bShoot;

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

//Somebody needs to activate this MHE_Base in order to activate an event
function RequiredForEvent()
{
	bQueriedByBot = true;
	bAttractBots = true;
	if ( (DeferTo == None) && (MarkedMechanism != None) ) //Force find defer point
	{
		DeferToMode = DTM_Nearest; //Defer to ANYTHING nearby
		FindDeferPoint( MarkedMechanism);
	}
}


function SetAttraction();
function BuildEventList();


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
		bQueriedByBot = false; //Hit!
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
			bQueriedByBot = false; //Hit!
			SetAttraction();
			bRecheckEvents = true;
			if ( !bMultiHit )
				Destroy();
		}
	}
}

function ClearIfUseless()
{
	if ( bMultiHit || ShouldAttractBots() || bTriggersMover || bTriggersPawn || bTriggersFactory )
		return;
	if ( RequiredEvent() != '' )
		return;
	Destroy();
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


defaultproperties
{
	DeferToMode=DTM_InCollision
	EventChain=";"
}
