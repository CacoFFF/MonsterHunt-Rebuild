class MHI_MonsterSpawner expands MHI_Base;

var string MonsterName;
var int MonstersLeft;
var int CompletedAt;
var bool bSpawnFinished;
var bool bSpawnInterrupted;
var bool bHasEvent;

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		MonsterName, bHasEvent;
	reliable if ( Role==ROLE_Authority )
		MonstersLeft, CompletedAt, bSpawnFinished, bSpawnInterrupted;
}

simulated function int DrawEvent( Canvas Canvas, float YStart, MonsterBoard MB)
{
	local float FY;
	
	Canvas.DrawColor = MB.Grey;
	Canvas.SetPos( 0, YStart+3);
	Canvas.DrawText( "Monster wave:"@MonsterName$" ", false);
	if ( bSpawnFinished || bSpawnInterrupted)
		Canvas.DrawColor = MB.Orange;
	else
		Canvas.DrawColor = MB.BrightCyan;
	Canvas.CurY = YStart+3;
	if ( MonstersLeft == 0 )
		Canvas.DrawText( "finished.", false);
	else if ( bSpawnInterrupted )
		Canvas.DrawText( "interrupted.", false);
	else
		Canvas.DrawText( string(MonstersLeft) @ "left.", false);

	//New Line!
	if ( CompletedAt > 0 )
	{
		Canvas.DrawColor = MB.Grey;
		Canvas.CurX = 0;
		FY = Canvas.CurY;
		Canvas.DrawText( "Finish time: ", false);

		Canvas.CurY = FY;
		Canvas.DrawColor = MB.BrightGold;
		Canvas.DrawText( MB.TimeToClock(CompletedAt), false);
	}
	return (Canvas.CurY-YStart) + 6;
}
