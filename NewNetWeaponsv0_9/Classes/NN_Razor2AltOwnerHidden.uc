class NN_Razor2AltOwnerHidden extends ST_Razor2Alt;

var bool bAlreadyHidden;
var float NN_OwnerPing, NN_EndAccelTime;
var bool bSpedUp, bSlowed;

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
			ExplosionDecal = None;
			SpawnSound = None;
			bAlreadyHidden = True;
			Destroy();
			return;
		}
		
		if (NN_OwnerPing > 0)
		{
			if (NN_EndAccelTime == 0)
			{
			}
			else if (bSpedUp && Level.TimeSeconds > NN_EndAccelTime && !bSlowed)
			{
				Velocity = Velocity / 2;
				NN_OwnerPing = 0;
				bSlowed = true;
			}
		}
		
	}
	
}

auto state Flying
{
	simulated function SetUp()
	{
		local vector X;
		local Pawn P;
		
		X = vector(Rotation);
		
		if (Level.NetMode == NM_Client && NN_OwnerPing > 0)
		{
			bSpedUp = true;
			Velocity = Speed * X * 2;     // Impart ONLY forward vel
			NN_EndAccelTime = Level.TimeSeconds + NN_OwnerPing * Level.TimeDilation / 1000;
			for (P = Level.PawnList; P != None; P = P.NextPawn)
				if (PlayerPawn(P) != None && Viewport(PlayerPawn(P).Player) != None)
					NN_EndAccelTime += P.PlayerReplicationInfo.Ping * Level.TimeDilation / 1000;
		}
		else
		{
			Velocity = Speed * X;     // Impart ONLY forward vel
		}
		if (Instigator != None && Instigator.HeadRegion.Zone.bWaterZone)
			bHitWater = True;
	}
	
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		local RipperPulse s;
		
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( Other != Instigator && Other.Owner != Owner ) 
		{
			if ( Role == ROLE_Authority && !bbPlayer(Owner).bNewNet )
			{
				if (STM != None)
					STM.PlayerHit(Instigator, 12, Other.IsA('Pawn'));	// 12 = Ripper Secondary, Direct if Pawn
				if (bbPlayer(Owner) == None || !bbPlayer(Owner).bNewNet)
					Other.TakeDamage(damage, instigator,HitLocation,
						(MomentumTransfer * Normal(Velocity)), MyDamageType );
				if (STM != None)
					STM.PlayerClear();
			}
			else
			{
				s = spawn(class'NN_RipperPulseOwnerHidden',Owner,,HitLocation);	
				s.RemoteRole = ROLE_None;
			}
			MakeNoise(1.0);
 			Destroy();
		}
	}

	simulated function Explode(vector HitLocation, vector HitNormal)
	{
		local RipperPulse s;
		
		if (bDeleteMe)
			return;
		if (Role == ROLE_Authority)
			BlowUp(HitLocation);
		else
		{
			s = spawn(class'NN_RipperPulseOwnerHidden',Owner,,HitLocation + HitNormal*16);
			s.RemoteRole = ROLE_None;
		}
		Destroy();
	}

	function BlowUp(vector HitLocation)
	{
		//Log(Class.Name$" (BlowUp) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
		if (!bbPlayer(Owner).bNewNet)
			OldBlowUp(HitLocation);
		MakeNoise(1.0);
	}
}

function OldBlowUp(vector HitLocation)
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;

	if( bHurtEntry )
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors( class 'Actor', Victims, 180, HitLocation )
	{
		if( Victims != self )
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			dir.Z = FMin(0.45, dir.Z); 
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/180);
			Victims.TakeDamage
			(
				damageScale * Damage,
				Instigator, 
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				damageScale * MomentumTransfer * dir,
				MyDamageType
			);
		} 
	}
	bHurtEntry = false;
	MakeNoise(1.0);
}

function NewProcessTouch (Actor Other, Vector HitLocation)
{
	local RipperPulse s;

	if ( Other != Instigator && Other != Owner ) 
	{
		if ( Role == ROLE_Authority )
		{
			if (bbPlayer(Owner).bNewNet)
				return;
			if (STM != None)
				STM.PlayerHit(Instigator, 12, Other.IsA('Pawn'));	// 12 = Ripper Secondary, Direct if Pawn
			Other.TakeDamage(damage, instigator,HitLocation,
				(MomentumTransfer * Normal(Velocity)), MyDamageType );
			if (STM != None)
				STM.PlayerClear();
			MakeNoise(1.0);
		}
		else
		{
			s = spawn(class'NN_RipperPulseOwnerHidden',Owner,,HitLocation);	
			s.RemoteRole = ROLE_None;
		}
	}
}

defaultproperties {
	bOwnerNoSee=True
}