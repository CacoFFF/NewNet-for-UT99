class NN_TranslocatorTarget extends TranslocatorTarget;

simulated function PreBeginPlay()
{
	if (Instigator == None)
		Instigator = Pawn(Owner);
	Super.PreBeginPlay();
}

simulated function bool Disrupted()
{
	return ( Disruption > DisruptionThreshold );
}

simulated function DropFrom(vector StartLocation)
{
	if ( !SetLocation(StartLocation) )
		return; 

	SetPhysics(PHYS_Falling);
	GotoState('PickUp');
}

simulated function Throw(Pawn Thrower, float force, vector StartPosition)
{
	local vector dir;

	dir = vector(Thrower.ViewRotation);
	if ( Thrower.IsA('Bot') )
		Velocity = force * dir + vect(0,0,200);
	else
	{
		dir.Z = dir.Z + 0.35 * (1 - Abs(dir.Z));
		Velocity = FMin(force,  Master.MaxTossForce) * Normal(dir);
	}
	bBounce = true;
	DropFrom(StartPosition);
}

auto state Pickup
{
	simulated event Landed( vector HitNormal )
	{
		Super.Landed(HitNormal);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxNN_MoveTTarget(Location, -1, Pawn(Owner));
	}
	
	simulated function AnimEnd()
	{
		local int glownum;
		
		if ( (Physics != PHYS_None) || (Glow != None) || (Instigator.PlayerReplicationInfo == None) || Disrupted() )
			return;

		glownum = Instigator.PlayerReplicationInfo.Team;
		if ( glownum > 3 )
			glownum = 0;
			
		Glow = spawn(GlowColor[glownum], self);
	}

	simulated event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
	{
		if (EventInstigator == Owner && bbPlayer(Owner) != None)
			bbPlayer(Owner).xxNN_MoveTTarget(Location, Damage, EventInstigator, HitLocation, Momentum, DamageType);
		
		SetPhysics(PHYS_Falling);
		Velocity = Momentum/Mass;
		Velocity.Z = FMax(Velocity.Z, 0.7 * VSize(Velocity));
		
		if ( EventInstigator == Owner
			|| (EventInstigator != None)
			&& (EventInstigator.PlayerReplicationInfo != None)
			&& (EventInstigator.PlayerReplicationInfo.Team == Pawn(Owner).PlayerReplicationInfo.Team) )
			return;
		
		Disruption += Damage;
		Disruptor = EventInstigator;
		if ( !Disrupted() )
			SetTimer(0.3, false);
		else if ( Glow != None )
			Glow.Destroy();
	}

	simulated singular function Touch( Actor Other )
	{
		local bool bMasterTouch;
		local vector NewPos;
		local ST_Translocator ST_Master;
		
		if (bDeleteMe || Other == None)
			return;
		
		if ( !Other.bIsPawn )
		{
			if ( (Physics == PHYS_Falling) && !Other.IsA('Inventory') && !Other.IsA('Triggers') && !Other.IsA('NavigationPoint') && !(Other.IsA('NN_TranslocatorTargetOwnerHidden') && Other.Owner == Owner) )
				HitWall(-1 * Normal(Velocity), Other);
			return;
		}
		bMasterTouch = ( Other == Instigator );
		
		if ( Physics == PHYS_None )
		{
			if ( bMasterTouch && Master != None )
			{
				PlayOwnedSound(Sound'Botpack.Pickups.AmmoPick',,2.0);
				Master.TTarget = None;
				Master.bTTargetOut = false;
				ST_Master = ST_Translocator(Master);
				if (ST_Master != None)
				{
					ST_Master.zzClientTTarget = None;
					ST_Master.bClientTTargetOut = false;
				}
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
		if ( (Level == None || Level.Game == None || Level.Game.bTeamGame)
			&& Instigator != None && (Instigator.PlayerReplicationInfo.Team == Pawn(Other).PlayerReplicationInfo.Team) )
			return;

		if ( Instigator != None && Instigator.IsA('Bot') && Master != None )
			Master.Translocate();
	}

	simulated function EndState()
	{
		DesiredTarget = None;
	}
}

defaultproperties
{
	bAlwaysRelevant=True
}