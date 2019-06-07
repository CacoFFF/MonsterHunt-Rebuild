class MHCR_Inventory expands Inventory
	abstract;
	
	
	
//****************************************************
// Bots shouldn't attempt to constantly pick up armors
event float BotDesireability( pawn Bot )
{
	local Inventory AlreadyHas;
	local float desire;
	local bool bChecked;

	desire = MaxDesireability;

	if ( RespawnTime < 10 )
	{
		bChecked = true;
		AlreadyHas = Bot.FindInventoryType(class); 
		if ( (AlreadyHas != None) && (AlreadyHas.Charge >= Charge) )
				return -1;
	}

	if( bIsAnArmor )
	{
		if ( !bChecked )
			AlreadyHas = Bot.FindInventoryType(class); 
		if ( AlreadyHas != None )
		{
			if ( AlreadyHas.Charge >= Charge )
				return -1;
			desire *= (1 - AlreadyHas.Charge * AlreadyHas.ArmorAbsorption * 0.00003);
		}
		
		desire *= (Charge * 0.005);
		desire *= (ArmorAbsorption * 0.01);
	}
	return desire;
}



static final function int GetShieldTeamNum( Pawn Other)
{
	local int TeamNum;
	
	if ( TeamSkin( Other.Skin,          TeamNum)
	||   TeamSkin( Other.MultiSkins[0], TeamNum)
	||   TeamSkin( Other.MultiSkins[1], TeamNum)
	||   TeamSkin( Other.MultiSkins[2], TeamNum)
	||   TeamSkin( Other.MultiSkins[3], TeamNum) )
		return TeamNum;
	
	TeamNum = 3;
	if ( (Other.PlayerReplicationInfo != None) && (Other.PlayerReplicationInfo.Team < 3) )
		TeamNum = Other.PlayerReplicationInfo.Team;
	return TeamNum;
}

static final function bool TeamSkin( Texture Skin, out int Team)
{
	local string Extracted;

	if ( Skin != None )
	{
		Team = -1;
		Extracted = string(Skin.Name);
		if ( Extracted ~= "T_Red" )
			Team = 0;
		else if ( Extracted ~= "T_Blue" )
			Team = 1;
		else if ( Extracted ~= "T_Green" )
			Team = 2;
		else if ( Extracted ~= "T_Yellow" )
			Team = 3;
			
		if ( Team >= 0 )
			return true;
			
		Extracted = Right( Extracted, 3);
		if ( Left( Extracted, 2) ~= "T_" )
		{
			Team = int( Right( Extracted, 1));
			return true;
		}
	}
	return false;
}