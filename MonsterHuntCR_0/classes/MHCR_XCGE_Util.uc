// Specialized mirror of XC_Engine_Actor without package dependancy
class MHCR_XCGE_Util expands Info;

const R_WALK       = 0x00000001; //walking required
const R_FLY        = 0x00000002; //flying required 
const R_SWIM       = 0x00000004; //swimming required
const R_JUMP       = 0x00000008; //jumping required
const R_DOOR       = 0x00000010;
const R_SPECIAL    = 0x00000020;
const R_PLAYERONLY = 0x00000040;
	
struct ReachSpec
{
	var() int Distance; 
	var() Actor Start;
	var() Actor End;
	var() int CollisionRadius; 
    var() int CollisionHeight; 
	var() int ReachFlags;
	var() byte bPruned;
};


//Native mirrors
function bool GetReachSpec( out ReachSpec R, int Idx);
function bool SetReachSpec( ReachSpec R, int Idx, optional bool bAutoSet);
function int ReachSpecCount();
function int AddReachSpec( ReachSpec R, optional bool bAutoSet); //Returns index of newle created ReachSpec
function int FindReachSpec( Actor Start, Actor End); //-1 if not found, useful for finding unused specs (actor = none)
function CompactPathList( NavigationPoint N); //Also cleans up invalid paths (Start or End = NONE)
function LockToNavigationChain( NavigationPoint N, bool bLock);
//Script mirrors
function CleanupNavSpecs( NavigationPoint N);
function EzConnectNavigationPoints( NavigationPoint Start, NavigationPoint End, optional float Scale, optional bool bOneWay);





defaultproperties
{
    RemoteRole=ROLE_None
}
