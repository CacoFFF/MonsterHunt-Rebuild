//******************************
// MHE_Base
// Status indicator of map stuff
class MHE_Base expands Triggers;

var MHE_Base NextEvent;
var MHI_Base Interface;
var NavigationPoint DeferTo;
//Pointer to net breifing element!
var bool bDiscovered;
var bool bCompleted;

function Discover()
{
	bDiscovered = true;
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
