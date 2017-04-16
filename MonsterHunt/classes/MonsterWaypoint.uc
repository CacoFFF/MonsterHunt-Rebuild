//************************************************
// MonsterWaypoint
// Game objectives, lower position higher priority
// This actor now also becomes a Trigger
class MonsterWaypoint expands Triggers;

#exec TEXTURE IMPORT NAME=MHMarker FILE=pcx\MHMarker.pcx

var(Waypoint) int Position;
var(Waypoint) Actor TriggerItem;
var(Waypoint) name TriggerEvent1;
var(Waypoint) name TriggerEvent2;
var(Waypoint) name TriggerEvent3;
var(Waypoint) name TriggerEvent4;
var Actor TriggerActor1;
var Actor TriggerActor2;
var Actor TriggerActor3;
var Actor TriggerActor4;
var bool bVisited;
var(Waypoint) bool bEnabled;

var MonsterWaypoint NextWaypoint;
var NavigationPoint DeferTo; //Alternate location to go to


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
		if ( (TriggerItem != None) && Pawn(Other).PlayerReplicationInfo.bIsABot )
		{
			if ( TriggerItem.IsA('Mover') )
				TriggerItem.Bump(Other);
			TriggerItem.Trigger(self,Pawn(Other));
		}
		if ( MonsterHunt(Level.Game) != None )
			MonsterHunt(Level.Game).WaypointVisited( self, Pawn(Other).PlayerReplicationInfo );
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
