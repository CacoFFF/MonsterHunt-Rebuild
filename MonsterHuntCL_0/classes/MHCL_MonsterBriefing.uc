// Dummy MHCL_MonsterBriefing class
// Use this to customize MH proto's client interface
class MHCL_MonsterBriefing expands MonsterBriefing;


simulated event PostBeginPlay()
{
	if ( Level.Game != None ) //Modify HUD and ScoreBoard, affects MH503 clients!
	{
		Level.Game.ScoreBoardType = Class'MHCL_ScoreBoard';
		Level.Game.HUDType = Class'MHCL_HUD';
	}
	Super.PostBeginPlay();
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
