class NN_PlasmaCapOwnerHidden extends PlasmaCap;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		LightType = LT_None;
		AmbientGlow=0;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
	}
}

defaultproperties {
	bOwnerNoSee=True
}