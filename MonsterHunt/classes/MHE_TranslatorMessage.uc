class MHE_TranslatorMessage expands MHE_Base;

var TranslatorEvent MarkedEvent;

function RegisterEvent( TranslatorEvent NewEvent)
{
	MarkedEvent = NewEvent;
	SetLocation( NewEvent.Location);
	SetCollisionSize( NewEvent.CollisionRadius, NewEvent.CollisionHeight);
}
