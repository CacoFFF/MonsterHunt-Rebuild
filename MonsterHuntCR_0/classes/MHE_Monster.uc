class MHE_Monster expands MHE_Base;

var ScriptedPawn Monsters[32];
var int MonsterCount;
var string EventChain;

function MHE_Monster AvailableForEvent( name aEvent)
{
	local MHE_Monster MHE;
	For ( MHE=self ; MHE!=None ; MHE=MHE_Monster(MHE.NextEvent) )
		if ( (MHE.Event == aEvent) && (MHE.MonsterCount < 32) )
			return MHE;
	return None;
}

function RegisterMonster( ScriptedPawn Other)
{
	Assert( MonsterCount < 32 );
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
	
	For ( i=MonsterCount-1 ; i>=0 ; i-- )
		if ( Monsters[i] == None || Monsters[i].bDeleteMe || Monsters[i].Health <= 0 )
		{
			Monsters[i] = Monsters[--MonsterCount];
			Monsters[MonsterCount] = None;
		}

	if ( MonsterCount > 0 )
	{
		if ( !bDiscovered )
		{
			i = Rand(MonsterCount);
			if ( (Monsters[i].Enemy != None) && (Monsters[i].Enemy.PlayerReplicationInfo != None) )
				Discover();
		}
		
		if ( DeferTo == None || !DeferTo.FastTrace( Monsters[0].Location) )
		{
			DeferTo = None;
			SetLocation( Monsters[0].Location);
			FindDeferPoint( Monsters[0] );
		}
		
		if ( DeferTo == None )
		{
			//Do something?
		}
	}
		
		
	bAttractBots = bDiscovered || bQueriedByBot;
	if ( MonsterCount <= 0 )
		Destroy();
}

defaultproperties
{
	DeferToMode=DTM_NearestVisible
}
