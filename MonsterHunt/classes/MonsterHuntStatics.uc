//General purpose functions
class MonsterHuntStatics expands Object;

native(3560) static final function bool ReplaceFunction( class<Object> ReplaceClass, class<Object> WithClass, name ReplaceFunction, name WithFunction, optional name InState);
native(3571) static final function float HSize( vector A);

static final function XC_Init( int Version)
{
	if ( Version < 19 )
		return;
	ReplaceFunction( class'MonsterHuntStatics', class'MonsterHuntStatics', 'InCylinder', 'InCylinder_XC');
}


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
