//Expires after 30 seconds of being hit
class MHI_TranslatorMessage expands MHI_Base;

var(MHI_Base) string Message, Hint;

replication
{
	reliable if ( Role==ROLE_Authority )
		Message, Hint;
}


event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.5, true);
}

event Timer()
{
	if ( Briefing == None || Briefing.bDeleteMe || (Briefing.CurrentTime - TimeStamp > 30) )
		Destroy();
}

defaultproperties
{
	bIsHint=True
	bDrawEvent=False
	ScreenOffset=(Y=1)
}
