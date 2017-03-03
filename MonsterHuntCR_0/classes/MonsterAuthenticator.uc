//************************************
// MonsterAuthenticator
class MonsterAuthenticator expands Info
	config(MonsterHunt);

var MonsterAuthenticator NextAuthenticator;
var MonsterBriefing Briefing;

var string FingerPrint;
var config string MyPlayerID;
var byte TeamSkin; //Temporary
var int TimeOut;

replication
{
	reliable if ( Role==ROLE_Authority )
		ServerWantsFingerPrint, ServerAcceptsFingerPrint;
	reliable if ( Role<ROLE_Authority )
		SendFingerPrint;
}

simulated event PostBeginPlay()
{
	local PlayerPawn PlayerOwner;
	
	FingerPrint = "";
	if ( MyPlayerID == "" )
		GenerateLocalID();

	if ( Level.NetMode != NM_Client )
	{
		PlayerOwner = PlayerPawn(Owner);
		InitialState = 'LocalAuth';
		if ( PlayerOwner != None )
		{
			if ( NetConnection(PlayerOwner.Player) != None )
				InitialState = 'RemoteAuth';
			else
				FingerPrint = MyPlayerID;
		}
		else //Bot
			FingerPrint = string(Owner.Class.Name) $ "_" $ Pawn(Owner).PlayerReplicationInfo.PlayerName;
	}
}


//Local player always auths first, bots never collide
state LocalAuth
{
Begin:
	Sleep( Level.TimeDilation * 0.5 * FRand() );
	Briefing.AuthFinished( self);
	Sleep( Level.TimeDilation );
	Destroy();
}

state RemoteAuth
{
	function bool FingerPrintTaken()
	{
		local MonsterPlayerData MPD;
		ForEach AllActors( class'MonsterPlayerData', MPD)
			if ( MPD.bAuthenticated && (MPD.FingerPrint == FingerPrint) )
				return true;
	}
Begin:
	Sleep( Level.TimeDilation * FRand() );  //Randomize a bit
// Wait 10 seconds before completing login
	TimeOut = 10;
	while ( TimeOut-- > 0 ) 
	{
		if ( FingerPrint == "" )
		{
			FingerPrint = "*";
			ServerWantsFingerPrint( false);
		}
		else if ( FingerPrint == "*" ) // Wait 2 seconds for next request
			FingerPrint = "";
		else if ( FingerPrintTaken() )
			ServerWantsFingerPrint( true);
		else
		{
			//Accept ASAP
			ServerAcceptsFingerPrint( FingerPrint); 
			while ( TimeOut-- > 0 )
				Sleep( Level.TimeDilation);
			//But wait until 10th second to create data holder
			//We can fail here, but chances are minimal
			Briefing.AuthFinished( self);
		}
		Sleep( Level.TimeDilation);
	}
	Destroy();
}

simulated function ServerWantsFingerPrint( bool bGenerateNew)
{
	if ( bGenerateNew )
		GenerateLocalID();
	SendFingerPrint( MyPlayerID);
}

simulated function ServerAcceptsFingerPrint( string AcceptedFingerprint)
{
	MyPlayerID = AcceptedFingerprint;
	SaveConfig();
}

simulated function GenerateLocalID()
{
	local int i;
	MyPlayerID = string(Level.Hour) $ string(Level.Minute) $ string(Level.Second) $ string(Level.Millisecond);
	i = Rand(Len(MyPlayerID));
	MyPlayerID = Left( MyPlayerID, i) $ Mid( MyPlayerID, i);
	SaveConfig();
}

function SendFingerPrint( string NewFingerPrint)
{
	FingerPrint = NewFingerPrint;
}


//Unlink from chained list
event Destroyed()
{
	local MonsterAuthenticator MA, Last;

	For ( MA=Briefing.AuthenticatorList ; MA!=None ; MA=MA.NextAuthenticator )
	{
		if ( MA == self )
		{
			if ( Last != None )
				Last.NextAuthenticator = NextAuthenticator;
			else
				Briefing.AuthenticatorList = NextAuthenticator;
			NextAuthenticator = None;
			break;
		}
		Last = MA;
	}
}


defaultproperties
{
	bGameRelevant=True
	RemoteRole=ROLE_SimulatedProxy
	LifeSpan=60
}
