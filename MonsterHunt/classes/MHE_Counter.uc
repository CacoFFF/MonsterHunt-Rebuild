class MHE_Counter expands MHE_Base;

var Counter MarkedCounter;

function RegisterCounter( Counter NewCounter)
{
	MarkedCounter = NewCounter;
	SetLocation( NewCounter.Location);
	Tag = NewCounter.Tag;
}

