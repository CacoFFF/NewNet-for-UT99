// ===============================================================
// Stats.ST_FlakSlug: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_FlakSlug extends flakslug;

var ST_Mutator STM;
var actor NN_HitOther;
var int zzNN_ProjIndex;

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

simulated function ProcessTouch (Actor Other, vector HitLocation)
{		
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( Other != instigator && Other != Owner && Other.Owner != Owner && NN_HitOther != Other )
	{
		NN_HitOther = Other;
		NewExplode(HitLocation,Normal(HitLocation-Other.Location), Other.IsA('Pawn'));
	}
}

simulated function NewExplode(vector HitLocation, vector HitNormal, bool bDirect)
{
	local vector start;
	local ST_UTChunkInfo CI;
	local bbPlayer bbP;
	local ST_UTChunk Proj;
	local int ProjIndex;
	
	bbP = bbPlayer(Owner);
	
	if (STM != None)
		STM.PlayerHit(Instigator, 15, bDirect);		// 15 = Flak Slug
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_FlakSlugOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'UT_FlakCannon', damage, 150, 'FlakDeath', MomentumTransfer, HitLocation, zzNN_ProjIndex);
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		}
	}
	else
	{
		HurtRadius(damage, 150, 'FlakDeath', MomentumTransfer, HitLocation);
	}
	
	if (STM != None)
		STM.PlayerClear();				// Damage is given now.
	start = Location + 10 * HitNormal;
 	Spawn( class'ut_FlameExplosion',,,Start);
	CI = Spawn(Class'ST_UTChunkInfo', Instigator);
	CI.STM = STM;
	
	Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk3',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk4',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk1',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
 	Destroy();
}

simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_FlakSlugOwnerHidden') || RemoteRole == ROLE_Authority )
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

simulated function Explode(vector HitLocation, vector HitNormal)
{
	if (bDeleteMe)
		return;
	NN_Momentum(150, MomentumTransfer, HitLocation);
	NewExplode(HitLocation, HitNormal, False);
}

defaultproperties {
}
