class NN_TranslocGoldOwnerHidden extends TranslocGold;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		if (Level.NetMode == NM_Client)
			Destroy();
		bAlreadyHidden = True;
	}
}

defaultproperties
{
	bOwnerNoSee=true
}