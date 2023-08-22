/***
* Name: Main
* Author: minhduc0711 & Alexis Drogoul
* Description: 
***/
model main 

import "Pollution.gaml"

global {
	float step <- 1.0 #s;
	list<road> open_roads;
	float player_size_GAMA <- 20.0;

	//Colors and icons
	string images_dir <- "../images/";
	list<rgb> pal <- palette([#green, #yellow, #orange, #red]);
	map<rgb, string>
	legends <- [color_inner_building::"District Buildings", color_outer_building::"Outer Buildings", color_road::"Roads", color_closed::"Closed Roads", color_lake::"Rivers & lakes", color_car::"Cars", color_moto::"Motorbikes"];
	rgb color_car <- #lightblue;
	rgb color_moto <- #cyan;
	rgb color_road <- #lightgray;
	rgb color_closed <- #mediumpurple;
	rgb color_inner_building <- rgb(100, 100, 100);
	rgb color_outer_building <- rgb(60, 60, 60);
	rgb color_lake <- rgb(165, 199, 238, 255);

	// Initialization 
	string resources_dir <- "../data/";

	// Load shapefiles
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	geometry shape <- envelope(buildings_shape_file);

	init {
		create road from: shape_file(resources_dir + "roads.shp");
		loop r over: road {
			if (!r.oneway) {
				create road with: (shape: polyline(reverse(r.shape.points)), name: r.name, type: r.type, s1_closed: r.s1_closed, s2_closed: r.s2_closed);
			} 
		}
			
		
		create building from: shape_file(buildings_shape_file);
			
		ask road {
			agent ag <- building closest_to self;
			float dist <- ag = nil ? 8.0 : max(min( ag distance_to self - 5.0, 8.0), 2.0);
			num_lanes <- int(dist / lane_width);
			 capacity <- 1 + (num_lanes * shape.perimeter/3);
		}
		int cars <- 500;
		int motos <- 1000;


		do update_road_scenario(0); 

		do update_car_population(cars);
		do update_motorbike_population( motos);
		
	}

	action update_motorbike_population (int new_number) {
		int delta <- length(motorbike) - new_number;
		if (delta > 0) {
			ask delta among motorbike {
				do unregister;
				do die;
			}

		} else if (delta < 0) {
			create motorbike number: -delta ;
		}

	}
	action update_car_population (int new_number) {
		int delta <- length(car) - new_number;
		if (delta > 0) {
			ask delta among car {
				do unregister;
				do die;
			}

		} else if (delta < 0) {
			create car number: -delta ;
		}

	}
	
	action update_road_scenario (int scenario) {
		open_roads <- scenario = 1 ? road where !each.s1_closed : (scenario = 2 ? road where !each.s2_closed : list(road));
		// Change the display of roads
		list<road> closed_roads <- road - open_roads;
		ask open_roads {
			closed <- false;
		}

		ask closed_roads {
			closed <- true;
		}

		ask agents of_generic_species vehicle {
			do unregister;
			if (current_road in closed_roads) {
				do die;
			}

		}

		ask building {
			closest_intersection <- nil;
		}

		ask intersection {
			do die;
		}

		graph g <- as_edge_graph(open_roads);
		loop pt over: g.vertices {
			create intersection with: (shape: pt);
		}

		ask building {
			closest_intersection <- intersection closest_to self;
		}
		ask road {
			vehicle_ordering <- nil;
		}
		//build the graph from the roads and intersections
		road_network <- as_driving_graph(open_roads, intersection) with_shortest_path_algorithm #FloydWarshall;
		//geometry road_geometry <- union(open_roads accumulate (each.shape));
		ask agents of_generic_species vehicle {
			do select_target_path;
		} 
	}

	
	} 

experiment "Run me" autorun: true  {
	float maximum_cycle_duration <- 0.15;
	output {
		display Computer virtual: false type: 3d toolbar: true background: #black axes: false {
			species road {
				draw self.shape + 4 color: closed ? color_closed : color_road;
			}

			agents "Vehicles" value: (agents of_generic_species(vehicle)) where (each.current_road != nil) {
				draw rectangle(vehicle_length * 5, lane_width * num_lanes_occupied * 5) at: shift_pt color: type = CAR ? color_car : color_moto rotate: self.heading;
			}

			species building {
				draw self.shape color: type = OUT ? color_outer_building : (color_inner_building);
			}

			mesh cell triangulation: true transparency: 0.4 smooth: 3 above: 5 color: pal position: {0, 0, 0.01} visible: true;
		}

	}

}

