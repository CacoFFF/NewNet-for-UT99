class NN_PBoltOwnerHidden extends ST_PBolt;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		LightType = LT_None;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
	}
}

simulated function CheckBeam(vector X, float DeltaTime)
{
	local actor HitActor;
	local vector HitLocation, HitNormal;
	local bbPlayer bbP;
	local ST_PulseGun PGun;
	local bool bNewNet;
	
	bbP = bbPlayer(Instigator);
	PGun = ST_PulseGun(Instigator.Weapon);
	if (PGun == None)
		return;
	bNewNet = bbP != None && PGun.bNewNet;
	
	// check to see if hits something, else spawn or orient child
	if (bNewNet && bbP.zzNN_HitActorLast != None)
	{
		HitActor = bbP.zzNN_HitActorLast;
		HitLocation = bbP.zzNN_HitLocLast;
		HitNormal = bbP.zzNN_HitNormalLast;
		bbP.zzNN_HitActorLast = None;
	}
	else
	{
		HitActor = Trace(HitLocation, HitNormal, Location + BeamSize * X, Location, true);
	}
	
	if ( (HitActor != None)	&& (HitActor != Instigator)	&& (HitActor != Owner)
		&& (HitActor.bProjTarget || (HitActor == Level) || (HitActor.bBlockActors && HitActor.bBlockPlayers)) 
		&& ((Pawn(HitActor) == None) || Pawn(HitActor).AdjustHitLocation(HitLocation, Velocity)) )
	{
		if ( Level.Netmode != NM_Client )
		{
			if ( DamagedActor == None )
			{
				AccumulatedDamage = FMin(0.5 * (Level.TimeSeconds - LastHitTime), 0.050);
				if (STM != None)
					STM.PlayerHit(Instigator, 10, False);						// 10 = Pulse Shaft
				if (!bNewNet)
					HitActor.TakeDamage(AccumulatedDamage * damage * 0.9 + 0.050, instigator,HitLocation, // *2?...
						(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
				AccumulatedDamage = 0;
			}
			else if ( DamagedActor != HitActor )
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 10, False);						// 10 = Pulse Shaft
				if (!bNewNet)
					DamagedActor.TakeDamage(damage * AccumulatedDamage * 0.9, instigator,HitLocation,
						(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
				AccumulatedDamage = 0;
			}				
			LastHitTime = Level.TimeSeconds;
			DamagedActor = HitActor;
			AccumulatedDamage += DeltaTime;
			if ( AccumulatedDamage > 0.22 )
			{
				if ( DamagedActor.IsA('Carcass') && (FRand() < 0.09) )
					AccumulatedDamage = 35/damage;
				if (STM != None)
					STM.PlayerHit(Instigator, 10, True);						// 10 = Pulse Shaft, Overload
				if (!bNewNet)
					DamagedActor.TakeDamage(damage * AccumulatedDamage * 0.9, instigator,HitLocation,
						(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
				AccumulatedDamage = 0;
			}
		}
		if ( HitActor.bIsPawn && Pawn(HitActor).bIsPlayer )
		{
			if ( WallEffect != None )
				WallEffect.Destroy();
		}
		else if ( (WallEffect == None) || WallEffect.bDeleteMe )
			WallEffect = Spawn(class'NN_PlasmaHitOwnerHidden',Owner,, HitLocation - 5 * X);
		else if ( !WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();
			WallEffect = Spawn(class'NN_PlasmaHitOwnerHidden',Owner,, HitLocation - 5 * X);
		}
		else
			WallEffect.SetLocation(HitLocation - 5 * X);

		if ( (WallEffect != None) && (Level.NetMode != NM_DedicatedServer) )
			Spawn(ExplosionDecal,,,HitLocation,rotator(HitNormal));

		if ( PlasmaBeam != None )
		{
			AccumulatedDamage = PlasmaBeam.AccumulatedDamage;
			PlasmaBeam.Destroy();
			PlasmaBeam = None;
		}

		return;
	}
	else if ( (Level.Netmode != NM_Client) && (DamagedActor != None) )
	{
		if (STM != None)
			STM.PlayerHit(Instigator, 10, True);								// 10 = Pulse Shaft
		if (!bNewNet)
			DamagedActor.TakeDamage(damage * AccumulatedDamage * 0.9, instigator, DamagedActor.Location - X * 1.2 * DamagedActor.CollisionRadius,
				(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
		if (STM != None)
			STM.PlayerClear();
		AccumulatedDamage = 0;
		DamagedActor = None;
	}			


	if ( Position >= 9 )
	{	
		if ( (WallEffect == None) || WallEffect.bDeleteMe )
			WallEffect = Spawn(class'NN_PlasmaCapOwnerHidden',Owner,, Location + (BeamSize - 4) * X);
		else if ( WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();	
			WallEffect = Spawn(class'NN_PlasmaCapOwnerHidden',Owner,, Location + (BeamSize - 4) * X);
		}
		else
			WallEffect.SetLocation(Location + (BeamSize - 4) * X);
	}
	else
	{
		if ( WallEffect != None )
		{
			WallEffect.Destroy();
			WallEffect = None;
		}
		if ( PlasmaBeam == None )
		{
			// Originally, it spawned a new segment every tick, meaning higher tickrate = faster growth of beam
			// This also meant it was incorrectly simulated on clients, since clients usually have a much higher framerate.
			// This should fix both issues. Tickrate 20 is assumed.
			GrowthAccumulator += DeltaTime;
			if (GrowthAccumulator > 0.050)		// 1 / 20 (Tickrate 20) = 0.050
			{
				PlasmaBeam = Spawn(class'NN_PBoltOwnerHidden',Owner,, Location + BeamSize * X);
				PlasmaBeam.Position = Position + 1;
				ST_PBolt(PlasmaBeam).GrowthAccumulator = GrowthAccumulator; // - 0.050;		// This causing extra damage?
				ST_PBolt(PlasmaBeam).STM = STM;
				GrowthAccumulator = 0.0;
				DoAmbientSound(PlayerPawn(Owner));
			}
		}
		else
			PlasmaBeam.UpdateBeam(self, X, DeltaTime);
	}
	
}

simulated function DoAmbientSound(PlayerPawn Pwner)
{
	local PlayerPawn P;

	//for (P = Level.PawnList; P != None; P = P.NextPawn)
		//if (P != Pwner)
			PlasmaBeam.AmbientSound = Sound'Botpack.PulseGun.PulseBolt';
}

defaultproperties {
	bOwnerNoSee=True
	AmbientSound=None
}
