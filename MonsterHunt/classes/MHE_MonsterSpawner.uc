class MHE_MonsterSpawner expands MHE_Base;

var ThingFactory MarkedFactory;
var int OriginalIndex;
var bool bWasSpawning;

function RegisterFactory( ThingFactory Other)
{
	MarkedFactory = Other;
	SetTimer( 1 + FRand() * 0.2, true);
}

function CheckState()
{
	UpdateInterface();
	if ( MarkedFactory == None || MarkedFactory.bDeleteMe || MarkedFactory.IsInState('Finished') )
	{
		bCompleted = true;
		return;
	}

	if ( MarkedFactory.IsInState('Waiting') )
	{
	}
	else if ( MarkedFactory.IsInState('Spawning') )
	{
		if ( !bDiscovered )
			Discover();
		bWasSpawning = True;
	}
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
		UpdateInterface();
	}
}

function UpdateInterface()
{
	local MHI_MonsterSpawner MHI;

	MHI = MHI_MonsterSpawner(Interface);
	if ( MHI != None )
	{
		if ( MHI.MonstersLeft != MarkedFactory.Capacity )
		{
			MHI.MonstersLeft = MarkedFactory.Capacity;
			if ( !MHI.IsTopInterface() )
				MHI.MoveToTop();
		}
		if ( (MHI.CompletedAt == 0) && (MarkedFactory.Capacity == 0) )
		{
			MHI.CompletedAt = MHI.Briefing.CurrentTime;
			MHI.bDormant = true;
			if ( MHI.EventIndex != OriginalIndex )
			{
				MHI.Briefing.RemoveIEvent( MHI);
				MHI.EventIndex = OriginalIndex;
				MHI.Briefing.InsertIEvent( MHI);
			}
		}
	}
}

event Timer()
{
	CheckState();
}
