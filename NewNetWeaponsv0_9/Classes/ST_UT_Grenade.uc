// ===============================================================
// Stats.ST_UT_Grenade: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_UT_Grenade extends UT_Grenade;

var ST_Mutator STM;
var float R1, R2, R3, R4, R5, R6, R7, R8;
var actor NN_HitOther;
var int zzNN_ProjIndex;

simulated function float GetFRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return 0;
	
	bbP.zzFRVI++;
	if (bbP.zzFRVI == bbP.FRVI_length)
		bbP.zzFRVI = 0;
	return bbP.GetFRV(bbP.zzFRVI);
}

simulated function PreBeginPlay()
{
	if (bbPlayer(Owner) != None)
	{
		R1 = GetFRV();
		R2 = GetFRV();
		R3 = GetFRV();
		R4 = GetFRV();
		R5 = GetFRV();
		R6 = GetFRV();
		R7 = GetFRV();
		R8 = GetFRV();
	}
	else
	{
		R1 = FRand();
		R2 = FRand();
		R3 = FRand();
		R4 = FRand();
		R5 = FRand();
		R6 = FRand();
		R7 = FRand();
		R8 = FRand();
	}
	
	Super.PreBeginPlay();
}

simulated function PostBeginPlay()
{
	local vector X,Y,Z;
	local rotator RandRot;
	local bbPlayer bbP;

	//Super.PostBeginPlay();
	if ( Level != None && Level.NetMode != NM_DedicatedServer )
		PlayAnim('WingIn');
	SetTimer(2.5+R1*0.5,false);                  //Grenade begins unarmed
	
	if (Instigator == None)
		Instigator = Pawn(Owner);
	
	bbP = bbPlayer(Instigator);
	
	if (Instigator == None)
		GetAxes(RandRot,X,Y,Z);
	else if (bbP == None || !bbP.bNewNet)
		GetAxes(Instigator.ViewRotation,X,Y,Z);
	else if (Level != None && Level.NetMode == NM_Client)
		GetAxes(bbP.ViewRotation,X,Y,Z);
	else
		GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	
	if (Instigator == None)
		Velocity = X * (vect(0,0,0) Dot X)*0.4 + Vector(Rotation) * (Speed +
			R2 * 100);
	else
		Velocity = X * (Instigator.Velocity Dot X)*0.4 + Vector(Rotation) * (Speed +
			R2 * 100);
	Velocity.z += 210;
	MaxSpeed = 1000;
	RandSpin(50000);	
	bCanHitOwner = False;
	if (Instigator != None && Instigator.HeadRegion.Zone.bWaterZone)
	{
		bHitWater = True;
		Disable('Tick');
		Velocity=0.6*Velocity;			
	}
	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}	
}

simulated function Tick(float DeltaTime)
{
	local UT_BlackSmoke b;

	if ( bHitWater || Level.bDropDetail ) 
	{
		Disable('Tick');
		Return;
	}
	Count += DeltaTime;
	if ( (Count>R3*SmokeRate+SmokeRate+NumExtraGrenades*0.03) && (Level.NetMode!=NM_DedicatedServer) ) 
	{
		b = Spawn(class'UT_BlackSmoke');
		b.RemoteRole = ROLE_None;		
		Count=0;
	}
}

simulated function Explosion(vector HitLocation)
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client && !IsA('NN_ut_GrenadeOwnerHidden') && NN_HitOther != None)
	{
		bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, Normal(HitLocation - NN_HitOther.Location));
	}
		
	Super.Explosion(HitLocation);
}

simulated function BlowUp(vector HitLocation)
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
		STM.PlayerHit(Instigator, 17, !bCanHitOwner);	// bCanHitOwner is set to True after the Grenade has bounced once. Neat hax
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_UT_Grenade'))
			bbP.NN_HurtRadius(self, class'UT_Eightball', damage, 200, MyDamageType, MomentumTransfer, HitLocation, zzNN_ProjIndex);
	}
	else
	{
		HurtRadius(damage, 200, MyDamageType, MomentumTransfer, HitLocation);
	}
	NN_Momentum(200, MomentumTransfer, HitLocation);
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
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_ut_GrenadeOwnerHidden') || RemoteRole == ROLE_Authority )
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

simulated function ProcessTouch( actor Other, vector HitLocation )
{
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( (Other!=instigator) && (Other!=Owner) || bCanHitOwner )
	{
		NN_HitOther = Other;
		Explosion(HitLocation);
	}
}

defaultproperties {
}
