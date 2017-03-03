class MHE_CriticalEvent expands MHE_Base;

var SpecialEvent MarkedEvent;

function RegisterEvent( SpecialEvent Other)
{
	MarkedEvent = Other;
	Tag = Other.Tag;
}

function Trigger( Actor Other, Pawn EventInstigator)
{
	local MHI_CriticalEvent NewEvent;
	if ( MarkedEvent != None && !MarkedEvent.bDeleteMe )
	{
		NewEvent = Level.Game.Spawn(class'MHI_CriticalEvent');
		NewEvent.CriticalMessage = MarkedEvent.Message;
	}
	Destroy();
}