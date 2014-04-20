// ===============================================================
// UTPureStats7A.ST_ut_biorifle: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_ut_biorifle extends ut_biorifle;

var ST_Mutator STM;
var bool bNewNet;				// Self-explanatory lol
var Rotator GV, LastGV;
var Vector CDO;
var float yMod;
var name LastState;

replication
{
	reliable if ( Role < ROLE_Authority )
		ServerForceFire, ServerForceAltFire, ServerShootLoad;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
		if (bNewNet)
		{
			ProjectileClass = Class'NN_UT_BioGelOwnerHidden';
			AltProjectileClass = Class'NN_BioGlobOwnerHidden';
		}
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

exec function ServerForceFire()
{
	bForceFire = true;
}
exec function ServerForceAltFire()
{
	bForceAltFire = true;
}
exec function ServerShootLoad( int ProjIndex, float ClientLocX, float ClientLocY, float ClientLocZ, int ViewPitch, int ViewYaw, int ViewRoll, optional int ClientFRVI )
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;
	
	bbP.zzNN_ProjIndex = ProjIndex;
	bbP.zzNN_ClientLoc.X = ClientLocX;
	bbP.zzNN_ClientLoc.Y = ClientLocY;
	bbP.zzNN_ClientLoc.Z = ClientLocZ;
	bbP.zzNN_ViewRot.Pitch = ViewPitch;
	bbP.zzNN_ViewRot.Yaw = ViewYaw;
	bbP.zzNN_ViewRot.Roll = ViewRoll;
	bbP.zzNN_FRVI = ClientFRVI;
	bbP.zzFRVI = ClientFRVI;
	bbP.zzbNN_ReleasedAltFire = true;
	
	GotoState('ShootLoad');
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
		carried = 'ut_biorifle';
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

simulated function bool ClientFire(float Value)
{
	local Vector Start, X,Y,Z;
	local rotator AdjAim;
	local Projectile Proj;
	local ST_UT_BioGel ST_Proj;
	local int ProjIndex;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		if ( (AmmoType == None) && (AmmoName != None) )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			yModInit();
			
			Instigator = Pawn(Owner);
			GotoState('ClientFiring');
			bPointing=True;
			bCanClientFire = true;
			if ( bRapidFire || (FiringSpeed > 0) )
				Pawn(Owner).PlayRecoil(FiringSpeed);

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = pawn(owner).AdjustToss(ProjectileSpeed, Start, 0, True, bWarnTarget);	
			
			Proj = Spawn(Default.ProjectileClass,Owner,, Start, AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			ST_Proj = ST_UT_BioGel(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_Fire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'UT_BioGel', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
		
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local bool bResult;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (bbP == None || bbP.ClientCannotShoot() || bbP.Weapon != Self)
		return false;

	InstFlash = 0.0;
	if ( (bCanClientFire || bNewNet && Level.NetMode == NM_Client) && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		yModInit();
		
		Instigator = Pawn(Owner);
		if ( (PlayerPawn(Owner) != None) 
			&& ((Level.NetMode == NM_Standalone) || PlayerPawn(Owner).Player.IsA('ViewPort')) )
		{
			if ( InstFlash != 0.0 )
				PlayerPawn(Owner).ClientInstantFlash( InstFlash, InstFog);
			PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
		}
		if ( Affector != None )
			Affector.FireEffect();
		PlayAltFiring();
		if ( Role < ROLE_Authority )
			GotoState('ClientAltFiring');
		bResult = true;
		
		bbP.xxNN_AltFire(-2, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
	}
	InstFlash = Default.InstFlash;
	
	return bResult;
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

function Fire( float Value )
{
	local bbPlayer bbP;
	local NN_UT_BioGelOwnerHidden NNBG;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
	if ( (AmmoType == None) && (AmmoName != None) )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		GotoState('NormalFire');
		bPointing=True;
		bCanClientFire = true;
		ClientFire(Value);
		if (!bNewNet && (bRapidFire || (FiringSpeed > 0) ) )
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
		}
		if (bNewNet)
		{
			NNBG = NN_UT_BioGelOwnerHidden(ProjectileFire(class'NN_UT_BioGelOwnerHidden', ProjectileSpeed, bWarnTarget));
			//NNBG.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			bbP = bbPlayer(Owner);
			if (bbP != None)
				NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
		}
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	}
}

function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ProjectileFire(ProjClass, ProjSpeed, bWarn);
	
	yModInit();
	
	bbP = bbPlayer(Owner);

	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	if (bbP == None || !bNewNet)
	{
		GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	}
	else
	{
		GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
		if (Mover(bbP.Base) == None)
			Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		else
			Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	}
	AdjustedAim = pawn(owner).AdjustToss(ProjSpeed, Start, 0, True, bWarn);	
	return Spawn(ProjClass,Owner,, Start,AdjustedAim);
}

state ClientAltFiring
{
	simulated function Tick(float DeltaTime)
	{
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		
		//SetLocation(Owner.Location);
		if ( ChargeSize < 4.1 )
		{
			Count += DeltaTime;
			if ( (Count > 0.5) && AmmoType.AmmoAmount > 0 )
			{
				ChargeSize += Count;
				Count = 0;
				if ( (PlayerPawn(Owner) == None) && (FRand() < 0.2) )
					GoToState('ClientShootLoad');
			}
		}
		if( (pawn(Owner).bAltFire==0) ) {
			GoToState('ClientShootLoad');
		}
		if ( bBurst )
			return;
		if ( !bCanClientFire || (Pawn(Owner) == None) )
			GotoState('');
		else if ( Pawn(Owner).bAltFire == 0 )
		{
			PlayAltBurst();
			bBurst = true;
		}
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( bBurst )
		{
			bBurst = false;
			Super.AnimEnd();
		}
		else
			TweenAnim('Loaded', 0.5);
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
		if (Owner.IsA('Bot'))
		{
			Super.EndState();
			return;
		}
		ChargeSize = FMin(ChargeSize, 4.1);
	}

Begin:
	if (!Owner.IsA('Bot'))
		FinishAnim();
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		//SetLocation(Owner.Location);
		if ( ChargeSize < 4.1 )
		{
			Count += DeltaTime;
			if ( (Count > 0.5) && AmmoType.UseAmmo(1) )
			{
				ChargeSize += Count;
				Count = 0;
				if ( (PlayerPawn(Owner) == None) && (FRand() < 0.2) )
					GoToState('ShootLoad');
			}
		}
		if( pawn(Owner).bAltFire==0)
		{
			if (bNewNet)
				GoToState('Idle');
			else
				GoToState('ShootLoad');
		}
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( bBurst )
		{
			bBurst = false;
			Super.AnimEnd();
		}
		else
			TweenAnim('Loaded', 0.5);
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
		if (Owner.IsA('Bot'))
		{
			Super.EndState();
			return;
		}
		ChargeSize = FMin(ChargeSize, 4.1);
	}

Begin:
	if (!Owner.IsA('Bot'))
		FinishAnim();
}

state ShootLoad
{
	function Timer()
	{
		local rotator R;
		local vector start, X,Y,Z;
		local bbPlayer bbP;
		local NN_BioGlobOwnerHidden NNBG;
		
		if (Owner.IsA('Bot'))
		{
			Super.Timer();
			return;
		}
		
		bbP = bbPlayer(Owner);
		
		yModInit();

		if (bbP == None || !bNewNet)
		{
			GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
			Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			R = Owner.Rotation;
			R.Yaw += 2000;
			R.Pitch -= 500;
			Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
			
			R.Yaw -= 3000;
			R.Pitch += 750;
			Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
		}
		else
		{
			GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
			if (Mover(bbP.Base) == None)
				Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			R = bbP.zzNN_ViewRot;
			R.Yaw += 2000;
			R.Pitch -= 500;
			NNBG = Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
			NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
			
			R.Yaw -= 3000;
			R.Pitch += 750;
			NNBG = Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
			NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
		}
	}

	function BeginState()
	{
		Local ST_BioGlob BG;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}

		bbP = bbPlayer(Owner);

		BG = ST_BioGlob(ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
		if (bbP != None)
			BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		BG.DrawScale = 1.0 + 0.8 * ChargeSize;
		PlayAltBurst();
	}
}

state ClientShootLoad
{
	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}
	
	simulated function bool ClientFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientFire(F);
		bForceFire = true;
		ServerForceFire();
	}
	simulated function bool ClientAltFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(F);
		bForceAltFire = true;
		ServerForceAltFire();
	}
	
	simulated function Timer()
	{
		local rotator R;
		local vector start, X,Y,Z;
		local bbPlayer bbP;
		local ST_BioGlob BG;
		
		if (Owner.IsA('Bot'))
		{
			Super.Timer();
			return;
		}
		
		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;

		GetAxes(LastGV,X,Y,Z);
		Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;
		R = LastGV;
		
		R.Yaw += 2000;
		R.Pitch -= 500;
		BG = ST_BioGlob(Spawn(Default.AltProjectileClass,Owner,, Start,R));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		bbP.xxClientDemoFix(BG, class'BioGlob', Start, BG.Velocity, BG.Acceleration, R);
		
		R.Yaw -= 3000;
		R.Pitch += 750;
		BG = ST_BioGlob(Spawn(Default.AltProjectileClass,Owner,, Start,R));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		bbP.xxClientDemoFix(BG, class'BioGlob', Start, BG.Velocity, BG.Acceleration, R);
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		ClientFinish();
	}

	simulated function BeginState()
	{
		local Vector Start, X,Y,Z;
		local ST_BioGlob BG;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
		
		yModInit();

		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;
		
		LastGV = GV;
		GetAxes(GV,X,Y,Z);
		Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustToss(AltProjectileSpeed, Start, 0, True, bAltWarnTarget);
		
		ServerShootLoad(bbP.zzNN_ProjIndex, bbP.Location.X, bbP.Location.Y, bbP.Location.Z, GV.Pitch, GV.Yaw, GV.Roll, bbP.zzNN_FRVI);

		BG = ST_BioGlob(Spawn(Default.AltProjectileClass,Owner,, Start, AdjustedAim));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		BG.DrawScale = 1.0 + 0.8 * ChargeSize;
		bbP.xxClientDemoFix(BG, class'BioGlob', Start, BG.Velocity, BG.Acceleration, AdjustedAim, BG.DrawScale);
		
		PlayAltBurst();
	}

Begin:
}

simulated function ClientFinish()
{
	local bool bForce, bForceAlt;

	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;

	if ( bChangeWeapon )
		GotoState('DownWeapon');
	else if ( (AmmoType.AmmoAmount<=0) || (Pawn(Owner).Weapon != self) )
		GotoState('Idle');
	else if ( (Pawn(Owner).bFire!=0) || bForce )
		Global.ClientFire(0);
	else if ( (Pawn(Owner).bAltFire!=0) || bForceAlt )
		Global.ClientAltFire(0);
	else 
		GotoState('Idle');
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

defaultproperties {
	ProjectileClass=Class'ST_UT_BioGel'
	AltProjectileClass=Class'ST_BioGlob'
	bNewNet=True
}
