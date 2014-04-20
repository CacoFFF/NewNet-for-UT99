class NN_ChunkTrailOwnerHidden extends ChunkTrail;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		DrawType = DT_None;
		Style = STY_None;
		Sprite = None;
		Texture = None;
		Skin = None;
		DrawScale = 0;
		//ScaleGlow = 0;
		AmbientSound = None;
		//AmbientGlow = 0;
		//LightType = LT_None;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
		Destroy();
	}
}

defaultproperties {
	bOwnerNoSee=True
}
