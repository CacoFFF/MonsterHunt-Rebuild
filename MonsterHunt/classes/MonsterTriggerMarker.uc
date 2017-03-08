//================================================================================
// MonsterTriggerMarker.
// Previously a effect-less navigation point, now it can play key roles in
// improving bot support in levels.
//================================================================================
class MonsterTriggerMarker extends NavigationPoint;

var Triggers MarkedTrigger;
var MonsterTriggerMarker NextTriggerMarker;

event PostBeginPlay()
{
	local Triggers T, PrevT;
	local NavigationPoint N;
	local Mover M;
	
	SetCollisionSize( 38, 17);
	
	ForEach RadiusActors ( class'Triggers', T, 200)
		if ( IsTouching(T) )
		{
			if ( !T.IsA('Trigger') && !T.IsA('MonsterMaypoint') && !T.IsA('Kicker') && !T.IsA('FearSpot') && !T.IsA('TriggeredDeath') ) //This trigger cannot be directly interacted with
				continue;
			MarkedTrigger = T;
			break;
		}
	
	//We got a trigger!
	if ( MarkedTrigger != None )
	{
		if ( MarkedTrigger.IsA('FearSpot') )
			InitialState = 'FearSpot';
		else if ( MarkedTrigger.IsA('MonsterWaypoint') )
			MonsterWaypoint(MarkedTrigger).DeferTo = self;
		else if ( MarkedTrigger.IsA('MonsterEnd') )
			MonsterEnd(MarkedTrigger).DeferTo = self;
		else if ( MarkedTrigger.IsA('TriggeredDeath') )
			ExtraCost = 10000000;
		else if ( MarkedTrigger.IsA('Kicker') ) //Makes bots go around this path if not attempting to go through the kicker
			ExtraCost = 400;
		else if ( MarkedTrigger.IsA('Trigger') )
		{
			if ( ((Trigger(MarkedTrigger).InitialState == 'OtherTriggerTurnsOn') || (Trigger(MarkedTrigger).InitialState == 'OtherTriggerToggles')) 
				&& (MarkedTrigger.Event != '') && HasTriggeredDoor(MarkedTrigger.Event) )
				InitialState = 'DoorControl';
		}
	}
	
	if ( MonsterHunt(Level.Game) != None )
		NextTriggerMarker = MonsterHunt(Level.Game).TriggerMarkers;
	else
	{
		For ( N=NextNavigationPoint ; N!=None ; N=N.NextNavigationPoint )
			if ( N.IsA('MonsterTriggerMarker') )
			{
				NextTriggerMarker = MonsterTriggerMarker(N);
				break;
			}
	}
}

state FearSpot
{
	event BeginState()
	{
		bSpecialCost = true;
	}
	
	event int SpecialCost( pawn Seeker)
	{
		if ( (FearSpot(MarkedTrigger) != None) && FearSpot(MarkedTrigger).bInitiallyActive )
			return 10000000;
		return 0;
	}
}

state DoorControl
{
	event BeginState()
	{
		bSpecialCost = true;
	}

	event int SpecialCost( pawn Seeker)
	{
		if ( Trigger(MarkedTrigger) != None && !Trigger(MarkedTrigger).bInitiallyActive )
			return 10000000;
		return 0;
	}
}


final function bool IsTouching( Actor Other)
{
	local vector Diff;
	Diff = Other.Location - Location;
	if ( Abs(Diff.Z) > CollisionHeight+Other.CollisionHeight )
		return false;
	Diff.Z = 0;
	return VSize(Diff) < CollisionRadius+Other.CollisionRadius;
}

function bool HasTriggeredDoor( name DoorTag)
{
	local Actor S, E, A;
	local int rF, rD, i, iR;
	local vector HL, HN;
	
	For ( i=0 ; (i<16) && (Paths[i]>=0) ; i++ )
	{
		describeSpec( Paths[i], A, E, rF, rD);
		A = None;
		ForEach TraceActors( class'Actor', A, HL, HN, E.Location)
			if ( (A.Tag == DoorTag) && A.IsA('Mover') )
				return true;
	}
}


defaultproperties
{
    ExtraCost=0
    bSpecialCost=False
    Texture=Texture'MHMarker'
	CollisionHeight=38
	CollisionRadius=17
	bStatic=False
}
