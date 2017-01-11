//*******************************
// MonsterReplicationInfo
// Global info visible by clients
class MonsterReplicationInfo expands TournamentGameReplicationInfo;

var int Lives;
var int Monsters;
var int Hunters;
var PlayerPawn LocalPlayer;

var MonsterPlayerData DataHash[32];
var MonsterPlayerData InactiveDatas;

replication
{
	reliable if ( ROLE==ROLE_Authority )
		Lives, Monsters, Hunters;
}

simulated function Timer()
{
	local ScriptedPawn P;
	
	Super.Timer();
	if ( Level.NetMode != NM_Client )
	{
		Hunters = MonsterHunt(Level.Game).CountHunters();
		Lives = MonsterHunt(Level.Game).Lives;
		if ( MonsterHunt(Level.Game).bCountMonstersAgain || (FRand() < 0.05) )
		{
			MonsterHunt(Level.Game).bCountMonstersAgain = false;
			Monsters = MonsterHunt(Level.Game).CountMonsters();
		}
		if ( MonsterHunt(Level.Game).bCheckEndLivesAgain )
			MonsterHunt(Level.Game).CheckEndGame();
	}
	else
	{
		//Later...
	}
}

//********************************************************
// Player authenticated
function AuthFinished( MonsterAuthenticator MA)
{
	local Pawn P;
	local MonsterPlayerData MPD;

	P = Pawn(MA.Owner);
	if ( P == None || P.PlayerReplicationInfo == None ) //Should never happen
		return;
	
	MPD = AttemptRecover( P.PlayerReplicationInfo, MA);
	if ( MPD == None )
	{
		MPD = SpawnPlayerData( P.PlayerReplicationInfo);
		MPD.MRI = self;
		MPD.Activate( P.PlayerReplicationInfo, MA.FingerPrint);
	}
	MPD.TeamSkin = MA.TeamSkin;
}



//********************************************************
// Utilitary methods

simulated final function MonsterPlayerData GetPlayerData( int PlayerID)
{
	local MonsterPlayerData MPD;
	For ( MPD=DataHash[PlayerID%32] ; MPD!=None ; MPD=MPD.HashNext )
		if ( MPD.PlayerID == PlayerID )
			return MPD;
}

function MonsterPlayerData SpawnPlayerData( PlayerReplicationInfo aPRI)
{
	return Spawn( class'MonsterPlayerData', aPRI.Owner);
}

final function MonsterPlayerData AttemptRecover( PlayerReplicationInfo aPRI, MonsterAuthenticator MA)
{
	local int i;
	local MonsterPlayerData MPD, Last;

	//Handle a recently authenticated player
	//Look among disconnected players
	For ( MPD=InactiveDatas ; MPD!=None ; MPD=MPD.HashNext )
	{
		if ( MPD.FingerPrint == MA.FingerPrint )
		{
			if ( Last != None )
				Last.HashNext = MPD.HashNext;
			else
				InactiveDatas = MPD.HashNext;
			MPD.Activate( aPRI, MA.FingerPrint );
			break;
		}
		Last = MPD;
	}
	return MPD;
}

simulated final function LinkPlayerData( MonsterPlayerData pData)
{
	local int i;
	i = pData.PlayerID%32;
	pData.HashNext = DataHash[i];
	DataHash[i] = pData;
}

simulated final function UnlinkPlayerData( MonsterPlayerData pData)
{
	local MonsterPlayerData MPD, Last;
	local int i;

	i = pData.PlayerID%32;
	For ( MPD=DataHash[i] ; MPD!=None ; MPD=MPD.HashNext )
	{
		if ( MPD == pData )
		{
			if ( Last != None )
				Last.HashNext = MPD.HashNext;
			else
				DataHash[i] = MPD.HashNext;
			break;
		}
		Last = MPD;
	}
	//Servers need to keep data for recovery
	if ( Level.NetMode != NM_Client )
	{
		MPD.HashNext = InactiveDatas;
		InactiveDatas = MPD;
	}
}
