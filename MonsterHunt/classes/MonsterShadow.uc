//*************************************************************
// MonsterShadow.
// On servers, it's an indicator of a monster being fully setup
// On clients, it's a decorative effect
class MonsterShadow expands PlayerShadow;

var MonsterShadow NextShadow;

event PostBeginPlay()
{
	if ( Owner != None )
		SetupFor( Owner);
	Super.PostBeginPlay();
}

function SetupFor( Actor Other)
{
	if ( Owner != Other )
	{
		DetachDecal();
		SetOwner( Other);
	}
	DrawScale = 0.03 * Owner.CollisionRadius;
	if ( Owner.IsA('Nali') || Owner.IsA('Slith') )
		DrawScale *= 0.75;
	if ( Owner.IsA('Pupae') )
		DrawScale *= 0.5;
}

state DedicatedServer
{
	event Update( Actor L)
	{
		TestDestroy();
	}
}

function bool TestDestroy()
{
	if ( Owner == None || Owner.bDeleteMe )
	{
		Destroy();
		return true;
	}
}


event Update( Actor L)
{
	if ( !TestDestroy() )
		Super.Update( L);
}

defaultproperties
{
    MultiDecalLevel=3
    Texture=Texture'Botpack.energymark'
    DrawScale=0.50
}
