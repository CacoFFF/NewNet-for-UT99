// ===============================================================
// Stats.ST_UT_FlakCannon: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_UT_FlakCannon extends UT_FlakCannon;

var ST_Mutator STM;
var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;

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

simulated function bool ClientFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local ST_UTChunk Proj;
	local int ProjIndex;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Value < 1)
			return false;
		
		yModInit();
		PawnOwner = Pawn(Owner);

		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(PawnOwner);
		}
		if (AmmoType.AmmoAmount > 0)
		{
			bbP.xxNN_Fire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, None, vect(0,0,0), vect(0,0,0), false, bbP.zzFRVI);
			
			Instigator = Pawn(Owner);
			bCanClientFire = true;
			bPointing=True;
			PawnOwner.PlayRecoil(FiringSpeed);

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO;
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));	
			Start = Start + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;	
			
			//bbP.ClientMessage("Client:"@GV);
			Proj = Spawn( class 'ST_UTChunk1',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk3',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk4',Owner, '', Start - Y, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Y, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk1',Owner, '', Start + 2 * Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk3',Owner, '', Start + Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk4',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			GoToState('NormalFire');
		}
	}
	
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local ST_FlakSlug Proj;
	local int ProjIndex;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Value < 1)
			return false;
		
		yModInit();
		PawnOwner = Pawn(Owner);

		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(PawnOwner);
		}
		if (AmmoType.AmmoAmount > 0)
		{
			bbP.xxNN_AltFire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, None, vect(0,0,0), vect(0,0,0), false, bbP.zzFRVI);
			
			Instigator = Pawn(Owner);
			PawnOwner.PlayRecoil(FiringSpeed);
			bPointing=True;
			bCanClientFire = true;
			
			PawnOwner = Pawn(Owner);
			GetAxes(GV,X,Y,Z);
			Start = PawnOwner.Location + CDO;
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));	
			Start = Start + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);
				
			Proj = Spawn(class'ST_FlakSlug',Owner,, Start,AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'FlakSlug', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	
	return Super.ClientAltFire(Value);
}

// Fire chunks
function Fire( float Value )
{
	local Vector Start, X,Y,Z;
	local Bot B;
	local ST_UTChunkInfo CI;
	local NN_UTChunkOwnerHidden COH;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local float OwnerPing;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	PawnOwner = Pawn(Owner);

	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(PawnOwner);
	}
	if (AmmoType.UseAmmo(1))
	{
		bCanClientFire = true;
		bPointing=True;
		
			
		B = Bot(PawnOwner);
		PawnOwner.MakeNoise(2.0 * PawnOwner.SoundDampening);
		if (bbP == None || !bNewNet)
		{
			Start = PawnOwner.Location + CalcDrawOffset();
			AdjustedAim = PawnOwner.AdjustAim(AltProjectileSpeed, Start, AimError, True, bWarnTarget);
			GetAxes(AdjustedAim,X,Y,Z);
			Start = Start + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;	
		}
		else
		{
			AdjustedAim = bbP.zzNN_ViewRot;
			GetAxes(AdjustedAim,X,Y,Z);
			if (Mover(bbP.Base) == None)
				Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		if (bNewNet)
			Spawn(class'NN_WeaponLightOwnerHidden',Owner,'',Start+X*20,rot(0,0,0));		
		else
		{
			PawnOwner.PlayRecoil(FiringSpeed);
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));		
		}
		CI = Spawn(class'ST_UTChunkInfo', PawnOwner);
		CI.STM = STM;
		OwnerPing = float(Owner.ConsoleCommand("GETPING"));
		// My comment
		// I am not sure why EPIC has decided to do flak (or rockets) this way, as they could
		// Have created a masterchunk on client that spawned the rest of the chunks according to
		// The below rules, creating less network traffic. Of course it would pose a problem
		// When you run into a chunk that wasn't relevant when the original shot was fired. Oh well :/
		if (bNewNet)
		{
			//bbP.ClientMessage("Server:"@bbP.zzNN_ViewRot);
			COH = Spawn( class 'NN_UTChunk1OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk2OwnerHidden',Owner, '', Start - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk3OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk4OwnerHidden',Owner, '', Start - Y, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk1OwnerHidden',Owner, '', Start + 2 * Y - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk2OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
		}
		else
		{
			CI.AddChunk(Spawn( class 'ST_UTChunk1',Owner, '', Start, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk2',Owner, '', Start - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk3',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk4',Owner, '', Start - Y, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk1',Owner, '', Start + 2 * Y - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk2',Owner, '', Start, AdjustedAim));
		}

		// lower skill bots fire less flak chunks
		if ( (B == None) || !B.bNovice || ((B.Enemy != None) && (B.Enemy.Weapon != None) && B.Enemy.Weapon.bMeleeWeapon) )
		{
			if (bNewNet)
			{
				COH = Spawn( class 'NN_UTChunk3OwnerHidden',Owner, '', Start + Y - Z, AdjustedAim);
				COH.NN_OwnerPing = OwnerPing;
				CI.AddChunk(COH);
				
				COH = Spawn( class 'NN_UTChunk4OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
				COH.NN_OwnerPing = OwnerPing;
				CI.AddChunk(COH);
				
			}
			else
			{
				CI.AddChunk(Spawn( class 'ST_UTChunk3',Owner, '', Start + Y - Z, AdjustedAim));
				CI.AddChunk(Spawn( class 'ST_UTChunk4',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			}
		}
		else if ( B.Skill > 1 )
			CI.AddChunk(Spawn( class 'ST_UTChunk3',Owner, '', Start + Y - Z, AdjustedAim));
		
		ClientFire(Value);
		
		GoToState('NormalFire');
	}
}

function AltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local ST_FlakSlug Slug;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local NN_FlakSlugOwnerHidden NNFS;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	PawnOwner = Pawn(Owner);

	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(PawnOwner);
	}
	if (AmmoType.UseAmmo(1))
	{
		bPointing=True;
		bCanClientFire = true;
		PawnOwner.MakeNoise(PawnOwner.SoundDampening);

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
		AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);	
		ClientAltFire(Value);
		if (bNewNet) {
			Spawn(class'NN_WeaponLightOwnerHidden',Owner,'',Start+X*20,rot(0,0,0));
			NNFS = Spawn(class'NN_FlakSlugOwnerHidden',Owner,, Start,AdjustedAim);
			if (bbP != None)
				NNFS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNFS);
			NNFS.STM = STM;
		} else {
			PawnOwner.PlayRecoil(FiringSpeed);
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));
			Slug = Spawn(class'ST_FlakSlug',,, Start,AdjustedAim);
			Slug.STM = STM;
		}
		if (STM != None)
			STM.PlayerFire(PawnOwner, 15);				// 15 = Flak Slug
		GoToState('AltFiring');
	}
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

state NormalFire
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

state AltFiring
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
		carried = 'UT_FlakCannon';
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

simulated function PlayPostSelect()
{
	//PlayAnim('Loading', 3.0, 0.0);
	Owner.PlayOwnedSound(Misc2Sound, SLOT_None,1.3*Pawn(Owner).SoundDampening);	
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
