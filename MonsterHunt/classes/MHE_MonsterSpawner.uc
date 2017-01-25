class MHE_MonsterSpawner expands MHE_Base;

var ThingFactory MarkedFactory;
var bool bWasSpawning;

function RegisterFactory( ThingFactory Other)
{
	MarkedFactory = Other;
	SetTimer( 1 + FRand() * 0.2, true);
}

function CheckState()
{
	if ( MarkedFactory == None || MarkedFactory.bDeleteMe || MarkedFactory.IsInState('Finished') )
	{
		bCompleted = true;
		return;
	}

	if ( MarkedFactory.IsInState('Waiting') )
	{
	}
	else if ( MarkedFactory.IsInState('Spawning') )
	{
		bDiscovered = True;
		bWasSpawning = True;
	}
}

event Timer()
{
}
