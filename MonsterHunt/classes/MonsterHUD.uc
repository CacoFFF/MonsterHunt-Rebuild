//**********************************************
// MonsterHUD
// Using SiegeIV improvements here - Higor
class MonsterHUD expands ChallengeTeamHUD
	config(User);
	
#exec TEXTURE IMPORT NAME=HUDIcon FILE=pcx\HUDIcon.pcx Mips=Off GROUP="HUD"
#exec Texture Import File=pcx\HUD_sgBoots.pcx Name=HUD_sgBoots Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\HUD_UDamT.pcx Name=HUD_UDamT Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\HUD_UDamM.pcx Name=HUD_UDamM Mips=Off Group=HUD Flags=64
#exec Texture Import File=pcx\HUD_Invis.pcx Name=HUD_Invis Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\HUD_Scuba.pcx Name=HUD_Scuba Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\HUD_DampenerON.pcx Name=HUD_DampenerON Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\HUD_DampenerOFF.pcx Name=HUD_DampenerOFF Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\HUD_DampenerModu.pcx Name=HUD_DampenerModu Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\PlatesBase.pcx Name=PlatesBase Mips=Off Group=HUD Flags=2
#exec Texture Import File=pcx\PlatesModu.pcx Name=PlatesModu Mips=Off Group=HUD Flags=64



var UDamage CachedAmp;
var Dampener CachedDamp;	
var Pawn LastStatusPawn;
var Texture CachedDoll;
var Texture CachedBelt;
var float DecimalTimer;
var float AddedYSynopsis;
var int PickupCounter;
var localized string IdentifyArmor;
var MonsterBriefing Briefing;


var color ProtectionColors[3];


simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	ForEach AllActors( class'MonsterBriefing', Briefing)
		break;
}

//Timer control
simulated function Tick( float DeltaTime)
{
	Super.Tick( DeltaTime);
	if ( (DecimalTimer += DeltaTime) >= 0.1 )
	{
		DecimalTimer -= 0.1;
		TimerDecimal();
	}
}

simulated function TimerDecimal()
{
	if ( Level.NetMode == NM_Client && (PlayerOwner != None) )
	{
		if ( (CachedDamp != None) && CachedDamp.bActive && (CachedDamp.Charge > 0) )
		{
			CachedDamp.Charge--;
			PlayerOwner.SoundDampening = 0.1;
		}
		else if ( PlayerOwner.SoundDampening == 0.1 )
			PlayerOwner.SoundDampening = 1.0;
	}
	if ( CachedAmp != None && CachedAmp.bActive && (CachedAmp.Charge > 0) )
		CachedAmp.Charge--;
}




//Do not use team colors
simulated function HUDSetup(Canvas Canvas)
{
	Super(ChallengeHUD).HUDSetup(Canvas);
}

simulated function PostRender( Canvas Canvas )
{
	local bool bOldIsPlayer;
	local bool bOldHideFaces;
	local bool bOldHideHUD;
	
	//Hacky, but now I know PawnOwner exists in my code below!
	if ( (PawnOwner == None) || (PlayerOwner.PlayerReplicationInfo == None) )
	{
		HUDSetup(Canvas);
		return;
	}
	
	//Log spam on watching non-player fix START
	bOldHideFaces = bHideFaces;
	bOldHideHUD = bHideHUD;
	if ( PawnOwner.PlayerReplicationInfo == None )
	{
		bHideFaces = true;
		bHideHUD = true;
	}
	
	if ( (Briefing != None) && (Briefing.HintList != None) && !PlayerOwner.bBehindView )
		DrawHints( Canvas);
	Super.PostRender( Canvas);
	
	//Log spam on watching non-player fix END
	bHideFaces = bOldHideFaces;
	bHideHUD = bOldHideHUD;
}

function DrawGameSynopsis( Canvas Canvas)
{
	local float XL, YL;
	local float XOffset, YOffset;
	local MonsterReplicationInfo MRI;

	MRI = MonsterReplicationInfo(PlayerOwner.GameReplicationInfo);
	if ( PlayerOwner == None || MRI == None )
		return;

	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	Canvas.DrawColor = WhiteColor;
	Canvas.StrLen(RankString,XL,YL);
	if ( bHideAllWeapons )
		YOffset = Canvas.ClipY - YL * 3;
	else
	{
		if ( HUDScale * WeaponScale * Canvas.ClipX <= Canvas.ClipX - 256 * Scale )
			YOffset = Canvas.ClipY - 64 * Scale - YL * 4;
		else
			YOffset = Canvas.ClipY - 128 * Scale - YL * 4;
	}
	YOffset -= AddedYSynopsis;

	if ( MRI.Lives > 0 )
	{
		Canvas.SetPos(0.0, YOffset);
		Canvas.DrawText(" Lives: " $ string(MRI.Lives-int(PawnOwner.PlayerReplicationInfo.Deaths)), false);
    }
	Canvas.SetPos(0, YOffset += YL);
	Canvas.DrawText(" Hunters: " $ string(MRI.Hunters), false);
	Canvas.SetPos(0, YOffset += YL);
	Canvas.DrawText(" Monsters: " $ string(MRI.Monsters), false);
	if ( MRI.KilledBosses + MRI.BossCount > 0 )
	{
		Canvas.SetPos(0.0, YOffset += YL);
		Canvas.DrawText(" Bosses: " $ string(MRI.KilledBosses) @"/"@ string( MRI.KilledBosses+MRI.BossCount), false);
    }
}

simulated function bool DrawIdentifyInfo(canvas Canvas)
{
	local float XL, YL, XOffset, X1;
	local Pawn P;
	local MonsterPlayerData MPD;
	local MonsterReplicationInfo MRI;


	if ( !TraceIdentify(Canvas) || (IdentifyTarget.PlayerName == "") )
		return false;
		
	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	DrawTwoColorID(Canvas,IdentifyName, IdentifyTarget.PlayerName, Canvas.ClipY - 256 * Scale);
	P = Pawn(IdentifyTarget.Owner);
	if ( P != None )
	{
		Canvas.StrLen("TEST", XL, YL);
		DrawTwoColorID(Canvas,IdentifyHealth,string(P.Health), (Canvas.ClipY - 256 * Scale) + 1.5 * YL);
		MRI = MonsterReplicationInfo(PlayerOwner.GameReplicationInfo);
		if ( MRI != None )	MPD = MRI.GetPlayerData( IdentifyTarget.PlayerID);
		if ( MPD != None )	DrawTwoColorID(Canvas,IdentifyArmor,string(MPD.Armor), (Canvas.ClipY - 256 * Scale) + 2.5 * YL);
	}
	return true;
}

simulated final function int GetProtIdx( name ProtType)
{
	switch ( ProtType )
	{
		case 'Corroded':	return 0;
		case 'Frozen':		return 1;
		case 'Burned':		return 2;
		default:			return 3;
	}
}

simulated final function UpdateDoll( Pawn Other)
{
	local ENetRole OldRole;
	if ( TournamentPlayer(PawnOwner) != None)
	{
		CachedDoll = TournamentPlayer(PawnOwner).StatusDoll;
		CachedBelt = TournamentPlayer(PawnOwner).StatusBelt;
	}		
	else if ( Bot(Owner) != None )
	{
		CachedDoll = Bot(Owner).StatusDoll;
		CachedBelt = Bot(Owner).StatusBelt;
	}
	else
	{
		OldRole = Other.Role;
		Other.Role = ROLE_AutonomousProxy;
		SetPropertyText("CachedDoll",Other.GetPropertyText("StatusDoll"));
		SetPropertyText("CachedBelt",Other.GetPropertyText("StatusBelt"));
		Other.Role = OldRole;
	}
	if ( CachedDoll == None )
	{
		CachedDoll = Texture'Botpack.Icons.Man';
		CachedBelt = Texture'Botpack.Icons.ManBelt';
	}
	LastStatusPawn = PawnOwner;
}

simulated function DrawStatus(Canvas Canvas)
{
	local float StatScale, Amount, OtherAmount, H1, H2, X, Y, DamageTime;
	Local int i, j, k;
	local int ThighArmor, ChestArmor, ShieldArmor, TotalArmor, CountJumps, CountInvis, CountScuba, CountAmp, CountDampener;
	Local Inventory Inv;
	local bool bJumpBoots, bHasDoll, bActiveDamp;
	local int KnownProtArmors[3]; //Corroded, Frozen, Burned, In that order
	local int KnownProts[2];

	local byte aStyle;
	local float YOffset, WeapScale; //For items
	
	i = 0;
	for( Inv=PawnOwner.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if (Inv.bIsAnArmor) 
		{
			KnownProts[0] = GetProtIdx( Inv.ProtectionType1);
			KnownProts[1] = GetProtIdx( Inv.ProtectionType2);
			k = int(KnownProts[0] < 3) + int(KnownProts[1] < 3);
			if ( k>0 )
			{
				if ( KnownProts[0] == 3 ) //Some armor may set ProtectionType2 and not ProtectionType1
					KnownProts[0] = KnownProts[1];
				KnownProtArmors[KnownProts[0]] += Inv.Charge / k;
				if ( k==2 )
					KnownProtArmors[KnownProts[1]] += Inv.Charge / k;
			}
			else //This armor doesn't have known damage type protections
			{
				if ( Inv.ArmorAbsorption >= 100 )
					ShieldArmor += Inv.Charge;
				else if ( Inv.IsA('Thighpads') )
					ThighArmor += Inv.Charge;
				else
					ChestArmor += Inv.Charge;
			}
			TotalArmor += Inv.Charge;
		}
		else if ( Inv.default.Charge > 0 ) //This check is faster that Weapon/Ammo class checks
		{
			if ( Inv.IsA('UT_JumpBoots') || Inv.IsA('JumpBoots') )
			{
				bJumpBoots = true;
				CountJumps += Inv.Charge;
			}
			else if ( Inv.IsA('Invisibility') || Inv.IsA('UT_Invisibility') )
				CountInvis += Inv.Charge;
			else if ( Inv.IsA('SCUBAGear') )
				CountScuba = Inv.Charge;
			else if ( Inv.Isa('UDamage') )
			{
				if ( Inv.bActive )
					CountAmp = Inv.Charge;
				if ( PawnOwner == PlayerOwner ) //Cache this damage amplifier for charge alteration
					CachedAmp = UDamage(Inv);
			}
			else if ( Inv.IsA('Dampener') )
			{
				CountDampener = Inv.Charge;
				bActiveDamp = Inv.bActive;
				if ( PawnOwner == PlayerOwner )
					CachedDamp = Dampener(Inv);
			}
		}

		if ( i++ > 100 )
			break; // can occasionally get temporary loops in netplay
	}

	if ( !bHideStatus )
	{	
		bHasDoll = Canvas.ClipX >= 400;

		if ( bHasDoll )
		{ 							
			if ( LastStatusPawn != PawnOwner )
				UpdateDoll( PawnOwner);
			Canvas.Style = ERenderStyle.STY_Translucent;
			StatScale = Scale * StatusScale;
			X = Canvas.ClipX - 128 * StatScale;
			Canvas.SetPos(X, 0);
			if (PawnOwner.DamageScaling > 2.0)
				Canvas.DrawColor = PurpleColor;
			else
				Canvas.DrawColor = HUDColor;
			Canvas.DrawTile( CachedDoll, 128*StatScale, 256*StatScale, 0, 0, 128.0, 256.0);
			Canvas.DrawColor = HUDColor;
			if ( ShieldArmor > 0 )
			{
				Amount = fClamp( 195 - float(ShieldArmor) * 1.30, 0, 195);
				Canvas.DrawColor = BaseColor;
				Canvas.DrawColor.B = 0;
				Canvas.SetPos(X, Amount*StatScale);
				Canvas.DrawTile( CachedBelt, 128.0 * StatScale, (256.0 - Amount)*StatScale, 0, Amount, 128, 256-Amount );
			}
			//Find highest special protections
			if ( ChestArmor > 0 )
			{
				Amount = FClamp(0.01 * float(ChestArmor), 0, 1.0-float(KnownProtArmors[0]+KnownProtArmors[1]+KnownProtArmors[2])*0.015);
				Canvas.DrawColor = HUDColor * Amount;
				Canvas.SetPos(X, 0);
				Canvas.DrawTile( CachedDoll, 128*StatScale, 80*StatScale, 128, 0, 128, 80);
			}
			if ( ThighArmor > 0 )
			{
				Amount = FMin(0.02 * float(ThighArmor),1);
				Canvas.DrawColor = HUDColor * Amount;
				Canvas.SetPos(X, 80*StatScale);
				Canvas.DrawTile( CachedDoll, 128*StatScale, 48*StatScale, 128, 80, 128, 48);
			}
			if ( bJumpBoots )
			{
				Canvas.DrawColor = HUDColor;
				Canvas.SetPos(X, 128*StatScale);
				Canvas.DrawTile( CachedDoll, 128*StatScale, 64*StatScale, 128, 128, 128, 64);
			}
			For ( j=0 ; j<3 ; j++ )
				if ( KnownProtArmors[j] > 0 )
				{
					k = 23+16*j; //Start X coord
					Canvas.SetPos( X + float(k) * StatScale, 0);
					Canvas.DrawColor = ProtectionColors[j];
					Canvas.DrawTile( CachedDoll, 16*StatScale, 80*StatScale, 128+k, 0, 16, 80);
				}
			Canvas.Style = Style;
			if ( (PawnOwner == PlayerOwner) && Level.bHighDetailMode && !Level.bDropDetail )
			{
				for ( i=0; i<4; i++ )
				{
					DamageTime = Level.TimeSeconds - HitTime[i];
					if ( DamageTime < 1 )
					{
						Canvas.SetPos(X + HitPos[i].X * StatScale, HitPos[i].Y * StatScale);
						if ( (HUDColor.G > 100) || (HUDColor.B > 100) )
							Canvas.DrawColor = RedColor;
						else
							Canvas.DrawColor = (WhiteColor - HudColor) * FMin(1, 2 * DamageTime);
						Canvas.DrawColor.R = 255 * FMin(1, 2 * DamageTime);
						Canvas.DrawTile(Texture'BotPack.HudElements1', StatScale * HitDamage[i] * 25, StatScale * HitDamage[i] * 64, 0, 64, 25.0, 64.0);
					}
				}
			}
		}
	}
	Canvas.DrawColor = HUDColor;
	if ( bHideStatus && bHideAllWeapons )
	{
		X = 0.5 * Canvas.ClipX;
		Y = Canvas.ClipY - 64 * Scale;
	}
	else
	{
		X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
		Y = 64 * Scale;
	}
	Canvas.SetPos(X,Y);
	if ( PawnOwner.Health < 50 )
	{
		H1 = 1.5 * TutIconBlink;
		H2 = 1 - H1;
		Canvas.DrawColor = WhiteColor * H2 + (HUDColor - WhiteColor) * H1;
	}
	else
		Canvas.DrawColor = HUDColor;
	Canvas.DrawTile(Texture'BotPack.HudElements1', 128*Scale, 64*Scale, 128, 128, 128.0, 64.0);

	if ( PawnOwner.Health < 50 )
	{
		H1 = 1.5 * TutIconBlink;
		H2 = 1 - H1;
		Canvas.DrawColor = Canvas.DrawColor * H2 + (WhiteColor - Canvas.DrawColor) * H1;
	}
	else
		Canvas.DrawColor = WhiteColor;

	DrawBigNum(Canvas, Max( 0, PawnOwner.Health), X + 4 * Scale, Y + 16 * Scale, 1);

	Canvas.DrawColor = HUDColor;
	if ( bHideStatus && bHideAllWeapons )
	{
		X = 0.5 * Canvas.ClipX - 128 * Scale;
		Y = Canvas.ClipY - 64 * Scale;
	}
	else
	{
		X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
		Y = 0;
	}
	Canvas.SetPos(X, Y);
	Canvas.DrawTile(Texture'BotPack.HudElements1', 128*Scale, 64*Scale, 0, 192, 128.0, 64.0);

	//MH panel
	if ( !bHideStatus || !bHideAllWeapons )
		Canvas.SetPos( X, 128.0 * Scale);
	Canvas.DrawTile(Texture'MonsterHunt.HUD.HUDIcon', 128 * Scale, 64 * Scale, 0, 192, 128, 64);
	Canvas.SetPos( X, Y);

	Canvas.DrawColor = WhiteColor;
	if ( bHideStatus )
	{
		if ( ShieldArmor > 0 )
			Canvas.DrawColor = GoldColor;
		else if ( KnownProtArmors[0] > 0 )
			Canvas.DrawColor = ProtectionColors[0];
		else if ( KnownProtArmors[2] > 0 )
			Canvas.DrawColor = ProtectionColors[2];
		else if ( KnownProtArmors[1] > 0 )
			Canvas.DrawColor = ProtectionColors[1];
	}
	DrawBigNum(Canvas, Min(999,TotalArmor), X + 4 * Scale, Y + 16 * Scale, 1);

	///////////////////////////////////////////////////////////////////
	//////////////////////// ITEM SETUP ///////////////////////////////
	if ( bHideAllWeapons )
		YOffset = Canvas.ClipY;
	else if ( HudScale * WeaponScale * Canvas.ClipX <= Canvas.ClipX - 256 * Scale )
		YOffset = Canvas.ClipY - 63.9*Scale;
	else
		YOffset = Canvas.ClipY - 127.9*Scale;
	aStyle = Style;
	if ( aStyle == ERenderStyle.STY_Normal )
		aStyle = ERenderStyle.STY_Masked;
	Canvas.Style = Style;
	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	WeapScale = (Scale + WeaponScale * Scale) / 2;
	Y = 63.9 * WeapScale;
	AddedYSynopsis = 0;
	
	//////////////////////// JUMPBOOTS ////////////////////////////////
	if ( bJumpBoots )
	{
		AddedYSynopsis += Y;
		YOffset -= Y;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);	
		Canvas.DrawIcon(Texture'HUD_sgBoots', WeapScale);
		Canvas.CurX = 5 * WeapScale;
		Canvas.CurY = YOffset + Canvas.CurX;
		Canvas.Style = ERenderStyle.STY_Normal;
		if ( CountJumps > 0 )
			Canvas.DrawColor = GoldColor;
		else
			Canvas.DrawColor = RedColor;
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountJumps % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}

	//////////////////////// INVISIBLE ////////////////////////////////
	if ( CountInvis > 0 )
	{
		AddedYSynopsis += Y;
		YOffset -= Y;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);	
		Canvas.DrawIcon(Texture'HUD_Invis', WeapScale);
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GoldColor;
		j = CountInvis / 2;
		if ( j >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(j % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}
	
	//////////////////////// AMPLIFIER/////////////////////////
	if ( CountAmp > 0 )
	{
		CountAmp /= 10;
		AddedYSynopsis += Y;
		YOffset -= Y;
		Canvas.DrawColor = HUDColor; //SolidHUDcolor?
		Canvas.SetPos(0,YOffset);	
		Canvas.DrawIcon(Texture'HUD_UDamT', WeapScale);
		Canvas.SetPos(0,YOffset);	
		Canvas.Style = ERenderStyle.STY_Modulated;
		Canvas.DrawIcon(Texture'HUD_UDamM', WeapScale);
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = GoldColor;
		if ( CountAmp >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountAmp / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountAmp % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}
	
	//////////////////////// DAMPENER ////////////////////////
	if ( CountDampener > 0 )
	{
		CountDampener /= 10;
		AddedYSynopsis += Y;
		YOffset -= Y;
		Canvas.SetPos(0,YOffset);	
		Canvas.Style = ERenderStyle.STY_Modulated;
		Canvas.DrawColor = WhiteColor;
		Canvas.DrawIcon(Texture'HUD_DampenerModu', WeapScale);
		Canvas.SetPos(0,YOffset);	
		Canvas.Style = ERenderStyle.STY_Translucent;
		Canvas.DrawColor = HUDColor;
		if ( bActiveDamp && (CountDampener > 0) )
		{
			Canvas.DrawIcon(Texture'HUD_DampenerON', WeapScale);
			Canvas.DrawColor = GoldColor;
		}
		else
		{
			Canvas.DrawIcon(Texture'HUD_DampenerOFF', WeapScale);
			Canvas.DrawColor = RedColor;
		}
		Canvas.Style = ERenderStyle.STY_Normal;
		if ( CountDampener >= 10 )
		{
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountDampener / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountDampener % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}
	
	//////////////////////// SCUBAGEAR /////////////////////////
	if ( CountScuba > 0 )
	{
		AddedYSynopsis += Y;
		YOffset -= Y;
		Canvas.DrawColor = HUDColor;
		Canvas.SetPos(0,YOffset);	
		Canvas.DrawIcon(Texture'HUD_Scuba', WeapScale);
		CountScuba /= 10;
		Canvas.DrawColor = GoldColor;
		Canvas.Style = ERenderStyle.STY_Normal;
		if ( CountScuba >= 10 )
		{
			if ( CountScuba >= 100 )
			{
				Canvas.SetPos( 62 * WeapScale, YOffset + 20 * WeapScale);
				Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountScuba / 100), 0, 25.0, 64.0);
				CountScuba -= (CountScuba/100)*100;
			}
			Canvas.SetPos( 79 * WeapScale, YOffset + 20 * WeapScale);
			Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountScuba / 10), 0, 25.0, 64.0);
		}
		Canvas.SetPos( 96 * WeapScale, YOffset + 20 * WeapScale);
		Canvas.DrawTile(Texture'BotPack.HudElements1', 17 * WeapScale, 36 * WeapScale, 25*(CountScuba % 10), 0, 25.0, 64.0);
		Canvas.Style = aStyle;
	}
	
}

//***************************************************
//******************** HINTS
simulated function DrawHints( Canvas Canvas)
{
	local vector V, X, Y, Z;
	local float InvMaxWidth;
	local MHI_Base Hint;
	local vector ScreenCoords;
	local vector MidPoints;
	local float ClipX, ClipY;
	
//	MaxWidth = tan((PlayerOwner.FOVAngle / 360) * pi); //1 if 90º, lower if less, bigger if more
	GetAxes( PawnOwner.ViewRotation, X, Y, Z);
	ClipX = Canvas.ClipX;
	ClipY = Canvas.ClipY;
	InvMaxWidth = 1 / tan( PlayerOwner.FOVAngle * 0.008727); //Optimization
	MidPoints.X = ClipX * 0.5;
	MidPoints.Y = ClipY * 0.5;
	Canvas.DrawColor = WhiteColor;
	Canvas.Style = ERenderStyle.STY_Translucent;

	For ( Hint=Briefing.HintList ; Hint!=None ; Hint=Hint.NextHint )
	{
		V = Hint.Location - PawnOwner.Location;
		V.Z -= PawnOwner.EyeHeight;
		
		//Need proximity test for selecting nearest hint here
		
		//X=h-distance from crosshair
		//Y=v-distance from crosshair (flipped, higher means below)
		//Z=depth
		
		ScreenCoords.Z = (V dot X);
		if ( ScreenCoords.Z < 0 || ScreenCoords.Z > 10000 )
			continue; //Off-depth
		ScreenCoords.X = (V dot Y);
		if ( ScreenCoords.Z < Abs(ScreenCoords.X * InvMaxWidth) )
			continue; //Off the horizontal FOV
		ScreenCoords.Y = -(V dot Z);
		ScreenCoords *= MidPoints.X * InvMaxWidth / ScreenCoords.Z; //Transform to unitary coords
		ScreenCoords.Z *= 0.001;
		Canvas.DrawColor = WhiteColor * (1 - VSize(ScreenCoords)/ClipX);
		ScreenCoords += MidPoints + Hint.ScreenOffset; //Transform to canvas coords
	
		if ( ScreenCoords.Y < 16 || ScreenCoords.Y > ClipX - 16 )
			continue;
		Canvas.SetPos( ScreenCoords.X - 16, ScreenCoords.Y - 16);
		Canvas.DrawIcon( Hint.HintIcon, 1);

	}
}


simulated function LocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject, optional String CriticalString )
{
	local int i;

	if ( ClassIsChildOf( Message, class'PickupMessagePlus' ) )
	{
		PickupTime = Level.TimeSeconds;
		if ( CriticalString == "" )
			CriticalString = Message.Static.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
		For ( i=0 ; i<10 ; i++ )
		{
			//Find previous pickup message (hopefully identical)
			if ( LocalMessages[i].Message == Message )
			{
				if ( LocalMessages[i].OptionalObject != OptionalObject )
					break;
				PickupCounter++;
				LocalMessages[i].EndOfLife = Message.Default.Lifetime + Level.TimeSeconds;
				LocalMessages[i].StringMessage = CriticalString@"x"$string(PickupCounter);
				return;
			}
		}
	}
	PickupCounter = 1;
	Super.LocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject, CriticalString);
}


// Entry point for string messages.
simulated function Message( PlayerReplicationInfo PRI, coerce string Msg, name MsgType )
{
	local int i;
	local Class<LocalMessage> MessageClass;

	switch (MsgType)
	{
		case 'Say':
			MessageClass = class'SayMessagePlus';
			break;
		case 'TeamSay':
			MessageClass = class'TeamSayMessagePlus';
			break;
		case 'CriticalEvent':
			MessageClass = class'CriticalStringPlus';
			LocalizedMessage( MessageClass, 0, None, None, None, Msg );
			return;
		case 'MonsterCriticalEvent':
			MessageClass = Class'MonsterCriticalString';
			LocalizedMessage( MessageClass, 0, None, None, None, Msg );
			return;
		case 'DeathMessage':
			MessageClass = class'RedSayMessagePlus';
			break;
		case 'Pickup':
			PickupTime = Level.TimeSeconds;
		default:
			MessageClass = class'StringMessagePlus';
			break;
	}

	if ( ClassIsChildOf(MessageClass, class'SayMessagePlus') || ClassIsChildOf(MessageClass, class'TeamSayMessagePlus') )
	{
		FaceTexture = PRI.TalkTexture;
		if ( FaceTexture != None )
			FaceTime = Level.TimeSeconds + 3;
		if ( Msg == "" )
			return;
	} 
	for (i=0; i<4; i++)
	{
		if ( ShortMessageQueue[i].Message == None )
		{
			// Add the message here.
			ShortMessageQueue[i].Message = MessageClass;
			ShortMessageQueue[i].Switch = 0;
			ShortMessageQueue[i].RelatedPRI = PRI;
			ShortMessageQueue[i].OptionalObject = None;
			ShortMessageQueue[i].EndOfLife = MessageClass.Default.Lifetime + Level.TimeSeconds;
			if ( MessageClass.Default.bComplexString )
				ShortMessageQueue[i].StringMessage = Msg;
			else
				ShortMessageQueue[i].StringMessage = MessageClass.Static.AssembleString(self,0,PRI,Msg);
			return;
		}
	}

	// No empty slots.  Force a message out.
	for (i=0; i<3; i++)
		CopyMessage(ShortMessageQueue[i], ShortMessageQueue[i+1]);

	ShortMessageQueue[3].Message = MessageClass;
	ShortMessageQueue[3].Switch = 0;
	ShortMessageQueue[3].RelatedPRI = PRI;
	ShortMessageQueue[3].OptionalObject = None;
	ShortMessageQueue[3].EndOfLife = MessageClass.Default.Lifetime + Level.TimeSeconds;
	if ( MessageClass.Default.bComplexString )
		ShortMessageQueue[3].StringMessage = Msg;
	else
		ShortMessageQueue[3].StringMessage = MessageClass.Static.AssembleString(self,0,PRI,Msg);
}



defaultproperties
{
	ProtectionColors(0)=(G=250)
	ProtectionColors(1)=(G=100,B=220)
	ProtectionColors(2)=(R=250,G=70)
	IdentifyArmor="Armor:"
	AltTeamColor(0)=(R=90,G=180,B=180)
	TeamColor(0)=(R=127,G=255,B=255)
}

