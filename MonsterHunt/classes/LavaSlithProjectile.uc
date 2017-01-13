//================================================================================
// LavaSlithProjectile.
//================================================================================
class LavaSlithProjectile extends SlithProjectile;

function Timer()
{
	local BlackSmoke gsp;

	gsp = Spawn(class'BlackSmoke',,,Location+SurfaceNormal*9);
	if (i!=-1) 
	{
		if (LightBrightness > 10) LightBrightness -= 10;
		DrawScale = 0.9*DrawScale;
		gsp.DrawScale = DrawScale*5;
		i++;
		if (i>12) Explode(Location, vect(0,0,0));
	}
}

function Explode(vector HitLocation, vector HitNormal)
{
	local FlameBall f;

  	HurtRadius(damage * DrawScale, DrawScale * 200, 'Burned', MomentumTransfer, HitLocation);
	Destroy();	
}

defaultproperties
{
    Style=STY_Translucent
    Skin=Texture'UnrealShare.Skins.Jflameball1'
    LightBrightness=160
    LightHue=21
    LightSaturation=31
}
