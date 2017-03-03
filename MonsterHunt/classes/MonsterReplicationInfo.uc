//*******************************
// MonsterReplicationInfo
// Global info visible by clients
class MonsterReplicationInfo expands TournamentGameReplicationInfo;

var bool bUseLives; //Keep network compatibility with 503
var const bool bUseTeamSkins; //Keep network compatibility with 503
var int Lives;
var int Monsters;
var int Hunters;
var localized int LocaleVersion;

replication
{
	reliable if ( ROLE==ROLE_Authority )
		bUseLives, bUseTeamSkins, Lives, Monsters, Hunters;
}

simulated function Timer()
{
	local ScriptedPawn P;
	
	Super.Timer();
	if ( Level.NetMode != NM_Client )
	{
		MonsterHunt(Level.Game).CountHunters();
		Lives = MonsterHunt(Level.Game).Lives;
		bUseLives = Lives > 0;
		if ( MonsterHunt(Level.Game).bCountMonstersAgain || (FRand() < 0.05) )
		{
			MonsterHunt(Level.Game).bCountMonstersAgain = false;
			MonsterHunt(Level.Game).CountMonsters();
		}
		if ( MonsterHunt(Level.Game).bCheckEndLivesAgain )
			MonsterHunt(Level.Game).CheckEndGame();
	}
}




