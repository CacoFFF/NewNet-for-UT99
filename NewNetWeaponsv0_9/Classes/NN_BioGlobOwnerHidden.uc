class NN_BioGlobOwnerHidden extends ST_BioGlob;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		LightType = LT_None;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
	}
}

function vector GetVRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return vect(0,0,0);
	
	bbP.zzVRVI++;
	if (bbP.zzVRVI == bbP.VRVI_length)
		bbP.zzVRVI = 0;
	return bbP.GetVRV(bbP.zzVRVI)/10000;
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{ 
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( ( Other.IsA('ST_BioSplash') || Other == Owner || Other.Owner == Owner ) )
			return;
		if ( Pawn(Other)!=Instigator || bOnGround) 
			Global.Timer();
	}
	
	simulated function HitWall( vector HitNormal, actor Wall )
	{

		SetPhysics(PHYS_None);		
		MakeNoise(1);	
		bOnGround = True;
		PlayOwnedSound(ImpactSound);	
		SetWall(HitNormal, Wall);
		if ( DrawScale > 1 )
			NumSplash = int(2 * DrawScale) - 1;
		SpawnPoint = Location + 5 * HitNormal;
		DrawScale= FMin(DrawScale, 3.0);
		if ( NumSplash > 0 )
		{
			SpawnSplash();
			if ( NumSplash > 0 )
				SpawnSplash();
		}
		GoToState('OnSurface');
	}
	
	function Explode( vector HitLocation, vector HitNormal )
	{
		local ut_GreenGelPuff f;
		
		if (bDeleteMe)
			return;

		f = spawn(class'ut_GreenGelPuff',,,Location + SurfaceNormal*8); 
		f.numBlobs = numBio;
		if ( numBio > 0 )
			f.SurfaceNormal = SurfaceNormal;	
		PlaySound (MiscSound,,3.0*DrawScale);	
		if ( (Mover(Base) != None) && Mover(Base).bDamageTriggered )	// A Base ain't a pawn, so don't worry.
			Base.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
		
		if (STM != None)
			STM.PlayerHit(Instigator, 4, bDirect);		// 4 = Bio.
		//Log(Class.Name$" (Explode) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
		if (!bbPlayer(Owner).bNewNet)
			HurtRadius(damage * Drawscale, FMin(250, DrawScale * 75), MyDamageType, MomentumTransfer * Drawscale, Location);
		//NN_Momentum(FMin(250, DrawScale * 75), MomentumTransfer * Drawscale, Location);
		if (STM != None)
			STM.PlayerClear();
		Destroy();	
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

function SpawnSplash()
{
	local vector Start, V1;
	local NN_BioSplashOwnerHidden BS;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if (bbP != None)
		V1 = GetVRV();
	else
		V1 = VRand();

	NumSplash--;
	Start = SpawnPoint + 4 * V1; 
	BS = Spawn(class'NN_BioSplashOwnerHidden',Owner,,Start,Rotator(Start - Location));
	BS.zzNN_ProjIndex = bbP.xxNN_AddProj(BS);
}

defaultproperties {
	bOwnerNoSee=True
}