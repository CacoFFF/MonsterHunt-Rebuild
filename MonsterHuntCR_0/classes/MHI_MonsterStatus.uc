class MHI_MonsterStatus expands MHI_Base;


var MHI_MonsterStatus NextMonster;
var ScriptedPawn Monster;
var int MonsterListGUID;
var vector MonsterLocation;

var string MonsterName;
var int StartingHP;
var int CurrentHP;
var vector KillLocation;

var int HintExpire;



replication
{
	reliable if ( Role == ROLE_Authority )
		CurrentHP, KillLocation;
	reliable if ( bNetInitial && Role == ROLE_Authority )
		StartingHP, MonsterName, MonsterListGUID;
}


function RegisterMonster( ScriptedPawn Other)
{
	Monster = Other;
	StartingHP = Monster.Health;
	MonsterName = Other.MenuName;
	Timer();
}

simulated event PostNetBeginPlay()
{
	local MHI_BossList List;
	
	Super.PostNetBeginPlay();
	ForEach AllActors( class'MHI_BossList', List)
		if ( List.MonsterListGUID == MonsterListGUID )
			List.AddStatus( self);
}

simulated event Timer()
{
	local float NextTimer;

	if ( Level.NetMode != NM_Client )
	{
		if ( Monster != None && !Monster.bDeleteMe && Monster.Health > 0 )
		{
			NextTimer = Level.TimeDilation * 0.5 + FRand();
			MonsterLocation = Monster.Location;
			if ( CurrentHP != Monster.Health )
			{
				BoostNet();
				NextTimer *= 0.3;
				CurrentHP = Monster.Health;
			}
			SetTimer( Level.TimeDilation * 0.5 + FRand(), true);
		}
		else
		{
			CurrentHP = 0;
			KillLocation = MonsterLocation;
		}
	}
	
	if ( KillLocation != vect(0,0,0) )
	{
		if ( HintExpire == 0 )
		{
			HintExpire = Briefing.CurrentTime + 5;
			if ( !bIsHint )
				Briefing.InsertHint( self);
		}
		else if ( Briefing.CurrentTime > HintExpire )
			Briefing.RemoveHint( self);
	}
}



defaultproperties
{
     bDrawEvent=False
     HintIcon=Texture'Engine.S_Corpse'
}
