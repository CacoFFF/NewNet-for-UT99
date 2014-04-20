class NN_ShockProjOwnerHidden extends ST_ShockProj;

var bool bAlreadyHidden;
var float NN_OwnerPing, NN_EndAccelTime;

replication
{
	reliable if ( Role == ROLE_Authority )
		NN_OwnerPing;
}

simulated function Tick(float DeltaTime)
{
	local Pawn P;
	
	if (Level.NetMode == NM_Client) {
	
		if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
			LightType = LT_None;
			SetCollisionSize(0, 0);
			bAlreadyHidden = True;
			Destroy();
			return;
		}
		
		if (NN_OwnerPing > 0)
		{
			if (NN_EndAccelTime == 0)
			{
				Velocity *= 2;
				NN_EndAccelTime = Level.TimeSeconds + NN_OwnerPing * Level.TimeDilation / 2500;
				for (P = Level.PawnList; P != None; P = P.NextPawn)
					if (PlayerPawn(P) != None && Viewport(PlayerPawn(P).Player) != None)
						NN_EndAccelTime += P.PlayerReplicationInfo.Ping * Level.TimeDilation / 2500;
			}
			else if (Level.TimeSeconds > NN_EndAccelTime)
			{
				Velocity = Velocity / 2;
				NN_OwnerPing = 0;
			}
		}
		
	}
	
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
	local bbPlayer bbP;
	
	if (bDeleteMe)
		return;
	if (STM != None)
		STM.PlayerHit(Instigator, 6, False);	// 6 = Shock Ball
	//Log(Class.Name$" (Explode) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (!bbPlayer(Owner).bNewNet)
		HurtRadius(Damage, 70, MyDamageType, MomentumTransfer, Location );
	if (STM != None)
		STM.PlayerClear();
	
	DoExplode(Damage, HitLocation, HitNormal);
	PlayOwnedSound(ImpactSound, SLOT_Misc, 0.5,,, 0.5+FRand());
	
	bbP = bbPlayer(Instigator);
	if (bbP != None && Level.NetMode != NM_Client)
	{
		bbP.xxNN_ClientProjExplode(zzNN_ProjIndex, HitLocation, HitNormal);
	}
	
	Destroy();
}

simulated function DoExplode(int Dmg, vector HitLocation,vector HitNormal)
{
	local Pawn P;
	local Actor CR;

	if (RemoteRole < ROLE_Authority) {
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (P != Instigator) {
				if (Dmg > 60)
					CR = P.Spawn(class'ut_RingExplosion3',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				else
					CR = P.Spawn(class'ut_RingExplosion',P,, HitLocation+HitNormal*8,rotator(Velocity));
				CR.bOnlyOwnerSee = True;
			}
	}
}

function SuperExplosion()	// aka, combo.
{	
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	//Log(Class.Name$" (SuperExplosion) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (!bbPlayer(Owner).bNewNet)
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	if (STM != None)
		STM.PlayerClear();
	
	DoSuperExplosion();
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	//Spawn(Class'ut_ComboRing',,'',Location, Instigator.ViewRotation);
	//PlaySound(ExploSound,,20.0,,2000,0.6);
	if (bbPlayer(Instigator) != None)
		bbPlayer(Instigator).xxNN_ClientProjExplode(-1*(zzNN_ProjIndex + 1));
	
	Destroy(); 
}

simulated function DoSuperExplosion()
{
	local Pawn P;
	local Actor CR;

	if (RemoteRole < ROLE_Authority) {
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (P != Owner) {
				CR = P.Spawn(Class'ut_ComboRing',P,'',Location, Pawn(Owner).ViewRotation);
				CR.bOnlyOwnerSee = True;
			}
	}
}

function SuperDuperExplosion()	// aka, combo.
{	
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	//Log(Class.Name$" (SuperExplosion) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (!bbPlayer(Owner).bNewNet)
		HurtRadius(Damage*9, 750, MyDamageType, MomentumTransfer*6, Location );
	if (STM != None)
		STM.PlayerClear();
	
	DoSuperDuperExplosion();
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	//Spawn(Class'UT_SuperComboRing',,'',Location, Instigator.ViewRotation);
	//PlaySound(ExploSound,,20.0,,2000,0.6);
	if (bbPlayer(Instigator) != None)
		bbPlayer(Instigator).xxNN_ClientProjExplode(-1*(zzNN_ProjIndex + 1));
	
	Destroy(); 
}

simulated function DoSuperDuperExplosion()
{
	local Pawn P;
	local Actor CR;

	if (RemoteRole < ROLE_Authority) {
		for (P = Level.PawnList; P != None; P = P.NextPawn)
			if (P != Owner) {
				CR = P.Spawn(Class'UT_SuperComboRing',P,'',Location, Pawn(Owner).ViewRotation);
				CR.bOnlyOwnerSee = True;
			}
	}
}

defaultproperties {
	bOwnerNoSee=True
}