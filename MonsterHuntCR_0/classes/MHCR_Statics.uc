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


static final function AddPathTo( NavigationPoint N, int iPath)
{
	local int i;
	
	For ( i=0 ; i<16 ; i++ )
	{
		if ( N.Paths[i] == iPath )
			break;
		if ( N.Paths[i] < 0 )
		{
			N.Paths[i] = iPath;
			break;
		}
	}
}

static final function AddUPathTo( NavigationPoint N, int iPath)
{
	local int i;

	For ( i=0 ; i<16 ; i++ )
	{
		if ( N.UpstreamPaths[i] == iPath )
			break;
		if ( N.UpstreamPaths[i] < 0 )
		{
			N.UpstreamPaths[i] = iPath;
			break;
		}
	}
}

static final function RemovePathFrom( NavigationPoint N, int iPath, optional int StartAt)
{
	local int i, k;
	For ( i=StartAt ; i<16 ; i++ )
	{
		if ( N.Paths[i] < 0 )
			break;
		if ( N.Paths[i] == iPath )
		{
			k=i+1;
			while ( (k<16) && (N.Paths[k] >= 0) )
				k++;
			k--; //Stop at first non-path, then go back to last path
			N.Paths[i] = N.Paths[k];
			N.Paths[k] = -1;
			break;
		}
	}
}

static final function RemoveUPathFrom( NavigationPoint N, int iPath, optional int StartAt)
{
	local int i, k;
	For ( i=StartAt ; i<16 ; i++ )
	{
		if ( N.UpstreamPaths[i] < 0 )
			break;
		if ( N.UpstreamPaths[i] == iPath )
		{
			k=i+1;
			while ( (k<16) && (N.UpstreamPaths[k] >= 0) )
				k++;
			k--; //Stop at first non-path, then go back to last path
			N.UpstreamPaths[i] = N.UpstreamPaths[k];
			N.UpstreamPaths[k] = -1;
			break;
		}
	}
}