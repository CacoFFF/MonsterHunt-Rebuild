//****************************************************************
// MonsterHunt rebuild
// All subclasses should also have their config in MonsterHunt.ini
class MonsterHunt expands TeamGamePlus
	config(MonsterHunt);
	
var() config int MonsterSkill; //0 to 7 in v1...
var() config int Lives;
var() config bool bUseTeamSkins;

//********************
// XC_Core / XC_Engine
native(3540) final iterator function PawnActors( class<Pawn> PawnClass, out pawn P, optional float Distance, optional vector VOrigin, optional bool bHasPRI, optional Pawn StartAt);


event InitGame(string Options, out string Error)
{
	//Force settings
	bUseTranslocator = False; //Warning: TranslocDest points will be unlinked with this
	bNoMonsters = False;
	MaxAllowedTeams = 1;
	
	Super.InitGame( Options, Error);
	
	MonsterReplicationInfo(GameReplicationInfo).Monsters = CountMonsters();
}


//Entry point from old MH.u
function SetPawnDifficulty( int Diff, ScriptedPawn S)
{
	local int i;
	local int SkillScale;
	local int StrenghtScale;
	local float fTmp;
	local name OtherDamages[6];
	
	SkillScale = 80 + int(Sqrt(Diff) * 15.0); //Skill has a cap
	StrenghtScale = 80 + Diff * 10; //Strenght on the other side doesn't

	//CombatStyle and Aggresiveness affect monster preference to charge or stay at a distance, do not alter
	S.Health = int(float(S.Health) * float(StrenghtScale) * 0.01); //Avoid going over the 32 bit INT cap
	S.SightRadius = S.SightRadius * SkillScale / 100;
	S.RefireRate = S.RefireRate * SkillScale / 100;
	S.ProjectileSpeed = S.ProjectileSpeed * SkillScale / 100;
	S.GroundSpeed = S.GroundSpeed * StrenghtScale / 100;
	S.AirSpeed = S.AirSpeed * StrenghtScale / 100;
	S.WaterSpeed = S.WaterSpeed * StrenghtScale / 100;
	
	//Adjust damages generically
	OtherDamages[0] = 'WhipDamage';
	OtherDamages[1] = 'PunchDamage';
	OtherDamages[2] = 'StrikeDamage';
	OtherDamages[3] = 'StingDamage';
	OtherDamages[4] = 'ClawDamage';
	OtherDamages[5] = 'BiteDamage';
	For ( i=0 ; i<6 ; i++ )
	{
		fTmp = float( S.GetPropertyText( string(OtherDamages[i]) ) );
		if ( fTmp != 0 )
		{
			fTmp *= StrenghtScale * 0.01; 
			S.SetPropertyText( string(OtherDamages[i]),string(int(fTmp)) );
		}
	}

	if ( S.Shadow == None )
		S.Shadow = Spawn( Class'MonsterShadow', S);
}

//****************************************
// Utilitary methods
// XC versions are used in XC_Engine servers

//Called once per monster
function ProcessMonster( ScriptedPawn S)
{
	if ( (S.default.AttitudeToPlayer != ATTITUDE_Friendly) && !S.IsA('Nali') && !S.IsA('Cow') ) //Will this fix 1337 mercenary?
		S.AttitudeToPlayer = ATTITUDE_Hate;
	SetPawnDifficulty(MonsterSkill,S);
}


function int CountMonsters()
{
	local int i;
	local Pawn P;
	
	For ( P=Level.PawnList ; P!=None ; P=P.NextPawn )
		if ( P.IsA('ScriptedPawn') )
		{
			i++; //Ignore friendly monsters?
			if ( P.Shadow == None )
				ProcessMonster( ScriptedPawn(P));
		}
	return i;
}
function int CountMonsters_XC()
{
	local int i;
	local ScriptedPawn S;

	ForEach PawnActors (class'ScriptedPawn', S)
	{
		i++; //Ignore friendly monsters?
		if ( S.Shadow == None )
			ProcessMonster( S);
	}
	return i;
}


function int CountHunters()
{
	local int i;
	local PlayerReplicationInfo PRI;
	
	ForEach AllActors (class'PlayerReplicationInfo', PRI)
		if ( PRI.Owner != None && !PRI.Owner.IsA('ScriptedPawn') && !PRI.bIsSpectator )
			i++;
	return i;
}
function int CountHunters_XC()
{
	local int i;
	local Pawn P;
	
	ForEach PawnActors (class'Pawn', P,,, true)
		if ( !P.IsA('ScriptedPawn') && !P.PlayerReplicationInfo.bIsSpectator )
			i++;
	return i;
}


defaultproperties
{
	MonsterSkill=5
	Lives=6
	bUseTeamSkins=True
	TimeLimit=30
	MutatorClass=Class'MonsterBase'
	DefaultWeapon=Class'Botpack.ChainSaw'
	MapPrefix="MH"
	BeaconName="MH"
	LeftMessage=" left the hunt."
	EnteredMessage=" has joined the hunt!"
	StartUpMessage="Work with your teammates to hunt down the monsters!"
	StartMessage="The hunt has begun!"
	StartUpTeamMessage="Welcome to the hunt!"
	GameEndedMessage="Hunt Successful!"
	TimeOutMessage="Time up, hunt failed!"
	SingleWaitingMessage="Press Fire to begin the hunt."
}
