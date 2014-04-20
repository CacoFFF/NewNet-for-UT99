// ===============================================================
// Stats.ST_minigun2: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_minigun2 extends minigun2;

// Tickrate independant minigun.
//
// The orginal minigun used a loop where Sleep() decided when to fire next shot.
// The problem with Sleep() is that it will NOT trigger accurately enough, and also
// it changes accuracy when tickrate of server.
//
// Assuming a tickrate of 20, you have 1000/20 = 50ms (0.05 seconds) between each update.
// (complex: actually, the formula is 1000/20 * Level.TimeDilation, and UT's timedilation is 1.1,
//           which means the time between ticks is 0.055s, but in most my tests it is 0.054s,
//           which means (...) that UT triggers tick just before it overflows. I need to get someone to check UT source.)
//
// Here is some more proof of the "bad" performance of Sleep()
// Ratio 1.00 = "perfect", <1.0 = "reacts too slow", >1.0 = "reacts too fast"
//	Tickrate 20		delta
//	Sleep	Actual	Ratio	Tick
//	0.010	0.054	0.184	0.054	(Notice how deltaTick is 0.054, if I change Level.TimeDilation to 1.0, it gives me 0.049 instead)
//	0.020	0.054	0.369	0.054
//	0.030	0.054	0.554	0.054
//	0.040	0.054	0.739	0.054
//	0.050	0.054	0.924	0.054
//	0.060	0.054	1.109	0.054
//	0.070	0.054	1.294	0.054
//	0.080	0.054	1.479	0.054	<-- !!! 1.5 as many sleep will be performed. Meaning 0.08 is not 12.5/sec, but really 18.48!!!
//	0.090	0.108	0.832	0.054
//	0.100	0.108	0.924	0.054
//	0.110	0.108	1.017	0.054
//	0.120	0.108	1.109	0.054
//	0.120	0.108	1.202	0.054
//	0.140	0.162	0.863	0.054
//	0.150	0.162	0.924	0.054
//	0.160	0.162	0.986	0.054
//	0.170	0.162	1.047	0.054
//	0.180	0.162	0.109	0.054
//	0.190	0.216	0.878	0.054
//
// In order to try to fix this, I implement the bullet generation in Tick() instead of a Sleep() loop.
// To get correct values, I made a little util which simply checked how many shots/sec minigun fired when
// using Sleep() and different Tickrates.
//

var ST_Mutator STM;
var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var float FireInterval, NextFireInterval;

// For Special minigun
var int HitCounter;

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

function Fire( float Value )
{
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		SoundVolume = 255*Pawn(Owner).SoundDampening;
		bCanClientFire = true;
		bPointing=True;
		ShotAccuracy = 0.2;
		FireInterval = 0.120;		// Spinup
		NextFireInterval = 0.111;	// 8.0 shots/sec
		ClientFire(value);
		if (!bNewNet)
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
		}
		GotoState('NormalFire');
	}
	else GoToState('Idle');
}

function AltFire( float Value )
{
	if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		bPointing=True;
		bCanClientFire = true;
		ShotAccuracy = 0.95;
		FireInterval = 0.120;		// Spinup
		NextFireInterval = 0.111;	// Use Primary fire speed until completely spun up
		SoundVolume = 255*Pawn(Owner).SoundDampening;	
		ClientAltFire(value);
		if (!bNewNet)
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
		}
		GoToState('AltFiring');		
	}
	else GoToState('Idle');	
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

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			Pawn(Owner).PlayRecoil(FiringSpeed);
			bCanClientFire = true;
			bPointing=True;
			ShotAccuracy = 0.2;
			FireInterval = 0.120;		// Spinup
			NextFireInterval = 0.111;	// 8.0 shots/sec
			GotoState('ClientFiring');
		}
		else GoToState('Idle');
	}
	return Super.ClientFire(Value);
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
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			bPointing=True;
			bCanClientFire = true;
			ShotAccuracy = 0.95;
			FireInterval = 0.120;		// Spinup
			NextFireInterval = 0.111;	// Use Primary fire speed until completely spun up
			Pawn(Owner).PlayRecoil(FiringSpeed);
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			GoToState('ClientAltFiring');		
		}
		else GoToState('Idle');	
	}
	return Super.ClientAltFire(Value);
}

simulated function NN_GenerateBullet()
{
	if (Owner.IsA('Bot'))
		return;
    LightType = LT_Steady;
	bFiredShot = true;
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
	if ( AmmoType.AmmoAmount > 0 ) 
		NN_TraceFire(ShotAccuracy);
	else
		GotoState('ClientFinish');
}

simulated function NN_TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z, AimDir;
	local actor Other;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local float R1, R2;
	local int ClientFRVI;
    local MTracer MT;
	
	if (Owner.IsA('Bot'))
		return;
		
	yModInit();

	PawnOwner = Pawn(Owner);
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;
	
	ClientFRVI = bbP.zzNN_FRVI;
	R1 = NN_GetFRV();
	R2 = NN_GetFRV();
	
	if (bbP.bAltFire != 0)
		Accuracy = 0.95;
	else if (bbP.bFire != 0)
		Accuracy = 0.2;
	
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z; 
	//AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
	EndTrace = StartTrace + Accuracy * (R1 - 0.5 )* Y * 1000
		+ Accuracy * (R2 - 0.5 ) * Z * 1000;
	AimDir = vector(GV);
	EndTrace += (10000 * AimDir);
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	
	if (PawnOwner.bFire != 0)
		bbP.xxNN_TakeDamage(Other, class'Minigun2', 7, PawnOwner, HitLocation, 3500.0*X, MyDamageType, -1);
	else
		bbP.xxNN_TakeDamage(Other, class'Minigun2', 10, PawnOwner, HitLocation, 5000.0*X, MyDamageType, -1);
	/*
	if (PawnOwner.bFire != 0)
		bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, vect(0,0,0), false, ClientFRVI, Accuracy);
	else
		bbP.xxNN_AltFire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, vect(0,0,0), false, ClientFRVI, Accuracy);
	*/
	
	MT = Spawn(class'MTracer',,, StartTrace + 96 * AimDir,rotator(EndTrace - StartTrace));
	bbP.xxClientDemoFix(MT, class'MTracer', StartTrace + 96 * AimDir, MT.Velocity, MT.Acceleration, rotator(EndTrace - StartTrace));
	NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
}

simulated function float NN_GetFRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return 0;
	
	bbP.zzNN_FRVI++;
	if (bbP.zzNN_FRVI == bbP.FRVI_length)
		bbP.zzNN_FRVI = 0;
	return bbP.GetFRV(bbP.zzNN_FRVI);
}

simulated function NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	if (Owner.IsA('Bot'))
		return;
	if (Other == Level) 
	{
		Spawn(class'UT_LightWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxClientDemoFix(None, class'UT_LightWallHitEffect', HitLocation+HitNormal,,, Rotator(HitNormal));
	}
	else if ( (Other!=self) && (Other!=Owner) && (Other != None) ) 
	{
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9); 
	}
}

function float GetFRV()
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

// Original code did: Sleep(0.13)
// This would (depending on tickrate) get called on irregular intervals.
// According to a 20 tickrate server, this would result in about 6.667 shots/sec, 
// 1/6.667 = 0.15s between, therefore...
// Due to excessive whining, shots/sec is increased to 7.5
// 1/7.5 = 0.13s between.
// Due to more testing, I have now set fireinterval up to 8.0
// 1/8.0 = 0.111s between
state NormalFire
{
	function Tick( float DeltaTime )
	{
		local Pawn P;
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);

		if (P == None)
			return;
	
		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
//			Log("FireInterval"@FireInterval@"Next"@NextFireInterval);
			FireInterval += NextFireInterval;
			if (P.bAltFire == 0)
				GenerateBullet();
		}

		if	( bFiredShot && ((P.bFire==0) || bOutOfAmmo) ) 
			GoToState('FinishFire');
	}

	function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( AmbientSound == None )
			AmbientSound = FireSound;
		if ( Affector != None )
			Affector.FireEffect();
	}

Begin:
	if (Owner.IsA('Bot'))
	{
		Sleep(0.13);
		GenerateBullet();
		Goto('Begin');
	}
}

// Original code did: Sleep(0.08)
// This would (depending on tickrate) get called on irregular intervals.
// According to a 20 tickrate server, this would result in about 10.000 shots/sec, 
// 1/10.000 = 0.10s between, therefore...
// Due to excessive whining, shots/sec increased to 11
// 1/11 = 0.091s between
// Due to more testing, I have now increased shots/sec to 12.5
// 1/12.5 = 0.08s (look in AnimEnd)
state AltFiring
{
	function Tick( float DeltaTime )
	{
		local Pawn P;
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);

		if (P == None)
			return;

		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
//			Log("FireInterval"@FireInterval@"Next"@NextFireInterval);
			FireInterval += NextFireInterval;
			if (P.bFire == 0)
				GenerateBullet();
		}

		if	( bFiredShot && ((P.bAltFire==0) || bOutOfAmmo) ) 
			GoToState('FinishFire');
	}

	function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
		{	
			AmbientSound = AltFireSound;
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			LoopAnim('Shoot2',1.9);
			NextFireInterval = 0.08;	// 11.11 shots/sec ..12.5 shots/sec
		}
		else if ( AmbientSound == None )
			AmbientSound = FireSound;
		if ( Affector != None )
			Affector.FireEffect();
	}
Begin:
	if (Owner.IsA('Bot'))
	{
		Sleep(0.13);
		GenerateBullet();
		if ( AnimSequence == 'Shoot2' )
			Goto('FastShoot');
		Goto('Begin');
	}
FastShoot:
	if (Owner.IsA('Bot'))
	{
		Sleep(0.08);
		GenerateBullet();
		Goto('FastShoot');
	}
}

state ClientFiring
{
	simulated function bool ClientFire(float F) {}
	simulated function bool ClientAltFire(float F) {}

	simulated function Tick( float DeltaTime )
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);

		if (P == None)
			return;
	
		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
//			Log("FireInterval"@FireInterval@"Next"@NextFireInterval);
			FireInterval += NextFireInterval;
			if (P.bAltFire == 0)
				NN_GenerateBullet();
		}

		if	( bFiredShot && ((P.bFire==0) || bOutOfAmmo) ) 
			GoToState('ClientFinish');
	}
	
	simulated function EndState()
	{
		if (!Owner.IsA('Bot'))
			LightType = LT_None;
		Super.EndState();
	}
}

state ClientAltFiring
{
	simulated function bool ClientFire(float F) {}
	simulated function bool ClientAltFire(float F) {}

	simulated function Tick( float DeltaTime )
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);

		if (P == None)
			return;

		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
//			Log("FireInterval"@FireInterval@"Next"@NextFireInterval);
			FireInterval += NextFireInterval;
			if (P.bFire == 0)
				NN_GenerateBullet();
		}

		if	( bFiredShot && ((P.bAltFire==0) || bOutOfAmmo) ) 
			GoToState('ClientFinish');
	}
	
	simulated function EndState()
	{
		if (!Owner.IsA('Bot'))
			LightType = LT_None;
		Super.EndState();
	}
Begin:
}

state ClientFinish
{
	simulated function BeginState()
	{
		if (Owner.IsA('Bot'))
			return;
		if (PlayerPawn(Owner).bFire != 0)
			GotoState('ClientFiring');
		else if (PlayerPawn(Owner).bAltFire != 0)
			GotoState('ClientAltFiring');
		
		PlayUnwind();
		Super.BeginState();
	}

Begin:
	FinishAnim();
	NN_Finish();
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

simulated function NN_Finish()
{
	local Pawn PawnOwner;
	local bool bForce, bForceAlt;
	
	if (Owner.IsA('Bot'))
		return;

	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;

	if ( bChangeWeapon )
	{
		GotoState('ClientDown');
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

function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z, AimDir;
	local actor Other;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.TraceFire(Accuracy);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (!bNewNet || bbP == None) {
		Super.TraceFire(Accuracy);
		return;
	}
	
	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000;
	AimDir = vector(AdjustedAim);
	EndTrace += (10000 * AimDir); 
	Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
	Other = bbP.zzNN_HitActor;
	if (Pawn(Other) != None && FastTrace(Other.Location))
		HitLocation += (bbP.zzNN_HitLoc - Other.Location);
	Spawn(class'NN_MTracerOwnerHidden',Owner,, StartTrace + 96 * AimDir,rotator(EndTrace - StartTrace));
	
	ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim),Y,Z);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local int rndDam;
	local Pawn PawnOwner;
	
	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}

	PawnOwner = Pawn(Owner);
	
	if (STM != None)
		STM.PlayerFire(PawnOwner, 13);				// 13 = Minigun

	if (Other == Level) 
		Spawn(class'NN_UT_LightWallHitEffectOwnerHidden',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
	else if ( (Other!=self) && (Other!=Owner) && (Other != None) ) 
	{

		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner,,HitLocation+HitNormal*9); 
		else
			Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);

		if ( Other.IsA('Bot') && (FRand() < 0.2) )
			Pawn(Other).WarnTarget(PawnOwner, 500, X);
		if (PlayerPawn(Owner).bAltFire != 0)
			rndDam = 10;	// was 9 + Rand(6);
		else
			rndDam = 7;		// was 9 + Rand(6);
		if ( FRand() < 0.2 )
			X *= 2.5;
		if (STM != None)
			STM.PlayerHit(PawnOwner, 13, False);			// 13 = Minigun
		if (!bNewNet)
			Other.TakeDamage(rndDam, PawnOwner, HitLocation, rndDam*500.0*X, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}

	if (Pawn(Other) != None && Other != Owner && Pawn(Other).Health > 0)
	{	// We hit a pawn that wasn't the owner or dead.
		HitCounter++;						// +1 hit
		if (HitCounter == 8)
		{	// Wowsers!
			HitCounter = 0;
			if (STM != None)
				STM.PlayerSpecial(PawnOwner, 13);		// 13 = Minigun
		}
	}
	else
		HitCounter = 0;
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
		carried = 'minigun2';
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

function DropFrom(vector StartLocation)
{
	bCanClientFire = false;
	bSimFall = true;
	SimAnim.X = 0;
	SimAnim.Y = 0;
	SimAnim.Z = 0;
	SimAnim.W = 0;
	if ( !SetLocation(StartLocation) )
		return; 
	AIRating = Default.AIRating;
	bMuzzleFlash = 0;
	if ( AmmoType != None )
	{
		if ( bbPlayer(Owner) != None && bbPlayer(Owner).FindInventoryType(class'ST_enforcer') == None )
		{
			PickupAmmoCount = AmmoType.AmmoAmount;
			AmmoType.AmmoAmount = 0;
		}
		else
		{
			PickupAmmoCount = AmmoType.AmmoAmount / 2;
			AmmoType.AmmoAmount -= PickupAmmoCount;
		}
	}
	RespawnTime = 0.0; //don't respawn
	SetPhysics(PHYS_Falling);
	RemoteRole = ROLE_DumbProxy;
	BecomePickup();
	NetPriority = 2.5;
	bCollideWorld = true;
	if ( Pawn(Owner) != None )
		Pawn(Owner).DeleteInventory(self);
	Inventory = None;
	GotoState('PickUp', 'Dropped');
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

defaultproperties {
	FireInterval=0.120
	NextFireInterval=0.111
	bNewNet=True
}
