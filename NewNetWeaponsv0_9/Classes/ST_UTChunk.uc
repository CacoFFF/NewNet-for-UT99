// ===============================================================
// Stats.ST_UTChunk: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_UTChunk extends UTChunk;

var ST_Mutator STM;
var ST_UTChunkInfo Chunkie;
var int ChunkIndex;
var float R1, R2, R3, R4, R5, R6, R7, R8;
var actor NN_HitOther;
var int zzNN_ProjIndex;
var float BirthTime;
var bool bHitWall;

replication
{
	reliable if ( Role == ROLE_Authority )
		R1, R2, R3, R4, R5, R6, R7, R8;
}

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

simulated function PostBeginPlay()
{
	local rotator RandRot;
	
	BirthTime = Level.TimeSeconds;
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
	
	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( !Region.Zone.bWaterZone )
			Trail = Spawn(class'ChunkTrail',self);
		SetTimer(0.1, true);
	}

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
		RandRot = Rotation;
		RandRot.Pitch += R2 * 2000 - 1000;
		RandRot.Yaw += R3 * 2000 - 1000;
		RandRot.Roll += R4 * 2000 - 1000;
		Velocity = Vector(RandRot) * (Speed + (R5 * 200 - 100));
		if (Region.zone.bWaterZone)
			Velocity *= 0.65;
	}
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	local bbPlayer bbP;
	local int Dmg;
	
	bbP = bbPlayer(Owner);
	
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( (Chunk(Other) == None) && ((Physics == PHYS_Falling) || (Other != Instigator || bHitWall)) && (Other != Owner && Other.Owner != Owner || bHitWall) )
	{
		speed = VSize(Velocity);
		If ( speed > 200 )
		{
			//if (Level.TimeSeconds - BirthTime > 0.7)
			//	Dmg = Damage / (0.3 + Level.TimeSeconds - BirthTime);
			//else
				Dmg = Damage;
			
			if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client && !IsA('NN_UTChunkOwnerHidden'))
			{
				NN_HitOther = Other;
				bbP.xxNN_TakeDamage(Other, class'UT_FlakCannon', Dmg, Instigator, HitLocation, (MomentumTransfer * Velocity/speed), MyDamageType, zzNN_ProjIndex);
				bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, (MomentumTransfer * Velocity/speed));
			}
			
			if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
			{
				Chunkie.HitSomething(Self, Other);
				Other.TakeDamage(Dmg, instigator,HitLocation,
					(MomentumTransfer * Velocity/speed), MyDamageType );
				Chunkie.EndHit();
			}
			if ( R1 < 0.5 )
				PlaySound(Sound 'ChunkHit',, 4.0,,200);
		}
		Destroy();
	}
}

simulated function NN_Momentum( vector Momentum, vector HitLocation )
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_UTChunkOwnerHidden') || RemoteRole == ROLE_Authority )
		return;
	
	if (bbP.Physics == PHYS_None)
		bbP.SetMovementPhysics();
	if (bbP.Physics == PHYS_Walking)
		Momentum.Z = FMax(Momentum.Z, 0.4 * VSize(Momentum));
		
	Momentum = 0.6*Momentum/bbP.Mass;

	bbP.AddVelocity(Momentum);
}

simulated function HitWall( vector HitNormal, actor Wall )
{
	local float Rand;
	local SmallSpark s;

	if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
	{
		//if (Level.NetMode == NM_Client)
		//	bbPlayer(Owner).xxMover_TakeDamage(Mover(Wall), Damage, Pawn(Owner), Location, MomentumTransfer*Vector(Rotation), MyDamageType);
		//else
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
		Destroy();
		return;
	}
	if ( Physics != PHYS_Falling ) 
	{
		SetPhysics(PHYS_Falling);
		if ( !Level.bDropDetail && (Level.Netmode != NM_DedicatedServer) && !Region.Zone.bWaterZone ) 
		{
			if ( R6 < 0.5 )
			{
				s = Spawn(Class'SmallSpark',,,Location+HitNormal*5,rotator(HitNormal));
				s.RemoteRole = ROLE_None;
			}
			else
				Spawn(class'WallCrack',,,Location, rotator(HitNormal));
		}
	}
	Velocity = 0.8*(( Velocity dot HitNormal ) * HitNormal * (-1.8 + R7*0.8) + Velocity);   // Reflect off Wall w/damping
	SetRotation(rotator(Velocity));
	speed = VSize(Velocity);
	if ( speed > 100 ) 
	{
		MakeNoise(0.3);
		Rand = R8;
		if (Rand < 0.33)	PlaySound(sound 'Hit1', SLOT_Misc,0.6,,1000);	
		else if (Rand < 0.66) PlaySound(sound 'Hit3', SLOT_Misc,0.6,,1000);
		else PlaySound(sound 'Hit5', SLOT_Misc,0.6,,1000);
	}
	bHitWall = true;
}

defaultproperties {
    LifeSpan=2.900000
}
