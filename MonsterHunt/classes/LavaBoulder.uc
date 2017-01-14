//================================================================================
// WaterBoulder.
//================================================================================
class LavaBoulder extends Boulder1;

function SpawnChunks(int num)
{
	local int    NumChunks,i;
	local LavaRock   TempRock;
	local float scale;

	NumChunks = 1+Rand(num);
	scale = 12 * sqrt(0.52/NumChunks);
	speed = VSize(Velocity);
	for (i=0; i<NumChunks; i++) 
	{
		TempRock = Spawn(class'LavaRock');
		if (TempRock != None )
			TempRock.InitFrag(self, scale);
	}
	InitFrag(self, 0.5);
}


defaultproperties
{
    MultiSkins(1)=Texture'UnrealShare.Skins.Jflameball1'
    Style=STY_Translucent
    LightType=1
    LightEffect=13
    LightBrightness=160
    LightHue=21
    LightSaturation=21
    LightRadius=6
}
