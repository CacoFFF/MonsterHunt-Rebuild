//*******************************
// MonsterReplicationInfo
// Global info visible by clients
class MonsterReplicationInfo expands TournamentGameReplicationInfo;

var int Lives;
var int Monsters;
var int Hunters;

replication
{
	reliable if ( ROLE==ROLE_Authority )
		Lives, Monsters, Hunters;
}

simulated function Timer()
{
	Super.Timer();
	if ( Level.NetMode != NM_Client )
	{
		Hunters = MonsterHunt(Level.Game).CountHunters();
		Lives = MonsterHunt(Level.Game).Lives;
		if ( MonsterHunt(Level.Game).bCountMonstersAgain || (FRand() < 0.05) )
		{
			MonsterHunt(Level.Game).bCountMonstersAgain = false;
			Monsters = MonsterHunt(Level.Game).CountMonsters();
		}
		if ( MonsterHunt(Level.Game).bCheckEndLivesAgain )
			MonsterHunt(Level.Game).CheckEndGame();
	}
}
