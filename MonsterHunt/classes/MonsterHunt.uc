//****************************************************************
// MonsterHunt rebuild
// All subclasses should also have their config in MonsterHunt.ini
class MonsterHunt expands TeamGamePlus
	config(MonsterHunt);

var() config int MonsterSkill; //0 to 7 in v1...
var() config int Lives;
var() config bool bUseTeamSkins;
var() config bool bReplaceUIWeapons;
var() config int DamageToScore;
var() config string HunterTeamName;
var() config string HunterTeamIcon;
var() config string ClientExtensionClass;

var bool bCountMonstersAgain; //Monster counting isn't immediate, helps other mutators properly affect monsters before we do it
var bool bCheckEndLivesAgain;
var bool bSkipThisMonster; //Mutator doesn't want this monster to be difficulty-scaled
var bool bQueryEnemies;

//User-define kill scores
var() config name MonsterKillType[10];
var() config int MonsterKillScore[10];

var localized string TimeOutMessage;

var(Debug) MonsterWaypoint WaypointList;
var(Debug) MonsterEnd EndList;
var(Debug) MonsterAuthenticator AuthenticatorList;
var(Debug) MonsterBriefing Briefing;
var(Debug) MonsterTriggerMarker TriggerMarkers;
var(Debug) ScriptedPawn ReachableEnemy;

var(Debug) private int MonstersPerZone[64]; //ACCESSOR: GetMonstersPerZone( byte ZoneNumber)

//********************
// XC_Core / XC_Engine
native(1718) final function bool AddToPackageMap( optional string PkgName);
native(3540) final iterator function PawnActors( class<Pawn> PawnClass, out pawn P, optional float Distance, optional vector VOrigin, optional bool bHasPRI, optional Pawn StartAt);
native(3560) static final function bool ReplaceFunction( class<Object> ReplaceClass, class<Object> WithClass, name ReplaceFunction, name WithFunction, optional name InState);
native(3561) static final function bool RestoreFunction( class<Object> RestoreClass, name RestoreFunction, optional name InState);


event InitGame(string Options, out string Error)
{
	local Mutator M;
	local Actor A;
	local Texture T;
	local class<MonsterBriefing> BriefingClass;
	
	//Force settings
	bUseTranslocator = False; //Warning: TranslocDest points will be unlinked with this
	bNoMonsters = False;
	MaxAllowedTeams = 1;

	BriefingClass = class<MonsterBriefing>( DynamicLoadObject(ClientExtensionClass,class'class') );
	if ( BriefingClass == None )
	{
		Error = "Failed to load client extension "$ClientExtensionClass$", check MonsterHunt.ini";
		return;
	}
	
	if ( int(ConsoleCommand("GET INI:ENGINE.ENGINE.GAMEENGINE XC_VERSION")) >= 19 )
	{
		ReplaceFunction( class'MonsterHunt', class'MonsterHunt', 'TaskMonstersVsBot', 'TaskMonstersVsBot_XC');
		ReplaceFunction( class'MonsterHunt', class'MonsterHunt', 'CountMonsters', 'CountMonsters_XC');
		ReplaceFunction( class'MonsterHunt', class'MonsterHunt', 'CountHunters', 'CountHunters_XC');
	}
	
	Super.InitGame( Options, Error);

	//Validate UI replacements of MonsterBase
	For ( M=BaseMutator ; M!=None ; M=M.NextMutator )
		if ( M.IsA('MonsterBase') )
		{
			MonsterBase(M).ValidateWeapons();
			break;
		}

	Briefing = Spawn( BriefingClass);
	T = Texture( DynamicLoadObject(HunterTeamIcon,class'Texture') );
	if ( T != None )
	{
		Briefing.HuntersIcon = T;
		if ( (Level.NetMode != NM_Standalone) && (int(ConsoleCommand("GET INI:ENGINE:ENGINE.GAMEENGINE XC_VERSION")) >= 11) )
			AddToPackageMap( Left(HunterTeamIcon, InStr(HunterTeamIcon,".")) );
	}
	
	bCountMonstersAgain = true;
}

event PostLogin( PlayerPawn NewPlayer )
{
	//Don't update player's Team in his URL
	Super(DeathMatchPlus).PostLogin(NewPlayer);
	//Prevent monsters from attacking spectators
	if ( NewPlayer.PlayerReplicationInfo != None && NewPlayer.PlayerReplicationInfo.bIsSpectator )
	{
		NewPlayer.Visibility = 0;
		NewPlayer.Health = 0; //Will this one work?
	}
}


function Timer()
{
	local Pawn P;
	local float DivChance;
	
	Super.Timer();
	
	//Can be used to override ReachableEnemy even if it's set
	if ( bQueryEnemies )
	{
		For ( P=Level.PawnList ; P!=None ; P=P.NextPawn )
			if ( (P.PlayerReplicationInfo == None) && P.IsA('ScriptedPawn') && P.bCollideActors && (P.AttitudeToPlayer < ATTITUDE_Friendly) )
			{
				DivChance += 1;
				if ( FRand() < 1/DivChance )
					ReachableEnemy = ScriptedPawn(P);
			}
		bQueryEnemies = false;
	}
}

//Recont everything right after match starts
function StartMatch()
{
	Super.StartMatch();
	GameReplicationInfo.Timer();
}

function CheckEndGame()
{
	local int KnockedOut;
	local PlayerReplicationInfo PRI;

	if ( bGameEnded || (Lives <= 0) )
		return;
		
	bCheckEndLivesAgain = False;

	//Task bots to attack?
	ForEach AllActors( class'PlayerReplicationInfo', PRI)
		if ( Spectator(PRI.Owner) == None )
		{
			if ( (PRI.Deaths > 0) && (PRI.Deaths >= Lives) )
				KnockedOut++;
			else
				return; //Game not ended
		}
	if ( KnockedOut > 0 )
		EndGame("No hunters");
}

function bool SetEndCams(string Reason)
{
	local MonsterEnd E;
	local bool bWon;
	local TeamInfo BestTeam;
	local int i;
	local pawn P, Best;
	local PlayerPawn player;

	// find prick that touched the MonsterEnd actor
	For ( E=EndList ; E!=None ; E=E.NextEnd )
		if ( E.TriggerTime == Level.TimeSeconds ) //This one caused the event
		{
			ForEach E.TouchingActors( class'Pawn', P)
				if ( P.bIsPlayer && (P.PlayerReplicationInfo != None) && (P.PlayerReplicationInfo.Team == 0) )
				{
					Best = P;
					break;
				}
			break;
		}
	
	// find individual winner
	if ( Best == None )
	{
		for ( P=Level.PawnList; P!=None; P=P.nextPawn )
			if ( P.bIsPlayer && P.PlayerReplicationInfo != None && ((Best == None) || (P.PlayerReplicationInfo.Score > Best.PlayerReplicationInfo.Score)) )
				Best = P;
	}
	
	if ( Reason ~= "No hunters" )
		GameReplicationInfo.GameEndedComments = "Hunting party eliminated!";
	else if ( Reason ~= "Timelimit" )
		GameReplicationInfo.GameEndedComments = TimeOutMessage;
	else
	{
		bWon = true;
		GameReplicationInfo.GameEndedComments = GameEndedMessage;
	}

	EndTime = Level.TimeSeconds + 3.0;
	for ( P=Level.PawnList; P!=None; P=P.nextPawn )
	{
		player = PlayerPawn(P);
		if ( Player != None )
		{
			PlayWinMessage(Player, bWon);
			player.bBehindView = true;
			if ( Player == Best )
				Player.ViewTarget = None;
			else
				Player.ViewTarget = Best;
			player.ClientGameEnded();
		}
		P.GotoState('GameEnded');
	}
	CalcEndStats();
	return true;
}


function bool RestartPlayer( Pawn aPlayer)
{
	local bool Result;

	aPlayer.Visibility = aPlayer.default.Visibility;
	if ( (Lives > 0) && (aPlayer.PlayerReplicationInfo != None) && (aPlayer.PlayerReplicationInfo.Deaths >= Lives) )
	{
		if ( bRestartLevel && (Level.NetMode == NM_Standalone) ) //This is coop code
			return True;
		BroadcastMessage( aPlayer.PlayerReplicationInfo.PlayerName $ " has been lost!", True, 'MonsterCriticalEvent');
		if ( !aPlayer.IsA('PlayerPawn') )
		{
			aPlayer.PlayerReplicationInfo.bIsSpectator = True;
			aPlayer.PlayerReplicationInfo.bWaitingPlayer = True;
			aPlayer.GotoState('GameEnded');
			return False;
		}
		aPlayer.PlayerRestartState = 'PlayerSpectating';
	}
    Result = Super.RestartPlayer(aPlayer);
	if ( aPlayer.bHidden )
		aPlayer.Visibility = 0;
	return Result;
}

//If a pawn is spawned, let game we want to count all monsters again
function bool IsRelevant( Actor Other)
{
	local bool Result;
	if ( Other.bIsPawn )
		bCountMonstersAgain = true;
	Result = Super.IsRelevant( Other);
	if ( (ScriptedPawn(Other) != None) && Result && !bSkipThisMonster )
		SetPawnDifficulty( MonsterSkill, ScriptedPawn(Other) );
	bSkipThisMonster = false;
	return Result;
}

// Fix monster dropped weapons/items breaking the client's inventory chain
function bool PickupQuery( Pawn Other, Inventory item )
{
	local bool bResult;
	
	bResult = Super.PickupQuery( Other, Item);
	if ( bResult && Item.bAlwaysRelevant )
		Item.bAlwaysRelevant = false;
	return bResult;
}

function bool ChangeTeam(Pawn Other, int NewTeam)
{
	local bool Result;
	local string SkinName, FaceName;
	
	Result = Super.ChangeTeam( Other, 0); //Add to red team
	if ( !bUseTeamSkins )
	{
		Other.static.GetMultiSkin(Other, SkinName, FaceName); //Apply non-team skin
		Other.static.SetMultiSkin(Other, SkinName, FaceName, NewTeam);
	}
	return Result;
}

function Killed( Pawn Killer, Pawn Other, name DamageType)
{
	if ( ScriptedPawn(Killer) != None )
		MonsterKill( ScriptedPawn(Killer), Other, DamageType);
	else
		Super.Killed( Killer, Other, DamageType);


	if ( (Lives > 0) && Other.bIsPlayer && (Other.PlayerReplicationInfo != None) && (Other.PlayerReplicationInfo.Deaths >= Lives) )
		bCheckEndLivesAgain = true;
}

function MonsterKill( ScriptedPawn Killer, Pawn Other, name DamageType)
{
	if ( Other == None || Killer == None )
		return;

	Other.DieCount++;
	Killer.KillCount++;
	BaseMutator.ScoreKill(Killer, Other);
		
	if ( Other.PlayerReplicationInfo != None )
	{
		Other.PlayerReplicationInfo.Deaths += 1;
		Other.PlayerReplicationInfo.Score -= 5;
		if ( ReachableEnemy == None || ReachableEnemy.bDeleteMe || Killer.bIsBoss )
			ReachableEnemy = Killer;
		BroadcastMessage( Killer.KillMessage( DamageType, Other), false, 'DeathMessage');
	}
}

function ScoreKill( Pawn Killer, Pawn Other)
{
	local int i;
	local bool bSpecialScore;
	local ScriptedPawn S;
	local MonsterPlayerData MPD;
	local float ScoreStart;

	bCountMonstersAgain = true;
	S = ScriptedPawn(Other);
	if ( (S != None) && S.bIsBoss && (Briefing != None) )
	{
		Briefing.KilledBosses++;
		Briefing.BossCount--;
	}
	if ( (Killer != None) && Killer.bIsPlayer && (Killer.PlayerReplicationInfo != None) && (S != None) )
	{
		if ( S.bIsPlayer )
			S.bIsPlayer = false; //Prevent skaarj log bug on non-XCGE servers (?)

		//Record initial score
		ScoreStart = Killer.PlayerReplicationInfo.Score;
		Super(GameInfo).ScoreKill( Killer, Other);

		BroadcastMessage( Killer.GetHumanName() @ "killed" $ Other.GetHumanName());
		For ( i=0 ; i<10 && (MonsterKillType[i] != '') ; i++ )
			if ( Other.IsA(MonsterKillType[i]) )
			{
				bSpecialScore = true;
				Killer.PlayerReplicationInfo.Score += MonsterKillScore[i];
				break;
			}
		if ( !bSpecialScore )
			Killer.PlayerReplicationInfo.Score += Sqrt( float(Other.default.Health) * 0.01 );

		if ( Briefing != None )
		{
			Briefing.KilledMonsters++;
			MPD = Briefing.GetPlayerData( Killer.PlayerReplicationInfo.PlayerID);
		}
		if ( MPD != None ) MPD.MonsterKills++;
		if ( S.bIsBoss )
		{
			Killer.PlayerReplicationInfo.Score += 9;
			if ( MPD != None ) MPD.BossKills++;
		}
		//Add score difference to team
		Teams[0].Score += Killer.PlayerReplicationInfo.Score - ScoreStart;
	}
	else
	{
		Super(GameInfo).ScoreKill( Killer, Other);
		if ( Other.PlayerReplicationInfo != None )
		{
			if ( Lives <= 0 )
			{
				if ( Killer == Other )
					Killer.PlayerReplicationInfo.Score -= 4;
			}
		}
	}
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
	if ( !S.bIsBoss && (S.Event != '') && (S.Health > 1500) ) //Count as boss
	{
		S.bIsBoss = true;
		S.Health = int(float(S.Health) * (float(StrenghtScale) * 0.01 - 0.15 * S.Skill)); //Avoid increasing health over boss status
	}
	else
		S.Health = int(float(S.Health) * float(StrenghtScale) * 0.01); //Avoid going over the 32 bit INT cap

	S.SightRadius = S.SightRadius * SkillScale / 100;
	S.RefireRate = S.RefireRate * SkillScale / 100;
	S.ProjectileSpeed = S.ProjectileSpeed * SkillScale / 100;
	S.GroundSpeed = S.GroundSpeed * SkillScale / 100;
	S.AirSpeed = S.AirSpeed * SkillScale / 100;
	S.WaterSpeed = S.WaterSpeed * SkillScale / 100;
	
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

}

function TaskMonstersVsBot( Bot aBot)
{
	local ScriptedPawn S;
	ForEach AllActors(Class'ScriptedPawn',S)
	{
		if ( S.CanSee(aBot) )
		{
			if ( ((S.Enemy == None) || S.Enemy.IsA('PlayerPawn') && (FRand() >= 0.5)) && (S.Health >= 1) )
			{
				S.Hated = aBot;
				S.Enemy = aBot;
				aBot.Enemy = S;
				S.GotoState('Attacking');
				if ( FRand() >= 0.35 )
				{
					aBot.GotoState('Attacking');
					return;
				}
			}
		}
		else
		{
			if ( aBot.CanSee(S) && (FRand() >= 0.34999999) && (S.Health >= 1) )
			{
				aBot.Enemy = S;
				aBot.GotoState('Attacking');
				S.Enemy = aBot;
				S.GotoState('Attacking');
				return;
			}
		}
	}
}
function TaskMonstersVsBot_XC( Bot aBot);


//Nearby hunters
function int NearbyTeammates( Pawn Other, float Distance, bool bVisible)
{
	local Pawn P;
	local int i;
	
	ForEach Other.RadiusActors ( class'Pawn', P, Distance)
	{
		if ( P.PlayerReplicationInfo == None || P.PlayerReplicationInfo.Team != Other.PlayerReplicationInfo.Team || P == Other )
			continue;
		if ( bVisible && !Other.FastTrace(P.Location + VRand() * P.CollisionRadius) )
			continue;
		i++;
	}
	return i;
}
function int NearbyTeammates_XC( Pawn Other, float Distance, bool bVisible)
{
	local Pawn P;
	local int i;
	
	ForEach PawnActors (class'Pawn', P, Distance, Other.Location, true)
	{
		if ( P.PlayerReplicationInfo.Team != Other.PlayerReplicationInfo.Team || (bVisible && !Other.FastTrace(P.Location + VRand()*P.CollisionRadius) ) )
			continue;
		i++;
	}
	return i;
}

//Returns whether this objective should cause bot attraction
function Actor ValidateObjective( Pawn Other, Actor Objective)
{
	if ( Objective == None || Objective.bDeleteMe )
		return None;
	if ( Objective.bIsPawn && (Pawn(Objective).Health > 0) )
		return Objective;
//	if ( MonsterWaypoint(Objective) != None && MonsterWaypoint(
// Later
}


//Sets MoveTarget on pawn
//Can be called recursively once
function bool AttractTo( Pawn Other, Actor Dest, optional bool bNoSearch)
{
	local NavigationPoint N, Nearest;
	local float Dist, BestDist;
	local vector Vect;
	
	if ( Other.ActorReachable(Dest) ) //Check actor
	{
		Other.MoveTarget = Dest;
		return true;
	}
	Vect = Dest.Location + Normal( Other.Location - Dest.Location) * (Other.CollisionRadius + Dest.CollisionRadius);
	if ( Other.PointReachable( Vect) ) //Check a point that allows touching the actor
	{
		Other.MoveTarget = Dest;
		return true;
	}
	N = NavigationPoint(Other.FindPathToward(Dest) ); //Find path to actor
	if ( N != None )
	{
		Other.MoveTarget = N;
		return true;
	}
	N = NavigationPoint(Other.FindPathTo(Vect) ); //Find path to said point
	if ( N != None )
	{
		Other.MoveTarget = N;
		return true;
	}
	
	if ( !bNoSearch )
	{
		BestDist = 700;
		ForEach Dest.RadiusActors( class'NavigationPoint', N, 500 )
			if ( N != Dest )
			{
				Vect = N.Location - Dest.Location;
				Dist = VSize( Vect);
				if ( Dist < BestDist )
				{
					Vect = Normal( Vect);
					Vect.X *= Dest.CollisionRadius;
					Vect.Y *= Dest.CollisionRadius;
					Vect.Z *= Dest.CollisionHeight * 0.5;
					if ( N.FastTrace(Dest.Location + Vect) )
					{
						Nearest = N;
						BestDist = Dist;
					}
				}
			}
		if ( Nearest != None )
		{
			if ( VSize(Nearest.Location - Other.Location) < 30 ) //We're touching nearest waypoint, go straight to destination
			{
				Other.MoveTarget = Dest;
				return true;
			}
			return AttractTo( Other, Nearest, true); //Recurse once and attract to Nearest
		}
	}
	return false;
}

function bool FindSpecialAttractionFor( Bot aBot)
{
	local MonsterWaypoint W, BestW;
	local float ChanceW;
	local MonsterEnd E;
	local Actor NewDest;
	local int Limit, MonsterLimit;
	local int BotID;
	local float BotState;
	local ScriptedPawn Enemy;
	local bool bAttract;

	if ( aBot.LastAttractCheck == Level.TimeSeconds )
		return false;

	if ( aBot.Health < 1 ) //Is this even needed?
	{
		aBot.GotoState('GameEnded');
		return False;
	}

	if ( Level.TimeSeconds - aBot.LastAttractCheck > 0.3 )
		TaskMonstersVsBot(aBot);
	aBot.LastAttractCheck = Level.TimeSeconds;
	
	//Force attack for now...
	if ( (aBot.Orders == 'Attack') || (aBot.Orders == 'Freelance') )
	{
		BotID = aBot.PlayerReplicationInfo.PlayerID + Asc(aBot.PlayerReplicationInfo $ "A");
		BotState = BotID + Level.TimeSeconds * 0.5;

		//The more conditions, the more the bot is likely to charge
		Limit = 3
		+ int(aBot.Orders == 'Attack')
		+ int(aBot.Enemy == None) * 2
		+ int(aBot.Weapon != none && aBot.Weapon.AiRating > 0.4 + FRand() * 0.2) * 2
		+ aBot.Health/150
		+ NearbyTeammates(aBot, 500+aBot.Health, aBot.Enemy!=None) / 2
		+ int(MonstersPerZone[aBot.Region.ZoneNumber] == 0)
		- int(aBot.Health < 68);

		BotState = BotState % Limit;
		//3 seconds for inventory grabbing
		if ( BotState < 1.5 ) 
			return False;
			
			
		//8-12 seconds prioritizing monsters (if MonsterLimit is too low the bot bounces back and forth!!)
		MonsterLimit = 4
		+ int(ScriptedPawn(aBot.OrderObject) != None) * 2
		+ Limit / 8;

		Enemy = ScriptedPawn(aBot.Enemy);
		if ( Enemy == None )	Enemy = ScriptedPawn(aBot.OrderObject);
		if ( Enemy == None )	Enemy = ReachableEnemy;
		if ( Enemy != None && (BotState < MonsterLimit) )
		{
			if ( AttractTo( aBot, Enemy) )
			{
				if ( (aBot.Enemy == Enemy && Enemy.bIsBoss) || ReachableEnemy == None || ReachableEnemy.bDeleteMe )
					ReachableEnemy = Enemy;
				if ( aBot.OrderObject == None || aBot.OrderObject.bDeleteMe )
					aBot.OrderObject = Enemy;
				if ( aBot.MoveTarget == Enemy ) //Don't charge
					return False;
				Goto ATTRACT_DEST;
			}
			else if ( Enemy == ReachableEnemy )
				ReachableEnemy = None;
		}
		
		//Otherwise prioritize the main objectives (sorted by priority)
		//Start with previously assigned goal
		BestW = MonsterWaypoint(aBot.OrderObject);
		if ( (BestW != None) && BestW.bEnabled && !BestW.bVisited && AttractTo( aBot, BestW) )
			Goto ATTRACT_DEST;
		BestW = None;

		ChanceW = 1;
		Limit = 0;
		For ( W=WaypointList ; W!=None ; W=W.NextWaypoint )
		{
			if ( W.bEnabled && !W.bVisited )
			{
				if ( Limit <= 0 )
					Limit = W.Position;
				else if ( W.Position > Limit+2 ) //Don't seek past next 2 objectives (speed reasons, game reasons, etc)
					break;
				if ( W.DeferTo != None )
					bAttract = AttractTo( aBot, W.DeferTo, true);
				else
					bAttract = AttractTo( aBot, W);
				if ( bAttract ) //Only query reachable objectives
				{
					if ( BestW == None ) //Get first one
						BestW = W;
					else if ( W.Position > BestW.Position ) //Stop if we're going past the position
						break;
					else //Otherwise randomize among WP's with same priority
					{
						ChanceW += 1.0;
						if ( FRand() < 1.0/ChanceW )
							BestW = W;
					}
					
					//We changed objectives, change attraction point
					if ( BestW == W )
						NewDest = aBot.MoveTarget;
				}
			}
		}
		
		//Assign objective and attract
		if ( NewDest != None )
		{
			aBot.OrderObject = BestW;
			aBot.MoveTarget = NewDest;
			Goto ATTRACT_DEST;
		}

		For ( E=EndList ; E!=None ; E=E.NextEnd )
		{
			if ( !E.bInitiallyActive && E.bReachedByPlayer )
				continue;
			if ( (E.DeferTo != None && AttractTo( aBot, E.DeferTo, true)) || (E.DeferTo == None && AttractTo( aBot, E)) )
			{
				NewDest = aBot.MoveTarget;
				if ( E.bCollideActors && E.bInitiallyActive ) //Prioritize 
					Goto ATTRACT_DEST;
			}
		}

		if ( NewDest != None )
			Goto ATTRACT_DEST;

		//Defer to enemy if failed to find objective
		if ( Enemy != None && BotState >= MonsterLimit )
		{
			if ( AttractTo( aBot, Enemy) )
			{
				aBot.OrderObject = Enemy;
				if ( aBot.MoveTarget == Enemy ) //Don't charge
					return False;
				Goto ATTRACT_DEST;
			}
			else if ( Enemy == ReachableEnemy )
				ReachableEnemy = None;
		}
		bQueryEnemies = (FRand() < 0.01) || (ReachableEnemy == None);
	}
	return False;
ATTRACT_DEST:
	SetAttractionStateFor(aBot);
	return true;
}


//****************************************
// Utilitary methods
// XC versions are used in XC_Engine servers

function ResetPerZoneCounter()
{
	local int i;
	For ( i=0 ; i<64 ; i++ )
		MonstersPerZone[i] = 0;
}
function int GetMonstersPerZone( byte ZoneNumber) //ACCESSOR
{
	if ( ZoneNumber >= 64 )
		return 0;
	return MonstersPerZone[ZoneNumber];
}

//Monster counter
function CountMonsters()
{
	local int i, iB;
	local Pawn P;
	
	ResetPerZoneCounter();
	For ( P=Level.PawnList ; P!=None ; P=P.NextPawn )
		if ( P.IsA('ScriptedPawn') && (P.Health > 0) )
		{
			i++; //Ignore friendly monsters?
			MonstersPerZone[P.Region.ZoneNumber] += int(P.AttitudeToPlayer < ATTITUDE_Friendly);
			if ( ScriptedPawn(P).bIsBoss )
				iB++;
			if ( P.Shadow == None && (Level.NetMode != NM_DedicatedServer) )
				P.Shadow = Spawn( Class'MonsterShadow', P);
		}
	if ( MonsterReplicationInfo(GameReplicationInfo) != None )
		MonsterReplicationInfo(GameReplicationInfo).Monsters = i;
	if ( Briefing != None )
		Briefing.BossCount = iB;
}

function CountMonsters_XC()
{
	local int i, iB;
	local ScriptedPawn S;

	ResetPerZoneCounter();
	ForEach PawnActors (class'ScriptedPawn', S)
	{
		if ( S.Health > 0 )
		{
			i++; //Ignore friendly monsters?
			MonstersPerZone[S.Region.ZoneNumber] += int(S.AttitudeToPlayer < ATTITUDE_Friendly);
			if ( S.bIsBoss )
				iB++;
			if ( S.Shadow == None && (Level.NetMode != NM_DedicatedServer) )
				S.Shadow = Spawn( Class'MonsterShadow', S);
		}
	}
	if ( MonsterReplicationInfo(GameReplicationInfo) != None )
		MonsterReplicationInfo(GameReplicationInfo).Monsters = i;
	if ( Briefing != None )
		Briefing.BossCount = iB;
}

//Hunter counter
function CountHunters()
{
	local int i;
	local PlayerReplicationInfo PRI;
	
	ForEach AllActors (class'PlayerReplicationInfo', PRI)
		if ( PRI.Owner != None && !PRI.Owner.IsA('ScriptedPawn') && !PRI.bIsSpectator )
			i++;
	if ( MonsterReplicationInfo(GameReplicationInfo) != None )
		MonsterReplicationInfo(GameReplicationInfo).Hunters = i;
}
function CountHunters_XC()
{
	local int i;
	local Pawn P;
	
	ForEach PawnActors (class'Pawn', P,,, true)
		if ( !P.IsA('ScriptedPawn') && !P.PlayerReplicationInfo.bIsSpectator )
			i++;
	if ( MonsterReplicationInfo(GameReplicationInfo) != None )
		MonsterReplicationInfo(GameReplicationInfo).Hunters = i;
}

//MonsterEnd chainer
function RegisterEnd( MonsterEnd Other)
{
	Other.NextEnd = EndList;
	EndList = Other;
}

//Waypoint chainer
function RegisterWaypoint( MonsterWaypoint Other)
{
	local MonsterWaypoint MW;

	if ( (WaypointList == None) || (WaypointList.Position > Other.Position) )
	{
		Other.NextWaypoint = WaypointList;
		WaypointList = Other;
	}
	else
	{
		For ( MW=WaypointList ; MW!=None ; MW=MW.NextWaypoint )
		{
			if ( MW == Other ) //BUG
				break;
			if ( (MW.NextWaypoint == None) || (MW.NextWaypoint.Position > Other.Position) )
			{
				Other.NextWaypoint = MW.NextWaypoint;
				MW.NextWaypoint = Other;
				break;
			}
		}
	}
}

//Waypoint has been visited
function WaypointVisited( MonsterWaypoint Other, PlayerReplicationInfo Visitor)
{
	local MonsterPlayerData MPD;
	
	MPD = Briefing.GetPlayerData( Visitor.PlayerID);
	if ( MPD != None )
		MPD.ObjectivesTaken++;
	UnregisterWaypoint( Other);
}

function UnregisterWaypoint( MonsterWaypoint Other)
{
	local MonsterWaypoint MW;

	if ( Other == WaypointList )
		WaypointList = Other.NextWaypoint;
	else
	{
		For ( MW=WaypointList ; MW!=None ; MW=MW.NextWaypoint )
			if ( MW.NextWaypoint == Other )
			{
				MW.NextWaypoint = Other.NextWaypoint;
				break;
			}
	}
	Other.NextWaypoint = None;
}

function AddToTeam( int num, Pawn Other )
{
	local TeamInfo aTeam;
	local bool bSuccess;
	local string SkinName, FaceName;
	local PlayerReplicationInfo PRI;
	
	if ( Other == None || Other.PlayerReplicationInfo == None )
		return;
		
	aTeam = Teams[0];
	aTeam.Size++;
	aTeam.TeamName = HunterTeamName;
	Other.PlayerReplicationInfo.Team = 0;
	Other.PlayerReplicationInfo.TeamName = aTeam.TeamName;
	if ( Other.IsA('PlayerPawn') )
	{
		Other.PlayerReplicationInfo.TeamID = 0;
		PlayerPawn(Other).ClientChangeTeam(Other.PlayerReplicationInfo.Team);
	}
	else
		Other.PlayerReplicationInfo.TeamID = 1;

	while ( !bSuccess )
	{
		bSuccess = true;
		ForEach AllActors ( class'PlayerReplicationInfo', PRI)
			if ( (PRI != Other.PlayerReplicationInfo) && (PRI.Team == Other.PlayerReplicationInfo.Team) && (PRI.TeamID == Other.PlayerReplicationInfo.TeamID) )
			{
				Other.PlayerReplicationInfo.TeamID++; //This trick works great with AllActors, this will most like only loop twice!
				bSuccess = false;
			}
	}

//	BroadcastLocalizedMessage( DMMessageClass, 3, Other.PlayerReplicationInfo, None, aTeam );

	Other.static.GetMultiSkin(Other, SkinName, FaceName);
	Other.static.SetMultiSkin(Other, SkinName, FaceName, num);
	CheckPlayerData( Other, num);
}

//Fix annoying spam
function ChangeName(Pawn Other, string S, bool bNameChange)
{
	local PlayerReplicationInfo PRI;

	if ( S == "" )
		return;
	S = left(S,24);
	if (Other.PlayerReplicationInfo.PlayerName~=S)
		return;
	
	ForEach AllActors( class'PlayerReplicationInfo', PRI)
		if ( PRI.PlayerName ~= S )
		{
			Other.ClientMessage(S$NoNameChange);
			return;
		}
	Other.PlayerReplicationInfo.OldName = Other.PlayerReplicationInfo.PlayerName;
	Other.PlayerReplicationInfo.PlayerName = S;
	if ( bNameChange && !Other.IsA('Spectator') )
		BroadcastLocalizedMessage( DMMessageClass, 2, Other.PlayerReplicationInfo );			
	if (LocalLog != None)	LocalLog.LogNameChange(Other);
	if (WorldLog != None)	WorldLog.LogNameChange(Other);
}

function CheckPlayerData( Pawn Other, int NewTeam)
{
	local MonsterPlayerData MPD;
	local MonsterAuthenticator MA;
	
	MPD = Briefing.GetPlayerData( Other.PlayerReplicationInfo.PlayerID);
	if ( MPD != None )
	{
		MPD.TeamSkin = NewTeam;
		return;
	}
	MA = Briefing.GetAuthenticator(Other);
	MA.TeamSkin = NewTeam;
}


defaultproperties
{
	MonsterSkill=5
	Lives=6
	bUseTeamSkins=True
	bReplaceUIWeapons=True
	DamageToScore=400
	TimeLimit=30
	MutatorClass=Class'MonsterBase'
	DefaultWeapon=Class'Botpack.ChainSaw'
	MapListType=Class'MonsterMapList'
	RulesMenuType="MonsterHunt.MonsterHuntRules"
	ClientExtensionClass="MonsterHuntCL_0.MHCL_MonsterBriefing"
	ScoreBoardType=Class'MonsterBoard'
	HUDType=Class'MonsterHUD'
	GameReplicationInfoClass=Class'MonsterReplicationInfo'
	MapPrefix="MH"
	BeaconName="MH"
	HunterTeamName="Hunters"
	HunterTeamIcon="Botpack.Icons.I_TeamN"
	GameName="Monster Hunt"
	LeftMessage=" left the hunt."
	EnteredMessage=" has joined the hunt!"
	StartUpMessage="Work with your teammates to hunt down the monsters!"
	StartMessage="The hunt has begun!"
	StartUpTeamMessage="Welcome to the hunt!"
	GameEndedMessage="Hunt Successful!"
	TimeOutMessage="Time up, hunt failed!"
	SingleWaitingMessage="Press Fire to begin the hunt."

	
	MonsterKillType(0)=Nali
	MonsterKillScore(0)=-6
	MonsterKillType(1)=Cow
	MonsterKillScore(1)=-6
}






