class ST_SuperShockRifleSingleShot extends ST_SuperShockRifle;

function SetWeaponStay()
{
    bWeaponStay = false;
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local Pawn PawnOwner;
	
	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}
		
	yModInit();

	PawnOwner = Pawn(Owner);

	if (STM != None)
		STM.PlayerFire(PawnOwner, 8);		// 8 = Super Shock

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}
	
	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);

	if (bNewNet && !bAltFired)
		DoSuperRing2(PlayerPawn(Owner), HitLocation, HitNormal);
	else
		Spawn(class'ut_SuperRing2',,, HitLocation+HitNormal*8,rotator(HitNormal));
	
	if (Other == None)
	{
		AmmoType.UseAmmo(1);	// single shot
	}
	else if ( (Other != self) && (Other != Owner) )
	{
		if (!Other.IsA('Pawn') && !Other.IsA('Projectile'))
			AmmoType.UseAmmo(1);	// single shot
		if (STM != None)
			STM.PlayerHit(PawnOwner, 8, (PawnOwner.Physics == PHYS_Falling) && (Other.Physics == PHYS_Falling));
						// 8 = Super Shock, Special if Both players are off the ground.
		Other.TakeDamage(HitDamage, PawnOwner, HitLocation, 60000.0*X, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}
}

defaultproperties {
    PickupAmmoCount=1
}