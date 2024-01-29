# InverseMagneticBilliards
A simulator of inverse magnetic billard for polygonal tables written with Godot 3.5.2.

Web Version can be found here: https://integrierbar.github.io/InverseMagneticBillards/

## Inverse Magnetic Billiards
While classical billiard can be thought of as a ball traveling inside a table bouncing at the border, 
in inverse magnetic billiard the table does not have a border where the ball can bounce.
Instead outside the table is a constant magnetic field and the ball is electrically charged.
As a consequence, as soon as the ball leaves the table it travels on a circlular path until it enters the table again where it continues in a straight path.

This system is of interest as the edgecases for the magnetic field strength are already known.
- If the field strength is infinitely strong, the resulting system is classical billiards.
- If the field strength is near 0, the table does not matter and the ball just travels on a giant circle.

## How to use
The simulator is split into 3 spaces (regular space, flow map and phase space) and 2 controls (main control and phase space control).

Both flow map and phase space use inverted y-Axis.

All spaces have their own camera that can zoom and be dragged by holding the right mouse button.

### Input Fields
Every user input field that immediately effects the system (like changing coordinates) will only update after the you press enter.


### Regular Space
The regular space shows the polygon and the trajectory as polygonal lines.

#### Billiard Type
Currently the programm can do both inverse magnetic billiard and symplectic billiard.  
You can choose which one it should be via a drop down menu.

Changing the type will reset all trajectories but not delete them.

#### Stop When Hitting a Vertex
Decides if a trajectory should stop iterating when it gets to close to a vertex or should continue.

#### Iterate
Pressing the "Iterate" button will iterate all trajectories by the "#iterations".  
"Max. #Iterations" sets a maximum number of iterations to be done for all trajectories.  
Once this number is reached the trajectories will not iterate further.

#### Radius
Both a numerical field and a slider from 0.01 to 20 allow you to change the radius of the billiard ball outside the table.  
radius = 1/field strength

#### Polygon
By pressing the "Choose New Polygon" button the current polygon and all trajectories are deleted.  
By left clicking inside the regular space you can now add a vertex to the new polygon at the mouse position.  
By clicking the "Close Countout" button, middle mouse button, the ESC key or "C" you will close the polygon.  
As long as the polygon is not closed, no trajectories can be created.  

Polygon vertices can be dragged using left mouse button at any time.  
Doing so will reset all trajectories to their phase space coordinates (NOT their R2 coordinates).

Clicking the button "Draw Regular n-gon" will automatically create a Regular n-gon with the number of vertices specified in "#Vertices and radius specified in "n-gon Radius".

#### Vertex Control
Clicking the "Open Vertex Cotrol" will open a new window where you can type in the coordinates of the vertices of the polygon.  

#### Flow Map Control
This button opens the control panel for the flow map.  
See below for more information.

#### Trajectories
"Delete All Trajectories" will delete all trajectories.  
"Reset All Trajectories" will reset them to their initial state, removing any iterations previously done.

Pressing "Add New Trajectory" creates a new trajectorie with a random color.  
The initial position and the direction are specified by clicking inside the Regular Space.

For any existing trajectory a new set of buttons is spawned.  
"New Start Position" allows you to again choose the start position and direction inside the Regular Space.  
"Delete Trajectory" will delete this single trajectory.  
The two input fields are the position and the direction in R2. By editing these fields and pressing enter, you can specify your own coordiniates.  
The color selection panel allows you to change the color of the trajectory.



### Phase Space
The phase space will show the trajecotries as points inside the phase space. The x-axis is the polygon and the y-Axis the angle with the positive tangent.

#### Points Per Multimesh
For drawing inside the phase space the programm uses Multimeshes.  
However due to hardware and software constraints only a certain number of multimeshes can be used and every multimesh can only display a certain number of points.  
These constraints are determined by the users system and can therefore not be calculated in advance.  
If there are more points per multimesh or multimeshes then your system can handle, the program will crash.  
Therefore you want the #Points Per Multimesh to be as large as possible.

Most system should be able to handle 1,000,000 points per Multimesh.

To update to the new value, press enter inside the input field.

#### Spawning Trajectories
The control center for the phase space allows for 3 different methods of creating new trajectories.

For individual trajectories the color can be chosen with the color selector "Trajectory Color".  
The checkmark "Trajectory Drawn in Regular Space" decides whether the spawned trajectories should also be drawn in regular space.

##### 1. On Click
After pressing the button left clickin inside the phase space will create a new trajectory with those coordinates.

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

##### Example of Usage
Let's say we want to add 1000 individual trajectories, each iterated 1000 times.

First in "#Trajectories to Spawn" inside the Phase Space Control panel we input 1000.
Next we have to decide on a grid size. 
If we want to spawn 1000 trajectories, then we need Grid Size of at least $\sqrt{1000} \approx 32$.
However if we iterate the trajectories everytime they are added before adding the next trajectory, we will need a much larger Grid Size, as each trajectory will fill multiple cells of the grid.

If you want to iterate trajectories everytime they are added, it is probably best to think more about the Grid Size, i.e. how dense the phase space should be in the end, and then just putting a large number into "#Trajectories to Spawn".
The algorithm will stop automatically if the grid is full.
However note that the algorithm scales heavily (between power of 2 and 4) with the Grid Size. 
So if this number is too large for your system, it might take a while to calculate.

Next make sure you are zoomed out far enough in the Phase Space Window so you can see the entire phase space (the black square). Or are zoomed into the part of the phase space you want filled.
The algorithm will only spawn trajectories in the part of the phase space that is currently visible.

In case you don't want all spawned trajectories drawn in the Regular Space as well, make sure to uncheck the box "Trajecotries Drawn in Regular Space".

Then go to the main control panel on the left.
If you want to first add all trajectories and then iterate them together, put 0 into the box "#Iterations" and 1000 into "Max. #Iterations".
Then click "Start to Fill Phase Space".
The programm should then have created 1000 individual trajectories.
Finaly put 1000 into "#Iterations" and click the "Iterate" button.

If you want each trajectory to iterate before you spawn the next trajectory, put 1000 into both "#Iterations" and "Max. #Iterations" and then click "Start to Fill Phase Space".


#### Clear Phase Space
By clicking this button, all points are deleted from the phase space.  
This will only visualy clear the phase space.
It will not affect the actual trajectories.
Only the main control is able to do that

#### Save Phase Space
Will write the phase space trajectories of all trajectories to a file and save it.  
If running in a browser it will be saved as a download.  
On PC it will save the file in "%APPDATA%\Godot\app_userdata\InverseMagneticBillard"



### Flow Map
The flow map shows the flow map of the current system. Controls can be opened under "Flow Map Control".  
The flow map is calculated by iterating each pixel and then setting the color red as the position and the color green as the angle.

"#Iterations" will specify how many iterations should be done.

With the forwards/backwards toggle you can decide whether the system should iterate forwards or iterate backwards.

#### Color Coding
With these toggles you can deactivate position or angle to show in the color.  

#### FTLE
By switching this toggle you can alternatively look at the FTLE of the phase space.  
This is calculated by spawning 4 trajectories around the pixel, thus approximating the jacobian at the point.  
The color is then the largest eigenvalue of the Jacobian.

The step size modifier allows you to decide how far away the trajectories should be from the pixel.  
The distance from the pixel is then given as the product of the step size modifier and the zoom factor of the camera.

#### On Click
By left clicking inside the flow map you can either show the trajectory started at that point in the Regular Space or spawn a trajectory with those phase space coordinates.

If you are currently showing a trajectory you can press the button "Spawn Currently Shown Trajectory" to spawn a trajectory with those coordinates.  
To stop showing the trajectory in Regular Space, simply left click anywhere inside the Regular Space.


## How to compile
The code is split into 2 parts.

The code inside the GDNative folder is the C++ code for the calculations.   
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