class  NN_ut_GrenadeOwnerHidden extends ST_UT_Grenade;

var bool bAlreadyHidden;

function float GetFRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return 0;
	
	bbP.zzFRVI++;
	if (bbP.zzFRVI == bbP.FRVI_length)
		bbP.zzFRVI = 0;
	return bbP.GetFRV(bbP.zzFRVI);
}

simulated function Tick(float DeltaTime) {
	local UT_BlackSmoke b;

	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		ImpactSound = None;
		ExplosionDecal = None;
		Mesh = None;
		AmbientGlow = 0;
		bAlreadyHidden = True;
		Destroy();
		return;
	}
	if ( bHitWater || Level.bDropDetail ) 
	{
		Disable('Tick');
		Return;
	}
	Count += DeltaTime;
	if ( (Count>R3*SmokeRate+SmokeRate+NumExtraGrenades*0.03) && (Level.NetMode!=NM_DedicatedServer) && !bNetOwner ) 
	{
		b = Spawn(class'UT_BlackSmoke');
		b.RemoteRole = ROLE_None;		
		Count=0;
	}
}

simulated function ZoneChange( Zoneinfo NewZone )
{
	local waterring w;
	
	if (!NewZone.bWaterZone || bHitWater) Return;

	bHitWater = True;
	w = Spawn(class'NN_WaterRingOwnerHidden',Owner,,,rot(16384,0,0));
	w.DrawScale = 0.2;
	w.RemoteRole = ROLE_None;
	Velocity=0.6*Velocity;
}

simulated function HitWall( vector HitNormal, actor Wall )
{
	bCanHitOwner = True;
	Velocity = 0.75*(( Velocity dot HitNormal ) * HitNormal * (-2.0) + Velocity);   // Reflect off Wall w/damping
	RandSpin(100000);
	speed = VSize(Velocity);
	if ( Level.NetMode != NM_DedicatedServer && !bNetOwner )
		PlaySound(ImpactSound, SLOT_Misc, 1.5 );
	if ( Velocity.Z > 400 )
		Velocity.Z = 0.5 * (400 + Velocity.Z);	
	else if ( speed < 20 ) 
	{
		bBounce = False;
		SetPhysics(PHYS_None);
	}
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	if (bDeleteMe)
		return;
	Explosion(HitLocation);
}

simulated function Explosion(vector HitLocation)
{
	local UT_SpriteBallExplosion s;

	BlowUp(HitLocation);
	if ( Level.NetMode != NM_DedicatedServer && !bNetOwner )
	{
		spawn(class'Botpack.BlastMark',,,,rot(16384,0,0));
  		s = spawn(class'UT_SpriteBallExplosion',,,HitLocation);
		s.RemoteRole = ROLE_None;
	}
 	Destroy();
}

simulated function BlowUp(vector HitLocation)
{
	if (STM != None)
		STM.PlayerHit(Instigator, 17, !bCanHitOwner);	// bCanHitOwner is set to True after the Grenade has bounced once. Neat hax
	//Log(Class.Name$" (BlowUp) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (!bbPlayer(Owner).bNewNet)
		HurtRadius(damage, 200, MyDamageType, MomentumTransfer, HitLocation);
	NN_Momentum(200, MomentumTransfer, HitLocation);
	if (STM != None)
		STM.PlayerClear();
	MakeNoise(1.0);
}

defaultproperties
{
	bOwnerNoSee=True
}
