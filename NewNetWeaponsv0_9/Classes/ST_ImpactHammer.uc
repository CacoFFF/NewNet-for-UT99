// ===============================================================
// Stats.ST_ImpactHammer: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_ImpactHammer extends ImpactHammer;

var ST_Mutator STM;
var bool bNewNet;		// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var float ReleaseFireTime, ReleaseAltFireTime;
var float ChargeModifier;

replication
{
	reliable if (Role < ROLE_Authority)
		ServerFiring;
}

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

function bool HandlePickupQuery( inventory Item )
{
	local bbPlayer bbP;
	
	if (Inventory == None)
		return Super.HandlePickupQuery(Item);
	
	bbP = bbPlayer(Inventory.Owner);
	
	if ( bbP != None && Level.TimeSeconds - bbP.zzThrownTime < 0.2 )
		return true;

	return Super.HandlePickupQuery(Item);
}

simulated function RenderOverlays(Canvas Canvas)
{
	local bbPlayer bbP;
	
	Super.RenderOverlays(Canvas);
	yModInit();
	
	bbP = bbPlayer(Owner);
	if (bNewNet && Role < ROLE_Authority && bbP != None)
	{
		if (bbP.bFire != 0 && !IsInState('ClientFiring'))
			ClientFire(1);
		else if (bbP.bAltFire != 0 && !IsInState('ClientAltFiring'))
			ClientAltFire(1);
	}
	
	if (ReleaseFireTime > 0 && Level.TimeSeconds > ReleaseFireTime)
	{
		ReleaseFireTime = 0;
		NN_TraceFire();
		PlayFiring();
		GoToState('ClientFireBlast');
	}
	else if (ReleaseAltFireTime > 0 && Level.TimeSeconds > ReleaseAltFireTime)
	{
		ReleaseAltFireTime = 0;
		NN_TraceAltFire();
		GoToState('ClientAltFiring');
	}
}

simulated function yModInit()
{
	if (bbPlayer(Owner) != None && Owner.Role == ROLE_AutonomousProxy)
		GV = bbPlayer(Owner).zzViewRotation;
	
	if (PlayerPawn(Owner) == None)
		return;
		
	yMod = PlayerPawn(Owner).Handedness;
	if (yMod != 2.0)
		yMod *= Default.FireOffset.Y;
	else
		yMod = 0;

	CDO = CalcDrawOffset();
}

simulated function bool ClientFire( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		yModInit();
		
		Instigator = Pawn(Owner);
		bPointing=True;
		bCanClientFire = true;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		GoToState('ClientFiring');
		ServerFiring();
	}
	
	return Super.ClientFire(Value);
}

function ServerFiring()
{
	bPointing=True;
	bCanClientFire = true;
	GoToState('Firing');
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		yModInit();
		
		Instigator = Pawn(Owner);
		bPointing=True;
		bCanClientFire = true;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		if (ReleaseAltFireTime == 0)
			ReleaseAltFireTime = Level.TimeSeconds + 0.02;
	}
	
	return Super.ClientAltFire(Value);
}

function Fire( float Value )
{
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	bPointing=True;
	bCanClientFire = true;
	ClientFire(Value);
	if (!bNewNet)
	{
		Pawn(Owner).PlayRecoil(FiringSpeed);
	}
	GoToState('Firing');
}

function AltFire( float Value )
{
	if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}
	bPointing=True;
	bCanClientFire = true;
	ClientAltFire(value);
	if (!bNewNet)
	{
		Pawn(Owner).PlayRecoil(FiringSpeed);
	}
	TraceAltFire();
	GoToState('AltFiring');
}

State ClientActive
{
	simulated function bool ClientFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientFire(Value);
		bForceFire = bbPlayer(Owner) == None || !bbPlayer(Owner).ClientCannotShoot();
		return bForceFire;
	}

	simulated function bool ClientAltFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(Value);
		bForceAltFire = bbPlayer(Owner) == None || !bbPlayer(Owner).ClientCannotShoot();
		return bForceAltFire;
	}
	
	simulated function AnimEnd()
	{
		if ( Owner == None )
		{
			Global.AnimEnd();
			GotoState('');
		}
		else if ( Owner.IsA('TournamentPlayer') 
			&& (TournamentPlayer(Owner).PendingWeapon != None || TournamentPlayer(Owner).ClientPending != None) )
			GotoState('ClientDown');
		else if ( bWeaponUp )
		{
			if ( (bForceFire || (PlayerPawn(Owner).bFire != 0)) && Global.ClientFire(1) )
				return;
			else if ( (bForceAltFire || (PlayerPawn(Owner).bAltFire != 0)) && Global.ClientAltFire(1) )
				return;
			PlayIdleAnim();
			GotoState('');
		}
		else
		{
			PlayPostSelect();
			bWeaponUp = true;
		}
	}
}

state ClientFiring
{
	simulated function bool ClientFire( float Value ){}
	simulated function Tick( float DeltaTime )
	{
		local Pawn P;
		local Rotator EnemyRot;
		local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X, Y, Z;
		local actor HitActor;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		if ( bChangeWeapon )
			GotoState('DownWeapon');
			
		P = Pawn(Owner);
		if ( P == None ) 
		{
			AmbientSound = None;
			GotoState('');
			return;
		}
		else if( P.bFire==0 ) 
		{
			if (ReleaseFireTime == 0)
				ReleaseFireTime = Level.TimeSeconds + 0.02;
			return;
		}

		ChargeSize += 0.75 * DeltaTime;

		Count += DeltaTime;
		if ( Count > 0.2 )
		{
			Count = 0;
			Owner.MakeNoise(1.0);
		}
		if (ChargeSize > 1) 
		{
			if ( !P.IsA('PlayerPawn') && (P.Enemy != None) )
			{
				EnemyRot = Rotator(P.Enemy.Location - P.Location);
				EnemyRot.Yaw = EnemyRot.Yaw & 65535;
				if ( (abs(EnemyRot.Yaw - (P.Rotation.Yaw & 65535)) > 8000)
					&& (abs(EnemyRot.Yaw - (P.Rotation.Yaw & 65535)) < 57535) )
					return;
				GetAxes(EnemyRot,X,Y,Z);
			}
			else
				GetAxes(P.ViewRotation, X, Y, Z);
			StartTrace = P.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			if ( (Level.NetMode == NM_Standalone) && P.IsA('PlayerPawn') )
				EndTrace = StartTrace + 25 * X; 
			else
				EndTrace = StartTrace + 60 * X; 
			
			bbP = bbPlayer(Owner);
			HitActor = bbP.NN_TraceShot(HitLocation, HitNormal, EndTrace, StartTrace, P);
			if ( (HitActor != None) && (HitActor.DrawType == DT_Mesh) )
			{
				NN_ProcessTraceHit(HitActor, HitLocation, HitNormal, vector(AdjustedAim), Y, Z, yMod);
				PlayFiring();
				GoToState('ClientFireBlast');
				
				if (HitActor.IsA('Pawn'))
					HitDiff = HitLocation - HitActor.Location;
				
				bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, HitActor, HitLocation, HitDiff, true);
				if (HitActor == bbP.zzClientTTarget)
					bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 66000.0 * ChargeSize * X, MyDamageType);
			}
		}
	}

	simulated function BeginState()
	{
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
		ChargeSize = 0.0;
		Count = 0.0;
	}

	simulated function EndState()
	{
		Super.EndState();
		if (Owner.IsA('Bot'))
			return;
		AmbientSound = None;
	}

Begin:
	if (!Owner.IsA('Bot'))
	{
		FinishAnim();
		AmbientSound = TensionSound;
		SoundVolume = 255*Pawn(Owner).SoundDampening;		
		LoopAnim('Shake', 0.9);
	}
}

state ClientAltFiring
{
	simulated function bool ClientFire(float F) 
	{
	}

	simulated function bool ClientAltFire(float F) 
	{
	}

	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		TweenAnim('Still', 1.0);
		ClientFinish();
	}

Begin:
	if (!Owner.IsA('Bot'))
		Sleep(0.0);
}

simulated function ClientWeaponEvent(name EventType)
{
	if (Owner.IsA('Bot'))
	{
		Super.ClientWeaponEvent(EventType);
		return;
	}
	if ( EventType == 'FireBlast' && !bNewNet )
	{
		PlayFiring();
		GotoState('ClientFireBlast');
	}
}

simulated function ClientFinish()
{
	local Pawn PawnOwner;
	local bool bForce, bForceAlt;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return;
	
	bbP = bbPlayer(Owner);
	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;
	

	if ( bChangeWeapon )
	{
		GotoState('DownWeapon');
		return;
	}

	PawnOwner = Pawn(Owner);
	if ( PawnOwner == None )
		return;
		
	if ( ((AmmoType != None) && (AmmoType.AmmoAmount<=0)) || (PawnOwner.Weapon != self) )
		GotoState('Idle');
	else if ( (PawnOwner.bFire!=0) || bForce )
		Global.ClientFire(0);
	else if ( (PawnOwner.bAltFire!=0) || bForceAlt )
		Global.ClientAltFire(0);
	else 
		GotoState('Idle');
}

state ClientFireBlast
{
	simulated function bool ClientFire( float Value ){}
	
Begin:
	if (!Owner.IsA('Bot'))
	{
		if ( (Level.NetMode != NM_Standalone) && Owner.IsA('PlayerPawn') 
			&& (ViewPort(PlayerPawn(Owner).Player) == None) )
			PlayerPawn(Owner).ClientWeaponEvent('FireBlast');
		FinishAnim();
		ClientFinish();
	}
}

State ClientDown
{
	simulated function AnimEnd()
	{
		local TournamentPlayer T;
		
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}

		T = TournamentPlayer(Owner);
		if ( T != None )
		{
			if ( (T.ClientPending != None) 
				&& (T.ClientPending.Owner == Owner) )
			{
				T.Weapon = T.ClientPending;
				T.Weapon.GotoState('ClientActive');
				T.ClientPending = None;
				GotoState('');
			}
			else
			{
				T.NeedActivate();
			}
		}
	}

	simulated function BeginState();
}

simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local actor Other;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return;

	bbP = bbPlayer(Owner);
	
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z;
	EndTrace = StartTrace + 120.0 * vector(GV); 
	if (bbP != None)
		Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,Pawn(Owner));
	NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z,yMod);
	
	if (Other != None && Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	if (bbP != None)
	{
		bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
		if (Other == bbP.zzClientTTarget && bbP.zzClientTTarget != None)
			bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 66000.0 * ChargeSize * X, MyDamageType);
	}
}

simulated function NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z, float yMod)
{
	local Pawn PawnOwner;
	
	if (Owner.IsA('Bot'))
		return;

	PawnOwner = Pawn(Owner);

	if ( (Other == None) || (Other == Owner) || (Other == self) || (Owner == None))
		return;

	ChargeSize = FMin(ChargeSize, 1.5);
	if ( (Other == Level) || Other.IsA('Mover') )
	{
		ChargeSize = FMax(ChargeSize, 1.0);
		if ( VSize(HitLocation - Owner.Location) < 80 )
			Spawn(class'ImpactMark',,, HitLocation+HitNormal, Rotator(HitNormal));
		NN_Momentum( -69000.0 * ChargeSize * X, HitLocation );
		//if (Other.IsA('Mover'))
		//	bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), 36, Pawn(Owner), HitLocation, -69000.0 * ChargeSize * X, MyDamageType);
	}
	if ( Other != Level )
	{
		if ( Other.bIsPawn && (VSize(HitLocation - Owner.Location) > 90) )
			return;
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
	}
}

simulated function NN_Momentum( vector Momentum, vector HitLocation )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return;
	
	bbP = bbPlayer(Owner);
	
	if ( Level.NetMode != NM_Client || bbP == None )
		return;
	
	if (bbP.Physics == PHYS_None)
		bbP.SetMovementPhysics();
	if (bbP.Physics == PHYS_Walking)
		Momentum.Z = FMax(Momentum.Z, 0.4 * VSize(Momentum));
		
	Momentum = 0.6*Momentum/bbP.Mass;

	bbP.AddVelocity(Momentum);
}

simulated function NN_TraceAltFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local actor Other;
	local Projectile P;
	local float speed;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return;

	bbP = bbPlayer(Owner);
	
	GetAxes(GV, X, Y, Z);
	StartTrace = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
	EndTrace = StartTrace + 180 * vector(GV); 
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,Pawn(Owner));
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	NN_ProcessAltTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z,yMod);
	bbP.xxNN_AltFire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff);

	// push aside projectiles
	ForEach VisibleCollidingActors(class'Projectile', P, 550, Owner.Location)
		if ( ((P.Physics == PHYS_Projectile) || (P.Physics == PHYS_Falling))
			&& (Normal(P.Location - Owner.Location) Dot X) > 0.9 )
		{
			P.speed = VSize(P.Velocity);
			if ( P.Velocity Dot Y > 0 )
				P.Velocity = P.Speed * Normal(P.Velocity + (750 - VSize(P.Location - Owner.Location)) * Y);
			else	
				P.Velocity = P.Speed * Normal(P.Velocity - (750 - VSize(P.Location - Owner.Location)) * Y);
		}
}

simulated function NN_ProcessAltTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z, float yMod)
{
	local vector realLoc;
	local float scale;
	
	if (Owner.IsA('Bot'))
		return;

	if ( (Other == None) || (Other == Owner) || (Other == self) || (Owner == None) )
		return;

	realLoc = Owner.Location + CDO;
	scale = VSize(realLoc - HitLocation)/180;
	if ( (Other == Level) || Other.IsA('Mover') )
	{
		NN_Momentum(-40000.0 * X * scale, HitLocation);
		//if (Other.IsA('Mover'))
		//	bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), 24 * scale, Pawn(Owner), HitLocation, -40000.0 * X * scale, MyDamageType);
	}
	else
	{
		//if (bNewNet)
		//	bbPlayer(Owner).xxNN_TakeDamage(Other, class'ImpactHammer', 20 * scale, Pawn(Owner), HitLocation, 30000.0 * X * scale, MyDamageType, -1);
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
	}
}

function TraceFire(float accuracy)
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local actor Other;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.TraceFire(accuracy);
		return;
	}
	
	if (accuracy == 0)
		return;
	
	bbP = bbPlayer(Owner);

	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	if (bbP == None || !bNewNet)
		GetAxes(Pawn(owner).ViewRotation, X, Y, Z);
	else
		GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z; 
	if (accuracy == 2)
		AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, AimError, False, False);	
	EndTrace = StartTrace + 120.0 * vector(AdjustedAim);
	if (bbP == None || !bNewNet)
		Other = Pawn(Owner).TraceShot(HitLocation, HitNormal, EndTrace, StartTrace);
	else
		Other = bbP.zzNN_HitActor;
	ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim), Y, Z);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local Pawn PawnOwner;

	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}
	
	PawnOwner = Pawn(Owner);
	if (STM != None)
		STM.PlayerFire(PawnOwner, 1);			// 1 = Impact Hammer.

	if ( (Other == None) || (Other == Owner) || (Other == self) || (Owner == None))
		return;

	ChargeSize = FMin(ChargeSize, 1.5);
	if ( (Other == Level) || Other.IsA('Mover') )
	{
		ChargeSize = FMax(ChargeSize, 1.0);
		if ( VSize(HitLocation - Owner.Location) < 80 && (!bNewNet || (!bNetOwner && Level.NetMode != NM_DedicatedServer)) )
			Spawn(class'ImpactMark',,, HitLocation+HitNormal, Rotator(HitNormal));
		if (STM != None)
			STM.PlayerHit(PawnOwner, 1, False);	// 1 = Impact Hammer
		Owner.TakeDamage(36.0, PawnOwner, HitLocation, -69000.0 * ChargeSize * X, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}
	if ( Other != Level )
	{
		if ( Other.bIsPawn && (VSize(HitLocation - Owner.Location) > 90) && !bNewNet )
			return;
		if (STM != None)
			STM.PlayerHit(PawnOwner, 1, False);	// 1 = Impact Hammer
		if (bNewNet)
			Other.TakeDamage(60.0 * ChargeSize, PawnOwner, HitLocation, 66000.0 * ChargeModifier * ChargeSize * X, MyDamageType);
		else
			Other.TakeDamage(60.0 * ChargeSize, PawnOwner, HitLocation, 66000.0 * ChargeSize * X, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
		{
			if (bNewNet)
				spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner,,HitLocation+HitNormal*9);
			else
				spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
		}
	}
}

function ProcessAltTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local vector realLoc;
	local float scale;
	local Pawn PawnOwner;

	if (Owner.IsA('Bot'))
	{
		Super.ProcessAltTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}

	if ( (Other == None) || (Other == Owner) || (Other == self) || (Owner == None) )
		return;

	PawnOwner = Pawn(Owner);

	realLoc = Owner.Location + CalcDrawOffset();
	scale = VSize(realLoc - HitLocation)/180;
	if ( (Other == Level) || Other.IsA('Mover') )
	{
		if (STM != None)
			STM.PlayerHit(PawnOwner, 1, False);	// 1 = IH!
		Owner.TakeDamage(24.0 * scale, Pawn(Owner), HitLocation, -40000.0 * X * scale, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}
	else
	{
		if (STM != None)
			STM.PlayerHit(PawnOwner, 1, False);	// 1 = IH!
		Other.TakeDamage(20 * scale, Pawn(Owner), HitLocation, 30000.0 * X * scale, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
		{
			if (bNewNet)
				spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner,,HitLocation+HitNormal*9);
			else
				spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
		}
	}
}

simulated function SetSwitchPriority(pawn Other)
{	// Make sure "old" priorities are kept.
	local int i;
	local name temp, carried;

	if ( PlayerPawn(Other) != None )
	{
		for ( i=0; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++)
			if ( IsA(PlayerPawn(Other).WeaponPriority[i]) )		// <- The fix...
			{
				AutoSwitchPriority = i;
				return;
			}
		// else, register this weapon
		carried = 'ImpactHammer';
		for ( i=AutoSwitchPriority; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++ )
		{
			if ( PlayerPawn(Other).WeaponPriority[i] == '' )
			{
				PlayerPawn(Other).WeaponPriority[i] = carried;
				return;
			}
			else if ( i<ArrayCount(PlayerPawn(Other).WeaponPriority)-1 )
			{
				temp = PlayerPawn(Other).WeaponPriority[i];
				PlayerPawn(Other).WeaponPriority[i] = carried;
				carried = temp;
			}
		}
	}		
}

simulated function PlaySelect()
{
	bForceFire = false;
	bForceAltFire = false;
	bCanClientFire = false;
	if ( !IsAnimating() || (AnimSequence != 'Select') )
		PlayAnim('Select',1.15 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000,0.0);
	Owner.PlaySound(SelectSound, SLOT_Misc, Pawn(Owner).SoundDampening);	
}

simulated function TweenDown()
{
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
		PlayAnim('Down', 1.15 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
}

state Active
{
	function Fire(float F) 
	{
		if (Owner.IsA('Bot'))
		{
			Super.Fire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.Fire(F);
	}
	function AltFire(float F) 
	{
		if (Owner.IsA('Bot'))
		{
			Super.AltFire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.AltFire(F);
	}
}

defaultproperties
{
    bNewNet=True
    ChargeModifier=0.70
}