class MHI_Base expands Info;

var MonsterBriefing Briefing;
var MHI_Base NextEvent;
var MHI_Base NextHint;
var int TargetNUF;

var int DrawY;
var int HintY;
var vector ScreenOffset; //X=horiz, Y=vert, Z=front (bigger means further in screen concept, should be 0 to MaxX/500)
var Texture HintIcon;

var int TimeStamp;
var int EventIndex;
var int OldIndex;
var bool bDormant;
var bool bDrawEvent; //Draw on ScoreBoard, def=True
var bool bIsHint; //HINT IS 100% SIMULATED, def=False


replication
{
	reliable if ( Role == ROLE_Authority )
		EventIndex, TimeStamp;
	reliable if ( bNetInitial && Role == ROLE_Authority )
		bIsHint;
}

event PostBeginPlay()
{
	TargetNUF = NetUpdateFrequency;
	if ( default.bNetTemporary )
		bDormant = true;

	if ( Briefing == None )
		ForEach AllActors( class'MonsterBriefing', Briefing)
			break;
	
	if ( Briefing != None )
	{
		EventIndex = Briefing.CurrentIndex++;
		TimeStamp = Briefing.CurrentTime;
		OldIndex = EventIndex;
		Briefing.InsertIEvent( self);
		if ( bIsHint )
			Briefing.InsertHint( self);
	}
	else
		Warn("MONSTER BRIEFING NOT FOUND!!!");
}

simulated event PostNetBeginPlay()
{
	ForEach AllActors( class'MonsterBriefing', Briefing)
	{
		Briefing.InsertIEvent( self);
		if ( bIsHint )
			Briefing.InsertHint( self);
		break;
	}
}

simulated event Destroyed()
{
	if ( Briefing != None )
	{
		Briefing.RemoveIEvent( self);
		if ( bIsHint )
			Briefing.RemoveHint( self);
	}
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
simulated function int DrawEvent( Canvas Canvas, float YStart, MHCR_ScoreBoard MB);
simulated function int DrawHint( Canvas Canvas, MHCR_HUD MH);


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
		NetUpdateFrequency *= 0.7;
		NetPriority *= 0.7;
	}
	GotoState('');
}


defaultproperties
{
	bAlwaysRelevant=True
	bDrawEvent=True
	NetUpdateFrequency=2
	HintIcon=Texture'UnrealShare.S_Alarm'
}
