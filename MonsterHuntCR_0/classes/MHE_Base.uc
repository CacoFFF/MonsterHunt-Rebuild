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
var bool bAttractBots;

var enum EDeferToMode
{
	DTM_None,
	DTM_InCollision,
	DTM_Nearest,
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

function bool CausesEvent( name aEvent);

function FindDeferPoint( Actor DeferFor)
{
	local NavigationPoint N, Best;
	local float Weight, BestWeight;
	local vector V, HN;
	local Actor A;
	
	if ( DeferToMode == DTM_None )
		return;
	if ( DeferToMode == DTM_InCollision )
	{
		V.X = CollisionRadius + 17;
		V.Z = CollisionHeight + 39;
		Weight = VSize(V);
		ForEach RadiusActors( class'NavigationPoint', N, Weight)
			if ( MHS.static.ActorsTouching(self,N) && (N.UpstreamPaths[0] != -1) )
			{
				if ( N.IsA('MonsterTriggerMarker') )
				{
					Best = N;
					break;
				}
				if ( (Best == None) || (Best.ExtraCost > N.ExtraCost) )
					Best = N;
			}
		if ( Best == None )
			DeferToMode = DTM_NearestVisible;
	}
	if ( DeferToMode == DTM_NearestVisible )
	{
		ForEach RadiusActors( class'NavigationPoint', N, 1500)
		{
			Weight = 1000 + 500*int(N.IsA('MonsterTriggerMarker')) - VSize( (N.Location - Location) * vect(1,1,3) );
			if ( Weight > BestWeight )
			{	//Make sure trace reaches this actor or DeferFor
				ForEach TraceActors( class'Actor', A, V, HN, Location, N.Location)
				{
					if ( A == self || A == DeferFor )
						break;
					if ( A == Level )
					{
						if ( !MHS.static.InCylinder( V-Location, CollisionRadius, CollisionHeight) )
							N = None;
						break;
					}
				}
				if ( N != None )
				{
					Best = N;
					BestWeight = Weight;
				}
			}
		}
	}
	
	DeferTo = Best;
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
