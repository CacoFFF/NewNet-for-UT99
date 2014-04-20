// ===============================================================
// Stats.ST_UT_SeekingRocket: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_UT_SeekingRocket extends UT_SeekingRocket;

var ST_Mutator STM;
var bool bDirect;
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
		b = Spawn(class'ut_SpriteSmokePuff');
		b.RemoteRole = ROLE_None;
	}
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( (Other != instigator) && !Other.IsA('Projectile') && Other != Owner && Other.Owner != Owner && NN_HitOther != Other ) 
		{
			bDirect = Other.IsA('Pawn');
			NN_HitOther = Other;
			Explode(HitLocation,Normal(HitLocation-Other.Location));
		}
	}
	
	simulated function Explode(vector HitLocation, vector HitNormal)
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe)
			return;
		if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client && !IsA('NN_ut_SeekingRocketOwnerHidden'))
		{
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		}
		
		Super.Explode(HitLocation, HitNormal);
	}

	simulated function BlowUp(vector HitLocation)
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		if (STM != None)
			STM.PlayerHit(Instigator, 16, bDirect);		// 16 = Rockets. No special for seeking, a seeker just means it has a larger chance of direct (yeah rite :P)
		if (bbP != None && bbP.bNewNet)
		{
			if (Level.NetMode == NM_Client && !IsA('NN_UT_SeekingRocket'))
				bbP.NN_HurtRadius(self, class'UT_Eightball', Damage, 220.0, MyDamageType, MomentumTransfer, HitLocation, zzNN_ProjIndex );
		}
		else
		{
			HurtRadius(Damage, 220.0, MyDamageType, MomentumTransfer, HitLocation );
		}
		NN_Momentum(220.0, MomentumTransfer, HitLocation);
		if (STM != None)
			STM.PlayerClear();
		MakeNoise(1.0);
	}

	simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
	{
		local actor Victims;
		local float damageScale, dist;
		local vector dir;
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_ut_SeekingRocketOwnerHidden') || RemoteRole == ROLE_Authority )
			return;

		foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
		{
			if( Victims == Owner )
			{
				dir = Owner.Location - HitLocation;
				dist = FMax(1,VSize(dir));
				dir = dir/dist; 
				damageScale = 1 - FMax(0,(dist - Owner.CollisionRadius)/DamageRadius);
				
				dir = damageScale * Momentum * dir;
				
				if (bbP.Physics == PHYS_None)
					bbP.SetMovementPhysics();
				if (bbP.Physics == PHYS_Walking)
					dir.Z = FMax(dir.Z, 0.4 * VSize(dir));
					
				dir = 0.6*dir/bbP.Mass;

				bbP.AddVelocity(dir); 
			}
		}
	}
}

defaultproperties {
}
