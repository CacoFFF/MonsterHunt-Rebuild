//Contributed by Spectra7
class MonsterBloodSpurt extends BloodSpurt;

var bool bGreenBlood;


function GreenBlood()
{
	bGreenBlood = True;
	Super.GreenBlood();
}

simulated function PostBeginPlay()
{
	PlayAnim( 'Burst', 1.0 );
	Super(Blood2).PostBeginPlay();
}

simulated event PostNetBeginPlay()
{
	if ( Texture == Texture'UnrealShare.Skins.BloodSGrn' )
		bGreenBlood = true;
}

simulated event Destroyed()
{
	local Decal D;

	if ( Level.NetMode != NM_DedicatedServer )
	{
		if( bGreenBlood || Texture == Texture'UnrealShare.Skins.BloodSGrn')
		{
			D = Spawn(Class'BioMark',,,Location,rot(16384,0,0));
			D.DrawScale *= 1.1;
		}
		else
			D = Spawn(Class'BloodSplat',,,Location,rot(16384,0,0));	//Floor
		//Resize decal a bit
		if ( (D != None) && (Carcass(Owner) != None) )
			D.DrawScale *= Sqrt(Owner.CollisionRadius/40);
	}

	Super.Destroyed();
}

defaultproperties
{
	Mesh=Mesh'Botpack.BloodUTm'
	AnimSequence=burst
	DrawScale=0.150000
    AmbientGlow=80
}
