class MonsterBloodNotify extends SpawnNotify;

simulated event Actor SpawnNotification(Actor A)
{
	local MonsterBloodSpurt MBS;
	local int i;

	if(A.IsA('BloodSpurt'))
	{
		MBS = Spawn(Class'MonsterBloodSpurt', A.Owner, A.Tag, A.Location, rot(0,16384,0));
		
		if(MBS != None)
		{
			if(BloodSpurt(A).Texture != Texture'BloodSpot')
			{
				MBS.bGreenBlood = True;
				MBS.GreenBlood();
			}
			A.bHidden = True;
			return MBS;
		}
	}
	
	return Super.SpawnNotification(A);
}

defaultproperties
{
	bGameRelevant=True
    ActorClass=Class'UnrealShare.BloodSpurt'
}