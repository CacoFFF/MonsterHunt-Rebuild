//************************************************
// MonsterWaypoint
// Game objectives, lower position higher priority
// This actor now also becomes a Trigger
class MonsterWaypoint expands Triggers;

#exec TEXTURE IMPORT NAME=MHMarker FILE=pcx\MHMarker.pcx

var(Waypoint) int Position;
var(Waypoint) bool bEnabled;
var bool bVisited;

var MonsterWaypoint NextWaypoint;

//Deprecated (those were originally buggy)
var Actor TriggerItem;
var name TriggerEvent1;
var name TriggerEvent2;
var name TriggerEvent3;
var name TriggerEvent4;

event PostBeginPlay()
{
	if ( MonsterHunt(Level.Game) != None )
		MonsterHunt(Level.Game).RegisterWaypoint( self);
}

function Touch( Actor Other)
{
	local Actor A;
	//Generic player
	if ( !bVisited && bEnabled && (Pawn(Other) != None) && Pawn(Other).bIsPlayer && (Pawn(Other).PlayerReplicationInfo != None)  )
	{
		bVisited = True;
		bEnabled = False;
		SetCollision( False);
		if ( Event != '' )
			ForEach AllActors (class'Actor', A, Event)
				A.Trigger( self, Pawn(Other));
		if ( MonsterHunt(Level.Game) != None )
			MonsterHunt(Level.Game).WaypointVisited( self);
 	}
}

event Trigger( Actor Other, Pawn EventInstigator)
{
	if ( !bVisited )
		bEnabled = true;
}

defaultproperties
{
	bEnabled=True
	bVisited=False
	bCollideActors=True
	bBlockPlayers=False
	bBlockActors=False
    Position=1
	bStatic=False
	Texture=Texture'MHMarker'
	CollisionRadius=30.00
	CollisionHeight=30.00
}
