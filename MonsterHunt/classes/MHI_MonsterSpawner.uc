class MHI_MonsterSpawner expands MHI_Base;


var localized string TEXT_MonsterWave;
var localized string TEXT_IndividualEvent;
var localized string TEXT_AllEvents;
var localized string TEXT_FirstEvent;
var localized string TEXT_NextEvent;
var localized string TEXT_LastEvent;
var localized string TEXT_Finished;
var localized string TEXT_Interrupted;
var localized string TEXT_Remaining;

var string MonsterName;
//var string NextCounterEvent;
var int MonstersLeft;
var int CompletedAt;
var byte CountersTotal;
var byte CountersLeft;
var byte NextCounterLowest;
var bool bSpawnFinished;
var bool bSpawnInterrupted;
var bool bHasEvent;

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		MonsterName, bHasEvent, CountersTotal;
	reliable if ( Role==ROLE_Authority )
		MonstersLeft, CompletedAt, bSpawnFinished, bSpawnInterrupted, CountersLeft, NextCounterLowest;
}

simulated function int DrawEvent( Canvas Canvas, float YStart, MonsterBoard MB)
{
	local float FY;
	
	Canvas.DrawColor = MB.Grey;
	Canvas.SetPos( 0, YStart+3);
	Canvas.DrawText( TEXT_MonsterWave $ ":" @ MonsterName, false);
	Canvas.CurX += 3;
	if ( bSpawnFinished || bSpawnInterrupted)
		Canvas.DrawColor = MB.Orange;
	else
		Canvas.DrawColor = MB.BrightCyan;
	Canvas.CurY = YStart+3;
	if ( MonstersLeft == 0 )
		Canvas.DrawText( TEXT_Finished$".", false);
	else if ( bSpawnInterrupted )
		Canvas.DrawText( TEXT_Interrupted$".", false);
	else
		Canvas.DrawText( string(MonstersLeft) @ TEXT_Remaining $ ".", false);

	if ( CountersTotal > 0 )
	{
		Canvas.CurX = 0;
		Canvas.DrawColor = MB.Grey;
		FY = Canvas.CurY;
		if ( CountersLeft == 0 )
		{
			if ( CountersTotal == 1 )
				Canvas.DrawText( TEXT_IndividualEvent, false);
			else
				Canvas.DrawText( TEXT_AllEvents, false);
			Canvas.CurY = FY;
			Canvas.CurX += 3;
			Canvas.DrawColor = MB.Orange;
			Canvas.DrawText( TEXT_Finished $ ".", false);
		}
		else
		{
			if ( CountersTotal == CountersLeft )
				Canvas.DrawText( TEXT_FirstEvent, false);
			else if ( CountersLeft == 1 )
				Canvas.DrawText( TEXT_LastEvent, false);
			else
				Canvas.DrawText( TEXT_NextEvent, false);
			Canvas.CurY = FY;
			Canvas.CurX += 3;
			Canvas.DrawColor = MB.BrightCyan;
			Canvas.DrawText( string(NextCounterLowest) @ TEXT_Remaining $ ".", false);
		}
	}
		
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


defaultproperties
{
	TEXT_MonsterWave="Monster wave"
	TEXT_IndividualEvent="Event"
	TEXT_AllEvents="All events"
	TEXT_FirstEvent="First event"
	TEXT_NextEvent="Next event"
	TEXT_LastEvent="Last event"
	TEXT_Finished="finished"
	TEXT_Interrupted="interrupted"
	TEXT_Remaining="remaining"
}
