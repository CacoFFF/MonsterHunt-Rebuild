class MHI_Base expands Info;

var MonsterBriefing Briefing;
var MHI_Base NextEvent;

var int DrawY;
var Color Cyan;
var Color White;
var Color Grey;

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


//Canvas clips and base positions must be preset!
simulated function int DrawEvent( Canvas Canvas, float YStart);



defaultproperties
{
	bAlwaysRelevant=True
	NetUpdateFrequency=3
	White=(R=255,G=255,B=255)
	Grey=(R=200,G=200,B=200)
	Cyan=(R=128,G=255,B=255)
}
