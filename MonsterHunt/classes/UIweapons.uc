class UIweapons expands TournamentWeapon;

var name PriorityName;

//Note:
//Default animation rate is 30
//Time to complete is 30/frames
//PlayAnimRate in PlayAnim is a multiplier to the above

function SetSwitchPriority(pawn Other)
{
	local int i;
	local name temp, carried;

	//Use unreal 1 names, not OL names
	if ( PriorityName == '' )
	{
		PriorityName = Class.Name;
		if ( (Len(String(PriorityName)) > 2) && (Left(String(PriorityName), 2) ~= "OL")  )
			SetPropertyText( "PriorityName", Mid(String(PriorityName),2) );
		default.PriorityName = PriorityName;
	}
	if ( PlayerPawn(Other) != None )
	{
		for ( i=0; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++)
			if ( PlayerPawn(Other).WeaponPriority[i] == PriorityName )
			{
				AutoSwitchPriority = i;
				return;
			}
		// else, register this weapon
		carried = PriorityName;
		for ( i=AutoSwitchPriority; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++ )
		{
			if ( PlayerPawn(Other).WeaponPriority[i] == '' )
			{
				PlayerPawn(Other).WeaponPriority[i] = carried;
				return;
			}
			else if ( i<ArrayCount(PlayerPawn(Other).WeaponPriority)-1 )
			{
				temp = PlayerPawn(Other).WeaponPriority[i];
				PlayerPawn(Other).WeaponPriority[i] = carried;
				carried = temp;
			}
		}
	}		
}


defaultproperties
{
    PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
    bNoSmooth=False
}