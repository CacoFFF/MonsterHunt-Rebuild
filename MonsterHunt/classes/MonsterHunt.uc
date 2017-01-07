//****************************************************************
// MonsterHunt rebuild
// All subclasses should also have their config in MonsterHunt.ini
class MonsterHunt expands TeamGamePlus
	config(MonsterHunt);
	
var() config int MonsterSkill; //0 to 7 in v1...
var() config int Lives;
var() config bool bUseTeamSkins;



event InitGame(string Options, out string Error)
{
	//Force settings
	bUseTranslocator = False;
	bNoMonsters = False;
	MaxAllowedTeams = 1;
	Super.InitGame( Options, Error);
}


defaultproperties
{
	MonsterSkill=5
	Lives=6
	bUseTeamSkins=True
	TimeLimit=30
	MutatorClass=Class'MonsterBase'
    DefaultWeapon=Class'Botpack.ChainSaw'
	MapPrefix="MH"
	BeaconName="MH"
	LeftMessage=" left the hunt."
	EnteredMessage=" has joined the hunt!"
	StartUpMessage="Work with your teammates to hunt down the monsters!"
	StartMessage="The hunt has begun!"
	StartUpTeamMessage="Welcome to the hunt!"
	GameEndedMessage="Hunt Successful!"
	TimeOutMessage="Time up, hunt failed!"
	SingleWaitingMessage="Press Fire to begin the hunt."
}
