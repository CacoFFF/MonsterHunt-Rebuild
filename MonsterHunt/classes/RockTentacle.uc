//================================================================================
// RockTentacle.
//================================================================================
class RockTentacle extends Tentacle;

#exec TEXTURE IMPORT NAME=RockTentacle FILE=pcx\RockTentacle.pcx GROUP="Skins" LODSET=2

function PreCacheReferences()
{
	MultiSkins[1] = Texture'RockTentacle';
}


defaultproperties
{
    MultiSkins(1)=Texture'MonsterHunt.Skins.RockTentacle'
}
