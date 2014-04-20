class NN_PlasmaSphereOwnerHidden extends ST_PlasmaSphere;

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

simulated function HitWall (vector HitNormal, actor Wall)
{
	if ( Role == ROLE_Authority )
	{
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), '');

		MakeNoise(1.0);
	}
	ReallyExplode(Location + ExploWallOut * HitNormal, HitNormal);
	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) && !bNetOwner )
		Spawn(ExplosionDecal,self,,Location, rotator(HitNormal));
}

function Explode(vector HitLocation, vector Momentum)
{
	if (bDeleteMe)
		return;
	//Log(Class.Name$" (Explode) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	ReallyExplode(HitLocation, Momentum);
}

simulated function ReallyExplode(vector HitLocation, vector Momentum)
{
	if ( !bExplosionEffect )
	{
		PlayOwnedSound(EffectSound1,,7.0);
		bExplosionEffect = true;
		if ( !Level.bHighDetailMode || bHitPawn || Level.bDropDetail )
		{
			if ( bExploded )
			{
				Destroy();
				return;
			}
			else
				DrawScale = 0.45;
		}
		else
			DrawScale = 0.65;

	    LightType = LT_Steady;
		LightRadius = 5;
		SetCollision(false,false,false);
		LifeSpan = 0.5;
		Texture = ExpType;
		DrawType = DT_SpriteAnimOnce;
		Style = STY_Translucent;
		if ( Region.Zone.bMoveProjectiles && (Region.Zone.ZoneVelocity != vect(0,0,0)) )
		{
			bBounce = true;
			Velocity = Region.Zone.ZoneVelocity;
		}
		else
			SetPhysics(PHYS_None);
	}
	bExploded = true;
}

simulated function NewProcessTouch (Actor Other, vector HitLocation)
{
	local bbPlayer bbP, bbO;
	
	If ( Other != Owner && Other!=Instigator  && PlasmaSphere(Other)==None )
	{
		if ( Other.bIsPawn )
		{
			bHitPawn = true;
			bExploded = !Level.bHighDetailMode || Level.bDropDetail;
		}
		if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
		{
			bbP = bbPlayer(Owner);
			bbO = bbPlayer(Other);
			
			if (bbP == None || bbO == None)
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 9, False);	// 9 = Plasma Sphere
				Other.TakeDamage( Damage, instigator, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType);	
				if (STM != None)
					STM.PlayerClear();
			}
			else if (bbP.PlayerReplicationInfo.Team == bbO.PlayerReplicationInfo.Team)
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 9, False);	// 9 = Plasma Sphere
				bbO.GiveHealth( Damage, bbP, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
			}
			else
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 9, False);	// 9 = Plasma Sphere
				bbO.StealHealth( Damage, bbP, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType);
				if (STM != None)
					STM.PlayerClear();
			}
		}
	}
}

defaultproperties {
	bOwnerNoSee=True
}