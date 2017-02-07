class MHE_MonsterSpawner expands MHE_Base;

var ThingFactory MarkedFactory;
var int OriginalIndex;
var int CountedPawns;
var name ItemTag;
var bool bWasSpawning;

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
	if ( MarkedFactory == None || MarkedFactory.bDeleteMe || MarkedFactory.IsInState('Finished') || (MarkedFactory.Capacity == 0) )
		bCompleted = true;
	else if ( MarkedFactory.IsInState('Waiting') )
	{
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
		MHI = Spawn( class'MHI_MonsterSpawner');
		Interface = MHI;
		OriginalIndex = MHI.EventIndex;
		MHI.MonsterName = Class<Pawn>(MarkedFactory.Prototype).default.MenuName;
		if ( MHI.MonsterName == "" )
			MHI.MonsterName = string(MarkedFactory.Prototype.Name);
	}
}

function UpdateInterface()
{
	local MHI_MonsterSpawner MHI;

	if ( MarkedFactory != None && !bCompleted )
		CountedPawns = MarkedFactory.Capacity + MarkedFactory.NumItems;
	else
		CountedPawns = CountPawns();
	
	MHI = MHI_MonsterSpawner(Interface);
	if ( MHI != None )
	{
		if ( MHI.MonstersLeft != CountedPawns )
		{
			MHI.MonstersLeft = CountedPawns;
			MHI.BoostNet();
			MHI.bSpawnFinished = bCompleted;
			if ( !MHI.IsTopInterface() )
				MHI.MoveToTop();
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
