//================================================================================
// MonsterHuntArena.
//================================================================================
class MonsterHuntArena extends MonsterHunt
	config(MonsterHunt);

var() config float WeaponRespawnTime;
var() config float AmmoRespawnTime;

//If a pawn is spawned, let game we want to count all monsters again
function bool IsRelevant( Actor Other)
{
	local bool Result;
	local Inventory Inv;
	
	Result = Super.IsRelevant( Other);
	if ( Result && (Inventory(Other) != None) && (Inventory(Other).RespawnTime > 0) )
	{
		if ( Other.IsA('Weapon') )
			Weapon(Other).RespawnTime = WeaponRespawnTime;
		else if ( Other.IsA('Ammo') )
			Ammo(Other).RespawnTime = AmmoRespawnTime;
	}
	return Result;
}

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
