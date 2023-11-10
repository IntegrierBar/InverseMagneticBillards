# InverseMagneticBillards
A simulator of inverse magnetic billard for polygonal tables written with Godot 3.5.2.


## How to use
The simulator is split into 3 spaces (regular space, flow map and phase space) and 2 controls (main control and phase space control).

Both flow map and phase space use inverted y-Axis.

All spaces have their own camera that can zoom and be dragged by holding the right mouse button.

### Regular Space
The regular space shows the polygon and the trajectory as polygonal lines.


### Phase Space
The phase space will show the trajecotries as points inside the phase space. The x-axis is the polygon and the y-Axis the angle with the positive tangent.

#### Spawning Trajectories
The control center for the phase space allows for 3 different methods of creating new trajectories.

For individual trajectories the color can be chosen with the color selector "Trajectory Color".  
The checkmark "Trajectory Drawn in Regular Space" decides whether the spawned trajectories should also be drawn in regular space.

##### 1. On Click
After pressing the button left clickin inside the phase space will create a new trajectory with those coordinates.
###### muahaha
##### 2. On Coordinates
Typing the phase space coordinates (first is polygon, second is angle) and then pressing the button "Spawn PS trajectory on Coordinates" will create a trajectory at those coordinates.

##### 3. Batch
By pressing the button "Spawn PS Trajectory Batch" you can specify a rectangular area inside the phase space by left clicking at two positions.  
Then "#Trajectories in Batch" trajectories will be evenly created inside this rectangle.  
The color of the trajectories is a predefined color gradient.

Due to problems with browsers it is not recomended to spawn more then 20 trajectories in one batch.  

#### Fill Phase Space
By pressing to button "Start to fill phase space" the program will automatically find the largest sqaure hole and spawn a new trajectory at the upper left corner (lower left in terms of coordinates).  
In order to to generate a gradient, the program will check if there is another trajectory close to it.  
If yes, it will choose a similar color for the new trajectory.
Otherwise the color is random.
Afterwards the all trajectories are iterated "#Iterations" times.

The program will repeat this process every frame as often as is specified in the "#trajectories to spawn" field.

The program calculates the holes by dividing the phase space into a squared grid.
The grid size (how many cells in each direction) can be specified in the "grid size" field.

#### Clear Phase Space
By clicking this button, all points are deleted from the phase space.  
This will only visualy clear the phase space.
It will not affect the actual trajectories.
Only the main control is able to do that

#### Save Phase Space
Will write the phase space trajectories of all trajectories to a file and save it.  
If running in a browser it will be saved as a download.  
On PC it will save the file in "AppData"...

### Flow Map
The flow map shows the flow map of the current system. Controls can be opened under "Flow Map Control".


## How to compile
The code is split into 2 parts.

The code inside the GDNative fodler is the C++ code for the calculations.   
Compilation is only required if you do not compile for windows or web.

The code inside the Godot folder is the Godot project itself.

### Requirements
Godot version 3.5.2 Standard (https://godotengine.org/download/archive/3.5.2-stable/)

If you need to compile the GDNative part as well, a C++ compiler and CMake is required.  
For Web compilation use emscripten (https://emscripten.org/).

### Compiling GDNative
If you are compiling for Windows or web this part can be skipped.

First compile the project inside the GDNative folder using cmake.  
(If you are using emscripten, simply using the commands "emcmake" and "emmake" should suffice).

Next copy the compiled library into "Godot/GDNative".

If you are not compiling for Windows or web, you will need to register it inside the Godot project.  
For this open the Project with Godot and in the file system open the "GDNative/InverseMagneticBillard.tres".  
This will open up a list in the bottom of the center.   
Find you target system, click the folder icon int the middle and select the library you just compiled.

### Compiling the Project
Detailed explenation can be found in the official Godot docs (https://docs.godotengine.org/en/3.5/tutorials/export/exporting_projects.html)

Open the project with Godot (Godot/project.godot).  
First add the export templates by clicking "Editor->Manage Export Templates" and downloading them.

Then click on "project->Export".  
Add the export target if it is not already there and click "Export Project".

When compiling for web, make sure the export type is set to GDNative.