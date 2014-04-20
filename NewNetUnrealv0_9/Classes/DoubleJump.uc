class DoubleJump extends Mutator;

var localized config int   maxJumps;

function Tick( float Delta )
{
	local UTPure zzUTP;
	ForEach AllActors(class'UTPure', zzUTP)
	{
		Log("*** NEWNET DOUBLEJUMP ACTIVATED ***");
		zzUTP.bDoubleJump = true;
		zzUTP.maxJumps = maxJumps;
		zzUTP.default.bDoubleJump = true;
		zzUTP.default.maxJumps = maxJumps;
		Disable('Tick');
	}
}

defaultProperties {
	maxJumps=2
}