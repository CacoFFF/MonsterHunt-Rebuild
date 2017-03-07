//=============================================================================
// Placeholder, MH503 will redirect MHProto players to the MHCR scoreboard
//=============================================================================
class MHCL_ScoreBoard expands MHCR_ScoreBoard;

event Destroyed()
{
	//Level about to be purged, no need for additional processing
	if ( (Level.NetMode == NM_Client) && (Owner != None) && Owner.bDeleteMe )
		return;
	Super.Destroyed();
}
