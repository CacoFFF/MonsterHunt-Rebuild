//Temporarily blocks NavigationPoints
class FV_PathBlocker expands Info;

const R_SPECIAL    = 0x00000020;


var MonsterBriefing Briefing;
var FV_PathBlocker NextBlocker;


var NavigationPoint BlockedDestinations[32];
var NavigationPoint BlockedStarts[32];
var int ReachSpec[32];
var int BlockedCount;
var float LastScanned;

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
				if ( Teleporter(BlockedStarts[BlockedCount]) != None ) //Re-enable this probe once the teleporter works
					BlockedStarts[BlockedCount].Enable('SpecialHandling');
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

//Here Nav is the destination route
function SetupBlock( NavigationPoint Nav, name DoorTag)
{
	local Actor Start, End, A;
	local int rD, rF;
	local int i, OrgBlocked;
	local vector HitLocation, HitNormal;
	local bool bOpposite;
	local NavigationPoint N;
	
	if ( Nav == None )
		return;

	while ( (i<16) && (Nav.UpstreamPaths[i] != -1) && (BlockedCount < ArrayCount(ReachSpec)) )
	{
		describeSpec( Nav.UpstreamPaths[i], Start, End, rF, rD); 
		if ( (NavigationPoint(Start) != None) && (End == Nav) )
		{
			bOpposite = true;
			ForEach Nav.TraceActors( class'Actor', A, HitLocation, HitNormal, Start.Location, Nav.Location, vect(17,17,39) )
				if ( A.Tag == DoorTag ) //Can be a trigger... can be a mover
				{
					ReachSpec[Blockedcount] = Nav.UpstreamPaths[i];
					BlockedStarts[BlockedCount] = NavigationPoint(Start);
					BlockedDestinations[BlockedCount] = Nav;
					class'MHCR_Statics'.static.RemovePathFrom( BlockedStarts[BlockedCount], ReachSpec[Blockedcount] );
					class'MHCR_Statics'.static.RemoveUPathFrom( BlockedDestinations[BlockedCount], ReachSpec[Blockedcount], i);
					SetLocation( HitLocation);
					BlockedCount++;
					bOpposite = false;
					i--;
					break;
				}
			//Try opposite direction with simple line
			if ( bOpposite )
			{
				ForEach Start.TraceActors( class'Actor', A, HitLocation, HitNormal, End.Location )
					if ( A.Tag == DoorTag ) //Can be a trigger... can be a mover
					{
						ReachSpec[Blockedcount] = Nav.UpstreamPaths[i];
						BlockedStarts[BlockedCount] = NavigationPoint(Start);
						BlockedDestinations[BlockedCount] = Nav;
						class'MHCR_Statics'.static.RemovePathFrom( BlockedStarts[BlockedCount], ReachSpec[Blockedcount] );
						class'MHCR_Statics'.static.RemoveUPathFrom( BlockedDestinations[BlockedCount], ReachSpec[Blockedcount], i);
						SetLocation( HitLocation);
						BlockedCount++;
						i--;
						break;
					}
			}

		}
		i++;
	}

	//This will add any UpstreamPath that was out of the list due to being more than 16
	bOpposite = false;
	if ( Level.TimeSeconds-LastScanned > 5 )
	{
		LastScanned = Level.TimeSeconds;
		ForEach Nav.RadiusActors( class'NavigationPoint', N, 1000)
		{
			For ( i=0 ; (i<16) && (N.Paths[i] != -1) ; i++ )
			{
				describeSpec( N.Paths[i], Start, End, rF, rD); 
				if ( (End == Nav) && (Start == N) )
					class'MHCR_Statics'.static.AddUPathTo( Nav, N.Paths[i] );
			}
		}
	}
}

//Here T is the starting teleporter
function SetupTeleporter( Teleporter T)
{
	local Actor Start, End;
	local Teleporter TEnd;
	local int rD, rF;
	local int i, oldBlockedCount;

	if ( T == None || !T.bEnabled || T.URL == "" )
		return;
		
	oldBlockedCount = BlockedCount;
	while ( (i<16) && (T.Paths[i] != -1) )
	{
		describeSpec( T.Paths[i], Start, End, rF, rD);
		TEnd = Teleporter(End);
		//Teleporter reachspecs are flagged R_SPECIAL and have 100 distance
		//Teleporters can have more than one reachspec to their destination, if the destination is directly reachable
		//So teleporters directly reachable to each other must still have their 'walk' reachspec functional after this
		if ( (TEnd != None) && (string(TEnd.Tag) ~= T.URL) && (Start == T) && ((rF & R_SPECIAL) != 0) && (rD == 100) )
		{
			ReachSpec[Blockedcount] = T.Paths[i];
			BlockedStarts[BlockedCount] = T;
			BlockedDestinations[BlockedCount] = TEnd;
			class'MHCR_Statics'.static.RemovePathFrom( BlockedStarts[BlockedCount], ReachSpec[Blockedcount], i);
			class'MHCR_Statics'.static.RemoveUPathFrom( BlockedDestinations[BlockedCount], ReachSpec[Blockedcount]);
			if ( ++BlockedCount >= ArrayCount(ReachSpec) )
				break;
			continue;
		}
		i++;
	}
	//MonsterHunt is overriding all logic, no need to 'handle' these teleporters
	if ( oldBlockedCount != BlockedCount )
		T.Disable('SpecialHandling');
}
