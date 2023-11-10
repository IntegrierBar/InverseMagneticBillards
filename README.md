# InverseMagneticBillards
A simulator of inverse magnetic billard for polygonal tables written with Godot 3.5.2.


# How to use
The simulator is split into 3 spaces (regular space, flow map and phase space) and 2 controlls (main control and phase space control).

Both flow map and phase space use inverted y-Axis.

### Regular Space
The regular space shows the polygon and the trajectory as polygonal lines.

### Flow Map
The flow map shows the flow map of the current system. Controls can be opened under "Flow Map Control".

## Phase Space
The phase space will show the trajecotries as points inside the phase space. The x-axis is the polygon and the y-Axis the angle with the positive tangent.

### Fill Phase Space


# How to compile
The code is split into 2 parts.

The code inside the GDNative fodler is the C++ code for the calculations.   
Compilation is only required if you do not compile for windows or web.

The code inside the Godot folder is the Godot project itself.

## Requirements
Godot version 3.5.2 Standard (https://godotengine.org/download/archive/3.5.2-stable/)

If you need to compile the GDNative part as well, a C++ compiler and CMake is required.  
For Web compilation use emscripten (https://emscripten.org/).

## Compiling GDNative
If you are compiling for Windows or web this part can be skipped.

First compile the project inside the GDNative folder using cmake.  
(If you are using emscripten, simply using the commands "emcmake" and "emmake" should suffice).

Next copy the compiled library into "Godot/GDNative".

If you are not compiling for Windows or web, you will need to register it inside the Godot project.  
For this open the Project with Godot and in the file system open the "GDNative/InverseMagneticBillard.tres".  
This will open up a list in the bottom of the center.   
Find you target system, click the folder icon int the middle and select the library you just compiled.

## Compiling the Project
Detailed explenation can be found in the official Godot docs (https://docs.godotengine.org/en/3.5/tutorials/export/exporting_projects.html)

Open the project with Godot (Godot/project.godot).  
First add the export templates by clicking "Editor->Manage Export Templates" and downloading them.

Then click on "project->Export".  
Add the export target if it is not already there and click "Export Project".

When compiling for web, make sure the export type is set to GDNative.