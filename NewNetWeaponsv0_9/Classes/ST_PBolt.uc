// ===============================================================
// UTPureStats7A.ST_PBolt: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_PBolt extends PBolt;

var ST_Mutator STM;
var float GrowthAccumulator;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
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
	HitActor = Trace(HitLocation, HitNormal, Location + BeamSize * X, Location, true);
	if ( (HitActor != None)	&& (HitActor != Instigator)
		&& (HitActor.bProjTarget || (HitActor == Level) || (HitActor.bBlockActors && HitActor.bBlockPlayers)) 
		&& ((Pawn(HitActor) == None) || Pawn(HitActor).AdjustHitLocation(HitLocation, Velocity)) )
	{
		if ( Level.Netmode != NM_Client || bNewNet )
		{
			if ( DamagedActor == None )
			{
				AccumulatedDamage = FMin(0.5 * (Level.TimeSeconds - LastHitTime), 0.050);
				if (STM != None)
					STM.PlayerHit(Instigator, 10, False);						// 10 = Pulse Shaft
				if (bNewNet)
					bbP.xxNN_TakeDamage(HitActor, class'PulseGun', AccumulatedDamage * damage * 0.9 + 0.050, Instigator, HitLocation, (MomentumTransfer * X * AccumulatedDamage), MyDamageType, -1, 0, 0, HitNormal, true);
				else
					HitActor.TakeDamage(AccumulatedDamage * damage + 0.050, instigator,HitLocation, // *2?...
						(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
				AccumulatedDamage = 0;
			}				
			else if ( DamagedActor != HitActor )
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 10, False);						// 10 = Pulse Shaft
				if (bNewNet)
					bbP.xxNN_TakeDamage(DamagedActor, class'PulseGun', damage * AccumulatedDamage * 0.9, Instigator, HitLocation, (MomentumTransfer * X * AccumulatedDamage), MyDamageType, -1, 0, 0, HitNormal, true);
				else
					DamagedActor.TakeDamage(damage * AccumulatedDamage, instigator,HitLocation,
						(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
				AccumulatedDamage = 0;
			}				
			LastHitTime = Level.TimeSeconds;
			DamagedActor = HitActor;
			AccumulatedDamage += DeltaTime;
			if ( AccumulatedDamage > 0.15 )
			{
				if ( DamagedActor.IsA('Carcass') && (FRand() < 0.09) )
					AccumulatedDamage = 35/damage;
				if (STM != None)
					STM.PlayerHit(Instigator, 10, True);						// 10 = Pulse Shaft, Overload
				if (bNewNet)
					bbP.xxNN_TakeDamage(DamagedActor, class'PulseGun', damage * AccumulatedDamage * 0.9, Instigator, HitLocation, (MomentumTransfer * X * AccumulatedDamage), MyDamageType, -1, 0, 0, HitNormal, true);
				else
					DamagedActor.TakeDamage(damage * AccumulatedDamage, instigator,HitLocation,
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
			WallEffect = Spawn(class'PlasmaHit',,, HitLocation - 5 * X);
		else if ( !WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();	
			WallEffect = Spawn(class'PlasmaHit',,, HitLocation - 5 * X);
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
	else if ( (Level.Netmode != NM_Client || bNewNet) && (DamagedActor != None) )
	{
		if (STM != None)
			STM.PlayerHit(Instigator, 10, True);								// 10 = Pulse Shaft
		if (bNewNet)
			bbP.xxNN_TakeDamage(DamagedActor, class'PulseGun', damage * AccumulatedDamage * 0.9, Instigator, DamagedActor.Location - X * 1.2 * DamagedActor.CollisionRadius, (MomentumTransfer * X * AccumulatedDamage), MyDamageType, -1, 0, 0, HitNormal, true);
		else
			DamagedActor.TakeDamage(damage * AccumulatedDamage, instigator, DamagedActor.Location - X * 1.2 * DamagedActor.CollisionRadius,
				(MomentumTransfer * X * AccumulatedDamage), MyDamageType);
		if (STM != None)
			STM.PlayerClear();
		AccumulatedDamage = 0;
		DamagedActor = None;
	}			


	if ( Position >= 9 )
	{	
		if ( (WallEffect == None) || WallEffect.bDeleteMe )
			WallEffect = Spawn(class'PlasmaCap',,, Location + (BeamSize - 4) * X);
		else if ( WallEffect.IsA('PlasmaHit') )
		{
			WallEffect.Destroy();	
			WallEffect = Spawn(class'PlasmaCap',,, Location + (BeamSize - 4) * X);
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
				PlasmaBeam = Spawn(class'ST_PBolt',,, Location + BeamSize * X);
				PlasmaBeam.Position = Position + 1;
				ST_PBolt(PlasmaBeam).GrowthAccumulator = GrowthAccumulator; // - 0.050;		// This causing extra damage?
				ST_PBolt(PlasmaBeam).STM = STM;
				GrowthAccumulator = 0.0;
			}
		}
		else
			PlasmaBeam.UpdateBeam(self, X, DeltaTime);
	}
	
}

defaultproperties {
}
