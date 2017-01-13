//================================================================================
// LavaSlith.
//================================================================================
class LavaSlith extends Slith;

#exec TEXTURE IMPORT NAME=LavaSlith FILE=pcx\LavaSlith.PCX GROUP=Skins LODSET=2

defaultproperties
{
    RangedProjectile=Class'LavaSlithProjectile'
    Skin=Texture'MonsterHunt.Skins.LavaSlith'
}
