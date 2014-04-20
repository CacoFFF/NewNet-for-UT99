class ST_ShockProjGib extends ST_ShockProj;

function SuperExplosion()	// aka, combo.
{	
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_ShockProjOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', Damage*3000, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex, true );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3000, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	if (STM != None)
		STM.PlayerClear();
	
	Spawn(Class'ut_ComboRing',,'',Location, Instigator.ViewRotation);
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	
	Destroy(); 
}

function SuperDuperExplosion()	// aka, combo.
{	
	local bbPlayer bbP;
    local UT_SuperComboRing Ring;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_ShockProjOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', Damage*9000, 750, MyDamageType, MomentumTransfer*6, Location, zzNN_ProjIndex, true );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*9000, 750, MyDamageType, MomentumTransfer*6, Location );
	}
	if (STM != None)
		STM.PlayerClear();
	
	Ring = Spawn(Class'UT_SuperComboRing',,'',Location, Instigator.ViewRotation);
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	
	Destroy(); 
}

simulated function NN_SuperExplosion(Pawn Pwner)	// aka, combo.
{
	local rotator Tater;
	local bbPlayer bbP;
    local UT_ComboRing Ring;
	
	bbP = bbPlayer(Pwner);
		
	if (bbP != None)
		Tater = bbP.zzViewRotation;
	else
		Tater = Pwner.ViewRotation;
		
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client)
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', Damage*3000, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex, true );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3000, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	Ring = Spawn(Class'ut_ComboRing',Pwner,'',Location, Tater);
	PlaySound(ExploSound,,20.0,,2000,0.6);
    if(bbP != none)
    {
        bbP.xxClientDemoFix(Ring, Class'UT_ComboRing', Location, Ring.Velocity, Ring.Acceleration, Tater);
    }
	
	Destroy();
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if (bDeleteMe)
		return;
	
	if (STM != None)
		STM.PlayerHit(Instigator, 6, False);	// 6 = Shock Ball
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_ShockProjOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', 0, 70, MyDamageType, MomentumTransfer, Location, zzNN_ProjIndex, true );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		}
	}
	else
	{
		HurtRadius(0, 70, MyDamageType, MomentumTransfer, Location );
	}
	NN_Momentum( 70, MomentumTransfer, Location );
	if (STM != None)
		STM.PlayerClear();

	if (Damage > 60)
		Spawn(class'ut_RingExplosion3',,, HitLocation+HitNormal*8,rotator(HitNormal));
	else
		Spawn(class'ut_RingExplosion',,, HitLocation+HitNormal*8,rotator(Velocity));
		
	PlayOwnedSound(ImpactSound, SLOT_Misc, 0.5,,, 0.5+FRand());

	Destroy();
}

defaultProperties {
	MomentumTransfer=0
}