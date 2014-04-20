PACKAGE: NewNet Server for UT99
VERSION: v0.9
AUTHOR:  Timothy Burgess
DATE:    2014-04-19


This package includes all files required to run a server with NewNet.

It includes an example server configuration (System/UnrealTournament.ini),
which consists of the absolute minimum set of ServerPackages and
ServerActors to run the mod.

Also included is MapVoteLA13.u and example config (System/MapVoteLA13.ini)
since it is so widely used.

Batch (.bat) files are included to help with quickly starting your server.




Integrating NewNet into an existing configuration:

1)  Stop your server if it is running.

2)  Copy all files within this package to your server's UT directory
    EXCEPT for the configuration files (UnrealTournament.ini and
    MapVoteLA13.ini) such that this package's System is merged with the
    server's and all of the batch files are within the UT directory.

3)  Update your server's System/UnrealTournament.ini:
    
    a)  Under [Engine.GameEngine] add:

        ServerPackages=2k4Combos
        ServerPackages=NewNetUnrealv0_9
        ServerPackages=NewNetWeaponsv0_9
        ServerActors=2k4Combos.CombosSA
    
    b)  If you aren't using MapVote, remove any reference to UTPure and
        then add:

        ServerActors=NewNetUnrealv0_9.NewNetServer
        ServerActors=NewNetWeaponsv0_9.PureStat

        To enable InstaGib, also add:
        ServerActors=NewNetIGv0_9.NewNetIG

        To enable Sniper Arena, also add:
        ServerActors=NewNetSAv0_9.NewNetSA
        
        To enable Shock Domination, also add:
        ServerActors=NewNetSDOMv0_9.NewNetSDOM
        
        To enable TeleGib, also add:
        ServerActors=NewNetTGv0_9.NewNetTG
        
        To enable DoubleJump, also add:
        ServerActors=NewNetUnrealv0_9.DoubleJump
        
        To enable AutoPause, also add:
        ServerActors=NewNetUnrealv0_9.PureAutoPause
    
    c)  If you are using MapVote, see the included MapVote configuration
        (System/MapVoteLA13.ini) for examples.
	
	d)  If you're running a linux server, remove all references to TF2.
    
    e)  If your server uses ACE, to ensure no issues,
        under [ACEv08h_S.ACEActor] add:

        UPackages[0]=NewNetUnrealv0_9.u
        UPackages[1]=NewNetWeaponsv0_9.u
    
    f)  Recommended settings under [IpDrv.TcpNetDriver]:
        MaxClientRate=25000
        NetServerMaxTickRate=65
        LanServerMaxTickRate=65
    
4)  Start your server!
    
    a)  If you're running it on a Windows server, run Server.bat or
        Server-NoMapVote.bat.
    
    b)  If you have a server provider that allows you to specify the command,
        you can copy it from one of the batch files.



        
Integrating NewNet into a fresh server configuration:

1)  Stop your server if it is running.

2)  Copy all files within this package to your server's UT directory
    such that this package's System is merged with the server's and
    all of the batch files are within the UT directory.
    
3)  Update your server's System/UnrealTournament.ini:
    
    a)  Under [Engine.GameReplicationInfo], set your ServerName, MOTD, etc.
    
    b)  If you would like to use MapVote, continue to Step 4.
    
    c)  If you would rather not use MapVote,
		under [Engine.GameEngine] add:
        
        ServerActors=NewNetUnrealv0_9.NewNetServer
        ServerActors=NewNetWeaponsv0_9.PureStat

        To enable InstaGib, also add:
        ServerActors=NewNetIGv0_9.NewNetIG

        To enable Sniper Arena, also add:
        ServerActors=NewNetSAv0_9.NewNetSA
        
        To enable Shock Domination, also add:
        ServerActors=NewNetSDOMv0_9.NewNetSDOM
        
        To enable TeleGib, also add:
        ServerActors=NewNetTGv0_9.NewNetTG
        
        To enable DoubleJump, also add:
        ServerActors=NewNetUnrealv0_9.DoubleJump
        
        To enable AutoPause, also add:
        ServerActors=NewNetUnrealv0_9.PureAutoPause
	
	d)  If you're running a linux server, remove all references to TF2.

4)  Start your server!
    
    a)  If you're running it on a Windows server, run Server.bat or
        Server-NoMapVote.bat.
    
    b)  If you have a server provider that allows you to specify the command,
        you can copy it from one of the batch files.



GL HF!
