//================================================================================
// MonsterArenaEnd.
//================================================================================
class MonsterArenaEnd extends MonsterEnd;

#exec TEXTURE IMPORT NAME=MAEnd FILE=pcx\MAEnd.pcx

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( !bInitiallyActive )
		SetCollision(False);
}

// Other trigger turns this on.
state() OtherTriggerTurnsOn
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		local bool bWasActive;

		bWasActive = bInitiallyActive;
		bInitiallyActive = true;
		if ( !bWasActive )
		{
			if ( !bCollideActors )
				SetCollision(True);
			CheckTouchList();
		}
	}
}

function TriggerObjective()
{
	if ( MonsterHuntArena(Level.Game) != None )
		MonsterHuntArena(Level.Game).EndGame("Arena Cleared!");
}

defaultproperties
{
	bInitiallyActive=False
	InitialState=OtherTriggerTurnsOn
	Texture=Texture'MAEnd'
	CollisionRadius=15000
	CollisionHeight=15000
}
