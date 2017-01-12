class RockTentacleCarcass expands TentacleCarcass;

//Get the tentacle skin, good for generic tentacles
function Initfor(actor Other)
{
	Super.InitFor(Other);
	MultiSkins[1] = Other.MultiSkins[1];
}