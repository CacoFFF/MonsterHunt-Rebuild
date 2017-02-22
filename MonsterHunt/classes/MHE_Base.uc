//******************************
// MHE_Base
// Status indicator of map stuff
class MHE_Base expands Triggers;

const MHS = class'MonsterHuntStatics';

var MHE_Base NextEvent;
var MHI_Base Interface;
var NavigationPoint DeferTo;
//Pointer to net breifing element!
var bool bDiscovered;
var bool bCompleted;
var bool bPostInit;

var enum EDeferToMode
{
	DTM_None,
	DTM_Nearest,
	DTM_InCollision,
	DTM_NearestVisible
} DeferToMode;

native(3553) final iterator function DynamicActors( class<actor> BaseClass, out actor Actor, optional name MatchTag );

function Discover()
{
	bDiscovered = true;
}

function PostInit();

function FindDeferPoint()
{
	local MonsterTriggerMarker MTM;

	if ( DeferToMode == DTM_None )
		return;
	if ( DeferToMode == DTM_InCollision )
	{
		For ( MTM=MonsterHunt(Level.Game).TriggerMarkers ; MTM!=None ; MTM=MTM.NextTriggerMarker )
			if ( MTM.IsTouching( self) )
			{
				DeferTo = MTM;
				return;
			}
	}
}



event PostBeginPlay()
{
	if ( MonsterHunt(Level.Game).Briefing != None )
	{
		NextEvent = MonsterHunt(Level.Game).Briefing.MapEventList;
		MonsterHunt(Level.Game).Briefing.MapEventList = self;
	}
}

event Destroyed()
{
	if ( MonsterHunt(Level.Game).Briefing != None )
		MonsterHunt(Level.Game).Briefing.RemoveEvent( self);
}




defaultproperties
{
	bCollideActors=False
}
