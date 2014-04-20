class NN_RocketTrailOwnerHidden extends RocketTrail;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		Sprite = None;
		Texture = None;
		Skin = None;
		bAlreadyHidden = True;
	}
}

defaultproperties
{
	bOwnerNoSee=True
}
