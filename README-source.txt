PACKAGE: NewNet Source for UT99
VERSION: v0.9
AUTHOR:  Timothy Burgess
DATE:    2014-04-19


This package includes NewNet's source code.

These instructions have been written with the assumption that you know how
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
