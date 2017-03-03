//******************************
// MHE_Base
// Status indicator of map stuff
class MHE_Base expands Triggers;

const MHS = class'MHCR_Statics';

var MonsterBriefing Briefing;
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

function PostInit()
{
	bPostInit = true;
}

function FindDeferPoint()
{
	local NavigationPoint N, Best;
	local float ScanRange;
	local vector V;
	
	if ( DeferToMode == DTM_None )
		return;
	else if ( DeferToMode == DTM_InCollision )
	{
		V.X = CollisionRadius + 17;
		V.Z = CollisionHeight + 39;
		ScanRange = VSize(V);
		ForEach RadiusActors( class'NavigationPoint', N, ScanRange)
			if ( MHS.static.ActorsTouching(self,N) )
			{
				if ( N.IsA('MonsterTriggerMarker') )
				{
					Best = N;
					break;
				}
				if ( (Best == None) || (Best.ExtraCost > N.ExtraCost) )
					Best = N;
			}
		DeferTo = Best;
	}
}




event PostBeginPlay()
{
	if ( MonsterBriefing(Owner) != None )
		Briefing = MonsterBriefing(Owner);
	else if ( Briefing == None ) //Shouldn't happen
		ForEach AllActors( class'MonsterBriefing', Briefing)
			break;
			
	if ( Briefing != None )
	{
		NextEvent = Briefing.MapEventList;
		Briefing.MapEventList = self;
	}
}

event Destroyed()
{
	if ( Briefing != None )
		Briefing.RemoveEvent( self);
}

//Make MHI_Base inherit Briefing pointer
event GainedChild( Actor Other)
{
	if ( MHI_Base(Other) != None )
		MHI_Base(Other).Briefing = Briefing;
}


defaultproperties
{
	bCollideActors=False
}
