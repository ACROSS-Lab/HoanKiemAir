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
import "agents/remotegui.gaml"

global {
	bool mqtt_connect <- false;
	
	// Benchmark execution time
	bool benchmark <- true;
	float time_absorb_pollutants;
	float time_diffuse_pollutants;
	float time_create_congestions;

	float step <- 15#s;
	
	// Load shapefiles
	string resources_dir <- "../includes/bigger_map/";
	shape_file map_boundary_rectangle_shape_file <- shape_file(resources_dir + "resize_rectangle.shp");	
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file dummy_roads_shape_file <- shape_file(resources_dir + "small_dummy_roads.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	shape_file buildings_admin_shape_file <- shape_file(resources_dir + "buildings_admin.shp");
	shape_file naturals_shape_file <- shape_file(resources_dir + "naturals.shp");
	
	geometry shape <- envelope(buildings_shape_file);
	list<road> open_roads;
	list<pollutant_cell> active_cells;
	
	init {
		create boundary from: map_boundary_rectangle_shape_file;		
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
		active_cells <- pollutant_cell overlapping road_geometry;
		
		// Additional visualization
		create building from: buildings_shape_file {
			p_cell <- pollutant_cell closest_to self;
		}
		create decoration_building from: buildings_admin_shape_file;
		create dummy_road from: dummy_roads_shape_file;
		create natural from: naturals_shape_file;
		
		create background with: [x::-1350, y::1000, width::1300, height::1100, alpha::0.6];
		create param_indicator with: [x::-1300, y::1100, size::20, name::"Time", value::"00:00:00"];
		create progress_bar with: [x::-1300, y::1300, width::500, height::100, max_val::500, title::"Cars",  left_label::"0", right_label::"500"];
		create progress_bar with: [x::-1300, y::1650, width::500, height::100, max_val::1000, title::"Motorbikes", left_label::"0", right_label::"1500"];
		create param_indicator with: [x::-1300, y::1950, size::20, name::"Road scenario", value::"no blocked roads"];
		create param_indicator with: [x::-1300, y::2050, size::20, name::"Display mode", value::"traffic"];
		
		create background with: [x::2450, y::1000, width::1250, height::1500, alpha::0.6];
		create indicator_health_concern_level with: [x::3100, y::1000, width::600, height::200];
		create line_graph with: [x::2500, y::1400, width::1200, height::1000, label::"Hourly AQI"];
		
		// Connect to remote controller
		if (mqtt_connect) {
			create controller;
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
		string param_val;
		switch road_scenario {
			match 0 {
				open_roads <- list(road);
				param_val <- "No closed roads";
				break;
			}
			match 1 {
				open_roads <- road where !each.s1_closed;
				param_val <- string(1);
				break;
			}
			match 2 {
				open_roads <- road where !each.s2_closed;
				param_val <- string(2);
				break;
			}
		}
		
		// Recreate road network
		map<road, float> road_weights <- open_roads as_map (each::each.shape.perimeter); 
		road_network <- as_edge_graph(open_roads) with_weights road_weights;
		ask vehicle {
			recompute_path <- true;
		}
		
		// Change the display of roads
		list<road> closed_roads <- road - open_roads;
		ask open_roads {
			closed <- false;
		}
		ask closed_roads {
			closed <- true;
		}

		// Choose the active cells again
		geometry road_geometry <- union(open_roads accumulate each.shape);
		active_cells <- pollutant_cell overlapping road_geometry;
		
		ask first(param_indicator where (each.name = "Road scenario")) {
			do update(param_val);
		}
		road_scenario_prev <- road_scenario;
	}
	
	reflex update_display_mode when: display_mode_prev != display_mode {
		string param_val;
		switch (display_mode) {
			match 0 {
				param_val <- "Traffic";
				break;	
			}
			match 1 {
				param_val <- "Pollution";
				break;	
			}
		}
		
		ask first(param_indicator where (each.name = "Display mode")) {
			do update(param_val);
		}
		display_mode_prev <- display_mode;
	}
	
	reflex update_time {
		int h <- current_date.hour;
		int m <- current_date.minute;
		int s <- current_date.second;
		string hh <- ((h < 10) ? "0" : "") + string(h);
		string mm <- ((m < 10) ? "0" : "") + string(m);
		string ss <- ((s < 10) ? "0" : "") + string(s);
		string t <- hh + ":" + mm + ":" + ss;
		ask first(param_indicator where (each.name = "Time")) {
			do update(t);
		}
	}
	
	reflex update_building_aqi {
		ask building parallel: true {
			aqi <- pollutant_cell(p_cell).aqi;
		}
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
	
	reflex calculate_aqi when: every(1 #hour) {
		 float aqi <- max(pollutant_cell accumulate each.aqi);
		 ask line_graph {
		 	do update(aqi);
		 }
		 ask indicator_health_concern_level {
		 	do update(aqi);
		 }
	}
	
	rgb day_time_color <- #black;
	date starting_date <- date("14 00 00","HH mm ss");
	reflex general_color_brew when:day_time_color_blender{
		if(day_time_colors.keys one_matches (each.hour = current_date.hour)){
			day_time_color <- day_time_colors[day_time_colors.keys first_with (each.hour = current_date.hour)]; 
		} else {
			date fd <- day_time_colors.keys where (each.hour > current_date.hour) with_min_of (each.hour - current_date.hour);
			date pd <- day_time_colors.keys where (each.hour < current_date.hour) with_min_of (current_date.hour - each.hour);
			
			day_time_color <- blend(day_time_colors[fd],day_time_colors[pd],(fd - current_date) / (fd - pd));
		}
		day_time_color <- blend(#black,day_time_color,1-day_time_color_blend_factor);
	}
	
	reflex benchmark when: benchmark and every(10 #cycle) {
		write "Vehicles move: " + time_vehicles_move;
		write "Path recomputed: " + nb_recompute_path;
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
	parameter "Display mode" var: display_mode <- 0 min: 0 max: 1;
	
	output {
		display main type: opengl fullscreen: true toolbar: false background: day_time_color 
		// draw_env: true
		camera_pos: {1055.5934,1521.1361,3673.6199} camera_look_pos: {1055.5934,1521.0706,-0.0027} camera_up_vector: {0.0,1.0,0.0} 
		keystone: [{-0.012307035907790373,-0.010174922123093566,0.0},{-0.002718485409631932,1.0083260530999232,0.0},{0.9972723971132761,1.0083271699173144,0.0},{1.0082138080822864,-0.016638704391143788,0.0}]
		
		// Config fullscreen  - résolution optimisée
		//camera_pos: {2649.9132,1496.4156,3913.1789} camera_look_pos: {2649.9132,1496.3473,3.0E-4} camera_up_vector: {0.0,1.0,0.0}
		//keystone: [{0.03872976704465195,-0.0037780075228106558,0.0},{0.039449285113880926,0.9431466070331477,0.0},{0.9667664101488327,0.9612354373001951,0.0},{0.9868345759281302,0.014214971982789648,0.0}]
		{
			species boundary;			
			species vehicle;
			species road;
			species natural;
			species building;
			species decoration_building;
			species dummy_road;
			//grid pollutant_cell transparency: (display_mode = 0) ? 1.0 : 0.4 elevation: norm_pollution_level * 10 triangulation: true;
			
			species background;
			species progress_bar;
			species param_indicator;
			species line_graph;
			species indicator_health_concern_level;
		}
	}
}