class MHI_MonsterSpawner expands MHI_Base;

var string MonsterName;
var int MonstersLeft;
var int CompletedAt;
var bool bHasEvent;

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		MonsterName, bHasEvent;
	reliable if ( Role==ROLE_Authority )
		MonstersLeft, CompletedAt;
}

simulated function int DrawEvent( Canvas Canvas, float YStart, MonsterBoard MB)
{
	local float FY;
	
	Canvas.DrawColor = Grey;
	Canvas.SetPos( 0, YStart+3);
	Canvas.DrawText( "Monster wave:"@MonsterName$" ", false);
	Canvas.DrawColor = Cyan;
	Canvas.CurY = YStart+3;
	if ( MonstersLeft == 0 )
		Canvas.DrawText( "finished.", false);
	else
		Canvas.DrawText( string(MonstersLeft) @ "left.", false);
	//New Line!
	if ( CompletedAt > 0 )
	{
		Canvas.CurX = 0;
		FY = Canvas.CurY;
		Canvas.DrawText( "Finish time: ", false);

		Canvas.CurY = FY-2;
		Canvas.Font = MB.PtsFont12;
		Canvas.DrawColor = MB.BrightGold;
		Canvas.DrawText( MB.TimeToClock(CompletedAt), false);
	}
	return (Canvas.CurY-YStart) + 6;
}
