class NN_ut_SeekingRocketOwnerHidden extends ST_UT_SeekingRocket;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		SpawnSound = None;
		ImpactSound = None;
		ExplosionDecal = None;
		AmbientSound = None;
		Mesh = None;
		AmbientGlow = 0;
		LightType = LT_None;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
		Destroy();
		return;
	}
}

simulated function Timer()
{
	local ut_SpriteSmokePuff b;
	local vector SeekingDir;
	local float MagnitudeVel;

	if ( InitialDir == vect(0,0,0) )
		InitialDir = Normal(Velocity);
		 
	if ( (Seeking != None) && (Seeking != Instigator) ) 
	{
		SeekingDir = Normal(Seeking.Location - Location);
		if ( (SeekingDir Dot InitialDir) > 0 )
		{
			MagnitudeVel = VSize(Velocity);
			SeekingDir = Normal(SeekingDir * 0.5 * MagnitudeVel + Velocity);
			Velocity =  MagnitudeVel * SeekingDir;	
			Acceleration = 25 * SeekingDir;	
			SetRotation(rotator(Velocity));
		}
	}
	if ( bHitWater || (Level.NetMode == NM_DedicatedServer) )
		Return;

	if ( (Level.bHighDetailMode && !Level.bDropDetail) || (FRand() < 0.5) )
	{
		b = Spawn(class'NN_UT_SpriteSmokePuffOwnerHidden');
		b.RemoteRole = ROLE_None;
	}
}

auto state Flying
{
	function BlowUp(vector HitLocation)
	{
		if (STM != None)
			STM.PlayerHit(Instigator, 16, bDirect);		// 16 = Rockets. No special for seeking, a seeker just means it has a larger chance of direct (yeah rite :P)
		//Log(Class.Name$" (BlowUp) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
		if (!bbPlayer(Owner).bNewNet)
			HurtRadius(Damage,220.0, MyDamageType, MomentumTransfer, HitLocation );
		NN_Momentum(220.0, MomentumTransfer, HitLocation);
		if (STM != None)
			STM.PlayerClear();
		MakeNoise(1.0);
	}
}

defaultproperties {
	bOwnerNoSee=True
}
