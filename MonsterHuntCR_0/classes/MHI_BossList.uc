class MHI_BossList expands MHI_Base;

var localized string TEXT_BossFight;
var localized string TEXT_Health;
var localized string TEXT_Defeated;
var localized string TEXT_RemainingMinions;

var MHI_MonsterStatus MonsterList;
var int MonsterListGUID;
var int CompletedAt;
var int RemainingMinions;
var bool bDisplayDead;
var int ExpireTime;

var int FinishBossCount;

replication
{
	reliable if ( Role == ROLE_Authority )
		RemainingMinions, CompletedAt, FinishBossCount;
	reliable if ( bNetInitial && Role == ROLE_Authority )
		MonsterListGUID, bDisplayDead;
}


function CreateStatus( ScriptedPawn Other, MHE_Monster Master)
{
	local MHI_MonsterStatus Status;
	
	Status = Spawn( class'MHI_MonsterStatus', Master);
	Status.RegisterMonster( Other);
	Status.MonsterListGUID = MonsterListGUID;
	AddStatus( Status);
}

function Completed()
{
	local MHI_MonsterStatus Link;

	CompletedAt = Briefing.CurrentTime;
	FinishBossCount = 0;
	For ( Link=MonsterList ; Link!=None ; Link=Link.NextMonster )
		FinishBossCount++;
	if ( !bDisplayDead )
		ExpireTime = CompletedAt + 60;
}

simulated function int DrawEvent( Canvas Canvas, float YStart, MHCR_ScoreBoard MB)
{
	local float FX, FY;
	local int TotalBoss, DefeatedBoss;
	local MHI_MonsterStatus Link;
	
	For ( Link=MonsterList ; Link!=None ; Link=Link.NextMonster )
	{
		DefeatedBoss += int(Link.CurrentHP <= 0);
		TotalBoss++;
	}
	
	FX = Canvas.CurX;
	Canvas.DrawColor = MB.Grey;
	if ( DefeatedBoss >= TotalBoss )
		Canvas.DrawColor = MB.Orange;
		
	Canvas.SetPos( 0, YStart+3);
	if ( TotalBoss > 1 )
		Canvas.DrawText( TEXT_BossFight @ DefeatedBoss $ "/" $ TotalBoss, false);
	else if ( FinishBossCount > 0 )
		Canvas.DrawText( TEXT_BossFight @ FinishBossCount $"/"$ FinishBossCount, false);
	else
		Canvas.DrawText( TEXT_BossFight, false);
	
	For ( Link=MonsterList ; (Link!=None) && (FinishBossCount==0) ; Link=Link.NextMonster )
	{
		Canvas.DrawColor = MB.Grey;
		Canvas.CurX = FX + 4;
		FY = Canvas.CurY;
		Canvas.DrawText( Link.MonsterName, false);
		Canvas.SetPos( Max(Canvas.CurX,Canvas.ClipX/3), FY);
		if ( Link.CurrentHP <= 0 )
		{
			if ( bDisplayDead )
			{
				Canvas.DrawColor = MB.Orange;
				Canvas.DrawText( TEXT_Defeated, false);
			}
		}
		else
		{
			Canvas.DrawColor = MB.BrightCyan;
			Canvas.DrawText( TEXT_Health $ ": ", false);
			Canvas.CurY = FY;
			if ( Link.CurrentHP < Link.StartingHP / 8 )
				Canvas.DrawColor = MB.BrightRed;
			else if ( Link.CurrentHP < Link.StartingHP / 3 )
				Canvas.DrawColor = MB.Orange;
			else
				Canvas.DrawColor = MB.BrightGold;
			Canvas.DrawText( string(Link.CurrentHP), false);
			Canvas.CurY = FY;
			Canvas.DrawColor = MB.BrightCyan;
			Canvas.DrawText( "/", false);
			Canvas.CurY = FY;
			Canvas.DrawColor = MB.BrightGold;
			Canvas.DrawText( string(Link.StartingHP), false);
		}
		Canvas.CurY -= 1;
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
	else if ( RemainingMinions > 0 )
	{
		Canvas.DrawColor = MB.Grey;
		Canvas.CurX = 10;
		FY = Canvas.CurY;
		Canvas.DrawText( TEXT_RemainingMinions$": ", false);
		Canvas.CurY = FY;
		Canvas.DrawText( RemainingMinions, false);
	}
	return (Canvas.CurY-YStart) + 6;
}








simulated event PostNetBeginPlay()
{
	local MHI_MonsterStatus Status;
	
	Super.PostNetBeginPlay();
	ForEach AllActors( class'MHI_MonsterStatus', Status)
		if ( Status.MonsterListGUID == MonsterListGUID )
			AddStatus( Status);
}

simulated event Destroyed() //Clean unlink
{
	local MHI_MonsterStatus Status;
	
	while ( MonsterList != None )
	{
		Status = MonsterList;
		MonsterList = Status.NextMonster;
		Status.NextMonster = None;
		if ( Level.NetMode != NM_Client )
			Status.Destroy();
	}
}

//**************************************************************
// List handlers

simulated function AddStatus( MHI_MonsterStatus Status)
{
	if ( Status.NextMonster == None || Status.NextMonster.bDeleteMe )
	{
		Status.NextMonster = MonsterList;
		MonsterList = Status;
	}
}


simulated function RemoveStatus( MHI_MonsterStatus Status)
{
	local MHI_MonsterStatus Link;
	
	if ( MonsterList == Status )
		MonsterList = Status.NextMonster;
	else
	{
		For ( Link=MonsterList ; Link!=None ; Link=Link.NextMonster )
			if ( Link.NextMonster == Status )
			{
				Link.NextMonster = Status.NextMonster;
				break;
			}
	}
	Status.NextMonster = None;
}



defaultproperties
{
	TEXT_BossFight="Boss Fight"
	TEXT_Health="Health"
	TEXT_Defeated="Defeated"
	TEXT_RemainingMinions="Remaining minions"
}




