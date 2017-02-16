class MHE_TranslatorMessage expands MHE_Base;

var TranslatorEvent MarkedEvent;
var Pawn Activator;
//Target = trigger actor, used for secondary touch checks

function RegisterEvent( TranslatorEvent NewEvent)
{
	MarkedEvent = NewEvent;
	SetLocation( NewEvent.Location);
	SetCollisionSize( NewEvent.CollisionRadius, NewEvent.CollisionHeight);
	SetCollision( NewEvent.bCollideActors);
	Tag = NewEvent.Tag;
}

event Trigger( Actor Other, Pawn EventInstigator)
{
	DisplayEvent( Other, EventInstigator);
}

event Touch( Actor Other)
{
	DisplayEvent( self, Pawn(Other));
}

//Update time on interface to prevent expiring if player is reading the translator message
event Timer()
{
	local Pawn P;
	SetTimer( FRand() * Level.TimeDilation + 0.1, false);
	
	if ( (Interface != None) && (Interface.Briefing != None) )
		Interface.TimeStamp = Interface.Briefing.CurrentTime; 

	if ( (Activator != None) && !Activator.bDeleteMe && (Target != None) 
	&& MHS.static.InCylinder(Activator.Location - Target.Location, Target.CollisionRadius+Activator.CollisionRadius, Target.CollisionHeight+Activator.CollisionHeight) )
		return;
	Activator = None;
	if ( Target != None ) //Check self or trigger
	{
		ForEach Target.TouchingActors( class'Pawn', P)
			if ( P.bIsPlayer && P.PlayerReplicationInfo != None )
			{
				Activator = P;
				return;
			}
		Target = None;
	}
	if ( Target != self ) //Check self if we have trigger
	{
		ForEach TouchingActors( class'Pawn', P)
			if ( P.bIsPlayer && P.PlayerReplicationInfo != None )
			{
				Activator = P;
				return;
			}
	}
	SetTimer( 0, false); //Nobody is touching
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
	SetTimer( 0.1, false);
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
	local vector V;
	
	MHI = MHI_TranslatorMessage(Interface);
	if ( MHI == None || MHI.bDeleteMe )
	{
		V = Location;
		if ( Target != None )
			V = Target.Location;
		if ( (Activator != None) && !FastTrace(Activator.Location, V) )
			V = Activator.Location + Normal(V - Activator.Location) * (Activator.CollisionRadius*0.5);
		MHI = Spawn( class'MHI_TranslatorMessage',,,V);
		Interface = MHI;
	}
	else if ( MHI.Briefing != None )
		MHI.TimeStamp = MHI.Briefing.CurrentTime;
	
	MHI.Message = MarkedEvent.Message;
	MHI.Hint = MarkedEvent.Hint;
}

