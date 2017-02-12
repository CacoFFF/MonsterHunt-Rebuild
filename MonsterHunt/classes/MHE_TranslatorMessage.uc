class MHE_TranslatorMessage expands MHE_Base;

var TranslatorEvent MarkedEvent;
var Pawn Activator;
//Target = trigger actor, used for secondary touch checks

function RegisterEvent( TranslatorEvent NewEvent)
{
	MarkedEvent = NewEvent;
	SetLocation( NewEvent.Location);
	SetCollisionSize( NewEvent.CollisionRadius, NewEvent.CollisionHeight);
	Tag = NewEvent.Tag;
}

event Trigger( Actor Other, Pawn EventInstigator)
{
}

event Touch( Actor Other)
{
}

function Discover()
{
	local PlayerPawn P;

	bDiscovered = True;
	ForEach AllActors( class'PlayerPawn', P)
		if ( P.Player != None )
			P.ClientPlaySound( MarkedEvent.NewMessageSound);
}

//When triggered, the message gets alt'd before this changes, so no problem
function DisplayEvent( Actor Medium, Pawn Other)
{
	if ( MarkedEvent == None || MarkedEvent.bDeleteMe )
	{
		Destroy();
		return;
	}
	if ( (Other == None) || !Other.bIsPlayer || (Other.PlayerReplicationInfo == None) )
		return;
	if ( (MarkedEvent.Message == "") && (MarkedEvent.Hint == "") )
		return;

	if ( !bDiscovered )
		Discover();
	else
		Medium.PlaySound( MarkedEvent.NewMessageSound, SLOT_Misc);
	

	Activator = Other;
	Target = Medium;
	UpdateInterface();
}

function UpdateInterface()
{
	local MHI_TranslatorMessage MHI;
	
	MHI = MHI_TranslatorMessage(Interface);
	if ( MHI == None )
	{
	}
}

