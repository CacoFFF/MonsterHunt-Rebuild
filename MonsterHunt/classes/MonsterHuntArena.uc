//================================================================================
// MonsterHuntArena.
//================================================================================
class MonsterHuntArena extends MonsterHunt
	config(MonsterHunt);

var() config float WeaponRespawnTime;
var() config float AmmoRespawnTime;



defaultproperties
{
    GoalTeamScore=500
    StartUpTeamMessage="Welcome to the ultimate arena battle!"
    FragLimit=500
    StartUpMessage="Work with your teammates to overcome the monsters!"
    StartMessage="The battle has begun!"
    GameEndedMessage="Arena Cleared!"
    SingleWaitingMessage="Press Fire to enter the arena."
    MapListType=Class'MonsterArenaMapList'
    MapPrefix="MA"
    BeaconName="MA"
    LeftMessage=" left the arena."
    EnteredMessage=" has entered the arena!"
    GameName="Monster Arena"
	WeaponRespawnTime=3.0
	AmmoRespawnTime=3.0
}
