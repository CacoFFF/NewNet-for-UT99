class NN_SpawnNotify extends SpawnNotify;

simulated event Actor SpawnNotification(Actor A)
{
	if (A.IsA('Carcass'))
		A.SetCollision(false, false, false);
	return A;
}