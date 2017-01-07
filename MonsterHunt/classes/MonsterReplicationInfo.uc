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
	Hunters = MonsterHunt(Level.Game).CountHunters();
	Lives = MonsterHunt(Level.Game).Lives;
}
