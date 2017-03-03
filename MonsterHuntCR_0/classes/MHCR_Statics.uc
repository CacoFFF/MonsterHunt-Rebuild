//General purpose functions
class MHCR_Statics expands Object;

native(3571) static final function float HSize( vector A);


static final function bool InCylinder( vector V, float EX, float EZ)
{
	if ( Abs(V.Z) >= EZ )
		return false;
	V.Z = 0;
	return VSize(V) < EX;
}

static final function bool InCylinder_XC( vector V, float EX, float EZ)
{
	return (Abs(V.Z) < EZ) && (HSize(V) < EX);
}

static final function bool ActorsTouching( Actor A, Actor B, optional float ExtraH, optional float ExtraV)
{
	return InCylinder( A.Location-B.Location, A.CollisionRadius+B.CollisionRadius+ExtraH, A.CollisionRadius+B.CollisionRadius+ExtraV);
}
