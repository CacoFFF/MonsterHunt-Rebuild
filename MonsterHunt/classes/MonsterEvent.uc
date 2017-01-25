//================================================================================
// MonsterEvent.
//================================================================================
class MonsterEvent expands Triggers;

#exec TEXTURE IMPORT NAME=MHEvent FILE=pcx\MHEvent.pcx

var() localized string Message;
var() bool bBroadcastOnceOnly;
var bool bDisabled;
var bool bAlreadyTriggered;

function Trigger( Actor Other, Pawn EventInstigator)
{
	local MHI_CriticalEvent NewEvent;
	
	if ( bDisabled )
		return;
	BroadcastMessage( Message, True, 'MonsterCriticalEvent');
	bDisabled = bBroadcastOnceOnly;
	
	if ( !bAlreadyTriggered && (MonsterHunt(Level.Game) != None) && (MonsterHunt(Level.Game).Briefing != None) )
	{
		NewEvent = Level.Game.Spawn(class'MHI_CriticalEvent');
		NewEvent.bMHCrit = true;
		NewEvent.CriticalMessage = Message;
	}
	bAlreadyTriggered = true;
}

defaultproperties
{
	Texture=Texture'MHEvent'
	bCollideActors=False
}
