# InverseMagneticBillards
Requires Godot game engine version 3.5 (we used 3.5.2)


# How to compile
The code is split into 2 parts.

The code inside the GDNative fodler is the C++ code for the calculations. 
Compilation is only required if you do not compile for windows or web

The code inside the Godot folder is the Godot project itself.

## Requirements
Godot version 3.5.2 Standard (https://godotengine.org/download/archive/3.5.2-stable/)

If you need to compile the GDNative part as well, a C++ compiler and CMake is required.
For Web compilation use emscripten (https://emscripten.org/)

## Compiling GDNative
If you are compiling for Windows or web this part can be skipped

First compile the project inside the GDNative folder using cmake.

Next copy the compiled library into "Godot/GDNative"

If you are not compiling for Windows or web, you will need to register it inside the Godot project. \n
For this open the Project with Godot and in the file system open the GDNative/InverseMagneticBillard.tres.
This will open up a list in the bottom of the center. 
Find you target system, click the folder icon and select the library you just compiled.

## Compiling the Project
Detailed explenation can be found in the official Godot docs (https://docs.godotengine.org/en/3.5/tutorials/export/exporting_projects.html)

When compiling for web, make sure the export type is set to GDNative

Open the project with Godot (Godot/project.godot).
First add the export templates by clicking "Editor->Manage Export Templates" and downloading them.

Then click on project->Export
Add the export target if it is not already there and click "Export Project"