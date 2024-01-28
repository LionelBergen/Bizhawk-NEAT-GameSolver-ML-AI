Notice
------
All credit goes to 'SethBling', video here: https://www.youtube.com/watch?v=qv6UVOQ0F44&ab_channel=SethBling  

Purpose
-------  
I've simply modified the original code in order to better understand it, and add readability, reusability and better error messages

Quick Start
-----------  
Download bizhawk: https://tasvideos.org/Bizhawk   
Download ROM for game (E.G SMW)  
Run the game, and create a `.state` file, at the beginning of the level, give it a name and save it to `/asserts/savedstates/nameoffile.state`  
Change the `saveFileName` inside `NEATEvolve.lua` to have the filename E.G: `saveFileName = SMW.state`  
Run Lua script: `source/NEATEvolve.lua` in Bizhawk  

**Important**: Bizhawk must be using 'Snes9x'. Otherwise the memory/tile functions act funky and the AI/program view will be off.   

**NOTE**: If you get an error similair to 'unprotected error in call to Lua API', make sure you've changed the state file to one to a recent one. An issue occurs if bizhawk updates, or the ROM was downloaded from a different place than the one used for the state file.   





Properties
----------
Properties can be found at the beginning of the main file;
