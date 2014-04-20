class NN_UTChunkOwnerHidden extends ST_UTChunk;

var bool bAlreadyHidden;
var float NN_OwnerPing, NN_EndAccelTime;

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
			bAlreadyHidden = True;
			Destroy();
			return;
		} else if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
			bAlreadyHidden = True;
			if ( !Region.Zone.bWaterZone )
				Trail = Spawn(class'ChunkTrail',self);
			SetTimer(0.1, true);
		}
		
		if (NN_OwnerPing > 0)
		{
			if (NN_EndAccelTime == 0)
			{
			}
			else if (Level.TimeSeconds > NN_EndAccelTime)
			{
				Velocity = Velocity / 2;
				NN_OwnerPing = 0;
			}
		}
		
	}
	
}

simulated function PostBeginPlay()
{
	local rotator RandRot;
	local Pawn P;
	
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
		
	if ( Role == ROLE_Authority )
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}
	
	RandRot = Rotation;
	RandRot.Pitch += R2 * 2000 - 1000;
	RandRot.Yaw += R3 * 2000 - 1000;
	RandRot.Roll += R4 * 2000 - 1000;

	if (Level.NetMode == NM_Client && NN_OwnerPing > 0)
	{
		Velocity = Vector(RandRot) * (Speed + (R5 * 200 - 100)) * 2;
		NN_EndAccelTime = Level.TimeSeconds + NN_OwnerPing * Level.TimeDilation / 1000;
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (PlayerPawn(P) != None && Viewport(PlayerPawn(P).Player) != None)
				NN_EndAccelTime += P.PlayerReplicationInfo.Ping * Level.TimeDilation / 1000;
	}
	else
	{
		Velocity = Vector(RandRot) * (Speed + (R5 * 200 - 100));
	}
	
	if (Region.zone.bWaterZone)
		Velocity *= 0.65;
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( (Chunk(Other) == None) && ((Physics == PHYS_Falling) || (Other != Instigator)) && Other.Owner != Owner)
	{
		speed = VSize(Velocity);
		If ( speed > 200 )
		{
			if ( Role == ROLE_Authority )
			{
				Chunkie.HitSomething(Self, Other);
				if (bbPlayer(Owner) == None || !bbPlayer(Owner).bNewNet)
					Other.TakeDamage(damage, instigator,HitLocation,
						(MomentumTransfer * Velocity/speed), MyDamageType );
				Chunkie.EndHit();
				if ( R1 < 0.5 )
					PlayOwnedSound(Sound 'ChunkHit',, 4.0,,200);
			}
		}
		Destroy();
	}
}

simulated function NewProcessTouch (Actor Other, vector HitLocation)
{
	if ( (Chunk(Other) == None) && ((Physics == PHYS_Falling) || (Other != Instigator)))
	{
		speed = VSize(Velocity);
		If ( speed > 200 )
		{
			if ( Role == ROLE_Authority )
			{
				Chunkie.HitSomething(Self, Other);
				if (bbPlayer(Owner) == None || !bbPlayer(Owner).bNewNet)
					Other.TakeDamage(damage, instigator,HitLocation,
						(MomentumTransfer * Velocity/speed), MyDamageType );
				Chunkie.EndHit();
				if ( R1 < 0.5 )
					PlayOwnedSound(Sound 'ChunkHit',, 4.0,,200);
			}
		}
	}
}

simulated function HitWall( vector HitNormal, actor Wall )
{
	if (Level.NetMode == NM_Client && NN_OwnerPing > 0) {
		Velocity = Velocity / 2;
		NN_OwnerPing = 0;
	}
	
	if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
	{
		if ( Level.NetMode != NM_Client )
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
				DoSmallSpark(Location+HitNormal*5, rotator(HitNormal));
			else
				DoWallCrack(Location, rotator(HitNormal));
		}
	}
	Velocity = 0.8*(( Velocity dot HitNormal ) * HitNormal * (-1.8 + R7*0.8) + Velocity);   // Reflect off Wall w/damping
	SetRotation(rotator(Velocity));
	speed = VSize(Velocity);
	if ( speed > 100 && Role == ROLE_Authority ) 
	{
		MakeNoise(0.3);
		if (R8 < 0.33)
			PlayOwnedSound(sound 'Hit1', SLOT_Misc,0.6,,1000);
		else if (R8 < 0.66)
			PlayOwnedSound(sound 'Hit3', SLOT_Misc,0.6,,1000);
		else
			PlayOwnedSound(sound 'Hit5', SLOT_Misc,0.6,,1000);
	}
}

simulated function DoSmallSpark(vector Loc, rotator Tater)
{
	local Pawn P;
	local SmallSpark s;

	if (RemoteRole < ROLE_Authority)
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (P != Owner) {
				s = Spawn(Class'SmallSpark',P,, Loc, Tater);
				s.RemoteRole = ROLE_None;
				s.bOnlyOwnerSee = True;
			}
}

simulated function DoWallCrack(vector Loc, rotator Tater)
{
	local Pawn P;
	local WallCrack s;
	
	if (RemoteRole < ROLE_Authority)
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (P != Owner) {
				s = Spawn(class'WallCrack',P,,Loc, Tater);
				s.bOnlyOwnerSee = True;
			}
}

defaultproperties {
	bOwnerNoSee=True
}

