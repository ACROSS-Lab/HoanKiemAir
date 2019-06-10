/***
* Name: maingridcells
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model main

import "agents/traffic_driving.gaml"
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

	float step <- 16#s;
	date starting_date <- date(starting_date_string,"HH mm ss");
	
	// Load shapefiles
	string resources_dir <- "../includes/driving/";
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file intersections_shape_file <- shape_file(resources_dir + "intersections.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	shape_file buildings_admin_shape_file <- shape_file(resources_dir + "buildings_admin.shp");

	geometry shape <- envelope(buildings_shape_file);
	list<road> open_roads;
	list<pollutant_cell> active_cells;
	
	init {
		create intersection from: intersections_shape_file with: [is_traffic_signal::(read("type") = "traffic_signals")] {
//			is_traffic_signal <- true;
		}
		create road from: roads_shape_file {
			geom_display <- shape + (2.5 * lanes);
			maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km / °h;
			if (!oneway) {
				create road {
					lanes <- max([1, int(myself.lanes / 2.0)]);
					shape <- polyline(reverse(myself.shape.points));
					maxspeed <- myself.maxspeed;
					geom_display <- myself.geom_display;
					linked_road <- myself;
					myself.linked_road <- self;
				}
				lanes <- int(lanes / 2.0 + 0.5);
			}
		}
		
		open_roads <- list(road);
		map<road, float> road_weights <- road as_map (each::(each.shape.perimeter / each.maxspeed)); 
		road_network <- as_driving_graph(road, intersection) with_weights road_weights;
		geometry road_geometry <- union(road accumulate (each.shape));
		active_cells <- pollutant_cell overlapping road_geometry;
		
		//initialize the traffic light
		ask intersection {
			do initialize;
		}
		
		create building from: buildings_shape_file {
			p_cell <- pollutant_cell closest_to self;
		}

		create progress_bar    with: [x::3100, y::1200, width::350, height::100, max_val::500, title::"Cars",  left_label::"0", right_label::"Max"];
		create progress_bar    with: [x::3100, y::1550, width::500, height::100, max_val::1000, title::"Motorbikes", left_label::"0", right_label::"Max"];
		create param_indicator with: [x::3100, y::1850, size::22, name::"Road scenario", value::"No blocked roads", with_RT::true];
		create param_indicator with: [x::3100, y::2050, size::22, name::"Display mode", value::"Traffic"];
		create line_graph_aqi with: [x::2500, y::2300, width::1100, height::500, label::"Hourly AQI"];
		create param_indicator with: [x::2500, y::2803, size::30, name::"Time", value::"00:00:00", with_box::true, width::1100, height::200];		
		
		// Connect to remote controller
		if (mqtt_connect) {
			create controller;
		}
	}
	
	action update_vehicle_population(string vehicle_type, int delta) {
		list<vehicle> vehicles <- vehicle where (each.type = vehicle_type);
		if (delta < 0) {
			ask -delta among vehicles {
				do die;
			}
		} else {
			create vehicle number: delta {
				self.type <- vehicle_type;
				if (type = "car") {
					vehicle_length <- 4.7#m;
				} else {
					vehicle_length <- 2.0#m;
				}
			}
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
		ask (param_indicator where (each.name = "Time")) {
			do update(t);
		}
	}
	
	reflex update_building_aqi {
		ask building parallel: true {
			aqi <- pollutant_cell(p_cell).aqi;
		}
	}
	
	matrix<float> mat_diff <- matrix([
		[pollutant_diffusion,pollutant_diffusion,pollutant_diffusion],
		[pollutant_diffusion, (1 - 8 * pollutant_diffusion) * pollutant_decay_rate, pollutant_diffusion],
		[pollutant_diffusion,pollutant_diffusion,pollutant_diffusion]]);

		
	reflex produce_pollutant {
		float start <- machine_time;
		// Absorb pollutants emitted by vehicles
		ask active_cells parallel: true {
			list<vehicle> vehicles_in_cell <- vehicle inside self;
			loop v over: vehicles_in_cell {
				if (is_number(v.real_speed)) {
					float dist_traveled <- (v.real_speed * step) / #m / 1000;
	
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
	
	reflex calculate_aqi when: every(refreshing_rate_plot) { //every(1 #minute) {
		 float aqi <- max(pollutant_cell accumulate each.aqi);
		 ask line_graph_aqi {
		 	do update(aqi);
		 }
		 ask indicator_health_concern_level {
		 	do update(aqi);
		 }
	}

	// ---------- BENCHMARK ---------- //
	
	reflex benchmark when: benchmark and every(10 #cycle) {
		write "Vehicles move: " + time_vehicles_move;
		write "Absorb pollutants: " + time_absorb_pollutants;
		write "Diffuse pollutants: " + time_diffuse_pollutants;
		time_vehicles_move <- 0.0;
	}
}

experiment exp autorun: false {
	parameter "Number of cars" var: n_cars <- max_number_of_cars min: 0 max: max_number_of_cars;
	parameter "Number of motorbikes" var: n_motorbikes <- max_number_of_motorbikes min: 0 max: max_number_of_motorbikes;
	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
	parameter "Display mode" var: display_mode <- 0 min: 0 max: 1;
	parameter "Refreshing time plot" var: refreshing_rate_plot init: 2#mn min:1#mn max: 1#h;
	
	output {
		display main type: opengl background: #black {
			species boundary;
			species road;
			species vehicle;
			species intersection;
			species building;
			
		//	species background;
			species progress_bar;
			species param_indicator;
	//		species line_graph;
			species line_graph_aqi;
		}
	}
}
