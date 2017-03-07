//================================================================================
// MonsterEnd.
//================================================================================
class MonsterEnd expands Trigger;

#exec TEXTURE IMPORT NAME=MHEnd FILE=pcx\MHEnd.pcx

var MonsterEnd NextEnd;
var NavigationPoint DeferTo;
var bool bReachedByPlayer;

function PostBeginPlay()
{
	if ( MonsterHunt(Level.Game) != None )
		MonsterHunt(Level.Game).RegisterEnd( self);
	Super.PostBeginPlay();
}


function Touch( Actor Other)
{
	local Actor A;

	if ( !bReachedByPlayer && (Pawn(Other) != None) && (Pawn(Other).PlayerReplicationInfo != None) )
		bReachedByPlayer = true;

	if ( !IsRelevant(Other) )
		return;

	if ( ReTriggerDelay > 0 )
	{
		if ( Level.TimeSeconds - TriggerTime < ReTriggerDelay )
			return;
	}
	TriggerTime = Level.TimeSeconds;
	if ( Event != '' )
	{
		ForEach AllActors( class'Actor', A, Event)
			A.Trigger( self, Pawn(Other));
	}
	if ( Other.IsA('Pawn') && (Pawn(Other).SpecialGoal == self) )
		Pawn(Other).SpecialGoal = None;
	if ( Message != "" )
		Other.Instigator.ClientMessage(Message);
	TriggerObjective();

	if ( bTriggerOnceOnly )
		SetCollision(False);
	else if ( RepeatTriggerTime > 0 )
		SetTimer( RepeatTriggerTime, False);
}

function TakeDamage( int Damage, Pawn instigatedBy, vector HitLocation, vector Momentum, name DamageType)
{
	local Actor A;

	if ( bInitiallyActive && (TriggerType == TT_Shoot) && (Damage >= DamageThreshold) && (instigatedBy != None) )
	{
		if ( ReTriggerDelay > 0 )
		{
			if ( Level.TimeSeconds - TriggerTime < ReTriggerDelay )
				return;
			TriggerTime = Level.TimeSeconds;
		}
		if ( Event != 'None' )
			ForEach AllActors( class'Actor', A, Event)
				A.Trigger( self, instigatedBy);
		if ( Message != "" )
			instigatedBy.Instigator.ClientMessage(Message);
		if ( bTriggerOnceOnly )
			SetCollision(False);
		TriggerObjective();
	}
}

//Entry point from old MH
function TriggerObjective()
{
	if ( !Level.Game.bGameEnded && MonsterHunt(Level.Game) != None )
		MonsterHunt(Level.Game).EndGame("Hunt Successfull!");
}



defaultproperties
{
	Texture=Texture'MHEnd'
}