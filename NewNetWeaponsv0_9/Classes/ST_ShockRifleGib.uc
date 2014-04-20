class ST_ShockRifleGib extends ST_ShockRifle;

function Fire ( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	
	if ( (AmmoType == None) && (AmmoName != None) )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	//if ( AmmoType.UseAmmo(1) )
	//{
		GotoState('NormalFire');
		bPointing=True;
		bCanClientFire = true;
		ClientFire(Value);
		if ( bRapidFire || (FiringSpeed > 0) )
			Pawn(Owner).PlayRecoil(FiringSpeed);
		if ( bInstantHit )
			TraceFire(0.0);
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	//}
}

function AltFire( float Value )
{
	local actor HitActor;
	local vector HitLocation, HitNormal, Start;
	local bbPlayer bbP;
	local NN_ShockProjOwnerHidden NNSP;
	
	if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	if ( Owner == None )
		return;

	if ( Owner.IsA('Bot') ) //make sure won't blow self up
	{
		Start = Owner.Location + CalcDrawOffset() + FireOffset.Z * vect(0,0,1); 
		if ( Pawn(Owner).Enemy != None )
			HitActor = Trace(HitLocation, HitNormal, Start + 250 * Normal(Pawn(Owner).Enemy.Location - Start), Start, false, vect(12,12,12));
		else
			HitActor = self;
		if ( HitActor != None )
		{
			Global.Fire(Value);
			return;
		}
	}	
	if ( AmmoType != None )
	{
		GotoState('AltFiring');
		bCanClientFire = true;
		if ( Owner.IsA('Bot') )
		{
			if ( Owner.IsInState('TacticalMove') && (Owner.Target == Pawn(Owner).Enemy)
			 && (Owner.Physics == PHYS_Walking) && !Bot(Owner).bNovice
			 && (FRand() * 6 < Pawn(Owner).Skill) )
				Pawn(Owner).SpecialFire();
		}
		bPointing=True;
		ClientAltFire(value);
		if (bNewNet)
		{
			NNSP = NN_ShockProjOwnerHidden(ProjectileFire(Class'NN_ShockProjOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
			if (NNSP != None)
			{
				NNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
				if (bbP != None)
					NNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(NNSP);
			}
		}
		else
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
			ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
		}
	}
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local PlayerPawn PlayerOwner;
	local Pawn PawnOwner;
	
	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}

	PawnOwner = Pawn(Owner);
	if (STM != None)
		STM.PlayerFire(PawnOwner, 5);		// 5 = Shock Beam.

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}

	PlayerOwner = PlayerPawn(Owner);
	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.4, vect(450, 190, 650));
	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);

	if ( NN_ShockProjOwnerHidden(Other)!=None )
	{
		//AmmoType.UseAmmo(1);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);		// 5 = Shock Beam
		Other.SetOwner(Owner);
		NN_ShockProjOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( ST_ShockProj(Other)!=None )
	{
		//AmmoType.UseAmmo(1);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);		// 5 = Shock Beam
		ST_ShockProj(Other).SuperExplosion();
		return;
	}
	else if (bNewNet)
	{
		DoRingExplosion5(PlayerPawn(Owner), HitLocation, HitNormal);
	}
	else
	{
		Spawn(class'ut_RingExplosion5',,, HitLocation+HitNormal*8,rotator(HitNormal));
	}

	if ( (Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if (STM != None)
			STM.PlayerHit(PawnOwner, 5, False);			// 5 = Shock Beam
		Other.TakeDamage(HitDamage, PawnOwner, HitLocation, vect(0,0,0), MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}

	if (Pawn(Other) != None && Other != Owner && Pawn(Other).Health > 0)
	{	// We hit a pawn that wasn't the owner or dead. (How can you hit yourself? :P)
		HitCounter++;						// +1 hit
		if (HitCounter == 3)
		{	// Wowsers!
			HitCounter = 0;
			if (STM != None)
				STM.PlayerSpecial(PawnOwner, 5);		// 5 = Shock Beam
		}
	}
	else
		HitCounter = 0;
}

defaultproperties {
    PickupAmmoCount=100
	AltProjectileClass=Class'ST_ShockProjGib'
	hitdamage=1000
	InstFog=(X=800.000000,Z=0.000000)
	AmmoName=Class'Botpack.SuperShockCore'
	aimerror=650.000000
	DeathMessage="%k gibbed %o with the %w."
	PickupMessage="You got the ComboGib Rifle."
	ItemName="ComboGib Rifle"
}