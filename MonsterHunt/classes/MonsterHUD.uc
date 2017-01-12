//**********************************************
// MonsterHUD
// Using SiegeIV improvements here - Higor
class MonsterHUD expands ChallengeTeamHUD
	config(User);
	
var Pawn LastStatusPawn;
var Texture CachedDoll;
var Texture CachedBelt;

var color ProtectionColors[3];

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
	
	Super.PostRender( Canvas);
	
	//Log spam on watching non-player fix END
	bHideFaces = bOldHideFaces;
	bHideHUD = bOldHideHUD;
}

function DrawGameSynopsis( Canvas Canvas)
{
	local float XL, YL;
	local float XOffset, YOffset;

	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	Canvas.DrawColor = WhiteColor;
	Canvas.StrLen(RankString,XL,YL);
	if ( bHideAllWeapons )
		YOffset = Canvas.ClipY - YL * 3;
	else
	{
		if ( HUDScale * WeaponScale * Canvas.ClipX <= Canvas.ClipX - 256 * Scale )
			YOffset = Canvas.ClipY - 64 * Scale - YL * 3;
		else
			YOffset = Canvas.ClipY - 128 * Scale - YL * 3;
	}
	if ( PlayerOwner == None )
		return;

	if ( MonsterReplicationInfo(PlayerOwner.GameReplicationInfo).Lives > 0 )
	{
		Canvas.SetPos(0.0, YOffset);
		Canvas.DrawText(" Lives: " $ string(int(PawnOwner.PlayerReplicationInfo.Deaths)), false);
    }
	Canvas.SetPos(0, YOffset += YL);
	Canvas.DrawText(" Hunters: " $ string(MonsterReplicationInfo(PlayerOwner.GameReplicationInfo).Hunters), false);
	Canvas.SetPos(0, YOffset += YL);
	Canvas.DrawText(" Monsters: " $ string(MonsterReplicationInfo(PlayerOwner.GameReplicationInfo).Monsters), false);
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
	local int ThighArmor, ChestArmor, ShieldArmor, TotalArmor;
	Local Inventory Inv;
	local bool bJumpBoots, bHasDoll;
	local int KnownProtArmors[3]; //Corroded, Frozen, Burned, In that order
	local int KnownProts[2];
	
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
		else if ( Inv.IsA('UT_JumpBoots') || Inv.IsA('JumpBoots') )
			bJumpBoots = true;

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
//				Canvas.DrawIcon(DollBelt, StatScale);
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
}


defaultproperties
{
	ProtectionColors(0)=(G=250)
	ProtectionColors(1)=(G=100,B=220)
	ProtectionColors(2)=(R=250,G=70)
}

