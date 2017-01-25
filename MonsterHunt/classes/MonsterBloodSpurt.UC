class MonsterBloodSpurt extends BloodSpurt;

var bool bGreenBlood;

simulated function GreenBlood()
{
	bGreenBlood = True;
	Super.GreenBlood();
}

simulated function PreBeginPlay()
{
	if( class'GameInfo'.Default.bVeryLowGore )
		GreenBlood();
}

simulated function AnimEnd()
{
  	Destroy();
}

simulated function PostBeginPlay()
{
	//if ( Level.NetMode != NM_DedicatedServer )
		//SpawnCloud();
	PlayAnim ( 'Burst', 1.0 );
	Super.PostBeginPlay();
}

simulated event Destroyed()
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		if(bGreenBlood || Texture == Texture'UnrealShare.Skins.BloodSGrn')
		{
			Spawn(Class'BioMark',,,Location,rot(16384,0,0));
			Spawn(Class'BioMark',,,Location,rot(49152,0,0));
			Spawn(Class'BioMark',,,Location,rot(0,16384,0));
			Spawn(Class'BioMark',,,Location,rot(0,49152,0));
			Spawn(Class'BioMark',,,Location,rot(0,32768,0));
			Spawn(Class'BioMark',,,Location,rot(0,0,0));
		}
		else
		{
			Spawn(Class'BloodSplat',,,Location,rot(16384,0,0));	//Floor
			Spawn(Class'BloodSplat',,,Location,rot(49152,0,0));	//Ceiling
			Spawn(Class'BloodSplat',,,Location,rot(0,16384,0));	//Left
			Spawn(Class'BloodSplat',,,Location,rot(0,49152,0));	//Right
			Spawn(Class'BloodSplat',,,Location,rot(0,32768,0));	//Front
			Spawn(Class'BloodSplat',,,Location,rot(0,0,0));		//Back
		}
	}

	Super.Destroyed();
}

simulated function SpawnCloud();

defaultproperties
{
	Mesh=Mesh'Botpack.BloodUTm'
	AnimSequence=burst
	DrawScale=0.150000
    AmbientGlow=80
}