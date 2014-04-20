class NN_RipperPulseOwnerHidden extends RipperPulse;

var bool bAlreadyHidden;

simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_Client && !bNetOwner )
		MakeSound();
	if ( Level.bDropDetail )
		LightRadius = 5;
//	Texture = SpriteAnim[int(FRand()*5)];
	//Super.PostBeginPlay();		
}

simulated function Tick(float DeltaTime) {
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
		NumFrames = 0;
		Pause = 0;
		EffectSound1 = None;
		LightEffect = LE_None;
		LightBrightness = 0;
		DrawType = DT_None;
		Style = STY_None;
		Sprite = None;
		Texture = None;
		Skin = None;
		DrawScale = 0;
		ScaleGlow = 0;
		AmbientSound = None;
		AmbientGlow = 0;
		LightRadius = 0;
		LightType = LT_None;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
		Destroy();
	}
}

defaultproperties {
	bOwnerNoSee=True
}