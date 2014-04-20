class NN_TranslocatorTargetOwnerHidden extends TranslocatorTarget;

var bool bAlreadyHidden;

auto state Pickup
{
	simulated function Timer()
	{
		local Pawn P;

		if ( (Physics == PHYS_None) && (Role != ROLE_Authority)
			&& (RealLocation != Location) && (RealLocation != vect(0,0,0)) )
				SetLocation(RealLocation);

		//disruption effect
		if ( Disrupted() )
		{
			if (!bNetOwner && Level.NetMode != NM_DedicatedServer)
				Spawn(class'Electricity',,,Location + Vect(0,0,6));
			PlayOwnedSound(sound'TDisrupt', SLOT_None, 4.0);
		}
		else
		{
			// tell local bots about self
			for ( P=Level.PawnList; P!=None; P=P.NextPawn )
				if ( P.IsA('Bot') && (P.Weapon != None) && !P.Weapon.bMeleeWeapon
					&& (!Level.Game.bTeamGame || (P.PlayerReplicationInfo.Team != Pawn(Master.Owner).PlayerReplicationInfo.Team)) )
				{
					if ( (VSize(P.Location - Location) < 500) && P.LineOfSightTo(self) )
					{
						Bot(P).ShootTarget(self);
						break;
					}
					else if ( P.IsInState('Roaming') && Bot(P).bCamping
								&& Level.Game.IsA('DeathMatchPlus') && DeathMatchPlus(Level.Game).CheckThisTranslocator(Bot(P), self) )
					{
						Bot(P).SetPeripheralVision();
						Bot(P).TweenToRunning(0.1);
						Bot(P).bCamping = false;
						Bot(P).GotoState('Roaming', 'SpecialNavig');
						break;
					}
				}
		}
		AnimEnd();
		SetTimer(1 + 2 * FRand(), false);
	}

	simulated event Landed( vector HitNormal )
	{
		local rotator newRot;
		
		if (bDeleteMe || Mesh == None)
			return;

		SetTimer(2.5, false);
		newRot = Rotation;
		newRot.Pitch = 0;
		newRot.Roll = 0;
		SetRotation(newRot);
		PlayAnim('Open',0.1);
		if ( Role == ROLE_Authority )
		{
			//bbPlayer(Owner).xxNN_MoveClientTTarget(Location, -1, Pawn(Owner));
			RemoteRole = ROLE_DumbProxy;
			RealLocation = Location;
			if ( Master.Owner.IsA('Bot') )
			{
				if ( Pawn(Master.Owner).Weapon == Master )
					Bot(Master.Owner).SwitchToBestWeapon();
				LifeSpan = 10;
			}
			Disable('Tick');
		}
	}		

	function AnimEnd()
	{
		local int glownum;

		if ( (Physics != PHYS_None) || (Glow != None) || (Instigator.PlayerReplicationInfo == None) || Disrupted() )
			return;

		glownum = Instigator.PlayerReplicationInfo.Team;
		if ( glownum > 3 )
			glownum = 0;

		Glow = spawn(GlowColor[glownum], self);
	}

	event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
	{
		if (bbPlayer(Owner) != None && bbPlayer(Owner).bNewNet && EventInstigator != Owner)
			bbPlayer(Owner).xxNN_MoveClientTTarget(Location, Damage, EventInstigator, HitLocation, Momentum, DamageType);
			
		SetPhysics(PHYS_Falling);
		Velocity = Momentum/Mass;
		Velocity.Z = FMax(Velocity.Z, 0.7 * VSize(Velocity));

		if ( Level.Game.bTeamGame && (EventInstigator != None)
			&& (EventInstigator.PlayerReplicationInfo != None)
			&& (EventInstigator.PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team) )
			return;

		Disruption += Damage;
		Disruptor = EventInstigator;
		if ( !Disrupted() )
			SetTimer(0.3, false);
		else if ( Glow != None )
			Glow.Destroy();
	}

	singular function Touch( Actor Other )
	{
		local bool bMasterTouch;
		local vector NewPos;

		if (bDeleteMe)
			return;
		
		if ( !Other.bIsPawn )
		{
			if ( (Physics == PHYS_Falling) && !Other.IsA('Inventory') && !Other.IsA('Triggers') && !Other.IsA('NavigationPoint') )
				HitWall(-1 * Normal(Velocity), Other);
			return;
		}
		bMasterTouch = ( Other == Instigator );
		
		if ( Physics == PHYS_None )
		{
			if ( bMasterTouch )
			{
				PlayOwnedSound(Sound'Botpack.Pickups.AmmoPick',,2.0);
				Master.TTarget = None;
				Master.bTTargetOut = false;
				if ( Other.IsA('PlayerPawn') )
					PlayerPawn(Other).ClientWeaponEvent('TouchTarget');
				destroy();
			}
			return;
		}
		if ( bMasterTouch ) 
			return;
		NewPos = Other.Location;
		NewPos.Z = Location.Z;
		SetLocation(NewPos);
		Velocity = vect(0,0,0);
		if ( Level.Game.bTeamGame
			&& (Instigator.PlayerReplicationInfo.Team == Pawn(Other).PlayerReplicationInfo.Team) )
			return;

		if ( Instigator.IsA('Bot') )
			Master.Translocate();
	}

	simulated function HitWall (vector HitNormal, actor Wall)
	{
		if ( bAlreadyHit )
		{
			bBounce = false;
			return;
		}
		bAlreadyHit = ( HitNormal.Z > 0.7 );
		PlayOwnedSound(ImpactSound, SLOT_Misc);	  // hit wall sound
		Velocity = 0.3*(( Velocity dot HitNormal ) * HitNormal * (-2.0) + Velocity);   // Reflect off Wall w/damping
		speed = VSize(Velocity);
	}

	simulated function Tick(float DeltaTime)
	{
		if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
			if (Level.NetMode == NM_Client) {
				Mesh = None;
				SetCollisionSize(0, 0);
				SetCollision(false,false,false);
				Destroy();
			} else if (Level.NetMode != NM_DedicatedServer) {
				ImpactSound = Sound'UnrealShare.Eightball.GrenadeFloor';
				AmbientSound = Sound'Botpack.Translocator.targethum';
			}
			bAlreadyHidden = True;
			return;
		}
		if ( Level.bHighDetailMode && (Shadow == None)
			&& (PlayerPawn(Instigator) != None) && (ViewPort(PlayerPawn(Instigator).Player) != None)
			&& !bNetOwner && Level.NetMode != NM_DedicatedServer )
			Shadow = spawn(class'TargetShadow',self,,,rot(16384,0,0));

		if ( Role != ROLE_Authority )
		{
			Disable('Tick');
			return;
		}
		if ( (DesiredTarget == None) || (Master == None) )
		{
			Disable('Tick');
			if ( Master.Owner.IsA('Bot') && (Pawn(Master.Owner).Weapon == Master) )
				Bot(Master.Owner).SwitchToBestWeapon();
			return;
		}

		if ( (Abs(Location.X - DesiredTarget.Location.X) < Master.Owner.CollisionRadius)
			&& (Abs(Location.Y - DesiredTarget.Location.Y) < Master.Owner.CollisionRadius) )
		{
			if ( !FastTrace(DesiredTarget.Location, Location) )
				return;	

			Pawn(Master.Owner).StopWaiting();
			Master.Translocate();
			if ( Master.Owner.IsA('Bot') && (Pawn(Master.Owner).Weapon == Master) )
				Bot(Master.Owner).SwitchToBestWeapon();
			Disable('Tick');
		}
	}

	simulated function BeginState()
	{
		SpawnTime = Level.TimeSeconds;
		TweenAnim('Open', 0.1);
	}

	function EndState()
	{
		DesiredTarget = None;
		if ( (Master != None) && (Master.Owner != None)
			&& Master.Owner.IsA('Bot') && (Pawn(Master.Owner).Weapon == Master) )
			Bot(Master.Owner).SwitchToBestWeapon();
	}
}

simulated function Tick(float DeltaTime) {
	if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		if (Level.NetMode == NM_Client) {
			Mesh = None;
			SetCollisionSize(0, 0);
			SetCollision(false,false,false);
			Destroy();
		} else if (Level.NetMode != NM_DedicatedServer) {
			ImpactSound = Sound'UnrealShare.Eightball.GrenadeFloor';
			AmbientSound = Sound'Botpack.Translocator.targethum';
		}
		bAlreadyHidden = True;
	}
}

defaultproperties
{
	bAlwaysRelevant=True
	ImpactSound=None
	AmbientSound=None
	bOwnerNoSee=True
	GlowColor(0)=Class'NN_TranslocGlowOwnerHidden'
	GlowColor(1)=Class'NN_TranslocBlueOwnerHidden'
	GlowColor(2)=Class'NN_TranslocGreenOwnerHidden'
	GlowColor(3)=Class'NN_TranslocGoldOwnerHidden'
}