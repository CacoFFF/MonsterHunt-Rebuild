class MHCR_UT_ShieldBelt expands UT_ShieldBelt
	abstract;


//****************************
// Do not destroy other armors
function bool HandlePickupQuery( inventory Item )
{
	return Super(Pickup).HandlePickupQuery( Item);
}



//****************************
// Do not destroy other armors
function PickupFunction(Pawn Other)
{
	MyEffect = Spawn( class'UT_ShieldBeltEffect', Other,,Other.Location, Other.Rotation); 
	MyEffect.Mesh = Owner.Mesh;
	MyEffect.DrawScale = Owner.Drawscale;

	TeamNum = class'MHCR_Inventory'.static.GetShieldTeamNum( Other);
	SetEffectTexture();

	if ( Pawn(Owner).FindInventoryType(class'UT_Invisibility') != None )
		MyEffect.bHidden = true;
}



