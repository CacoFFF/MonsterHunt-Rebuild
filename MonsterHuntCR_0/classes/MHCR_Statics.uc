//General purpose functions
class MHCR_Statics expands Object;


static function ReplaceInventoryFunctions()
{
	ReplaceFunction( class'Inventory', class'MHCR_Inventory', 'BotDesireability', 'BotDesireability');
	ReplaceFunction( class'Pickup', class'MHCR_Pickup', 'HandlePickupQuery', 'HandlePickupQuery');
	ReplaceFunction( class'UT_ShieldBelt', class'MHCR_UT_ShieldBelt', 'HandlePickupQuery', 'HandlePickupQuery');
	ReplaceFunction( class'UT_ShieldBelt', class'MHCR_UT_ShieldBelt', 'PickupFunction', 'PickupFunction');
	ReplaceFunction( class'Armor2', class'MHCR_UT_ShieldBelt', 'HandlePickupQuery', 'HandlePickupQuery');
	ReplaceFunction( class'ThighPads', class'MHCR_UT_ShieldBelt', 'HandlePickupQuery', 'HandlePickupQuery');
	ReplaceFunction( class'Armor2', class'Pickup', 'SpawnCopy', 'SpawnCopy');
	ReplaceFunction( class'ThighPads', class'Pickup', 'SpawnCopy', 'SpawnCopy');
}


static final function bool InCylinder( vector V, float EX, float EZ)
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

static final function PopRouteCache( out NavigationPoint List[16])
{
	local int i;
	while ( i<15 && (List[i] != None) )
		List[i] = List[++i];
	List[15] = None;
}