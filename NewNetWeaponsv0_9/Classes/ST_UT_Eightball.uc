// ===============================================================
// Stats.ST_UT_Eightball: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_UT_Eightball extends UT_Eightball;

var ST_Mutator STM;
var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var Actor NN_LockedTarget;
var name LastState;

replication
{
	reliable if ( bNetOwner && Role == ROLE_Authority )
		NN_LockedTarget;
	reliable if ( Role < ROLE_Authority )
		ServerForceFire, ServerForceAltFire, ServerFireRockets;
}

simulated function Tick( float Delta )
{
	Super.Tick( Delta );
	
	if (!bNewNet)
		return;
	
	if (Role == ROLE_Authority && NN_LockedTarget != LockedTarget)
		NN_LockedTarget = LockedTarget;
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

simulated function RenderOverlays(Canvas Canvas)
{
	local bbPlayer bbP;
	
	Super.RenderOverlays(Canvas);
	yModInit();
	
	bbP = bbPlayer(Owner);
	if (bNewNet && Role < ROLE_Authority && bbP != None)
	{
		if (bbP.bFire != 0)
		{
			if (AmmoType.AmmoAmount == 0)
			{
				if (!IsInState('NN_FireRockets'))
					GotoState('NN_FireRockets');
			}
			else if (!IsInState('ClientFiring'))
				ClientFire(1);
		}
		else if (bbP.bAltFire != 0)
		{
			if (AmmoType.AmmoAmount == 0)
			{
				if (!IsInState('NN_FireRockets'))
					GotoState('NN_FireRockets');
			}
			else if (!IsInState('ClientAltFiring'))
				ClientAltFire(1);
		}
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
		bbP.xxNN_Fire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
		bPointing=True;
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			
			bCanClientFire = true;
			bInstantRocket = bAlwaysInstant || ( (bbP != None) && bbP.bInstantRocket );
			if ( bInstantRocket )
			{
				bFireLoad = True;
				RocketsLoaded = 1;
				GotoState('');
				GotoState('NN_FireRockets', 'Begin');
			}
			else
				GotoState('NN_NormalFire');
			
			return true;
		}
	}
	else if ( bCanClientFire && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		GotoState('ClientFiring');
		return true;
	}
	return false;
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
		bbP.xxNN_AltFire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			GotoState('NN_AltFiring');
			return true;
		}
	}
	else if ( bCanClientFire && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		GotoState('NN_AltFiring');
		return true;
	}
	return false;
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

simulated function RotateRocket()
{
}

exec function ServerForceFire(bool bF)
{
	bForceFire = bF;
}
exec function ServerForceAltFire(bool bF)
{
	bForceAltFire = bF;
}
exec function ServerFireRockets( int ProjIndex, bool bPrimary, int RoxLoaded, float ClientLocX, float ClientLocY, float ClientLocZ, int ViewPitch, int ViewYaw, int ViewRoll, optional int ClientFRVI, optional bool bInstant )
{
	local bbPlayer bbP;
	local int Diff;
	
	if (Owner.IsA('Bot'))
		return;
	
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
	bbP.zzbNN_ReleasedFire = true;
	
	if (!bInstant)
	{
		Diff = RoxLoaded - RocketsLoaded;
		if (Diff > 0)
			AmmoType.UseAmmo(Diff);
	}
	RocketsLoaded = RoxLoaded;
	bFireLoad = bPrimary;
	
	GotoState('FireRockets');
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

///////////////////////////////////////////////////////
state NN_FireRockets
{
	simulated function bool ClientFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientFire(F);
		if (Left(AnimSequence, 4) != "Fire" && F > 0)
		{
			bForceFire = true;
			ServerForceFire(true);
		}
	}
	simulated function bool ClientAltFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(F);
		if (Left(AnimSequence, 4) != "Fire" && F > 0)
		{
			bForceAltFire = true;
			ServerForceAltFire(true);
		}
	}

	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}

	simulated function bool SplashJump()
	{
		return false;
	}

	simulated function BeginState()
	{
		local vector FireLocation, StartLoc, X,Y,Z;
		local rotator FireRot, RandRot;
		local float Angle, RocketRad, R1, R2, R3, R4, R5, R6, R7;
		local pawn BestTarget, PawnOwner;
		local PlayerPawn PlayerOwner;
		local int DupRockets, ProjIndex;
		local bool bMultiRockets;
		local ST_UT_SeekingRocket s;
		local ST_RocketMk2 r;
		local ST_UT_Grenade g;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}

		PawnOwner = Pawn(Owner);
		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;
		
		yModInit();
		
		ServerFireRockets(bbP.zzNN_ProjIndex, bFireLoad, RocketsLoaded, bbP.Location.X, bbP.Location.Y, bbP.Location.Z, GV.Pitch, GV.Yaw, GV.Roll, bbP.zzNN_FRVI, bAlwaysInstant || bbP.bInstantRocket);
		
		R1 = NN_GetFRV();
		
		PawnOwner.PlayRecoil(FiringSpeed);
		PlayerOwner = PlayerPawn(Owner);
		Angle = 0;
		DupRockets = RocketsLoaded - 1;
		if (DupRockets < 0) DupRockets = 0;
		if ( PlayerOwner == None )
			bTightWad = ( R1 * 4 < PawnOwner.skill );

		GetAxes(GV,X,Y,Z);
		StartLoc = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;

		if ( bFireLoad ) 		
			AdjustedAim = PawnOwner.AdjustAim(ProjectileSpeed, StartLoc, AimError, True, bWarnTarget);
		else 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, StartLoc, AimError, True, bAltWarnTarget);	
			
		if ( PlayerOwner != None )
			AdjustedAim = GV;
		
		PlayRFiring(RocketsLoaded-1);		
		Owner.MakeNoise(PawnOwner.SoundDampening);
		if ( !bFireLoad )
		{
			NN_LockedTarget = None;
			bLockedOn = false;
		}
		else if ( NN_LockedTarget == None )
			BestTarget = None;
		bPendingLock = false;
		bPointing = true;
		FireRot = AdjustedAim;
		RocketRad = 4;
		if (bTightWad || !bFireLoad) RocketRad=7;
		bMultiRockets = ( RocketsLoaded > 1 );
		
		While ( RocketsLoaded > 0 )
		{
			R2 = NN_GetFRV();
			R3 = NN_GetFRV();
			R4 = NN_GetFRV();
			R5 = NN_GetFRV();
			R6 = NN_GetFRV();
			R7 = NN_GetFRV();
			
			if ( bMultiRockets )
				Firelocation = StartLoc - (Sin(Angle)*RocketRad - 7.5)*Y + (Cos(Angle)*RocketRad - 7)*Z - X * 4 * R2;
			else
				FireLocation = StartLoc;
			if (bFireLoad)
			{
				if ( Angle > 0 )
				{
					if ( Angle < 3 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw - Angle * 600;
					else if ( Angle > 3.5 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw + (Angle - 3)  * 600;
					else
						FireRot.Yaw = AdjustedAim.Yaw;
				}
				
				if ( NN_LockedTarget != None )
				{
					s = Spawn( class 'ST_UT_SeekingRocket',Owner, '', FireLocation,FireRot);
					s.Seeking = NN_LockedTarget;
					s.NumExtraRockets = DupRockets;					
					if ( Angle > 0 )
						s.Velocity *= (0.9 + 0.2 * R3);
					ProjIndex = bbP.xxNN_AddProj(s);
					s.zzNN_ProjIndex = ProjIndex;
                    bbP.xxClientDemoFix(S, class'UT_SeekingRocket', FireLocation, S.Velocity, S.Acceleration, FireRot,, NN_LockedTarget);
				}
				else 
				{
					r = Spawn( class'ST_RocketMk2',Owner, '', FireLocation,FireRot);
					r.NumExtraRockets = DupRockets;
					if (RocketsLoaded>4 && bTightWad) r.bRing=True;
					if ( Angle > 0 )
						r.Velocity *= (0.9 + 0.2 * R4);
					ProjIndex = bbP.xxNN_AddProj(r);
					r.zzNN_ProjIndex = ProjIndex;
                    bbP.xxClientDemoFix(R, class'RocketMk2', FireLocation, R.Velocity, R.Acceleration, FireRot);
				}
			}
			else 
			{
				g = Spawn( class 'ST_UT_Grenade',Owner, '', FireLocation, AdjustedAim);
				g.NumExtraGrenades = DupRockets;
				if ( DupRockets > 0 )
				{
					RandRot.Pitch = R5 * 1500 - 750;
					RandRot.Yaw = R6 * 1500 - 750;
					RandRot.Roll = R7 * 1500 - 750;
					g.Velocity = g.Velocity >> RandRot;
				}
				ProjIndex = bbP.xxNN_AddProj(g);
				g.zzNN_ProjIndex = ProjIndex;
                bbP.xxClientDemoFix(G, class'UT_Grenade', FireLocation, G.Velocity, G.Acceleration, G.Rotation);
			}

			Angle += 1.0484; //2*3.1415/6;
			RocketsLoaded--;
		}
		bTightWad=False;
		bRotated = false;
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( !bRotated && (AmmoType.AmmoAmount > 0) ) 
		{	
			PlayLoading(1.5,0);
			RocketsLoaded = 1;
			bRotated = true;
			return;
		}
		NN_Finish();
	}
}

state NN_NormalFire
{
	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}

	simulated function bool ClientFire(float F) 
	{
	}
	simulated function bool ClientAltFire(float F) 
	{
	}
	
	simulated function bool SplashJump()
	{
		return true;
	}

	simulated function Tick( float DeltaTime )
	{
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		
		if ( (PlayerPawn(Owner) == None) 
			&& ((Pawn(Owner).MoveTarget != Pawn(Owner).Target) 
				|| (LockedTarget != None)
				|| (Pawn(Owner).Enemy == None)
				|| ( Mover(Owner.Base) != None )
				|| ((Owner.Physics == PHYS_Falling) && (Owner.Velocity.Z < 5))
				|| (VSize(Owner.Location - Pawn(Owner).Target.Location) < 400)
				|| !Pawn(Owner).CheckFutureSight(0.15)) )
			Pawn(Owner).bFire = 0;

		if( pawn(Owner).bFire==0 || RocketsLoaded > 5 || AmmoType.AmmoAmount == 0)  // If Fire button down, load up another
 			GoToState('NN_FireRockets');
	}
	
	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( bRotated )
		{
			bRotated = false;
			PlayLoading(1.1, RocketsLoaded);
		}
		else
		{
			if ( RocketsLoaded == 6 || AmmoType.AmmoAmount == 0 )
			{
				GotoState('NN_FireRockets');
				return;
			}
			RocketsLoaded++;
			AmmoType.UseAmmo(1);
			if (pawn(Owner).bAltFire!=0) bTightWad=True;
			NewTarget = CheckTarget();
			if ( Pawn(NewTarget) != None )
				Pawn(NewTarget).WarnTarget(Pawn(Owner), ProjectileSpeed, vector(Pawn(Owner).ViewRotation));	
			if ( LockedTarget != None )
			{
				If ( NewTarget != LockedTarget ) 
				{
					LockedTarget = None;
					Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening);
					bLockedOn=False;
				}
				else if (LockedTarget != None)
 					Owner.PlaySound(Misc1Sound, SLOT_None, Pawn(Owner).SoundDampening);
			}
			bPointing = true;
			Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
			RotateRocket();
		}
	}

	simulated function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		bFireLoad = True;
		RocketsLoaded = 1;
		RotateRocket();
	}

	simulated function RotateRocket()
	{
		if (Owner.IsA('Bot'))
			return;
		if ( AmmoType.AmmoAmount <= 0 ) 
		{
			GotoState('NN_FireRockets');
			return;
		}
		if ( AmmoType.AmmoAmount == 1 )
			Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening); 
		PlayRotating(RocketsLoaded-1);
		bRotated = true;
	}
				
Begin:
	Sleep(0.0);
	FinishAnim();
	NN_Finish();
}

state NN_AltFiring
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

	simulated function Tick( float DeltaTime )
	{
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		
		if( (pawn(Owner).bAltFire==0) || (RocketsLoaded > 5) || AmmoType.AmmoAmount == 0 )  // If if Fire button down, load up another
 			GoToState('NN_FireRockets');
	}
	
	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( bRotated )
		{
			bRotated = false;
			PlayLoading(1.1, RocketsLoaded);
		}
		else
		{
			if ( RocketsLoaded == 6 || AmmoType.AmmoAmount == 0 )
			{
				GotoState('NN_FireRockets');
				return;
			}
			RocketsLoaded++;
			AmmoType.UseAmmo(1);		
			if ( (PlayerPawn(Owner) == None) && ((FRand() > 0.5) || (Pawn(Owner).Enemy == None)) )
				Pawn(Owner).bAltFire = 0;
			bPointing = true;
			Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
			RotateRocket();
		}
	}

	simulated function RotateRocket()
	{
		if (Owner.IsA('Bot'))
			return;
		if (AmmoType.AmmoAmount<=0)
		{ 
			GotoState('NN_FireRockets');
			return;
		}		
		PlayRotating(RocketsLoaded-1);
		bRotated = true;
	}

	simulated function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		RocketsLoaded = 1;
		bFireLoad = False;
		RotateRocket();
	}
	
Begin:
	if (!Owner.IsA('Bot'))
	{
		bLockedOn = False;
		FinishAnim();
		NN_Finish();
	}
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

	if ( bChangeWeapon || AmmoType.AmmoAmount <= 0 )
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
	{
		Global.Fire(0);
		Global.ClientFire(0);
	}
	else if ( (PawnOwner.bAltFire!=0) || bForceAlt )
	{
		Global.AltFire(0);
		Global.ClientAltFire(0);
	}
	else 
		GotoState('Idle');
}

state NormalFire
{
	function Tick( float DeltaTime )
	{
		if (!bNewNet || Owner.IsA('Bot'))
			Super.Tick(DeltaTime);
	}
	
	function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( bRotated )
		{
			bRotated = false;
			PlayLoading(1.1, RocketsLoaded);
		}
		else
		{
			if ( RocketsLoaded == 6 )
			{
				if (bNewNet)
					GotoState('Idle');
				else
					GotoState('FireRockets');
				return;
			}
			else if (bbPlayer(Owner) != None && bNewNet && bbPlayer(Owner).bFire == 0)
			{
				GotoState('Idle');
				return;
			}
			RocketsLoaded++;
			AmmoType.UseAmmo(1);
			if (pawn(Owner).bAltFire!=0) bTightWad=True;
			NewTarget = CheckTarget();
			if ( Pawn(NewTarget) != None )
				Pawn(NewTarget).WarnTarget(Pawn(Owner), ProjectileSpeed, vector(Pawn(Owner).ViewRotation));	
			if ( LockedTarget != None )
			{
				If ( NewTarget != LockedTarget ) 
				{
					LockedTarget = None;
					Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening);
					bLockedOn=False;
				}
				else if (LockedTarget != None)
 					Owner.PlaySound(Misc1Sound, SLOT_None, Pawn(Owner).SoundDampening);
			}
			bPointing = true;
			Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
			RotateRocket();
		}
	}

	function RotateRocket()
	{
		if (Owner.IsA('Bot'))
		{
			Super.RotateRocket();
			return;
		}
		if ( PlayerPawn(Owner) == None )
		{
			if ( FRand() > 0.33 )
				Pawn(Owner).bFire = 0;
			if ( Pawn(Owner).bFire == 0 )
			{
				if (bNewNet)
					GotoState('Idle');
				else
					GoToState('FireRockets');
				return;
			}
		}
		if ( AmmoType.AmmoAmount <= 0 ) 
		{
			if (bNewNet)
				GotoState('Idle');
			else
				GotoState('FireRockets');
			return;
		}
		if ( AmmoType.AmmoAmount == 1 )
			Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening); 
		PlayRotating(RocketsLoaded-1);
		bRotated = true;
	}
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		if (!bNewNet || Owner.IsA('Bot'))
			Super.Tick(DeltaTime);
	}
	
	function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		if ( bRotated )
		{
			bRotated = false;
			PlayLoading(1.1, RocketsLoaded);
		}
		else
		{
			if ( RocketsLoaded == 6 )
			{
				if (bNewNet)
					GotoState('Idle');
				else
					GotoState('FireRockets');
				return;
			}
			else if (bbPlayer(Owner) != None && bNewNet && bbPlayer(Owner).bAltFire == 0)
			{
				GotoState('Idle');
				return;
			}
			RocketsLoaded++;
			AmmoType.UseAmmo(1);		
			if ( (PlayerPawn(Owner) == None) && ((FRand() > 0.5) || (Pawn(Owner).Enemy == None)) )
				Pawn(Owner).bAltFire = 0;
			bPointing = true;
			Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
			RotateRocket();
		}
	}

	function RotateRocket()
	{
		if (Owner.IsA('Bot'))
		{
			Super.RotateRocket();
			return;
		}
		if (AmmoType.AmmoAmount<=0)
		{ 
			if (bNewNet)
				GotoState('Idle');
			else
				GotoState('FireRockets');
			return;
		}
		PlayRotating(RocketsLoaded-1);
		bRotated = true;
	}

	function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		RocketsLoaded = 1;
		bFireLoad = False;
		RotateRocket();
	}

Begin:
	if (!Owner.IsA('Bot'))
		bLockedOn = False;
}

///////////////////////////////////////////////////////
state Idle
{
	function Timer()
	{
		if (Owner.IsA('Bot'))
		{
			Super.Timer();
			return;
		}
		NewTarget = CheckTarget();
		if ( NewTarget == OldTarget )
		{
			LockedTarget = NewTarget;
			If (LockedTarget != None) 
			{
				bLockedOn=True;			
				Owner.MakeNoise(Pawn(Owner).SoundDampening);
				Owner.PlaySound(Misc1Sound, SLOT_None,Pawn(Owner).SoundDampening);
				if ( (Pawn(LockedTarget) != None) && (FRand() < 0.7) )
					Pawn(LockedTarget).WarnTarget(Pawn(Owner), ProjectileSpeed, vector(Pawn(Owner).ViewRotation));	
				if ( bPendingLock )
				{
					OldTarget = NewTarget;
					Pawn(Owner).bFire = 0;
					bFireLoad = True;
					RocketsLoaded = 1;
					if (bNewNet)
						GotoState('Idle');
					else
						GotoState('FireRockets', 'Begin');
					return;
				}
			}
		}
		else if( (OldTarget != None) && (NewTarget == None) ) 
		{
			Owner.PlaySound(Misc2Sound, SLOT_None,Pawn(Owner).SoundDampening);
			bLockedOn = False;
		}
		else 
		{
			LockedTarget = None;
			bLockedOn = False;
		}
		OldTarget = NewTarget;
		bPendingLock = false;
	}

Begin:
	if (Pawn(Owner).bFire!=0 && !bNewNet) Fire(0.0);
	if (Pawn(Owner).bAltFire!=0 && !bNewNet) AltFire(0.0);	
	bPointing=False;
	if (AmmoType.AmmoAmount<=0 && bbPlayer(Owner) != None) 
		bbPlayer(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	PlayIdleAnim();
	OldTarget = CheckTarget();
	SetTimer(1.25,True);
	LockedTarget = None;
	bLockedOn = False;
PendingLock:
	if ( bPendingLock )
		bPointing = true;
	if ( TimerRate <= 0 )
		SetTimer(1.0, true);
}

state FireRockets
{
	function BeginState()
	{
		local vector FireLocation, StartLoc, X,Y,Z;
		local rotator FireRot, RandRot;
		local ST_RocketMk2 r;
		local ST_UT_SeekingRocket s;
		local ST_UT_Grenade g;
		local float Angle, RocketRad, R1, R2, R3, R4, R5, R6, R7;
		local pawn BestTarget, PawnOwner;
		local PlayerPawn PlayerOwner;
		local int DupRockets;
		local bool bMultiRockets;
		local bbPlayer bbP;
		local NN_rocketmk2OwnerHidden NNR;
		local NN_ut_SeekingRocketOwnerHidden NNS;
		local NN_ut_GrenadeOwnerHidden NNG;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
		
		bbP = bbPlayer(Owner);
		R1 = GetFRV();

		PawnOwner = Pawn(Owner);
		if ( PawnOwner == None )
			return;
		PlayerOwner = PlayerPawn(Owner);
		Angle = 0;
		DupRockets = RocketsLoaded - 1;
		if (DupRockets < 0) DupRockets = 0;
		if ( PlayerOwner == None )
			bTightWad = ( R1 * 4 < PawnOwner.skill );
			
		if (bbP == None || !bNewNet)
		{
			GetAxes(PawnOwner.ViewRotation,X,Y,Z);
			StartLoc = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		else
		{
			GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
			if (Mover(bbP.Base) == None)
				StartLoc = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				StartLoc = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}

		if ( bFireLoad ) 		
			AdjustedAim = PawnOwner.AdjustAim(ProjectileSpeed, StartLoc, AimError, True, bWarnTarget);
		else 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, StartLoc, AimError, True, bAltWarnTarget);	
			
		if (bbP == None || !bNewNet)
			AdjustedAim = Pawn(Owner).ViewRotation;
		else
			AdjustedAim = bbP.zzNN_ViewRot;
		
		if (!bNewNet)
			PawnOwner.PlayRecoil(FiringSpeed);
		PlayRFiring(RocketsLoaded-1);
		Owner.MakeNoise(PawnOwner.SoundDampening);
		if ( !bFireLoad )
		{
			LockedTarget = None;
			bLockedOn = false;
		}
		else if ( LockedTarget != None )
		{
			BestTarget = Pawn(CheckTarget());
			if ( (LockedTarget!=None) && (LockedTarget != BestTarget) ) 
			{
				LockedTarget = None;
				bLockedOn=False;
			}
		}
		else 
			BestTarget = None;
		bPendingLock = false;
		bPointing = true;
		FireRot = AdjustedAim;
		RocketRad = 4;
		if (bTightWad || !bFireLoad) RocketRad=7;
		bMultiRockets = ( RocketsLoaded > 1 );
		While ( RocketsLoaded > 0 )
		{
			R2 = GetFRV();
			R3 = GetFRV();
			R4 = GetFRV();
			R5 = GetFRV();
			R6 = GetFRV();
			R7 = GetFRV();
			
			if ( bMultiRockets ) {
				Firelocation = StartLoc - (Sin(Angle)*RocketRad - 7.5)*Y + (Cos(Angle)*RocketRad - 7)*Z - X * 4 * R2;
			} else
				FireLocation = StartLoc;
			if (bFireLoad)
			{
				if ( Angle > 0 )
				{
					if ( Angle < 3 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw - Angle * 600;
					else if ( Angle > 3.5 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw + (Angle - 3)  * 600;
					else
						FireRot.Yaw = AdjustedAim.Yaw;
				}
				if ( LockedTarget != None )
				{
					if (bNewNet)
					{
						s = Spawn( class 'NN_ut_SeekingRocketOwnerHidden',Owner, '', FireLocation,FireRot);
						NNS = NN_ut_SeekingRocketOwnerHidden(s);
						//NNS.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNS);
					}
					else
						s = Spawn( class 'ST_UT_SeekingRocket',, '', FireLocation,FireRot);
					s.Seeking = LockedTarget;
					s.NumExtraRockets = DupRockets;					
					if ( Angle > 0 )
						s.Velocity *= (0.9 + 0.2 * R3);			
				}
				else 
				{
					if (bNewNet)
					{
						r = Spawn( class'NN_rocketmk2OwnerHidden',Owner, '', FireLocation,FireRot);
						NNR = NN_rocketmk2OwnerHidden(r);
						NNR.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNR.zzNN_ProjIndex = bbP.xxNN_AddProj(NNR);
					}
					else
						r = Spawn( class'ST_RocketMk2',, '', FireLocation,FireRot);
					r.NumExtraRockets = DupRockets;
					if (RocketsLoaded>4 && bTightWad) r.bRing=True;
					if ( Angle > 0 )
						r.Velocity *= (0.9 + 0.2 * R4);			
				}
			}
			else 
			{
				if (bNewNet)
				{
					g = Spawn( class 'NN_ut_GrenadeOwnerHidden',Owner, '', FireLocation,AdjustedAim);
					NNG = NN_ut_GrenadeOwnerHidden(g);
					//NNG.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
					if (bbP != None)
						NNG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNG);
				}
				else
					g = Spawn( class 'ST_UT_Grenade',Owner, '', FireLocation,AdjustedAim);
				g.NumExtraGrenades = DupRockets;
				if ( DupRockets > 0 )
				{
					RandRot.Pitch = R5 * 1500 - 750;
					RandRot.Yaw = R6 * 1500 - 750;
					RandRot.Roll = R7 * 1500 - 750;
					g.Velocity = g.Velocity >> RandRot;
				}
			}

			Angle += 1.0484; //2*3.1415/6;
			RocketsLoaded--;
		}
		bTightWad=False;
		bRotated = false;
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
		carried = 'UT_Eightball';
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
	RocketsLoaded = 0;
	bForceFire = false;
	bForceAltFire = false;
	bCanClientFire = false;
	ServerForceFire(false);
	ServerForceAltFire(false);
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
	bNewNet=True
}
