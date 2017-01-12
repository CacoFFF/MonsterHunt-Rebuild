class RockTentacleCarcass expands TentacleCarcass;

//Get the tentacle skin, good for generic tentacles
function Initfor(actor Other)
{
	Super.InitFor(Other);
	MultiSkins[1] = Other.MultiSkins[1];
	if ( MultiSkins[1] == None )
		MultiSkins[1] = Texture'UnrealShare.Skins.JTentacle1'; //For old MH clients
}
