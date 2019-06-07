class MHCR_Pickup expands Pickup
	abstract;

	
static final function SimulatePickup( Inventory Item, Pawn Other)
{
	if ( Item.Level.Game.LocalLog != None)
		Item.Level.Game.LocalLog.LogPickup( Item, Other);
	if ( Item.Level.Game.WorldLog != None)
		Item.Level.Game.WorldLog.LogPickup( Item, Other);
	if ( Item.PickupMessageClass == None )
		Other.ClientMessage( Item.PickupMessage, 'Pickup');
	else
		Other.ReceiveLocalizedMessage( Item.PickupMessageClass, 0, None, None, Item.Class );
	Item.PlaySound( Item.PickupSound,,2.0);
	Item.SetRespawn();
}

//****************************************************
// Armors cannot be picked up if owner already has one
function bool HandlePickupQuery( Inventory Item )
{
	if ( Item.class == class) 
	{
		if (bCanHaveMultipleCopies) 
		{   
			NumCopies++; // for items like Artifact
			SimulatePickup( Item, Pawn(Owner));
		}
		else if ( bDisplayableInv && (Charge < Item.Charge) ) 
		{		
			Charge = Item.Charge;
			SimulatePickup( Item, Pawn(Owner));
		}
		return true;				
	}
	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}
