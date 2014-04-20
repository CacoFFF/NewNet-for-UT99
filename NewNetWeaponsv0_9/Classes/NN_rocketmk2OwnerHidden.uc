class NN_rocketmk2OwnerHidden extends ST_RocketMk2;

var bool bAlreadyHidden;
var float NN_OwnerPing, NN_EndAccelTime;

replication
{
	reliable if ( Role == ROLE_Authority )
		NN_OwnerPing;
}

simulated function Tick(float DeltaTime)
{
	local Pawn P;
	
	if (Level.NetMode == NM_Client) {
	
		if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
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
		
		if (NN_OwnerPing > 0)
		{
			if (NN_EndAccelTime == 0)
			{
				Velocity *= 2;
				NN_EndAccelTime = Level.TimeSeconds + NN_OwnerPing * Level.TimeDilation / 1000;
				for (P = Level.PawnList; P != None; P = P.NextPawn)
					if (PlayerPawn(P) != None && Viewport(PlayerPawn(P).Player) != None)
						NN_EndAccelTime += P.PlayerReplicationInfo.Ping * Level.TimeDilation / 1000;
			}
			else if (Level.TimeSeconds > NN_EndAccelTime)
			{
				Velocity = Velocity / 2;
				NN_OwnerPing = 0;
			}
		}
		
	}
	
}

simulated function Timer()
{
	local ut_SpriteSmokePuff b;

	if (!bNetOwner && Level.NetMode!=NM_DedicatedServer) {
		if ( Region.Zone.bWaterZone || (Level.NetMode == NM_DedicatedServer) )
			Return;

		if ( Level.bHighDetailMode )
		{
			if ( Level.bDropDetail || ((NumExtraRockets > 0) && (FRand() < 0.5)) )
				Spawn(class'NN_LightSmokeTrailOwnerHidden',Owner);
			else
				Spawn(class'NN_UTSmokeTrailOwnerHidden',Owner);
			if (Speed != 0)
				SmokeRate = 152/Speed; 
		}
		else 
		{
			SmokeRate = 0.15 + FRand()*(0.01+NumExtraRockets);
			b = Spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner);
			b.RemoteRole = ROLE_None;
		}
		SetTimer(SmokeRate, false);
	}
}

auto state Flying
{
	simulated function ZoneChange( Zoneinfo NewZone )
	{
		local waterring w;
		
		if (!NewZone.bWaterZone || bHitWater || bNetOwner) Return;

		bHitWater = True;
		if ( Level.NetMode != NM_DedicatedServer )
		{
			w = Spawn(class'NN_WaterRingOwnerHidden',Owner,,,rot(16384,0,0));
			w.DrawScale = 0.2;
			w.RemoteRole = ROLE_None;
			PlayAnim( 'Still', 3.0 );
		}		
		Velocity=0.6*Velocity;
	}

	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( (Other != instigator) && !Other.IsA('Projectile') && Other != Owner && Other.Owner != Owner ) 
			Explode(HitLocation,Normal(HitLocation-Other.Location));
	}

	function BlowUp(vector HitLocation)
	{
		//Log(Class.Name$" (BlowUp) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
		if (!bbPlayer(Owner).bNewNet)
			HurtRadius(Damage,220.0, MyDamageType, MomentumTransfer, HitLocation );
		MakeNoise(1.0);
	}

	simulated function Explode(vector HitLocation, vector HitNormal)
	{
		local UT_SpriteBallExplosion s;
		local bbPlayer bbP;

		if (bDeleteMe)
			return;
		if (!bNetOwner && Level.NetMode!=NM_DedicatedServer) {
			s = spawn(class'NN_UT_SpriteBallExplosionOwnerHidden',Owner,,HitLocation + HitNormal*16);	
			s.RemoteRole = ROLE_None;
		}
		
		bbP = bbPlayer(Owner);
		if (bbP != None)
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		BlowUp(HitLocation);

 		Destroy();
	}

	function BeginState()
	{
		local vector Dir;

		Dir = vector(Rotation);
		Velocity = speed * Dir;
		Acceleration = Dir * 50;
		if (!bNetOwner && Level.NetMode!=NM_DedicatedServer)
			PlayAnim( 'Wing', 0.2 );
		if (Region.Zone.bWaterZone)
		{
			bHitWater = True;
			Velocity=0.6*Velocity;
		}
	}
}

defaultproperties
{
	speed=900.000000
	MaxSpeed=1600.000000
	Damage=75.000000
	MomentumTransfer=80000
	MyDamageType=RocketDeath
	SpawnSound=Sound'UnrealShare.Eightball.Ignite'
	ImpactSound=Sound'UnrealShare.Eightball.GrenadeFloor'
	ExplosionDecal=Class'Botpack.BlastMark'
	RemoteRole=ROLE_SimulatedProxy
	LifeSpan=6.000000
	AnimSequence=Wing
	AmbientSound=Sound'Botpack.RocketLauncher.RocketFly1'
	Mesh=LodMesh'Botpack.UTRocket'
	DrawScale=0.020000
	AmbientGlow=96
	bUnlit=True
	SoundRadius=14
	SoundVolume=255
	SoundPitch=100
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightBrightness=255
	LightHue=28
	LightRadius=6
	bBounce=True
	bFixedRotationDir=True
	RotationRate=(Roll=50000)
	DesiredRotation=(Roll=30000)
	bOwnerNoSee=True
}
