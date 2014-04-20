// ===============================================================
// UTPureStats7A.ST_UT_BioGel: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_UT_BioGel extends UT_BioGel;

var ST_Mutator STM;
var bool bDirect;
var actor NN_HitOther;
var int zzNN_ProjIndex;

simulated function PostBeginPlay()
{
	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
		if (STM != None)
			STM.PlayerFire(Instigator, 4);			// 4 = Bio. (Each Potential Damage giver is 1 shot! Not ammo!)
	}
	Super.PostBeginPlay();
}


simulated function Timer()
{
	local ut_GreenGelPuff f;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);

	f = spawn(class'ut_GreenGelPuff',,,Location + SurfaceNormal*8); 
	f.numBlobs = numBio;
	if ( numBio > 0 )
		f.SurfaceNormal = SurfaceNormal;	
	PlaySound (MiscSound,,3.0*DrawScale);	
	if ( (Mover(Base) != None) && Mover(Base).bDamageTriggered )	// A Base ain't a pawn, so don't worry.
		Base.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);

	if (STM != None)
		STM.PlayerHit(Instigator, 4, bDirect);		// 4 = Bio.
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !bOwnerNoSee)
			bbP.NN_HurtRadius(self, class'UT_BioRifle', damage * Drawscale, FMin(250, DrawScale * 75), MyDamageType, MomentumTransfer * Drawscale, Location, zzNN_ProjIndex);
	}
	else
	{
		HurtRadius(damage * Drawscale, FMin(250, DrawScale * 75), MyDamageType, MomentumTransfer * Drawscale, Location);
	}
	NN_Momentum(FMin(250, DrawScale * 75), MomentumTransfer * Drawscale, Location);
	if (STM != None)
		STM.PlayerClear();
	Destroy();
}

simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_UT_BioGelOwnerHidden') || RemoteRole == ROLE_Authority )
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

auto state Flying
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{ 
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( ( Other != Owner && Pawn(Other)!=Instigator && Other.Owner != Owner || bOnGround) && (!Other.IsA('ST_UT_BioGel') || Other.Owner != Owner) && NN_HitOther != Other && !bOwnerNoSee )
		{
			NN_HitOther = Other;
			bDirect = Other.IsA('Pawn') && !bOnGround;
			Global.Timer(); 
	
			if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client)
			{
				//bbP.xxNN_TakeDamage(Other, class'UT_BioRifle', Damage, Instigator, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType, zzNN_ProjIndex);
				bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, Normal(HitLocation - Other.Location));
			}
		}
	}
}

state OnSurface
{
	simulated function ProcessTouch (Actor Other, vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if (Other.IsA('ST_UT_BioGel') && Other.Owner == Owner)
			return;
		GotoState('Exploding');
	}
}

defaultproperties {
}
