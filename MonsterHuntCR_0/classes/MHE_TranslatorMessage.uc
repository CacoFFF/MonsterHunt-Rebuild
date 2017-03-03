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
	local Triggers T;
	//Normal trigger doesn't pass itself as 'Other'
	if ( (EventInstigator != None) && (Other == EventInstigator) )
	{
		ForEach EventInstigator.TouchingActors( class'Triggers', T)
			if ( T.Event == Tag )
				Other = T;
	}
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

	if ( Interface == None || Interface.bDeleteMe )
		return;
	//This trigger has been disabled, this event should not be displayed
	else if ( (Trigger(Target) != None) && !Trigger(Target).bInitiallyActive )
	{
KILL_INTERFACE:
		Interface.Destroy();
		Interface = None;
		SetTimer( 0, false);
		return;
	}
	else if ( (Interface.Briefing == None) || (Interface.Briefing.CurrentTime > Interface.TimeStamp) )
		Goto KILL_INTERFACE;
	
	if ( Activator == None || Activator.bDeleteMe ) //Try to pick up another activator
	{
		if ( Target != None ) //Check self or trigger
		{
			ForEach Target.TouchingActors( class'Pawn', P)
				if ( P.bIsPlayer && P.PlayerReplicationInfo != None )
					Activator = P;
		}
		if ( Target != self ) //Check self if we have trigger
		{
			ForEach TouchingActors( class'Pawn', P)
				if ( P.bIsPlayer && P.PlayerReplicationInfo != None )
				{
					Activator = P;
					Target = self;
				}
		}
	} //Else validate existing one
	else if ( (Target != None) && !MHS.static.InCylinder(Activator.Location - Target.Location, Target.CollisionRadius+Activator.CollisionRadius, Target.CollisionHeight+Activator.CollisionHeight) )
		Activator = None;

	if ( Activator != None )
		Interface.TimeStamp++; 
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
	if ( Target == Other ) //Normal triggers cause the event to never go away!!
		Target = None;
	else if ( (Trigger(Target) != None) && !Trigger(Target).bInitiallyActive ) //This trigger self-disabled right away, do not consider it anymore
		Target = None;

	if ( Interface != None )
	{
		SetTimer( 1, true);
		Timer();
	}
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
		MHI = Spawn( class'MHI_TranslatorMessage',self,,V);
		Interface = MHI;
	}
	
	MHI.Message = MarkedEvent.Message;
	MHI.Hint = MarkedEvent.Hint;
	if ( MHI.Briefing != None )
		MHI.TimeStamp = MHI.Briefing.CurrentTime + 10 + (Len(MHI.Hint)+Len(MHI.Message))/8;
}

