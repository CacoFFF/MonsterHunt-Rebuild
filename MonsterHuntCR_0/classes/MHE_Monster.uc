class MHE_Monster expands MHE_Base;

var ScriptedPawn Monsters[64];
var ScriptedPawn CurrentTarget; //AI
var MHE_Monster ExtraMonsters;
var int MonsterCount; //Fast access
var int BossCount; //Fast access
var int OriginalIndex;

function MHE_Monster AvailableForEvent( name aEvent)
{
	local MHE_Monster MHE;
	For ( MHE=self ; MHE!=None ; MHE=MHE_Monster(MHE.NextEvent) )
		if ( MHE.Event == aEvent )
			return MHE;
	return None;
}

function RegisterMonster( ScriptedPawn Other)
{
	local int Top;
	
	if ( (MonsterCount >= 64) && BossCount < 64 )
		MonsterCount--;
	
	if ( Other.bIsBoss )
	{
		Monsters[MonsterCount++] = Monsters[BossCount];
		Monsters[BossCount++] = Other;
	}
	else
		Monsters[MonsterCount++] = Other;
	Event = Other.Event;
}

function PostInit()
{
	if ( Event != '' )
		AnalyzeEvent( Event );
	SetTimer( 1+FRand(), true);
	bPostInit = true;
}

function RequiredForEvent(); //Somebody needs to activate this MHE_Base in order to activate an event

event Timer()
{
	local int i;
	local bool bActiveEnemy;
	
	For ( i=MonsterCount-1 ; i>=0 ; i-- )
	{
		if ( Monsters[i] == None || Monsters[i].bDeleteMe || Monsters[i].Health <= 0 )
		{
			if ( i < BossCount )
			{
				Monsters[i] = Monsters[--BossCount];
				Monsters[BossCount] = Monsters[--MonsterCount];
				BossCount--;
			}
			else
				Monsters[i] = Monsters[--MonsterCount];
		}
		else if ( !bDiscovered && !bActiveEnemy )
			bActiveEnemy = (Monsters[i].Enemy != None) && (Monsters[i].Enemy.PlayerReplicationInfo != None);
	}
	
	UpdateInterface();
	
	if ( CurrentTarget == None || CurrentTarget.bDeleteMe || CurrentTarget.Health <= 0 )
	{
		if ( MonsterCount > 0 )
			CurrentTarget = Monsters[Rand(MonsterCount)];
		else
		{
			Destroy();
			return;
		}
	}
	
	if ( DeferTo == None || !DeferTo.FastTrace( CurrentTarget.Location) )
	{
		DeferTo = None;
		SetLocation( CurrentTarget.Location);
		FindDeferPoint( CurrentTarget );
	}
		
	if ( !bDiscovered && bActiveEnemy )
		Discover();

	bAttractBots = bDiscovered || bQueriedByBot;
}

function UpdateInterface()
{
	local MHI_BossList MHI;
	
	MHI = MHI_BossList(Interface);
	if ( MHI != None )
	{
		//Completed!
		MHI.RemainingMinions = MonsterCount - BossCount;
		if ( (MHI.CompletedAt == 0) && (MonsterCount <= 0) )
			MHI.Completed();
	}
}

function Discover() //Create interface here
{
	local MHI_BossList MHI;
	local int i;

	bDiscovered = true;
	if ( Interface == None && (BossCount > 0) )
	{
		MHI = Spawn( class'MHI_BossList', self);
		Interface = MHI;
		OriginalIndex = MHI.EventIndex;
		MHI.MonsterListGUID = EventGUID;
		MHI.bDisplayDead = true;
		For ( i=BossCount-1 ; i>=0 ; i-- )
			if ( (Monsters[i] != None) && Monsters[i].bIsBoss && (Monsters[i].Health > 0) )
				MHI.CreateStatus( Monsters[i], self);
	}
}

event Destroyed()
{
	Super.Destroyed();
}


defaultproperties
{
	DeferToMode=DTM_NearestVisible
}
