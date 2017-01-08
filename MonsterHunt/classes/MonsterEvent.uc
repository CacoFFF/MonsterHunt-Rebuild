//================================================================================
// MonsterEvent.
//================================================================================
class MonsterEvent expands Triggers;

var() localized string Message;
var() bool bBroadcastOnceOnly;
var bool bDisabled;

function Trigger( Actor Other, Pawn EventInstigator)
{
	if ( bDisabled )
		return;
	bDisabled = bBroadcastOnceOnly;
	BroadcastMessage( Message, True, 'MonsterCriticalEvent');
}

defaultproperties
{
	Texture=Texture'MHEvent'
	bCollideActors=False
}
