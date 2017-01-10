//================================================================================
// ClimbZone.
//================================================================================
class ClimbZone extends ZoneInfo;

#exec TEXTURE IMPORT NAME=MHClimb FILE=pcx\MHClimb.pcx

event ActorEntered (Actor Other)
{
	if ( Pawn(Other).bIsPlayer )
		Other.SetPhysics(PHYS_Spider);
}

event ActorLeaving (Actor Other)
{
	if ( Pawn(Other).bIsPlayer )
		Other.SetPhysics(PHYS_Walking);
}

defaultproperties
{
    Texture=Texture'MHClimb'
}
