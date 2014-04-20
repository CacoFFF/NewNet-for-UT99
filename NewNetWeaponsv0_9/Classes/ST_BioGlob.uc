// ===============================================================
// UTPureStats7A.ST_BioGlob: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_BioGlob extends ST_UT_BioGel;

var int NumSplash;
var vector SpawnPoint;

function vector GetVRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return vect(0,0,0);
	
	bbP.zzVRVI++;
	if (bbP.zzVRVI == bbP.VRVI_length)
		bbP.zzVRVI = 0;
	return bbP.GetVRV(bbP.zzVRVI)/10000;
}

simulated function PreBeginPlay()
{
	if (bbPlayer(Owner) != None)
		bbPlayer(Owner).zzNN_VRVI = bbPlayer(Owner).zzVRVI;
	
	Super.PreBeginPlay();
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{ 
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( Other.IsA('ST_UT_BioGel') || Other == Owner || Other.Owner == Owner )
			return;
		if ( Pawn(Other)!=Instigator || bOnGround) 
			Global.Timer(); 
			
		NN_HitOther = Other;
		if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client && !bOwnerNoSee)
		{
			//bbP.xxNN_TakeDamage(Other, class'UT_BioRifle', damage * Drawscale, Instigator, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType, zzNN_ProjIndex);
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, Normal(HitLocation - Other.Location));
		}
	}
	
	simulated function HitWall( vector HitNormal, actor Wall )
	{
		SetPhysics(PHYS_None);		
		MakeNoise(1);	
		bOnGround = True;
		PlaySound(ImpactSound);	
		SetWall(HitNormal, Wall);
		if ( DrawScale > 1 )
			NumSplash = int(2 * DrawScale) - 1;
		SpawnPoint = Location + 5 * HitNormal;
		DrawScale= FMin(DrawScale, 3.0);
		if ( NumSplash > 0 )
		{
			SpawnSplash();
			if ( NumSplash > 0 )
				SpawnSplash();
		}
		GoToState('OnSurface');
	}
}

simulated function SpawnSplash()
{
	local vector Start, V1;
	local ST_BioSplash BS;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if (bbP != None)
		V1 = GetVRV();
	else
		V1 = VRand();

	NumSplash--;
	Start = SpawnPoint + 4 * V1; 
	BS = Spawn(class'ST_BioSplash',Owner,,Start,Rotator(Start - Location));
	BS.zzNN_ProjIndex = bbP.xxNN_AddProj(BS);
}

state OnSurface
{
	simulated function Tick(float DeltaTime)
	{
		if ( NumSplash > 0 )
		{
			SpawnSplash();
			if ( NumSplash > 0 )
				SpawnSplash();
			else
				Disable('Tick');
		}
		else
			Disable('Tick');
	}

	simulated function ProcessTouch (Actor Other, vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( Other.IsA('ST_UT_BioGel') && Other.Owner == Owner )
			return;
		GotoState('Exploding');
	}
}

defaultproperties
{
     speed=700.000000
     Damage=75.000000
     MomentumTransfer=30000
}