//================================================================================
// WaterBoulder.
//================================================================================
class WaterBoulder extends Boulder1;

function SpawnChunks(int num)
{
	local int    NumChunks,i;
	local WaterRock   TempRock;
	local float scale;

	NumChunks = 1+Rand(num);
	scale = 12 * sqrt(0.52/NumChunks);
	speed = VSize(Velocity);
	for (i=0; i<NumChunks; i++) 
	{
		TempRock = Spawn(class'WaterRock');
		if (TempRock != None )
			TempRock.InitFrag(self, scale);
	}
	InitFrag(self, 0.5);
}


defaultproperties
{
    Style=STY_Translucent
}
