// Dummy MHCL_MonsterBriefing class
// Use this to customize MH proto's client interface
class MHCL_MonsterBriefing expands MonsterBriefing;

var class<Actor> BoomBoySpawnerBase;
var bool bTrue;

simulated event PostBeginPlay()
{
	if ( Level.Game != None ) //Modify HUD and ScoreBoard, affects MH503 clients!
	{
		Level.Game.ScoreBoardType = Class'MHCL_ScoreBoard';
		Level.Game.HUDType = Class'MHCL_HUD';
	}
	Super.PostBeginPlay();
	Spawn( class'MonsterBloodNotify');
}

function MonsterAuthenticator SpawnAuthenticator( Pawn Other)
{
	return Spawn( class'MonsterAuthenticator', Other);
}

function MonsterPlayerData SpawnPlayerData( PlayerReplicationInfo aPRI)
{
	return Spawn( class'MonsterPlayerData', aPRI.Owner);
}


//Extension of base MonsterBriefing Server state
state Server
{
	function GenerateSpawners()
	{
		Super.GenerateSpawners();
		GenerateBoomBoySpawners();
	}

	function GenerateBoomBoySpawners()
	{
		local Actor A, B;
		local MHE_BB_MonsterSpawner CurSpawner;
		local class<Actor> BBSB;
	
		bTrue = true;

		SetPropertyText("BoomBoySpawnerBase", "BBoyShare.B_MonsterSpawner");
		if ( BoomBoySpawnerBase != None )
		{
			BBSB = BoomBoySpawnerBase;
			ForEach AllActors( BoomBoySpawnerBase, A)
				if ( A.Target != self && A.Class == BoomBoySpawnerBase && A.GetPropertyText("bSpawnOnceOnly")==GetPropertyText("bTrue") )
				{
					CurSpawner = Spawn( class'MHE_BB_MonsterSpawner', self, A.Tag);
					CurSpawner.CreatureType = A.GetPropertyText("CreatureType");
					ForEach AllActors( BoomBoySpawnerBase, B, A.Tag)
						if ( B.GetPropertyText("bSpawnOnceOnly")==GetPropertyText("bTrue") && CurSpawner.RegisterSpawner(B) )
							B.Target = self;
					CurSpawner.SetTimer( Level.TimeDilation+FRand(), true);
				}
		}
		
		SetPropertyText("BoomBoySpawnerBase", "BBoyShare.B_MonsterLoopSpawner");
		if ( BoomBoySpawnerBase != None )
		{
			ForEach AllActors( BoomBoySpawnerBase, A)
				if ( A.Target != self && A.Class == BoomBoySpawnerBase )
				{
					CurSpawner = Spawn( class'MHE_BB_MonsterSpawner', self, A.Tag);
					CurSpawner.CreatureType = A.GetPropertyText("CreatureType");
					CurSpawner.bLoopSpawner = true;
					ForEach AllActors( BoomBoySpawnerBase, B, A.Tag)
						if ( CurSpawner.RegisterSpawner(B) )
							B.Target = self;
					CurSpawner.SetTimer( Level.TimeDilation+FRand(), true);
				}
		}
		
		SetPropertyText("BoomBoySpawnerBase", "BBoyShare.B_MonsterWaveSpawner");
		if ( BoomBoySpawnerBase != None )
		{
			ForEach AllActors( BoomBoySpawnerBase, A)
				if ( A.Target != self && A.Class == BoomBoySpawnerBase )
				{
					CurSpawner = Spawn( class'MHE_BB_MonsterSpawner', self, A.Tag);
					CurSpawner.bLoopSpawner = true;
					CurSpawner.bWaveSpawner = true;
					ForEach AllActors( BoomBoySpawnerBase, B, A.Tag)
						if ( CurSpawner.RegisterSpawner(B) )
							B.Target = self;
					CurSpawner.SetTimer( Level.TimeDilation+FRand(), true);
				}
		}

		if ( BBSB != None )
			ForEach AllActors( BBSB, A)
				A.Target = None;
		
	}
}