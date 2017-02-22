//Expires after 30 seconds of being hit
class MHI_TranslatorMessage expands MHI_Base;

#exec Texture Import File=pcx\HUD_TEvent.pcx Name=HUD_TEvent Mips=Off Group=HUD Flags=2

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

function int DrawHint( Canvas Canvas, MonsterHUD MHUD)
{
	Canvas.SetPos( 0, 0);
	Canvas.Font = Font'Engine.MedFont'; //Keeps the old feeling
	Canvas.DrawText( Message, false);
	
	if ( Hint != "" )
	{
		Canvas.Font = Font'UnrealShare.WhiteFont';
		Canvas.CurX = 5;
		Canvas.CurY += 4;
		Canvas.DrawColor = MHUD.ProtectionColors[1];
		Canvas.DrawText( "Hint:", false);
		Canvas.CurX = 0;
		Canvas.DrawText( Hint, false);
	}
	
	return Canvas.CurY;
}

defaultproperties
{
	bIsHint=True
	bDrawEvent=False
	ScreenOffset=(Y=1)
	HintIcon=Texture'HUD_TEvent'
}
