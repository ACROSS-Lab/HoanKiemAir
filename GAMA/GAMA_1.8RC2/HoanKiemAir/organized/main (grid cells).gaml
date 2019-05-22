/***
* Name: maingridcells
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model main

import "agents/traffic.gaml"
import "agents/pollution.gaml"
import "agents/visualization.gaml"

global {
	// Benchmark execution time
	bool benchmark <- true;
	float time_absorb_pollutants;
	float time_diffuse_pollutants;
	float time_create_congestions;

	float step <- 15#s;
	float pollutant_decay_rate <- 0.9;
	// Simulation parameters
	int n_cars;
	int n_motorbikes;
	int road_scenario;
	// Save params' old value to detect value changes
	int n_cars_prev;
	int n_motorbikes_prev;
	int road_scenario_prev;
	
	// Load shapefiles
	string resources_dir <- "../includes/bigger_map/";
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file dummy_roads_shape_file <- shape_file(resources_dir + "small_dummy_roads.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	
	geometry shape <- envelope(buildings_shape_file);
	graph road_network;
	list<road> open_roads;
	list<pollutant_cell> active_cells;
	
	init {
		create building from: buildings_shape_file;
		create road from: roads_shape_file {
			// Create a reverse road if the road is not oneway
			if (!oneway) {
				create road {
					shape <- polyline(reverse(myself.shape.points));
					name <- myself.name;
					type <- myself.type;
					s1_close <- myself.s1_close;
					s2_close <- myself.s2_close;
				}
			}
		}
		open_roads <- list(road);
		map<road, float> road_weights <- road as_map (each::each.shape.perimeter); 
		road_network <- as_edge_graph(road) with_weights road_weights;
		geometry road_geometry <- union(road accumulate (each.shape));
		active_cells <- pollutant_cell overlapping road_geometry;
		
		// Additional visualization
		create dummy_road from: dummy_roads_shape_file;
		create progress_bar with: [x::-700, y::1800, width::500, height::100, max_val::500, title::"Cars",  left_label::"0", right_label::"500"];
		create progress_bar with: [x::-700, y::2000, width::500, height::100, max_val::1500, title::"Motorbikes", left_label::"0", right_label::"1500"];
		create line_graph with: [x::2600, y::1400, width::1300, height::1000, label::"Hourly AQI"];
	}
	
	action update_vehicle_population(string type, int delta) {
		list<vehicle> vehicles <- vehicle where (each.type = type);
		if (delta < 0) {
			ask -delta among vehicle {
				do die;
			}
		} else {
			create vehicle number: delta with: [type::type, road_network::road_network];
		}
	}
	
	reflex update_car_population when: n_cars != n_cars_prev {
		int delta_cars <- n_cars - n_cars_prev;
		do update_vehicle_population("car", delta_cars);
		ask first(progress_bar where (each.title = "Cars")) {
			do update(n_cars);
		}
		n_cars_prev <- n_cars;
	}
	
	reflex update_motorbike_population when: n_motorbikes != n_motorbikes_prev {
		int delta_motorbikes <- n_motorbikes - n_motorbikes_prev;
		do update_vehicle_population("motorbike", delta_motorbikes);
		ask first(progress_bar where (each.title = "Motorbikes")) {
			do update(n_motorbikes);
		}
		n_motorbikes_prev <- n_motorbikes;
	}

	reflex update_road_scenario when: road_scenario != road_scenario_prev {
		switch road_scenario {
			match 0 {
				open_roads <- list(road);
			}
			match 1 {
				open_roads <- road where !each.s1_close;
			}
			match 2 {
				open_roads <- road where !each.s2_close;
			}
		}
		
		list<road> closed_roads <- road - open_roads;
		ask open_roads {
			closed <- false;
		}
		ask closed_roads {
			closed <- true;
		}
		
		map<road, float> road_weights <- open_roads as_map (each::each.shape.perimeter); 
		graph new_road_network <- as_edge_graph(open_roads) with_weights road_weights;
		ask vehicle {
			do update_road_network(new_road_network);
		}
		road_network <- new_road_network;
		road_scenario_prev <- road_scenario;
		
		geometry road_geometry <- union(open_roads accumulate each.shape);
		active_cells <- pollutant_cell overlapping road_geometry;
	}
	
	reflex create_congestions {
		float start <- machine_time;
		ask open_roads {
			list<vehicle> vehicles_on_road <- vehicle at_distance 1;
			int n_cars_on_road <- vehicles_on_road count (each.type = "car");
			int n_motorbikes_on_road <- vehicles_on_road count (each.type = "motorbike");
			do update_speed_coeff(n_cars_on_road, n_motorbikes_on_road);
		}
		
		map<float, float> road_weights <- open_roads as_map (each::(each.shape.perimeter / each.speed_coeff));
		road_network <- road_network with_weights road_weights;
		time_create_congestions <- machine_time - start;
	}
	
	matrix<float> mat_diff <- matrix([
		[1/20,1/20,1/20],
		[1/20, 3/5 * pollutant_decay_rate,1/20],
		[1/20,1/20,1/20]]);
		
	reflex produce_pollutant {
		float start <- machine_time;
		// Absorb pollutants emitted by vehicles
		ask active_cells parallel: true {
			list<vehicle> vehicles_in_cell <- vehicle inside self;
			loop v over: vehicles_in_cell {
				if (is_number(v.real_speed)) {
					float dist_traveled <- v.real_speed * step / #km;
	
					co <- co + dist_traveled * EMISSION_FACTOR[v.type]["CO"];
					nox <- nox + dist_traveled * EMISSION_FACTOR[v.type]["NOx"];
					so2 <- so2 + dist_traveled * EMISSION_FACTOR[v.type]["SO2"];
				    pm <- pm + dist_traveled * EMISSION_FACTOR[v.type]["PM"];
				}
			}
		}
		time_absorb_pollutants <- machine_time - start;
		
		// Diffuse pollutants to neighbor cells
		start <- machine_time;
		diffuse var: co on: pollutant_cell matrix: mat_diff;
		diffuse var: nox on: pollutant_cell matrix: mat_diff;
		diffuse var: so2 on: pollutant_cell matrix: mat_diff;
		diffuse var: pm on: pollutant_cell matrix: mat_diff;
		time_diffuse_pollutants <- machine_time - start;
	}
	
	reflex benchmark when: benchmark and every(10 #cycle) {
		write "Vehicles move: " + time_vehicles_move;
		write "Create congestions: " + time_create_congestions;
		write "Absorb pollutants: " + time_absorb_pollutants;
		write "Diffuse pollutants: " + time_diffuse_pollutants;
		
		time_vehicles_move <- 0.0;
	}
}

experiment exp {
	parameter "Number of cars" var: n_cars <- 500 min: 0 max: 500;
	parameter "Number of motorbikes" var: n_motorbikes <- 1000 min: 0 max: 1000;
	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
	
	output {
		display main type: opengl background: #black {
			species vehicle;
			species road;
			species building;
			grid pollutant_cell transparency: 0.5 elevation: norm_pollution_level * 1000 triangulation: true;
			
			species dummy_road;
			species progress_bar;
			species line_graph;
		}
	}
}