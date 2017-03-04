//Contributed by Spectra7
//Readapted to authoritatively operate on the server only.
class MonsterBloodNotify extends SpawnNotify;


//Spawn notification takes place after PreBeginPlay and before spawner gets to modify it
//If the level is in low detail mode then the new blood spurt will also become green.
//If the monster that spawns it has green blood, by reference exchange the new effect will become green
event Actor SpawnNotification(Actor A)
{
	local MonsterBloodSpurt MBS;
	local int i;

	if( A.class == class'BloodSpurt' )
	{
		MBS = Spawn(Class'MonsterBloodSpurt', A.Owner, A.Tag, A.Location, rot(0,16384,0));
		if ( MBS != None )
		{
			A.Destroy();
			return MBS;
		}
	}
	
	return A;
}

defaultproperties
{
	bGameRelevant=True
	RemoteRole=ROLE_None
    ActorClass=Class'UnrealShare.BloodSpurt'
}