class MHE_Counter expands MHE_Base;

var Counter MarkedCounter;
var MHE_Counter NextSameTag; //Another counter with same tag
var bool bFirstCounter;
var bool bEnabledWithoutSpawner;
var bool bSpawnerContains;
var bool bSpawnerCompletes;


function RegisterCounter( Counter NewCounter)
{
	local MHE_Base MHE;

	MarkedCounter = NewCounter;
	SetLocation( NewCounter.Location);
	Tag = NewCounter.Tag;
	bFirstCounter = true;
	
	//During this process all initial MHE's are counters, with 'self' being first one in list
	//Find if there's another counter with same tag, chain it
	For ( MHE=NextEvent ; MHE_Counter(MHE)!=None ; MHE=MHE.NextEvent )
		if ( MHE.Tag == Tag )
		{
			NextSameTag = MHE_Counter(MHE);
			NextSameTag.bFirstCounter = false;
			break;
		}
}

function bool CausesEvent( name aEvent)
{
	return !bCompleted && (MarkedCounter != None) && HasEvent(aEvent);
}
function name RequiredEvent() //Will this redirect bots towards monsters?
{
	if ( !bCompleted && (MarkedCounter != None) )
		return MarkedCounter.Tag;
}

//Get rid of this Event
event Trigger( Actor Other, Pawn EventInstigator)
{
	if ( !bDiscovered )
		Discover();
	bCompleted = MarkedCounter == None || MarkedCounter.bDeleteMe || MarkedCounter.NumToCount == 0;
	if ( bCompleted )
		Destroy();
}

event Timer()
{
	if ( MarkedCounter != None )
	{
		ResetEvents();
		AnalyzeEvent( MarkedCounter.Event);
	}
}

event Destroyed()
{
	local MHE_Base MHE;
	
	if ( bFirstCounter )
	{
		if ( NextSameTag != None )
			NextSameTag.bFirstCounter = true;
		if ( bSpawnerContains )
			For ( MHE=Briefing.MapEventList ; MHE!=None ; MHE=MHE.NextEvent )
				if ( MHE.IsA('MHE_MonsterSpawner') )
					MHE_MonsterSpawner(MHE).Counter = NextSameTag;
	}
	else
	{
		For ( MHE=Briefing.MapEventList ; MHE!=None ; MHE=MHE.NextEvent )
			if ( MHE.IsA('MHE_Counter') && (MHE_Counter(MHE).NextSameTag == self) )
			{
				MHE_Counter(MHE).NextSameTag = NextSameTag;
				break;
			}
	}
	
	Super.Destroyed();
}

function byte GetLowestCounter()
{
	local MHE_Counter C;
	local byte Lowest;
	local byte L;
	
	For ( C=self ; C!=None ; C=C.NextSameTag )
	{
		L = C.MarkedCounter.NumToCount;
		if ( (L > 0) && ((Lowest == 0) || (Lowest > L)) )
			Lowest = L;
	}
	return Lowest;
}

function int ActiveCounters()
{
	local MHE_Counter C;
	local int i;
	For ( C=self ; C!=None ; C=C.NextSameTag )
		i += int( C.MarkedCounter.NumToCount > 0 );
	return i;
}



//Attach to MHE_MonsterSpawner events
function PostInit()
{
	local MHE_Base MHE;
	local MHE_Counter C;
	local ThingFactory TF;
	local int CountersTotal;

	if ( Briefing != None )
	{
		if ( bFirstCounter )
		{
			CountersTotal = ActiveCounters();
			AnalyzeEvent( MarkedCounter.Event);
			SetTimer( 5+FRand(), true);

			//Identify other trigger
			//Monster Spawner never return true because it doesn't really directly trigger this actor
			For ( MHE=Briefing.MapEventList ; MHE!=None ; MHE=MHE.NextEvent )
				if ( MHE.CausesEvent(Tag) && !MHE.IsA('MHE_MonsterSpawner') && !MHE.IsA('MHE_BB_MonsterSpawner') )
				{
					For ( C=self ; C!=none ; C=C.NextSameTag )
						C.bEnabledWithoutSpawner = true;
					break;
				}
			
			//Identify monster spawners related to this
			For ( MHE=Briefing.MapEventList ; MHE!=None ; MHE=MHE.NextEvent )
				if ( MHE.Tag == Tag )
				{
					if ( MHE.IsA('MHE_MonsterSpawner') && !bSpawnerContains )
					{
						MHE_MonsterSpawner(MHE).Counter = self;
						MHE_MonsterSpawner(MHE).CountersTotal = CountersTotal;
						TF = MHE_MonsterSpawner(MHE).MarkedFactory;
						For ( C=self ; C!=none ; C=C.NextSameTag )
						{
							C.bSpawnerContains = true;
							C.bSpawnerCompletes = TF.Capacity + TF.NumItems + int(bEnabledWithoutSpawner) >= C.MarkedCounter.NumToCount;
							C.EventChain = EventChain; //Propagate event chain to other counters
						}
					}
				}
		}
	}
	Super.PostInit();
}
