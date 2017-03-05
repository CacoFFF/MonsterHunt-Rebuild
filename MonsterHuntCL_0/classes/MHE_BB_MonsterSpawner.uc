//BoomBoy monster spawner status!
class MHE_BB_MonsterSpawner expands MHE_Base;

var Actor BoomSpawners[16];
var int SpawnerCount;
var int CountedPawns;
var int OriginalIndex;
var string CreatureType;
var class<ScriptedPawn> SP;
var bool bLoopSpawner;
var bool bWaveSpawner;
var bool bCompleted;

function bool RegisterSpawner( Actor Other)
{
	local int i;
	if ( SpawnerCount < ArrayCount(BoomSpawners) )
	{
		i = SpawnerCount;
		if ( bWaveSpawner )
		{
			if ( Other.IsA('B_MonsterWaveSpawner') )
				BoomSpawners[SpawnerCount++] = Other;
		}
		else if ( bLoopSpawner )
		{
			if ( Other.IsA('B_MonsterLoopSpawner') && (Other.GetPropertyText("CreatureType") == CreatureType) )
				BoomSpawners[SpawnerCount++] = Other;
		}
		else
		{
			if ( Other.IsA('B_MonsterSpawner') )
				BoomSpawners[SpawnerCount++] = Other;
		}
		return i != SpawnerCount;
	}
}

event Trigger( Actor Other, Pawn EventInstigator)
{
	if ( !bDiscovered )
		Discover();
	CheckState();
}

event Timer()
{
	CheckState();
}

function Discover()
{
	local MHI_MonsterSpawner MHI;

	bDiscovered = true;
	SetTimer( Level.TimeDilation, true);

	if ( Interface == None )
	{
		MHI = Spawn( class'MHI_MonsterSpawner', self);
		Interface = MHI;
		OriginalIndex = MHI.EventIndex;
		SetPropertyText("SP", CreatureType);
		if ( SP != None )
		{
			MHI.MonsterName = SP.default.MenuName;
			if ( MHI.MonsterName == "" )
				MHI.MonsterName = string(SP.Name);
		}
		if ( MHI.MonsterName == "" )
			MHI.MonsterName = FixClassName( CreatureType);
//		if ( Counter != None )
//			MHI.CountersTotal = CountersTotal;
	}
}

function string FixClassName( string Cls)
{
	local int i;
	
DOT:
	i=InStr(Cls,".");
	if ( i >= 0 )
	{
		Cls = Mid( Cls, i+1);
		Goto DOT;
	}
	i = Len(Cls);
	return Left(Cls, i-1);
}

function CheckState()
{
	local int i, j, k;
	
	CountedPawns = 0;
	bCompleted = true;
	if ( bWaveSpawner ) //Can't access wave count!!
	{
		For ( i=0 ; i<SpawnerCount ; i++ )
			if ( BoomSpawners[i] != None )
			{
				j = int( BoomSpawners[i].GetPropertyText("SpawnNum") );
				bCompleted = bCompleted && (j==0);
				CountedPawns += int( BoomSpawners[i].GetPropertyText("NumMonster") );
			}
	}
	else if ( bLoopSpawner )
	{
		For ( i=0 ; i<SpawnerCount ; i++ )
			if ( BoomSpawners[i] != None )
			{
				j = int( BoomSpawners[i].GetPropertyText("SpawnNum") );
				bCompleted = bCompleted && (j==0);
				CountedPawns += j + int( BoomSpawners[i].GetPropertyText("NumMonster") );
			}
	}
	else
	{
		For ( i=0 ; i<SpawnerCount ; i++ )
			if ( BoomSpawners[i] != None )
				bCompleted = bCompleted && BoomSpawners[i].IsInState('Finished');
		if ( bCompleted )
			CountedPawns = CountPawns();
	}

	UpdateInterface();
}


function UpdateInterface()
{
	local MHI_MonsterSpawner MHI;

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
/*			if ( Counter != None )
			{
				MHI.CountersLeft = Counter.ActiveCounters();
				MHI.NextCounterLowest = Counter.GetLowestCounter();
			}*/
		}
	
		if ( (MHI.CompletedAt == 0) && (CountedPawns <= 0) && bCompleted )
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

function int CountPawns()
{
	local Actor S;
	local int i;
	
	ForEach AllActors ( SP, S)
		if ( S.Event == Tag )
			i++;
	return i;
}

function int CountPawns_XC()
{
	local Actor S;
	local int i;
	
	ForEach DynamicActors ( SP, S)
		if ( S.Event == Tag )
			i++;
	return i;
}
