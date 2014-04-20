class NN_FlakSlugOwnerHidden extends ST_FlakSlug;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None)
	{	
		if (Level.NetMode == NM_Client) {
			SpawnSound = None;
			ImpactSound = None;
			Mesh = None;
			ExplosionDecal = None;
			AmbientSound = None;
			AmbientGlow = 0;
			LightType = LT_None;
			SetCollisionSize(0, 0);
			Destroy();
		}
		else if ( !Region.Zone.bWaterZone && (Level.NetMode != NM_DedicatedServer) )
			Trail = Spawn(class'ChunkTrail',self);
			
		bAlreadyHidden = True;
	}
}

simulated function PostBeginPlay()
{
	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}
	
	Velocity = Vector(Rotation) * Speed;     
	initialDir = Velocity;
	Velocity.z += 200; 
	initialDir = Velocity;
	if ( Level.bHighDetailMode  && !Level.bDropDetail ) 
		SetTimer(0.04,True);
	else 
		SetTimer(0.25,True);
}

function ProcessTouch (Actor Other, vector HitLocation)
{
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( Other != instigator && Other.Owner != Owner ) 
		NewExplode(HitLocation,Normal(HitLocation-Other.Location), Other.IsA('Pawn'));
}

function NewExplode(vector HitLocation, vector HitNormal, bool bDirect)
{
	local vector start;
	local bbPlayer bbP;
	local ST_UTChunkInfo CI;
	local ST_UTChunk Proj;
	local int ProjIndex;
	
	bbP = bbPlayer(Owner);
	
	if (STM != None)
		STM.PlayerHit(Instigator, 15, bDirect);		// 15 = Flak Slug
	//Log(Class.Name$" (NewExplode) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (bbP == None || !bbP.bNewNet)
		HurtRadius(damage, 150, 'FlakDeath', MomentumTransfer, HitLocation);
	if (STM != None)
		STM.PlayerClear();				// Damage is given now.
	start = Location + 10 * HitNormal;
	CI = Spawn(Class'ST_UTChunkInfo', Instigator);
	CI.STM = STM;
	Spawn( class'NN_ut_FlameExplosionOwnerHidden',Owner,,Start);
	
	Proj = Spawn( class 'NN_UTChunk2OwnerHidden',Owner, '', Start);
	if (bbP != None)
	{
		ProjIndex = bbP.xxNN_AddProj(Proj);
		Proj.zzNN_ProjIndex = ProjIndex;
	}
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'NN_UTChunk3OwnerHidden',Owner, '', Start);
	if (bbP != None)
	{
		ProjIndex = bbP.xxNN_AddProj(Proj);
		Proj.zzNN_ProjIndex = ProjIndex;
	}
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'NN_UTChunk4OwnerHidden',Owner, '', Start);
	if (bbP != None)
	{
		ProjIndex = bbP.xxNN_AddProj(Proj);
		Proj.zzNN_ProjIndex = ProjIndex;
	}
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'NN_UTChunk1OwnerHidden',Owner, '', Start);
	if (bbP != None)
	{
		ProjIndex = bbP.xxNN_AddProj(Proj);
		Proj.zzNN_ProjIndex = ProjIndex;
	}
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'NN_UTChunk2OwnerHidden',Owner, '', Start);
	if (bbP != None)
	{
		ProjIndex = bbP.xxNN_AddProj(Proj);
		Proj.zzNN_ProjIndex = ProjIndex;
	}
	CI.AddChunk(Proj);
	
 	Destroy();
}

function Explode(vector HitLocation, vector HitNormal)
{
	if (bDeleteMe)
		return;
	NewExplode(HitLocation, HitNormal, False);
}

function Landed( vector HitNormal )
{
	local DirectionalBlast D;

	if ( Level.NetMode != NM_DedicatedServer )
	{
		D = Spawn(class'NN_DirectionalBlastOwnerHidden',Owner);
		if ( D != None )
			D.DirectionalAttach(initialDir, HitNormal);
	}
	Explode(Location,HitNormal);
}

function HitWall (vector HitNormal, actor Wall)
{
	local DirectionalBlast D;

	if ( Level.NetMode != NM_DedicatedServer && !bNetOwner )
	{
		D = Spawn(class'NN_DirectionalBlastOwnerHidden',Owner);
		if ( D != None )
			D.DirectionalAttach(initialDir, HitNormal);
	}
	
	if ( Role == ROLE_Authority )
	{
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), '');

		MakeNoise(1.0);
	}
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) && !bNetOwner )
		Spawn(ExplosionDecal,self,,Location, rotator(HitNormal));
}

function Timer()
{
	local ut_SpriteSmokePuff s;

	initialDir = Velocity;
	if (Level.NetMode!=NM_DedicatedServer && !bNetOwner) 
	{
		s = Spawn(class'NN_UT_SpriteSmokePuffOwnerHidden');
		s.RemoteRole = ROLE_None;
	}	
	if ( Level.bDropDetail )
		SetTimer(0.25,True);
	else if ( Level.bHighDetailMode )
		SetTimer(0.04,True);
}

defaultproperties {
	bOwnerNoSee=True
}
