//Temporarily blocks NavigationPoints
class FV_PathBlocker expands Info;

var MonsterBriefing Briefing;
var FV_PathBlocker NextBlocker;


var NavigationPoint BlockedDestinations[32];
var NavigationPoint BlockedStarts[32];
var int ReachSpec[32];
var int BlockedCount;

//No need to forward the call to NavigationPoint
native(519) final function describeSpec(int iSpec, out Actor Start, out Actor End, out int ReachFlags, out int Distance); 

function FV_PathBlocker FindByTag( name aTag)
{
	local FV_PathBlocker Link;
	For ( Link=self ; Link!=None ; Link=Link.NextBlocker )
		if ( (Link.Tag == aTag) && (Link.BlockedCount < ArrayCount(ReachSpec) ) )
			return Link;
}

event PostBeginPlay()
{
	Briefing = MonsterBriefing(Owner);
	if ( Briefing != None )
	{
		NextBlocker = Briefing.BlockerList;
		Briefing.BlockerList = self;
	}
}

event Trigger( Actor Other, Pawn EventInstigator)
{
	Destroy();
}

event Destroyed()
{
	local Actor Start, End;
	local int rD, rF;
	local FV_PathBlocker Link;
	
	Super.Destroyed();
	while ( --BlockedCount >= 0 )
		if ( (BlockedDestinations[BlockedCount] != None) && !BlockedDestinations[BlockedCount].bDeleteMe )
		{
			describeSpec( ReachSpec[BlockedCount], Start, End, rF, rD);
			if ( (End == BlockedDestinations[BlockedCount]) && (Start == BlockedStarts[BlockedCount]) )
			{
				class'MHCR_Statics'.static.AddPathTo( BlockedStarts[BlockedCount], ReachSpec[BlockedCount] );
				class'MHCR_Statics'.static.AddUPathTo( BlockedDestinations[BlockedCount], ReachSpec[BlockedCount] );
			}
		}
	
	if ( Briefing != None )
	{
		if ( Briefing.BlockerList == self )
			Briefing.BlockerList = NextBlocker;
		else
		{
			For ( Link=Briefing.BlockerList ; Link.NextBlocker!=None ; Link=Link.NextBlocker )
				if ( Link.NextBlocker == self )
				{
					Link.NextBlocker = NextBlocker;
					break;
				}
		}
		NextBlocker = None;
	}
}

//If the list fills up before ALL reachspecs are evaluated, don't despair
//A new FV_PathBlocker will be spawned and pick up where we left off here
function SetupBlock( NavigationPoint Nav, name DoorTag)
{
	local Actor Start, End, A;
	local int rD, rF;
	local int i, j;
	local vector HitLocation, HitNormal;
	
	if ( Nav == None )
		return;

	while ( (i<16) && (Nav.UpstreamPaths[i] != -1) )
	{
		describeSpec( Nav.UpstreamPaths[i], Start, End, rF, rD); 
		if ( (NavigationPoint(Start) != None) && (End == Nav) )
		{
			ForEach Nav.TraceActors( class'Actor', A, HitLocation, HitNormal, Start.Location, Nav.Location, vect(17,17,39) )
				if ( A.Tag == DoorTag ) //Can be a trigger... can be a mover
				{
					ReachSpec[Blockedcount] = Nav.UpstreamPaths[i];
					BlockedStarts[BlockedCount] = NavigationPoint(Start);
					BlockedDestinations[BlockedCount] = Nav;
					class'MHCR_Statics'.static.RemovePathFrom( BlockedStarts[BlockedCount], ReachSpec[Blockedcount] );
					class'MHCR_Statics'.static.RemoveUPathFrom( Nav, ReachSpec[Blockedcount], i);
					if ( ++BlockedCount >= ArrayCount(ReachSpec) )
						return;
					i--;
					break;
				}
		}
		i++;
	}
}

