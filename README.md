NewNet-for-UT99
===============

Modern Netcode for UT99 (AKA a bunch of hacks on top of a 15 year old engine!)

I'll make a nice README.md later on but for now, let's copy and paste the original README(s).

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
    
3)  Start your server!
    
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

3)  Start your server!
    
    a)  If you're running it on a Windows server, run Server.bat or
        Server-NoMapVote.bat.
    
    b)  If you have a server provider that allows you to specify the command,
        you can copy it from one of the batch files.



GL HF!









PACKAGE: NewNet Source for UT99
VERSION: v0.9
AUTHOR:  Timothy Burgess
DATE:    2014-04-19


This package includes NewNet's source code.

These guidelines have been written with the assumption that you know how
to compile new mods for UT.  Any referenced file not within this package
can be found in the server package (NewNetv0.9-server).

The example configuration (System/UnrealTournament.ini) includes the
set of EditPackages (under [Editor.EditorEngine]) used for properly
compiling this version of NewNet and its mods.


Dependencies:
- Use patch 451b to compile!
- System/2k4Combos.u
- System/Engine.u (modified to allow assigning of constant variables)


Instructions for creating your own version of NewNet:

1)  Copy all files within this package to your UT directory.

2)  Make a copy of the source files and give them a new version number
    and/or name.  A batch file (Copy.bat) has been included to make this
    quick and easy.  Feel free to edit Copy.bat to give it a unique name.
    
3)  You'll need to edit the following files to match the new name/version:
    - Make.bat
    - Compress.bat
    - System/UnrealTournament.ini
    - System/MapVoteLA.ini (if applicable)
    - <Copy of NewNetUnrealv0_9>/Classes/UTPure.uc
        Note: Under DefaultProperties, you should update both ThisVer and
        NiceVer. If you've modified the actual name, update VersionStr,
        and within <Copy of NewNetWeaponsv0_9>/Classes/ST_Mutator.uc,
        you'll need to update PreFix to match the new name.

4)  Modify the source code as you see fit.

5)  I've included batch files to quickly compile your changes (Make.bat)
    and compress the new files for redirect (Compress.bat).



Some final notes:

A list of all changes before this release can be found in
ChangeLog-PreRelease.txt, and my personal todo list can be found in
TODO.txt.  I have no idea if/when I'll have time to resume working on
this mod, so feel free to knock those out if you're up for it.

Admittedly, a lot of this code is a jumbled mess, and I was hoping that
before releasing the source, I'd have time to clean it up and make it more
readable, easily extendable, and more compatible with other mods, but it
is what it is.

You'll find that the vast majority of the code lies within bbPlayer,
which certainly isn't the best way to do things in an ideal world, but
given the limitations with Unreal Engine 1, it's the best way to achieve
most of the mod's goals.  A handful of concepts can likely be factored out
into separate classes containing static methods, but for certain concepts,
you may run into issues with the number of arguments you can pass to said
methods.  A prime example is the lagless movers (which is currently
disabled via commenting).

You'll also find quite a few strange hacks and go "WTF?", but without
proper access to lower level parts of the engine, I found most of these
hacks to be necessary, regardless of how inefficient.

I hope this covers everything and I look forward to seeing what others
come up with!  Enjoy!
