// ===============================================================
// UTPureStats7A.ST_Razor2Alt: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_Razor2Alt extends Razor2Alt;

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
			STM.PlayerFire(Instigator, 12);		// 11 = Ripper Secondary
	}
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		local RipperPulse s;
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( Other != Instigator && Other != Owner && Other.Owner != Owner ) 
		{
			if (NN_HitOther != Other && !IsA('NN_Razor2AltOwnerHidden') )
			{
				NN_HitOther = Other;
				if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client)
				{
					bbP.xxNN_TakeDamage(Other, class'Ripper', damage, instigator,HitLocation,
						(MomentumTransfer * Normal(Velocity)), MyDamageType, zzNN_ProjIndex );
					bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, (MomentumTransfer * Normal(Velocity)));
				}
			}
				
			if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 12, Other.IsA('Pawn'));	// 12 = Ripper Secondary, Direct if Pawn
				Other.TakeDamage(damage, instigator,HitLocation,
					(MomentumTransfer * Normal(Velocity)), MyDamageType );
				if (STM != None)
					STM.PlayerClear();
			}
			s = spawn(class'RipperPulse',,,HitLocation);	
 			s.RemoteRole = ROLE_None;
			MakeNoise(1.0);
 			Destroy();
		}
	}

	simulated function NN_Momentum( vector Momentum, vector HitLocation )
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_Razor2AltOwnerHidden') || RemoteRole == ROLE_Authority )
			return;
		
		if (bbP.Physics == PHYS_None)
			bbP.SetMovementPhysics();
		if (bbP.Physics == PHYS_Walking)
			Momentum.Z = FMax(Momentum.Z, 0.4 * VSize(Momentum));
			
		Momentum = 0.6*Momentum/bbP.Mass;

		bbP.AddVelocity(Momentum);
	}

	simulated function BlowUp(vector HitLocation)
	{
		local actor Victims, TracedTo;
		local int DamageRadius;
		local float damageScale, dist;
		local vector dir, VictimHitLocation, VictimMomentum, MoverHitLocation, MoverHitNormal;
		local bbPlayer bbP;
		local Mover M;
		
		bbP = bbPlayer(Owner);

		if( bHurtEntry )
			return;
		
		DamageRadius = 180;
		bHurtEntry = true;
		foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
		{
			if( Victims != self )
			{
				dir = Victims.Location - HitLocation;
				dist = FMax(1,VSize(dir));
				dir = dir/dist;
				dir.Z = FMin(0.45, dir.Z); 
				damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
				VictimHitLocation = Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir;
				VictimMomentum = damageScale * MomentumTransfer * dir;
				if (bbP != None && bbP.bNewNet)
				{
					if (Level.NetMode == NM_Client && !IsA('NN_Razor2AltOwnerHidden'))
					{
						bbP.xxNN_TakeDamage
						(
							Victims,
							class'Ripper',
							damageScale * Damage,
							Instigator, 
							VictimHitLocation,
							VictimMomentum,
							MyDamageType,
							zzNN_ProjIndex,
							DamageRadius
						);
					}
				}
				else
				{
					Victims.TakeDamage
					(
						damageScale * Damage,
						Instigator, 
						VictimHitLocation,
						VictimMomentum,
						MyDamageType
					);
				}
				if (Victims == Owner)
					NN_Momentum(VictimMomentum, VictimHitLocation);
			} 
		}
		
		if (bbP != None && bbP.bNewNet)
		{
			foreach RadiusActors( class 'Mover', M, DamageRadius, HitLocation )
			{
				TracedTo = Trace(MoverHitLocation, MoverHitNormal, M.Location, HitLocation, True);
				dir = MoverHitLocation - HitLocation;
				dist = FMax(1,VSize(dir));
				if (TracedTo != M || dist > DamageRadius)
					continue;
				dir = dir/dist; 
				damageScale = 1 - FMax(0,(dist - M.CollisionRadius)/DamageRadius);
				bbP.xxNN_ServerTakeDamage( M, class'Ripper', damageScale * Damage, Instigator, HitLocation, bbP.GetBetterVector(damageScale * MomentumTransfer * dir), MyDamageType, zzNN_ProjIndex);
				//bbP.xxMover_TakeDamage( M, damageScale * Damage, bbP, M.Location - 0.5 * (M.CollisionHeight + M.CollisionRadius) * dir, damageScale * MomentumTransfer * dir, MyDamageType );
			}
		}
		
		bHurtEntry = false;
		MakeNoise(1.0);
	}
}

defaultproperties {
}
