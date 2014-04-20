// ===============================================================
// UTPureStats7A.ST_PlasmaSphere: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_PlasmaSphere extends PlasmaSphere;

var ST_Mutator STM;
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
			STM.PlayerFire(Instigator, 9);			// 9 = Plasma Sphere
	}
	Velocity = Speed * vector(Rotation);
	Super.PostBeginPlay();
}

simulated function ProcessTouch(Actor Other, vector HitLocation)
{
	local bbPlayer bbP, bbO;
	local int Which;
	
	bbP = bbPlayer(Owner);
	
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	If ( Other != Owner && Other!=Instigator && Other.Owner != Owner  && PlasmaSphere(Other)==None )
	{
		if ( Other.bIsPawn )
		{
			bHitPawn = true;
			bExploded = !Level.bHighDetailMode || Level.bDropDetail;
		}
		if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
		{
			if (STM != None)
				STM.PlayerHit(Instigator, 9, False);	// 9 = Plasma Sphere
			Other.TakeDamage( Damage, instigator, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType);	
			if (STM != None)
				STM.PlayerClear();
		}
		
		if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client && !IsA('NN_PlasmaSphereOwnerHidden'))
		{
			NN_HitOther = Other;
			bbO = bbPlayer(Other);
			
			if (bbO == None)
				Which = 0;
			else if (bbP.PlayerReplicationInfo.Team == bbO.PlayerReplicationInfo.Team)
				Which = 1;
			else
				Which = 2;
			
			bbP.xxNN_TakeDamage(Other, class'PulseGun', Damage, Instigator, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType, zzNN_ProjIndex, 0, Which);
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, MomentumTransfer*Vector(Rotation));
		}
		Explode(HitLocation, vect(0,0,1));
	}
}

simulated function HitWall (vector HitNormal, actor Wall)
{
	//if (Level.NetMode == NM_Client && Wall.IsA('Mover'))
	//	bbPlayer(Owner).xxMover_TakeDamage(Mover(Wall), Damage, Pawn(Owner), Location, MomentumTransfer*Vector(Rotation), MyDamageType);
	
	Super.HitWall(HitNormal, Wall);
}

defaultproperties {
}
