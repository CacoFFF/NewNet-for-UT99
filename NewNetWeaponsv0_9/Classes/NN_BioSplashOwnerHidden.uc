class NN_BioSplashOwnerHidden extends NN_UT_BioGelOwnerHidden;

auto state Flying
{
	function ProcessTouch (Actor Other, vector HitLocation) 
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
		if (Other.IsA('ST_UT_BioGel') && Other.Owner == Owner)
			return;
		GotoState('Exploding');
	}
}

defaultproperties
{
	speed=300.000000
	bOwnerNoSee=True
}
