// ===============================================================
// UTPureStats7A.ST_Razor2: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_Razor2 extends Razor2;

var ST_Mutator STM;
var actor NN_HitOther;
var int zzNN_ProjIndex;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
		if (STM != None)
			STM.PlayerFire(Instigator, 11);		// 11 = Ripper Primary
	}
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( bCanHitInstigator || (Other != Owner && Other != Instigator) && Other.Owner != Owner )
		{
			if (Other == Owner)
				NN_Momentum(MomentumTransfer * Normal(Velocity), HitLocation);
				
			if (NN_HitOther != Other && !IsA('NN_Razor2OwnerHidden'))
			{
				NN_HitOther = Other;
				if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client)
				{
					if ( Other.bIsPawn && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight) )
					{
						bbP.xxNN_TakeDamage(Other, class'Ripper', 3.5 * damage, instigator,HitLocation,
							(MomentumTransfer * Normal(Velocity)), 'decapitated', zzNN_ProjIndex );
					}
					else			 
					{
						bbP.xxNN_TakeDamage(Other, class'Ripper', damage, instigator,HitLocation,
							(MomentumTransfer * Normal(Velocity)), 'shredded', zzNN_ProjIndex );
					}
					bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, (MomentumTransfer * Normal(Velocity)));
				}
			}	
				
			if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
			{
				if ( Other.bIsPawn && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight) 
					&& (!Instigator.IsA('Bot') || !Bot(Instigator).bNovice) )
				{
					if (STM != None)
						STM.PlayerHit(Instigator, 11, True);		// 11 = Ripper Primary Headshot
					Other.TakeDamage(3.5 * damage, instigator,HitLocation,
						(MomentumTransfer * Normal(Velocity)), 'decapitated' );
					if (STM != None)
						STM.PlayerClear();
				}
				else			 
				{
					if (STM != None)
						STM.PlayerHit(Instigator, 11, False);		// 11 = Ripper Primary
					Other.TakeDamage(damage, instigator,HitLocation,
						(MomentumTransfer * Normal(Velocity)), 'shredded' );
					if (STM != None)
						STM.PlayerClear();
				}
			}
			if ( Other.bIsPawn )
				PlaySound(MiscSound, SLOT_Misc, 2.0);
			else
				PlaySound(ImpactSound, SLOT_Misc, 2.0);
			destroy();
		}
	}

	simulated function HitWall (vector HitNormal, actor Wall)
	{
		local vector Vel2D, Norm2D;

		bCanHitInstigator = true;
		PlaySound(ImpactSound, SLOT_Misc, 2.0);
		LoopAnim('Spin',1.0);
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
		{
			//if (Level.NetMode == NM_Client)
			//	bbPlayer(Owner).xxMover_TakeDamage(Mover(Wall), Damage, Pawn(Owner), Location, MomentumTransfer*Vector(Rotation), MyDamageType);
			//else
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
			Spawn(class'WallCrack',,,Location, rotator(HitNormal));
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

	simulated function NN_Momentum( vector Momentum, vector HitLocation )
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_Razor2OwnerHidden') || RemoteRole == ROLE_Authority )
			return;
		
		if (bbP.Physics == PHYS_None)
			bbP.SetMovementPhysics();
		if (bbP.Physics == PHYS_Walking)
			Momentum.Z = FMax(Momentum.Z, 0.4 * VSize(Momentum));
			
		Momentum = 0.6*Momentum/bbP.Mass;

		bbP.AddVelocity(Momentum);
	}
}

defaultproperties
{
}