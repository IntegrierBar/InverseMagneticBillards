#include "InverseMagneticBillard.h"
#include <iostream>



namespace godot {
  

    void InverseMagneticBillard::_init()
    {
    }

    void InverseMagneticBillard::_ready()
    {
        set_process(false);
        Godot::print("ready is called");
        set_grid_size(gridSize);
    }

    void InverseMagneticBillard::_register_methods()
    {
        register_method((char*)"_ready", &InverseMagneticBillard::_ready);
        register_method((char*)"_process", &InverseMagneticBillard::_process);
        register_method((char*)"_draw", &InverseMagneticBillard::_draw);
        register_method((char*)"clear_polygon", &InverseMagneticBillard::clear_polygon);
        register_method((char*)"add_polygon_vertex", &InverseMagneticBillard::add_polygon_vertex);
        register_method((char*)"close_polygon", &InverseMagneticBillard::close_polygon);
        register_method((char*)"set_polygon_vertex", &InverseMagneticBillard::set_polygon_vertex);
        register_method((char*)"set_billard_type", &InverseMagneticBillard::set_billard_type);
        register_method((char*)"set_radius", &InverseMagneticBillard::set_radius);
        register_method((char*)"set_initial_values", &InverseMagneticBillard::set_initial_values);
        register_method((char*)"add_trajectory", &InverseMagneticBillard::add_trajectory);
        register_method((char*)"add_trajectory_phasespace", &InverseMagneticBillard::add_trajectory_phasespace);
        register_method((char*)"remove_trajectory", &InverseMagneticBillard::remove_trajectory);
        register_method((char*)"clear_trajectories", &InverseMagneticBillard::clear_trajectories);
        register_method((char*)"get_trajectory_colors", &InverseMagneticBillard::get_trajectory_colors);
        register_method((char*)"get_trajectories", &InverseMagneticBillard::get_trajectories);
        register_method((char*)"get_trajecotries_phasespace", &InverseMagneticBillard::get_trajecotries_phasespace);
        register_method((char*)"set_color", &InverseMagneticBillard::set_color);
        register_method((char*)"set_max_count", &InverseMagneticBillard::set_max_count);
        register_method((char*)"set_max_count_index", &InverseMagneticBillard::set_max_count_index);
        register_method((char*)"set_max_iter", &InverseMagneticBillard::set_max_iter);
        register_method((char*)"reset_trajectories", &InverseMagneticBillard::reset_trajectories);
        register_method((char*)"iterate_batch", &InverseMagneticBillard::iterate_batch); 
        register_method((char*)"iterate_trajectory", &InverseMagneticBillard::iterate_trajectory);
        
        // for inverse Trajectories
        register_method((char*)"add_inverse_trajectory", &InverseMagneticBillard::add_inverse_trajectory);
        register_method((char*)"add_inverse_trajectory_phasespace", &InverseMagneticBillard::add_inverse_trajectory_phasespace);
        register_method((char*)"iterate_inverse_batch", &InverseMagneticBillard::iterate_inverse_batch);

        // for symplectic Trajectories
        //register_method((char*)"add_symplectic_trajectory", &InverseMagneticBillard::add_symplectic_trajectory);
        //register_method((char*)"add_symplectic_trajectory_phasespace", &InverseMagneticBillard::add_symplectic_trajectory_phasespace);
        //register_method((char*)"iterate_symplectic_batch", &InverseMagneticBillard::iterate_symplectic_batch);

        //register_property<InverseMagneticBillard, double>((char*)"radius", &InverseMagneticBillard::radius, 1);
        //register_property((char*)"maxCount", &InverseMagneticBillard::maxCount, 1000);
        //register_property((char*)"polygonClosed", &InverseMagneticBillard::polygonClosed, false);
        register_method((char*)"set_grid_size", &InverseMagneticBillard::set_grid_size);
        register_property((char*)"defaultBatch", &InverseMagneticBillard::defaultBatch, 1000);
        register_method((char*)"hole_in_phasespace", &InverseMagneticBillard::hole_in_phasespace);

        register_method((char*)"get_phasespace_data", &InverseMagneticBillard::get_phasespace_data);

        //register_signal<InverseMagneticBillard>((char*)"iterated", "phasespace_points", GODOT_VARIANT_TYPE_ARRAY);
    }

    void InverseMagneticBillard::_process()
    {
        // TODO could do stuff here
        Godot::print("process runs");
    }

    // For each trajectory use polyline to draw it in normal space
    void InverseMagneticBillard::_draw()
    {
        // TODO consider using antialiasing and width
        for (auto& t : trajectories) {
            // due to constraints of Godot drawing, we need to split trajecotry every 700 iterations
            for (const auto& line : t.trajectoryToDraw)
            {
                if (line.size() > 1)
                {
                    draw_polyline(line, t.trajectoryColor, 1.0F, true);   // antialiasing could hit draw performance
                }
                
            }
            
        }

        // inverse trajecotries are always small so no noeed to split them
        for (auto& t : inverseTrajectories) {
            if (t.trajectoryToDraw.size() > 1) {
                draw_polyline(t.trajectoryToDraw[0], t.trajectoryColor);
            }
        }

        //for (auto& t : symplecticTrajectories) {
        //    if (t.trajectoryToDraw.size() > 1) {
        //        draw_polyline(t.trajectoryToDraw, t.trajectoryColor);
        //    }
        //}
        
    }

    void InverseMagneticBillard::clear_polygon()
    {
        polygonClosed = false;
        polygon.clear();
        polygonLength.clear();
        reset_trajectories();
        update();
    }

    void InverseMagneticBillard::add_polygon_vertex(Vector2 vertex)
    {
        if (polygonClosed) {    // if the polygon es closed do nothing
            return;
        }
        
        if (polygon.size() > 0)
        {
            if (polygonLength.size() < 1) { // TODO should be unneccessary now
                polygonLength.push_back(length(polygon.back() - vec2_d(vertex)));
            }
            else {
                polygonLength.push_back(polygonLength.back() + length(polygon.back() - vec2_d(vertex)));

            }
                
        }
        else
        {
            polygonLength.push_back(0); // first entry needs to by a zero
        }
            
        polygon.push_back(vec2_d(vertex));
    }

    void InverseMagneticBillard::close_polygon()
    {
        if (polygonClosed || polygon.size() < 3) { return; }    // polygon needs to haev at least 3 edges

        polygonLength.push_back(polygonLength.back() + length(polygon.back() - vec2_d(polygon[0])));
        

        polygon.push_back(polygon[0]);
        polygonClosed = true;

        // only update polygon for the trajectories, once polygon is closed
        for (auto& t : trajectories) {
            t.set_polygon(polygon, polygonLength);
        }
        for (auto& t : inverseTrajectories) {
            t.set_polygon(polygon, polygonLength);
        }
        //for (auto& t : symplecticTrajectories) {
        //    t.set_polygon(polygon, polygonLength);
        //}

        update();
    }

    // in order to change one vertex, we rebuild the entire polygon
    void InverseMagneticBillard::set_polygon_vertex(int index, Vector2 vertex)
    {
        if (index >= polygon.size())
        {
            return;
        }
        std::vector<vec2_d> oldPolygon = polygon;
        oldPolygon[index] = vertex;
        oldPolygon.pop_back();
        clear_polygon();
        for (auto& v : oldPolygon) {
            add_polygon_vertex(v.to_godot());
        }
        close_polygon();
    }

    void InverseMagneticBillard::add_trajectory(Vector2 start, Vector2 dir, Color color)
    {
        Trajectory t = Trajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.maxIter = maxIter;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(start), vec2_d(dir));
        trajectories.push_back(t);
        PoolVector2Array startPoint;
        startPoint.push_back(t.phaseSpaceTrajectory[0].to_godot());
        fill_grid_with_points(startPoint, color);
    }

    void InverseMagneticBillard::add_inverse_trajectory(Vector2 start, Vector2 dir, Color color)
    {
        InverseTrajectory t = InverseTrajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.maxIter = maxIter;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(start), vec2_d(dir));
        inverseTrajectories.push_back(t);
    }

    void InverseMagneticBillard::add_trajectory_phasespace(Vector2 pos, Color color)
    {
        Trajectory t = Trajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.maxIter = maxIter;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(pos));
        trajectories.push_back(t);
        PoolVector2Array startPoint;
        startPoint.push_back(t.phaseSpaceTrajectory[0].to_godot());
        fill_grid_with_points(startPoint, color);
    }

    void InverseMagneticBillard::add_inverse_trajectory_phasespace(Vector2 pos, Color color)
    {
        InverseTrajectory t = InverseTrajectory();
        t.radius = radius;
        t.maxCount = maxCount;
        t.maxIter = maxIter;
        t.trajectoryColor = color;

        t.polygon = polygon;
        t.polygonLength = polygonLength;

        t.set_initial_values(vec2_d(pos));
        inverseTrajectories.push_back(t);
    }

    //void InverseMagneticBillard::add_symplectic_trajectory(Vector2 start, Vector2 dir, Color color)
    //{
    //    SymplecticTrajectory t = SymplecticTrajectory();
    //    t.radius = radius;
    //    t.maxCount = maxCount;
    //    t.trajectoryColor = color;

    //    t.polygon = polygon;
    //    t.polygonLength = polygonLength;

    //    t.set_initial_values(vec2_d(start), vec2_d(dir));
    //    symplecticTrajectories.push_back(t);
    //}

    //void InverseMagneticBillard::add_symplectic_trajectory_phasespace(Vector2 pos, Color color)
    //{
    //    SymplecticTrajectory t = SymplecticTrajectory();
    //    t.radius = radius;
    //    t.maxCount = maxCount;
    //    t.trajectoryColor = color;

    //    t.polygon = polygon;
    //    t.polygonLength = polygonLength;

    //    t.set_initial_values(vec2_d(pos));
    //    symplecticTrajectories.push_back(t);
    //}

    void InverseMagneticBillard::remove_trajectory(int index)
    {
        trajectories.erase(trajectories.begin() + index);
        update();
    }

    void InverseMagneticBillard::clear_trajectories()
    {
        trajectories.clear();
        inverseTrajectories.clear();
        //symplecticTrajectories.clear();
    }

    Array InverseMagneticBillard::get_trajectories()
    {
        Array ts = Array();
        for (size_t i = 0; i < trajectories.size(); i++)
        {
            ts.push_back(trajectories[i].currentPosition.to_godot());
        }
        return ts;
    }

    Array InverseMagneticBillard::get_trajecotries_phasespace()
    {
        Array ts = Array();
        for (size_t i = 0; i < trajectories.size(); i++)
        {
            ts.push_back(trajectories[i].phaseSpaceTrajectory[0].to_godot());   // maybe need some carefull testing that this does not cause a crash. In theory phaseSpaceTrajectory should always have one element
        }
        return ts;
    }

    Array InverseMagneticBillard::iterate_batch(int batch, bool stopAtVertex)
    {
        Array phaseSpace;
        for (auto& t : trajectories)
        {
            PoolVector2Array phaseSpacePoints;  // points from this trajectory
            if (billardType == 0)
            {
                phaseSpacePoints = t.iterate_batch(batch, stopAtVertex);
                //phaseSpace.push_back(t.iterate_batch(batch));
            }
            else if (billardType == 1)
            {
                phaseSpacePoints = t.iterate_symplectic_batch(batch, stopAtVertex);
                //phaseSpace.push_back(t.iterate_symplectic_batch(batch));
            }
            phaseSpace.push_back(phaseSpacePoints);
            fill_grid_with_points(phaseSpacePoints, t.trajectoryColor);
        }

        update();
        return phaseSpace;
    }

    PoolVector2Array InverseMagneticBillard::iterate_trajectory(int index, int batch, bool stopAtVertex)
    {
        if (index < 0) {
            Godot::print("index less then 0 not possible");
            return PoolVector2Array();
        }
        if (index >= trajectories.size()) {
            Godot::print("index to large");
            return PoolVector2Array();
        }
        auto phaseSpacePoints = trajectories[index].iterate_batch(batch, stopAtVertex);
        fill_grid_with_points(phaseSpacePoints, trajectories[index].trajectoryColor);
        return phaseSpacePoints;
    }

    Array InverseMagneticBillard::iterate_inverse_batch(int batch)
    {
        Array phaseSpace;
        for (auto& t : inverseTrajectories)
        {
            PoolVector2Array phaseSpacePoints;  // points from this trajectory
            if (billardType == 0)
            {
                phaseSpacePoints = t.iterate_batch(batch);
            }
            else if (billardType == 1)
            {
                phaseSpacePoints = t.iterate_symplectic_batch(batch);
            }
            phaseSpace.push_back(phaseSpacePoints);
            //fill_grid_with_points(phaseSpacePoints, t.trajectoryColor);   // do not need this for inverse
        }
        update();
        return phaseSpace;
    }

    void InverseMagneticBillard::set_grid_size(int gs)
    {
        gridSize = gs;
        grid = std::vector<std::vector<std::optional<Color>>>(gridSize, std::vector<std::optional<Color>>(gridSize, std::nullopt)); // initialize grid with nullopt everywhere
        //reset_trajectories();
        // add points to grid
        for (const auto& t : trajectories)
        {
            PoolVector2Array pstrajectory;
            for (const auto& p : t.phaseSpaceTrajectory) { pstrajectory.push_back(p.to_godot()); }
            fill_grid_with_points(pstrajectory, t.trajectoryColor);
        }
    }

    // go through the grid trying to find the largest sqare hole and return point inside
    // returns (0,0) if there is no hole
    Array InverseMagneticBillard::hole_in_phasespace()
    {
        std::pair<int, int> largestHoleCoords;
        int largestHoleOffset = 0;
        for (size_t i = 0; i < gridSize; i++)
        {
            for (size_t j = 0; j < gridSize; j++)
            {
                int offset = 0;
                while (offset + i < gridSize && offset + j < gridSize)
                {
                    for (size_t k = 0; k <= offset; k++)
                    {
                        // if there is an intersection break outer loop via goto
                        if (grid[i + k][j + offset])
                        {
                            goto foundmaxsquare;
                        }
                        if (grid[i + offset][j + k])
                        {
                            goto foundmaxsquare;
                        }
                    }
                    offset++;
                }
            foundmaxsquare:

                /*while (!grid[i+sizeX][j])
                {
                    int sizeY = 0;
                    while (!grid[i+sizeX][j+sizeY])
                    {
                        size++;
                        sizeY++;
                        if (sizeY + j >= gridSize)
                        {
                            break;
                        }
                    }
                    sizeX++;
                    if (sizeX + i >= gridSize)
                    {
                        break;
                    }
                }*/

                if (offset > largestHoleOffset)
                {
                    largestHoleOffset = offset;
                    largestHoleCoords = std::make_pair(i, j);
                }
            }
        }
        if (largestHoleOffset == 0)
        {
            Array coordsAndColor;
            coordsAndColor.push_back(Vector2(0,0));
            coordsAndColor.push_back(Color(0,0,0));
            return coordsAndColor;
        }
        // determine Color for trajectory
        Color holeColor;
        if (largestHoleCoords.first>0 && grid[(largestHoleCoords.first-1)][largestHoleCoords.second])
        {
            holeColor = *grid[(largestHoleCoords.first - 1)][largestHoleCoords.second];
        }
        else
        {
            if (largestHoleCoords.second > 0 && grid[largestHoleCoords.first][largestHoleCoords.second - 1])
            {
                holeColor = *grid[largestHoleCoords.first][largestHoleCoords.second - 1];
            }
            else
            {
                holeColor = Color(1, 1, 1); // choose white to show we have problem
            }
        }
        // calculate the coordinates of the next point by taking the center coords of the first emtpy grid cell
        Vector2 coords = Vector2(((double)largestHoleCoords.first) / gridSize + 1. / (2 * gridSize), ((double)largestHoleCoords.second) / gridSize + 1. / (2 * gridSize));
        Array coordsAndColor;
        coordsAndColor.push_back(coords);
        coordsAndColor.push_back(holeColor);
        return coordsAndColor;

    }

    void InverseMagneticBillard::fill_grid_with_points(PoolVector2Array points, Color c)
    {
        for (size_t i = 0; i < points.size(); i++)
        {
            int xCoord = std::floor(points[i].x * gridSize);
            int yCoord = std::floor(points[i].y * gridSize);
            grid[xCoord][yCoord] = c;
        }
    }

    String InverseMagneticBillard::get_phasespace_data()
    {
        String data;
        for (const auto& t : trajectories)
        {
            for (const auto& point : t.phaseSpaceTrajectory)
            {
                data += point.to_string();
                data += "\n";
            }
            data += "\n";
        }
        return data;
    }


    //Array InverseMagneticBillard::iterate_symplectic_batch(int batch)
    //{
    //    Array phaseSpace;
    //    Godot::print(Vector2(symplecticTrajectories.size(), 1));
    //    for (auto& t : symplecticTrajectories)
    //    {
    //        phaseSpace.push_back(t.iterate_batch(batch));
    //    }
    //    update();
    //    return phaseSpace;
    //}

    void InverseMagneticBillard::set_initial_values(int index, Vector2 start, Vector2 dir)
    {
        trajectories[index].set_initial_values(start, dir);
        set_grid_size(gridSize);    // recalculate the grid
        update();
    }

    void InverseMagneticBillard::set_color(int index, Color c)
    {
        trajectories[index].trajectoryColor = c;
        update();
    }

    void InverseMagneticBillard::set_max_count_index(int index, int newMaxCount)
    {

        if (index >= trajectories.size() || index < 0) {
            Godot::print("trying to set max count of not existing trajecotry");
            return;
        }
        trajectories[index].maxCount = newMaxCount;
    }

    void InverseMagneticBillard::set_max_count(int newMaxCount)
    {
        maxCount = newMaxCount;
        for (auto& t : trajectories)
        {
            // -1 is used to make sure the trajectory never draws
            if (t.maxCount > -1)
            {
                t.maxCount = newMaxCount;
            }
            
        }
    }

    void InverseMagneticBillard::set_max_iter(int newMaxIter)
    {
        maxIter = newMaxIter;
        for (auto& t : trajectories)
        {
            t.maxIter = maxIter;
        }
    }

    PoolColorArray InverseMagneticBillard::get_trajectory_colors()
    {
        PoolColorArray colors;
        for (const auto& t : trajectories) {
            colors.push_back(t.trajectoryColor);
        }
        return colors;
    }

    void InverseMagneticBillard::set_billard_type(int type)
    {
        billardType = type;
        reset_trajectories();
    }

    void InverseMagneticBillard::set_radius(double r)
    {
        radius = r;
        for (auto& t : trajectories)
        {
            t.radius = r;
            t.reset_trajectory();
        }

        for (auto& i : inverseTrajectories)
        {
            i.radius = r;
            i.reset_trajectory();
        }

        //for (auto& i : symplecticTrajectories)
        //{
        //    i.radius = r;
        //    i.reset_trajectory();
        //}
        update();
    }

    void InverseMagneticBillard::reset_trajectories()
    {
        for (auto& t : trajectories)
        {
            t.reset_trajectory();
        }
        for (auto& t : inverseTrajectories)
        {
            t.reset_trajectory();
        }
        //for (auto& t : symplecticTrajectories)
        //{
        //    t.reset_trajectory();
        //}
        // Fill grid
        set_grid_size(gridSize);    // recalculate the grid
        update();
    }

}