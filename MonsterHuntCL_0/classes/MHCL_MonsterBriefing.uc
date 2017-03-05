// Dummy MHCL_MonsterBriefing class
// Use this to customize MH proto's client interface
class MHCL_MonsterBriefing expands MonsterBriefing;

var class<Actor> BoomBoySpawnerBaseL;

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

function InitXCGE( int Version)
{
	Super.InitXCGE( Version); //XC_Engine servers will auto-load this package on ServerPackages (implicitly)
}

function MonsterAuthenticator SpawnAuthenticator( Pawn Other)
{
	return Spawn(class'MonsterAuthenticator', Other);
}

function MonsterPlayerData SpawnPlayerData( PlayerReplicationInfo aPRI)
{
	return Spawn( class'MonsterPlayerData', aPRI.Owner);
}


//Extension of base MonsterBriefing Server state
state Server
{
	function GenerateBoomBoySpawners()
	{
		local Actor A, B;
		local MHE_BB_MonsterSpawner CurSpawner;
		
		//Do not load the class, simply obtain it from memory if possible
		SetPropertyText("BoomBoySpawnerBaseL", "BBoyShare.B_MonsterLoopSpawner");
		if ( BoomBoySpawnerBaseL != None )
		{
			ForEach AllActors( BoomBoySpawnerBaseL, A)
				if ( A.Target != self && A.Class == BoomBoySpawnerBaseL )
				{
					CurSpawner = Spawn( class'MHE_BB_MonsterSpawner', self, A.Tag);
					CurSpawner.CreatureType = A.GetPropertyText("CreatureType");
					CurSpawner.bLoopSpawner = true;
					ForEach AllActors( BoomBoySpawnerBaseL, B, A.Tag)
						if ( CurSpawner.RegisterSpawner(B) )
							B.Target = self;
					CurSpawner.SetTimer( Level.TimeDilation+FRand(), true);
				}
			
			ForEach AllActors( BoomBoySpawnerBaseL, A)
				A.Target = None;
		}
	}

Begin:
	Sleep( 0.01);
	Level.Game.KillCredit( self); //Generic communication with MonsterHunt
	GenerateCriticalEvents();
	Sleep( 0.01);
	GenerateSpawners();
	Sleep( 0.01);
	GenerateBoomBoySpawners();
	Sleep( 0.01);
	GenerateTranslatorEvents();
	Sleep( 0.01);
	GenerateCounters();
	
	While ( !PostInit() )
		Sleep( 0.01);
}