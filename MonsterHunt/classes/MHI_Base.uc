class MHI_Base expands Info;

var MonsterBriefing Briefing;
var MHI_Base NextEvent;
var int TargetNUF;

var int DrawY;

var int TimeStamp;
var int EventIndex;
var int OldIndex;
var bool bDormant;


replication
{
	reliable if ( Role == ROLE_Authority )
		EventIndex, TimeStamp;
}

event PostBeginPlay()
{
	TargetNUF = NetUpdateFrequency;
	if ( default.bNetTemporary )
		bDormant = true;
	if ( (MonsterHunt(Level.Game) != None) && (MonsterHunt(Level.Game).Briefing != None) )
	{
		Briefing = MonsterHunt(Level.Game).Briefing;
		EventIndex = Briefing.CurrentIndex++;
		TimeStamp = Briefing.CurrentTime;
		OldIndex = EventIndex;
		Briefing.InsertIEvent( self);
	}
}

simulated event PostNetBeginPlay()
{
	ForEach AllActors( class'MonsterBriefing', Briefing)
	{
		Briefing.InsertIEvent( self);
		break;
	}
}

simulated event Destroyed()
{
	if ( Briefing != None )
		Briefing.RemoveIEvent( self);
}

simulated final function bool IsTopInterface()
{
	return Briefing != None && Briefing.InterfaceEventList == self;
}

simulated final function MoveToTop()
{
	if ( Briefing != None )
	{
		Briefing.RemoveIEvent( self);
		EventIndex = Briefing.CurrentIndex++;
		Briefing.InsertIEvent(self);
	}
}

//Canvas clips and base positions must be preset!
simulated function int DrawEvent( Canvas Canvas, float YStart, MonsterBoard MB);



//*************************************************
//**************** NetUpdateFrequency regulators

function BoostNet()
{
	GotoState('BoostNUF');
}

auto state BoostNUF
{
	function BoostNet()
	{
	}
Begin:
	NetUpdateFrequency = 10;
	NetPriority = default.NetPriority*2;
	Sleep(0.5);
	NetUpdateFrequency = TargetNUF;
	NetPriority = default.NetPriority;
	if ( bDormant )
	{
		NetUpdatePriority *= 0.7;
		NetUpdateFrequency *= 0.7;
	}
	GotoState('');
}


defaultproperties
{
	bAlwaysRelevant=True
	NetUpdateFrequency=2
}
