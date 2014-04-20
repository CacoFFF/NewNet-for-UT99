// ===============================================================
// UTPureStats7A.ST_BioSplash: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_BioSplash extends ST_UT_BioGel;

auto state Flying
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{ 
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( Other.IsA('ST_UT_BioGel') && Other.Owner == Owner )
			return;
		if ( Pawn(Other)!=Instigator || bOnGround) 
			Global.Timer(); 
	}
}

state OnSurface
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( Other.IsA('ST_UT_BioGel') && Other.Owner == Owner)
			return;
		GotoState('Exploding');
	}
}

defaultproperties
{
     speed=300.000000
}
