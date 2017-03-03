class MHI_CriticalEvent expands MHI_Base;

var string CriticalMessage;
var bool bMHCrit;

replication
{
	reliable if ( Role==ROLE_Authority )
		CriticalMessage, bMHCrit;
}

simulated function int DrawEvent( Canvas Canvas, float YStart, MHCR_ScoreBoard MB)
{
	if ( bMHCrit )
		Canvas.DrawColor = MB.BrightCyan;
	else
		Canvas.DrawColor = MB.Grey;
	Canvas.SetPos( 0, YStart+3);
	Canvas.DrawText( CriticalMessage, false);
	return (Canvas.CurY-YStart) + 6;
}



defaultproperties
{
	bNetTemporary=True
}
