project(InverseMagneticBillard CXX)

set(SOURCES
    src/GodotLibrary.cpp
    include/InverseMagneticBillard.h
    src/InverseMagneticBillard.cpp
    include/Vectors.h
    include/Trajectory.h
    src/Trajectory.cpp
    )

if(EMSCRIPTEN)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -s ASSERTIONS=1 -s SIDE_MODULE=1")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s ASSERTIONS=1 -s SIDE_MODULE=1")
    set(CMAKE_EXECUTABLE_SUFFIX ".wasm")
    
    add_executable(InverseMagneticBillard ${SOURCES})
else()
    add_library(InverseMagneticBillard SHARED ${SOURCES})
endif()

target_link_libraries(InverseMagneticBillard PUBLIC godot-cpp)

target_include_directories(InverseMagneticBillard
                           PUBLIC
                           $<INSTALL_INTERFACE:include>
                           $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                           PRIVATE
                           ${CMAKE_CURRENT_SOURCE_DIR}/src
                           )