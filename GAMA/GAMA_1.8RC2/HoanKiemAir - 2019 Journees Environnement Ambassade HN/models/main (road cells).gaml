/***
* Name: mainroadcells
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
	
	// Load shapefiles
	string resources_dir <- "../includes/bigger_map/";
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file dummy_roads_shape_file <- shape_file(resources_dir + "small_dummy_roads.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	shape_file road_cells_shape_file <- shape_file(resources_dir + "road_cells.shp");
	shape_file naturals_shape_file <- shape_file(resources_dir + "naturals.shp");
	shape_file buildings_admin_shape_file <- shape_file(resources_dir + "buildings_admin.shp");
	
	geometry shape <- envelope(buildings_shape_file);
	list<road> open_roads;
	
	init {
		create road from: roads_shape_file {
			// Create a reverse road if the road is not oneway
			if (!oneway) {
				create road {
					shape <- polyline(reverse(myself.shape.points));
					name <- myself.name;
					type <- myself.type;
					s1_closed <- myself.s1_closed;
					s2_closed <- myself.s2_closed;
				}
			}
		}
		open_roads <- list(road);
		map<road, float> road_weights <- road as_map (each::each.shape.perimeter); 
		road_network <- as_edge_graph(road) with_weights road_weights;
		geometry road_geometry <- union(road accumulate (each.shape));
		
		// Additional visualization
		create building from: buildings_shape_file;
		create decoration_building from: buildings_admin_shape_file;
		create dummy_road from: dummy_roads_shape_file;
		create natural from: naturals_shape_file;
		create progress_bar with: [x::-700, y::1800, width::500, height::100, max_val::500, title::"Cars",  left_label::"0", right_label::"500"];
		create progress_bar with: [x::-700, y::2000, width::500, height::100, max_val::1500, title::"Motorbikes", left_label::"0", right_label::"1500"];
		create line_graph with: [x::2600, y::1400, width::1300, height::1000, label::"Hourly AQI"];
	
		// Init pollutant cells
		create road_cell from: road_cells_shape_file {
			neighbors <- road_cell at_distance 10#cm;
			affected_buildings <- building at_distance 50 #m;
		}
	}
	
	action update_vehicle_population(string type, int delta) {
		list<vehicle> vehicles <- vehicle where (each.type = type);
		if (delta < 0) {
			ask -delta among vehicle {
				do die;
			}
		} else {
			create vehicle number: delta with: [type::type];
		}
	}
	
	reflex update_car_population when: n_cars != n_cars_prev {
		int delta_cars <- n_cars - n_cars_prev;
		do update_vehicle_population("car", delta_cars);
		ask first(progress_bar where (each.title = "Cars")) {
			do update(float(n_cars));
		}
		n_cars_prev <- n_cars;
	}
	
	reflex update_motorbike_population when: n_motorbikes != n_motorbikes_prev {
		int delta_motorbikes <- n_motorbikes - n_motorbikes_prev;
		do update_vehicle_population("motorbike", delta_motorbikes);
		ask first(progress_bar where (each.title = "Motorbikes")) {
			do update(float(n_motorbikes));
		}
		n_motorbikes_prev <- n_motorbikes;
	}

	reflex update_road_scenario when: road_scenario != road_scenario_prev {
		switch road_scenario {
			match 0 {
				open_roads <- list(road);
			}
			match 1 {
				open_roads <- road where !each.s1_closed;
			}
			match 2 {
				open_roads <- road where !each.s2_closed;
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
			recompute_path <- true;
		}
		road_network <- new_road_network;
		road_scenario_prev <- road_scenario;
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
		// Absorb pollutants emitted by vehicles
		ask building parallel: true {
			aqi <- 0.0;
		}
		ask road_cell {
			float start <- machine_time;
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
			time_absorb_pollutants <- time_absorb_pollutants + (machine_time - start);
			
			// Diffuse pollutants to neighbor cells
			start <- machine_time;
			ask neighbors {
				self.co <- self.co + pollutant_diffusion * myself.co;
				self.nox <- self.nox + pollutant_diffusion * myself.nox;
				self.so2 <- self.so2 + pollutant_diffusion * myself.so2;
				self.pm <- self.pm + pollutant_diffusion * myself.pm;
			}
			co <- co * (1 - pollutant_diffusion * length(neighbors));
			nox <- nox * (1 - pollutant_diffusion * length(neighbors));
			so2 <- so2 * (1 - pollutant_diffusion * length(neighbors));
			pm <- pm * (1 - pollutant_diffusion * length(neighbors));			
			
			// Decay pollutants
			co <- pollutant_decay_rate * co;
			nox <- pollutant_decay_rate * nox;
			so2 <- pollutant_decay_rate * so2;
			pm <- pollutant_decay_rate * pm;
			
			time_diffuse_pollutants <- time_diffuse_pollutants + (machine_time - start);
			list<building> buildings <- list<building>(self.affected_buildings);
			ask buildings {
				self.aqi <- self.aqi + myself.aqi; 
			}
		}
	}
	
	reflex benchmark when: benchmark and every(5 #cycle) {
		write "Vehicles move: " + time_vehicles_move;
		write "Create congestions: " + time_create_congestions;
		write "Absorb pollutants: " + time_absorb_pollutants;
		write "Diffuse pollutants: " + time_diffuse_pollutants;
		
		time_vehicles_move <- 0.0;
		time_absorb_pollutants <- 0.0;
		time_diffuse_pollutants <- 0.0;
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
			species natural;
			species building;
			species decoration_building;
			
			species dummy_road;
			species progress_bar;
			species line_graph;
		}
	}
}