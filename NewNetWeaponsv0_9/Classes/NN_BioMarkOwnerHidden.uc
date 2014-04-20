class NN_BioMarkOwnerHidden extends BioMark;

simulated function BeginPlay()
{
	if (bNetOwner)
		Texture = None;
	else if ( !Level.bDropDetail && (FRand() < 0.5) )
		Texture = texture'Botpack.biosplat2';
}

defaultproperties
{
	bOwnerNoSee=True
}