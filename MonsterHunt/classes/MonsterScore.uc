//=============================================================================
// sgScore
// by Sektor
// Greatly optimized by Higor > now adapted to MH
//=============================================================================
class MonsterScore expands TournamentScoreBoard;

#exec TEXTURE IMPORT NAME=Shade FILE=pcx\Shade.PCX GROUP=ScoreBoard MIPS=OFF
#exec TEXTURE IMPORT NAME=Shade2 FILE=pcx\Shade2.PCX GROUP=ScoreBoard MIPS=OFF

var transient PlayerReplicationInfo PRI[128];
var transient MonsterPlayerData MPD[128];
var transient int iPRI, sPRI;


var int AvgPing, AvgPL, NotShownPlayers, ShowMaxPlayer;
var int tableWidth, tableHeaderHeight, cellHeight, tableLine1, tableLine2, paddingInfo;
var transient float LastSortTime;

var bool bAllowDraw;
var MonsterReplicationInfo MRI;
var Font PtsFont26,PtsFont24,PtsFont22, PtsFont20, PtsFont18, PtsFont16, PtsFont14, PtsFont12;
var FontInfo MyFonts;
var TeamInfo HunterTeam;

var Color BrightRed, BrightBlue, BrightGold, White, BrightCyan;
var() localized string MonthString[13];
var() localized string DayString[7];


function Destroyed()
{
	Super.Destroyed();
	if ( MyFonts != None )
		MyFonts.Destroy();
}


function PostBeginPlay()
{
	Super.PostBeginPlay();
	MyFonts = FontInfo(spawn(Class<Actor>(DynamicLoadObject(class'ChallengeHUD'.default.FontInfoClass, class'Class'))));

	LastSortTime = -100;

	PtsFont26 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
	PtsFont24 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
	PtsFont22 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
	PtsFont20 = Font( DynamicLoadObject( "LadderFonts.UTLadder20", class'Font' ) );
	PtsFont18 = Font( DynamicLoadObject( "LadderFonts.UTLadder18", class'Font' ) );
	PtsFont16 = Font( DynamicLoadObject( "LadderFonts.UTLadder16", class'Font' ) );
	PtsFont14 = Font( DynamicLoadObject( "LadderFonts.UTLadder14", class'Font' ) );
	PtsFont12 = Font( DynamicLoadObject( "LadderFonts.UTLadder12", class'Font' ) );
	Timer();
}

//Acquire some required actors
event Timer()
{
	local TeamInfo T;

	MRI = MonsterReplicationInfo( PlayerPawn(Owner).GameReplicationInfo);
	ForEach AllActors (class'TeamInfo', T)
		if ( T.TeamIndex == 0 )
		{
			HunterTeam = T;
			break;
		}
	
	if ( (HunterTeam != None && MRI != None) || (Level.TimeSeconds > 3 * Level.TimeDilation) )
		bAllowDraw = true;
	else
		SetTimer( 0.2 * Level.TimeDilation, false);
}

//Timer measuring
native(3559) static final function int AppCycles();
final function int GetCycles();
final function int GetCycles_XC()
{
	if ( PlayerPawn(Owner).bAdmin )
		return AppCycles();
}

final function string AlignToRight( int Align)
{
	if ( Align < 10 )	return "  "$string(Align);
	if ( Align < 100 )	return " "$string(Align);
	return string(Align);
}

function ShowScores(Canvas Canvas)
{
	local int i, Time, TeamX, TeamY;
	local float X,Y, xLen,yLen, pnx,pny, paddingInfo, ruX, avgY;
	local string s;
	local PlayerReplicationInfo aPRI;
	local MonsterPlayerData aMPD;
	local int Cycles;

	if ( !bAllowDraw )
		return;
	Cycles = GetCycles();

	if(Canvas.ClipX < 900)
	{
		tableWidth = 370;
		paddingInfo = 160;
	}
	else
	{
		tableWidth = Self.default.tableWidth;
		paddingInfo = Self.default.paddingInfo;
	}

	//Reserve space: 7.5% top, 5% mid (centered), 7.5% bottom
	tableLine1 = (Canvas.ClipY / 40) * 3;
	tableLine2 = Canvas.ClipY / 2 + tableLine1 / 3;
	tableLine1 += 5; //Because we need to see messages
	ShowMaxPlayer = (Canvas.ClipY - (tableLine1*1.7 + 80)) / 40;
	tableLine1 += 5;

	if( Level.TimeSeconds - LastSortTime > 0.5 )
	{
		sortPRI();
		LastSortTime = Level.TimeSeconds;
	}
	
	//Setup
	X = getXHeader( 1, Canvas.ClipX);
	Y = getYHeader( 1);
	TeamX = X;
	TeamY = Y;
			
	ruX = iPRI - NotShownPlayers;
	if( NotShownPlayers > 0) //Not shown players need extra shade space (3/4 of player cell)
		ruX += 0.75; //HACK
			
			
	////////
	//Header
	////////
	Canvas.bNoSmooth = False;
	Canvas.DrawColor = White;
	//Canvas.Style = ERenderStyle.STY_Translucent;
	Canvas.Style = ERenderStyle.STY_Modulated;
	Canvas.SetPos( X, Y );
	Canvas.DrawRect( texture'shade2', tableWidth , tableHeaderHeight + cellHeight * ruX );

	Canvas.Style = ERenderStyle.STY_Translucent;
/*	Canvas.DrawColor = getHeaderColor[i];
	Canvas.SetPos( X, Y );
	if ( getHeaderTexture[i] != none )
		Canvas.DrawPattern( getHeaderTexture[i], tableWidth , tableHeaderHeight , 1 );*/

	//Header core icons
	Canvas.DrawColor = BrightCyan;

	if ( (HunterTeam != none) && (HunterTeam.TeamName != "") )
		s = HunterTeam.TeamName;
	else
		s = "Hunters";

	Canvas.Font = PtsFont26;
	Canvas.SetPos( X+5, Y+5 );
	Canvas.StrLen( s,xLen,yLen);
	if ( (xLen < 180) && (MRI != None) && (MRI.HuntersIcon != None) )
	{
		Canvas.DrawIcon( MRI.HuntersIcon, 32.0 / float(MRI.HuntersIcon.VSize) );
		Canvas.SetPos( X+50, Y + 10);
	}
	else
	{
		Canvas.SetPos( X+5, Y + 10);
		xLen -= 50;
	}
	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawText( s);

	//avgInfo
	Canvas.Font = Font'SmallFont';
	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.StrLen("AVG",pnx,pny);
	avgY = (tableHeaderHeight - (3*pny))/4;
	Canvas.SetPos(X+70+xLen, Y + avgY);
	Canvas.DrawText("PI:"@AvgPing@"ms");
	Canvas.SetPos(X+70+xLen, Y + 2*avgY + pny);
	Canvas.DrawText("PL:"@AvgPL$"%");
//	Canvas.SetPos(X+70+xLen, Y + 3*avgY + 2*pny );
//	Canvas.DrawText("EFF:"@avgEff[i]$"%");

	Canvas.Style = ERenderStyle.STY_Translucent;
/*	Canvas.Font = Font'LEDFont2';
	if ( sgGRI.Cores[i] != none )
		s = string( int(sgGRI.Cores[i].Energy / sgGRI.Cores[i].MaxEnergy * 100));
	else
		s = "0";
	Canvas.StrLen(s,xLen,yLen);

	Canvas.SetPos(X+tableWidth-xLen-42, Y+5 );
	Canvas.DrawIcon(getIconTexture[i], 0.5 );

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.SetPos( X+tableWidth-xLen-5, Y + 5);
	Canvas.DrawText(s);*/

	for ( i=0; i<iPRI; i++)
	{
		aPRI = PRI[i];
		if ( aPRI == none )
		{
			LastSortTime -= 0.5; //Force sort on next frame
			continue;
		}
		aMPD = MPD[i];

		if ( i >= ShowMaxPlayer )
			break;

		X = TeamX; 
		Y = TeamY + tableHeaderHeight + i * cellHeight;
		xLen = 59; //Font is fixed, this should be faster here
		yLen = 8;

		//face
		Canvas.DrawColor = White;
		Canvas.Style = ERenderStyle.STY_Translucent;
		Canvas.SetPos( X+5,Y+5);
/*		if ( (aPRI != none) && aPRI.bReadyToPlay )
			Canvas.DrawIcon( Texture'IconCoreGreen', 0.5);
		else*/ if( aPRI.TalkTexture != None )
			Canvas.DrawIcon( aPRI.TalkTexture, 0.5 * 64.0 / aPRI.TalkTexture.VSize );
		else
			Canvas.DrawIcon( Texture'shade', 1 );	  

		//name
		Canvas.Font = PtsFont20;
		if(aPRI.bAdmin)
			Canvas.DrawColor = White;
		else if(aPRI.PlayerID == PlayerPawn(Owner).PlayerReplicationInfo.PlayerID)
			Canvas.DrawColor = BrightGold;
		else
			Canvas.DrawColor = BrightCyan;
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.SetPos( X + 45, Y + 7);
		Canvas.StrLen(aPRI.PlayerName,pnx,pny);
		Canvas.DrawText(aPRI.PlayerName);
			
		//ping-packetloss-bot
		Canvas.Font = Font'SmallFont';
		Canvas.SetPos( X + 45, Y + pny + 7);
		if(aPRI.bIsABot)
			Canvas.DrawText("BOT");
		else
		{
			Canvas.CurYL = 0;
			Canvas.DrawText("PI:"@aPRI.Ping@"ms | PL:"@aPRI.PacketLoss$"%", false); //Clear line = false, saves a StrLen call
			// Country flag
			if ( aMPD != None && aMPD.CachedFlag != None )
			{
				Canvas.CurX += 45;
				Canvas.CurY -= Canvas.CurYL;
				Canvas.DrawColor = WhiteColor;
				Canvas.DrawIcon( aMPD.CachedFlag, 16.0 / aMPD.CachedFlag.VSize);
			}
		}

		if ( aMPD != None )
		{
			// Draw Boss kill count and objectives taken
			Canvas.DrawColor=BrightRed;
			Canvas.SetPos(X + paddingInfo + 40, Y + 7);
			Canvas.DrawText("Boss:"$AlignToRight(aMPD.BossKills), false);

			Canvas.DrawColor=BrightBlue;
			Canvas.SetPos(X + paddingInfo + 40, Y + yLen + 9);
			Canvas.DrawText("Objs:"$AlignToRight(aMPD.ObjectivesTaken), false);

			// Draw Health and Armor
			Time = Min( 255, 100 + aMPD.Health); //Retarded compiler
			Canvas.DrawColor.R = byte(Time);
			Time = Min( 200, aMPD.Health);
			Canvas.DrawColor.G = byte(Time);
			Canvas.DrawColor.B = Canvas.DrawColor.G;
			Canvas.SetPos(X+xLen+paddingInfo+40, Y + 7);
			Canvas.DrawText("HP: "@AlignToRight(aMPD.Health), false);

			Time = Min(255, 80+aMPD.Armor);
			Canvas.DrawColor.R = byte(Time);
			Canvas.DrawColor.G = Canvas.DrawColor.R;
			Canvas.DrawColor.B = Canvas.DrawColor.R;
			Canvas.SetPos(X+xLen+paddingInfo+40, Y + yLen + 9);
			Canvas.DrawText("AP: "@AlignToRight(aMPD.Armor), false);

			Time = (30+aMPD.ActiveTime) / 60;
		}
		else
			Time = Max(1, (Level.TimeSeconds + PlayerPawn(Owner).PlayerReplicationInfo.StartTime - aPRI.StartTime)/60);

		// Draw
		Canvas.DrawColor=White;
		Canvas.SetPos(X+paddingInfo+40, Y + 2 * yLen + 11);
		Canvas.DrawText("Time:"$AlignToRight(Time), false);
		

		// Draw Effective
/*		Canvas.DrawColor=Orange;
		Canvas.SetPos(X+xLen+paddingInfo+40, Y + 2 * yLen + 11);
		Canvas.DrawText("Eff:"@Eff[i]$"%", false);*/

		// Kills && Points
		if ( aMPD != None )
			s = string(aMPD.MonsterKills)@"/"@string(int(aPRI.Score));
		else
			s = string(int(aPRI.Score));
		Canvas.Font = PtsFont16;
		Canvas.DrawColor = BrightCyan;
		Canvas.StrLen( s, xLen, yLen);
		Canvas.SetPos( X+tableWidth-xLen-5, Y + 7);
		Canvas.DrawText( s, false);

		//Deaths
		Canvas.Font = Font'SmallFont';
		s = "Deaths:"$int(aPRI.Deaths);
		Canvas.StrLen(s,xLen,yLen);
		Canvas.SetPos(X+tableWidth-xLen-5, Y + pny + 7);
		Canvas.DrawText(s, false);
	}
	
	if ( NotShownPlayers > 0 )
	{
		X = TeamX;
		Y = TeamY + tableHeaderHeight + ShowMaxPlayer * cellHeight;				
		Canvas.DrawColor = BrightCyan;
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.Font = PtsFont16;
		Canvas.SetPos( X+5,Y+5);
		Canvas.DrawText(NotShownPlayers@"Player not shown!", false);
	}
	DrawFooters(Canvas);
	
	Cycles = GetCycles() - Cycles;
	if ( Cycles > 0 )
	{
		Canvas.SetPos( 5, 100);
		Canvas.DrawText( "Render cycles: "$Cycles);
	}
}


function DrawFooters( Canvas C )
{
  local float DummyX, DummyY, Nil, X1, Y1;
  local string TextStr;
  local string TimeStr, HeaderText;
  local int Hours, Minutes, Seconds, i;
  local color specColor;
  local int baseX, baseY;

  C.bCenter = True;
  C.Font = MyFonts.GetSmallFont( C.ClipX );

  // Display server info in bottom center
  C.DrawColor = White;
  C.StrLen( "Test", DummyX, DummyY );
  C.SetPos( 0, C.ClipY - DummyY );
  TextStr = "Playing" @ Level.Title @ "on" @ MRI.ServerName;
  C.DrawText( TextStr );

  // Draw Time
  if( ( PlayerPawn(Owner).GameReplicationInfo.RemainingTime > 0 ) )
  {
	if( PlayerPawn(Owner).GameReplicationInfo.RemainingTime <= 0 )
	  TimeStr = RemainingTime $ "00:00";
	else
	{
	  Minutes = PlayerPawn(Owner).GameReplicationInfo.RemainingTime / 60;
	  Seconds = PlayerPawn(Owner).GameReplicationInfo.RemainingTime % 60;
	  TimeStr = RemainingTime $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
	}
  }
  else
  {
	Seconds = PlayerPawn(Owner).GameReplicationInfo.ElapsedTime;
	Minutes = Seconds / 60;
	Hours = Minutes / 60;
	Seconds = Seconds - ( Minutes * 60 );
	Minutes = Minutes - ( Hours * 60 );
	TimeStr = Class'TournamentScoreBoard'.default.ElapsedTime $ TwoDigitString( Hours ) $ ":" $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
  }

	//Higor: this should help us break the 32 player limit barrier
	For ( i=sPRI ; i<128 ; i++ )
		if ( PRI[i] != None && !PRI[i].bDeleteMe )
		{
			if( HeaderText == "" )
				HeaderText = PRI[i].Playername;
			else
				HeaderText = HeaderText$", "$PRI[i].Playername;
		}

  C.SetPos( 0, C.ClipY - 2 * DummyY );
  C.DrawText( "Current Time:" @ GetTimeStr() @ "|" @ TimeStr );

  // Draw Spectators
  C.StrLen( HeaderText, DummyX, Nil );
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( 0, C.ClipY - 3 * DummyY );
  
  C.Font = MyFonts.GetSmallestFont(C.ClipX);
  C.DrawColor = White;	  // Added in 4E
	if ( HeaderText == "" )
		C.DrawText("No spectators.");
	else
		C.DrawText("Spectators:"@HeaderText$".");
  C.SetPos( 0, C.ClipY - 4 * DummyY );
  C.DrawText(PlayerPawn(Owner).GameReplicationInfo.GameName);
  C.bCenter = False;
}


function SortPRI()
{
	local int i,j,k, maxIndex, sorted;
	local PlayerReplicationInfo aPRI;

	AvgPing = 0;
	AvgPL = 0;
	iPRI = 0;
	sPRI = 128;
	//Cache significant stuff
	foreach AllActors(class'PlayerReplicationInfo', aPRI)
	{
		if( (!aPRI.bIsSpectator || aPRI.bWaitingPlayer) && (aPRI.Team == 0) )
		{
			PRI[iPRI] = aPRI;
			AvgPing += aPRI.Ping;
			AvgPL += aPRI.PacketLoss;
			iPRI++;
		}
		else if ( aPRI.bIsSpectator && (!aPRI.bAdmin || aPRI.PlayerID != 0) ) //Avoid displaying admin bots
			PRI[--sPRI] = aPRI;
	}
	
	//Calculate averages
	maxIndex = 0;
	AvgPing /= iPRI;
	AvgPL /= iPRI;

	//How many can we show
	if ( iPRI > ShowMaxPlayer )
	{
		NotShownPlayers = iPRI-ShowMaxPlayer;
		if ( NotShownPlayers == 1 )
			NotShownPlayers = 0;
	}

	//Sort using least amount of uscript code as possible
	For ( i=1 ; i<iPRI ; k=i++ )
		if ( PRI[k].Score < PRI[i].Score ) //Movement is necessary!
		{
			For ( j=k-1 ; (j>=0) && (PRI[j].Score < PRI[i].Score) ; j-- )
				k=j; //Find target slot
			aPRI = PRI[i]; //Cache movee'
			j = i;
			while ( j > k ) //Move [k,i-1] to [k+1,i]
				PRI[j] = PRI[--j];
			PRI[k] = aPRI; //Put movee' in [k]
		}

	//Now get extra data
	if ( MRI == None )
		MRI = MonsterReplicationInfo( PlayerPawn(Owner).GameReplicationInfo);
	else
	{
		For ( i=0 ; i<iPRI ; i++ )
			MPD[i] = MRI.GetPlayerData( PRI[i].PlayerID);
	}
}

function string GetTimeStr()
{
	local string Day, Hour, Min;

	Hour = string( PlayerPawn( Owner ).Level.Hour );
	if( PlayerPawn( Owner ).Level.Hour < 10 )
		Hour = "0" $ Hour;

	Min = string( PlayerPawn( Owner ).Level.Minute );
	if( PlayerPawn( Owner ).Level.Minute < 10 )
		Min = "0" $ Min;

	return DayString[ Clamp(PlayerPawn( Owner ).Level.dayOfWeek,0,6) ]
		@	PlayerPawn( Owner ).Level.Day 
		@	MonthString[ Clamp(PlayerPawn( Owner ).Level.month,0,12) ]
		@	PlayerPawn( Owner ).Level.Year
		$	"," @ Hour $ ":" $Min;
}

function float getXHeader( int CurTeam, int screenWidth)
{
	local float x;
	x = (screenWidth-2*tableWidth)/3; 
	switch(CurTeam)
	{
		case 1: 
		case 3: return x;
		case 2: 
		case 4: return 2*x+tableWidth;
		default: return 0;
	}
}

function float getYHeader( int CurTeam)
{
	if ( CurTeam <= 2 )
		return tableLine1;
	return tableLine2;
}


defaultproperties
{
	 tableWidth=450
	 tableHeaderHeight=40
	 cellHeight=40
	 ShowMaxPlayer=12
	 tableLine1=100
	 tableLine2=410
	 paddingInfo=200

	White=(R=255,G=255,B=255)
	BrightCyan=(R=128,G=255,B=255)
	BrightRed=(R=255,G=50,B=50)
	BrightBlue=(R=80,B=255,G=120)
	BrightGold=(R=255,G=255,B=20)
	DayString(0)="Sunday"
	DayString(1)="Monday"
	DayString(2)="Tuesday"
	DayString(3)="Wednesday"
	DayString(4)="Thursday"
	DayString(5)="Friday"
	DayString(6)="Saturday"
	MonthString(1)="Jan"
	MonthString(2)="Feb"
	MonthString(3)="Mar"
	MonthString(4)="Apr"
	MonthString(5)="May"
	MonthString(6)="Jun"
	MonthString(7)="Jul"
	MonthString(8)="Aug"
	MonthString(9)="Sep"
	MonthString(10)="Oct"
	MonthString(11)="Nov"
	MonthString(12)="Dec"
}

