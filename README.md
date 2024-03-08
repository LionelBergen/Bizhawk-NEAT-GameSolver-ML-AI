Machine Learning SNES Game Solver
---------------------------------   
Uses The NEAT Machine Learning algorithm to solve various SNES games in Bizhawk (Snes/Nes emulator)  

Purpose
-------  
Easy to use readable program   
Program can be used to learn **any SNES/NES game**. The ROM.lua class just needs to be extended and functions written so program can calculate fitness and read values from whichever game.  

Quick Start
-----------  
Download bizhawk: https://tasvideos.org/Bizhawk     
Download ROM for game (E.G SMW)  
Run the ROM in bizhawk (File -> Open ROM)  
Get to the beginning of a level (or whatever state in the game you want) and create a `.state` file by going to `file -> save state -> save named  state..`. Give it a name and save it to THIS project directory, in `/asserts/savedstates/nameoffile.state`  
Change the `saveFileName` inside `NEATEvolve.lua` to have the filename E.G: `saveFileName = SMW.state`  
Run Lua script: `source/NEATEvolve.lua` in Bizhawk  
Optionally set speed to 400x in Bizhawk for faster learning (Config -> Speed/Skip -> 400x)  

**Important**: Bizhawk must be using 'Snes9x'. Otherwise the memory/tile functions act funky and the AI/program view will be off.   

**NOTE**: If you get an error similar to 'unprotected error in call to Lua API', make sure you've changed the state file to one to a recent one. An issue occurs if bizhawk updates, or the ROM was downloaded from a different place than the one used for the state file.   


Log File
--------  
Log file written to machine_learning_outputs/NEAT_PROGRAM.log  

Properties
----------   
NEAT/Machine Learning properties, such as Population, Mutation Chance ETC can be found inside machinelearning.ai.sstatic.Properties    
Game and other Properties can be found at the beginning of the main file.   


IDE Setup
---------   
In InteliJ, simply right click the 'scripts' folder, 'mark directory as', 'sources root'.  
Install Lua plugin if not installed. `EmmyLua`    

Running Tests
-------------  
Tests should be run using `lua tests.lua`. Currently the tests.lua file contains all tests. when a new test class is added it should be added to this class.   
Individual tests can also be run through InteliJ, modifying the path to be `/scripts` (removing `src/` from default inteliJ)  


Demo gif
--------

Latest run, completes level with 4727 fitness score by gen 15.  
![SMW Gen 15 complete level](./assets/docs/2024-02-20.gif)

