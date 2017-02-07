// Trigger handler
class MHE_Trigger expands MHE_Base;

var Trigger MarkedTrigger;
var MHE_Base ToggledDoor; //Fix later
var bool bIsSlave; //Do not create interface
var bool bNotifyTriggerEnable;
var bool bNotifyTriggerHit;

function RegisterTrigger( Trigger Other)
{
	MarkedTrigger = Other;
	SetTimer( 1 + FRand() * 0.2, true);
	SetTag();
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
