class NN_Razor2OwnerHidden extends ST_Razor2;

var bool bAlreadyHidden;
var float NN_OwnerPing, NN_EndAccelTime;
var bool bSpedUp, bSlowed;

replication
{
	reliable if ( Role == ROLE_Authority )
		NN_OwnerPing;
}

simulated function Tick(float DeltaTime)
{
	local bbPlayer bbP;
	
	if (Level.NetMode == NM_Client) {
	
		if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
			LightType = LT_None;
			SetCollisionSize(0, 0);
			ExplosionDecal = None;
			SpawnSound = None;
			bAlreadyHidden = True;
			Destroy();
			return;
		}
		
		if (NN_OwnerPing > 0)
		{
			if (NN_EndAccelTime == 0)
			{
			}
			else if (bSpedUp && Level.TimeSeconds > NN_EndAccelTime && !bSlowed)
			{
				Velocity = Velocity / 2;
				NN_OwnerPing = 0;
				bSlowed = true;
			}
		}
		
	}
	
}

auto state Flying
{
	simulated function SetUp()
	{
		local vector X;
		local Pawn P;
		
		X = vector(Rotation);
		
		if (Level.NetMode == NM_Client && NN_OwnerPing > 0)
		{
			bSpedUp = true;
			Velocity = Speed * X * 2;     // Impart ONLY forward vel
			NN_EndAccelTime = Level.TimeSeconds + NN_OwnerPing * Level.TimeDilation / 1000;
			for (P = Level.PawnList; P != None; P = P.NextPawn)
				if (PlayerPawn(P) != None && Viewport(PlayerPawn(P).Player) != None && P.PlayerReplicationInfo != None)
					NN_EndAccelTime += P.PlayerReplicationInfo.Ping * Level.TimeDilation / 1000;
		}
		else
		{
			Velocity = Speed * X;     // Impart ONLY forward vel
		}
		if (Instigator != None && Instigator.HeadRegion.Zone.bWaterZone)
			bHitWater = True;
	}
	
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( bCanHitInstigator || (Other != Owner && Other != Instigator) && Other.Owner != Owner )
		{
			if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
			{
				if ( Other.bIsPawn && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight) 
					&& (!Instigator.IsA('Bot') || !Bot(Instigator).bNovice) )
				{
					if (STM != None)
						STM.PlayerHit(Instigator, 11, True);		// 11 = Ripper Primary Headshot
					if (bbPlayer(Owner) == None || !bbPlayer(Owner).bNewNet)
						Other.TakeDamage(3.5 * damage, instigator,HitLocation,
							(MomentumTransfer * Normal(Velocity)), 'decapitated' );
					if (STM != None)
						STM.PlayerClear();
				}
				else			 
				{
					if (STM != None)
						STM.PlayerHit(Instigator, 11, False);		// 11 = Ripper Primary
					if (bbPlayer(Owner) == None || !bbPlayer(Owner).bNewNet)
						Other.TakeDamage(damage, instigator,HitLocation,
							(MomentumTransfer * Normal(Velocity)), 'shredded' );
					if (STM != None)
						STM.PlayerClear();
				}
			}
			if ( Other.bIsPawn )
				PlayOwnedSound(MiscSound, SLOT_Misc, 2.0);
			else
				PlayOwnedSound(ImpactSound, SLOT_Misc, 2.0);
			destroy();
		}
	}
	
	simulated function HitWall (vector HitNormal, actor Wall)
	{
		local vector Vel2D, Norm2D;
		
		if (bSpedUp && NN_OwnerPing > 0 && !bSlowed) {
			Velocity = Velocity / 2;
			NN_OwnerPing = 0;
			bSlowed = true;
		}
		bCanHitInstigator = true;
		DoWallHit(PlayerPawn(Owner), HitNormal);
		PlayOwnedSound(ImpactSound, SLOT_Misc, 2.0);
		LoopAnim('Spin',1.0);
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
		{
			if ( Role == ROLE_Authority )
				Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
			Destroy();
			return;
		}
		NumWallHits++;
		SetTimer(0, False);
		MakeNoise(0.3);
		if ( NumWallHits > 6 )
			Destroy();

		if ( NumWallHits == 1 ) 
		{
			Vel2D = Velocity;
			Vel2D.Z = 0;
			Norm2D = HitNormal;
			Norm2D.Z = 0;
			Norm2D = Normal(Norm2D);
			Vel2D = Normal(Vel2D);
			if ( (Vel2D Dot Norm2D) < -0.999 )
			{
				HitNormal = Normal(HitNormal + 0.6 * Vel2D);
				Norm2D = HitNormal;
				Norm2D.Z = 0;
				Norm2D = Normal(Norm2D);
				if ( (Vel2D Dot Norm2D) < -0.999 )
				{
					//if ( Rand(1) == 0 )
					//	HitNormal = HitNormal + vect(0.05,0,0);
					//else
					//	HitNormal = HitNormal - vect(0.05,0,0);
					//if ( Rand(1) == 0 )
					//	HitNormal = HitNormal + vect(0,0.05,0);
					//else
					//	HitNormal = HitNormal - vect(0,0.05,0);
					HitNormal = Normal(HitNormal);
				}
			}
		}
		Velocity -= 2 * (Velocity dot HitNormal) * HitNormal;  
		SetRoll(Velocity);
	}
}

simulated function DoWallHit(PlayerPawn Pwner, vector HitNormal)
{
	local Pawn P;
	local Actor WC;

	if (RemoteRole < ROLE_Authority) {
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (P != Pwner) {
				if (NumWallHits < 1) {
					WC = P.Spawn(class'WallCrack',P,,Location, rotator(HitNormal));
					WC.bOnlyOwnerSee = True;
				}
			}
	}
}

defaultproperties {
	bOwnerNoSee=True
}