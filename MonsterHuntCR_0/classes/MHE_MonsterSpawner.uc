class MHE_MonsterSpawner expands MHE_Base;

var ThingFactory MarkedFactory;
var MHE_Counter Counter;
var int OriginalIndex;
var int CountedPawns;
var int CountersTotal; //Cached at start
var name ItemTag;
var bool bWasSpawning;
var bool bInterrupted;

function RegisterFactory( ThingFactory Other)
{
	MarkedFactory = Other;
	Tag = Other.Tag;
	ItemTag = Other.ItemTag;
	SetTimer( 1.5 + FRand(), true);
}

event Trigger( Actor Other, Pawn EventInstigator)
{
	//A monster has died
	if ( (Other.Tag == ItemTag) && (ScriptedPawn(Other) != None) && (ScriptedPawn(Other).Health <= 0) )
		CheckState();
}

function CheckState()
{
	bInterrupted = false;
	if ( MarkedFactory == None || MarkedFactory.bDeleteMe || MarkedFactory.IsInState('Finished') || (MarkedFactory.Capacity == 0) )
		bCompleted = true;
	else if ( MarkedFactory.IsInState('Waiting') )
	{
		bInterrupted = bWasSpawning;
	}
	else if ( MarkedFactory.IsInState('Spawning') )
	{
		if ( !bDiscovered )
			Discover();
		bWasSpawning = True;
	}
	UpdateInterface();
}

function Discover()
{
	local MHI_MonsterSpawner MHI;

	bDiscovered = true;
	if ( Interface == None )
	{
		MHI = Spawn( class'MHI_MonsterSpawner', self);
		Interface = MHI;
		OriginalIndex = MHI.EventIndex;
		MHI.MonsterName = Class<Pawn>(MarkedFactory.Prototype).default.MenuName;
		if ( MHI.MonsterName == "" )
			MHI.MonsterName = string(MarkedFactory.Prototype.Name);
		if ( Counter != None )
			MHI.CountersTotal = CountersTotal;
	}
}

function UpdateInterface()
{
	local MHI_MonsterSpawner MHI;
	local MHE_Counter C;
	local int LowestC;

	if ( MarkedFactory != None && !bCompleted )
		CountedPawns = MarkedFactory.Capacity + MarkedFactory.NumItems;
	else
		CountedPawns = CountPawns();
	
	MHI = MHI_MonsterSpawner(Interface);
	if ( MHI != None )
	{
		MHI.bSpawnInterrupted = bInterrupted;
		if ( MHI.MonstersLeft != CountedPawns )
		{
			MHI.MonstersLeft = CountedPawns;
			MHI.BoostNet();
			MHI.bSpawnFinished = bCompleted;
			if ( !MHI.IsTopInterface() )
				MHI.MoveToTop();
			if ( Counter != None )
			{
				MHI.CountersLeft = Counter.ActiveCounters();
				MHI.NextCounterLowest = Counter.GetLowestCounter();
			}
			else
			{
				MHI.CountersLeft = 0;
				MHI.NextCounterLowest = 0;
			}
		}
		
		if ( bInterrupted && (MHI.EventIndex != OriginalIndex) )
		{
			MHI.Briefing.RemoveIEvent( MHI);
			MHI.EventIndex = OriginalIndex;
			MHI.Briefing.InsertIEvent( MHI);
		}
		
		if ( (MHI.CompletedAt == 0) && (CountedPawns == 0) )
		{
			MHI.CompletedAt = MHI.Briefing.CurrentTime;
			MHI.bDormant = true;
			if ( MHI.EventIndex != OriginalIndex )
			{
				MHI.Briefing.RemoveIEvent( MHI);
				MHI.EventIndex = OriginalIndex;
				MHI.Briefing.InsertIEvent( MHI);
			}
			Destroy();
		}
	}
}

event Timer()
{
	CheckState();
}

function int CountPawns()
{
	local ScriptedPawn S;
	local int i;
	
	ForEach AllActors ( class'ScriptedPawn', S, ItemTag)
		if ( S.Event == Tag )
			i++;
	return i;
}

function int CountPawns_XC()
{
	local ScriptedPawn S;
	local int i;
	
	ForEach DynamicActors ( class'ScriptedPawn', S, ItemTag)
		if ( S.Event == Tag )
			i++;
	return i;
}
