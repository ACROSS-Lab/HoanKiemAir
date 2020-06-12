/***
* Name: maingridcellsv2
* Author: minhduc0711
* Description: Dispersion of pollutants now involves buildings
* Tags: Tag1, Tag2, TagN
***/

model maingridcellsv2

import "agents/traffic.gaml"
import "agents/pollution_grid_v2.gaml"
import "misc/remotegui.gaml"
import "misc/utils.gaml"
import "misc/visualization.gaml"

global {
	float step <- 16#s;
	date starting_date <- date(starting_date_string,"HH mm ss");

	geometry shape <- envelope(roads_shape_file);
	list<pollutant_cell> active_cells;
	
	init {
		do init_traffic;
		
		geometry road_geometry <- union(road accumulate (each.shape));
		active_cells <- pollutant_cell overlapping road_geometry;
		
		create pollutant_manager;

		loop s over: sensor {
			save ["time", "co", "nox", "so2", "pm"] to: "../output/sensor_readings/" + s.name + ".csv" type: csv rewrite: true;
		}	
		
		do init_visualization;
	}
	
	reflex read_sensors when: every(5#mn) {
		string t <- get_time();
		loop s over: sensor {
			pollutant_cell cell <- pollutant_cell(s.connected_pollutant_cell);
			save [t, cell.co, cell.nox, cell.so2, cell.pm] to: "../output/sensor_readings/" + s.name + ".csv" type: csv rewrite: false;
		}	
	}
	
	// Headless package
	int SIZE_WINDOW <- 20;
	string result_folder <- "results/";
	list<float> max_on_interval <- [];
	
	reflex update_max_on_interval {
		if(length(max_on_interval) > SIZE_WINDOW) {
			remove index: 0 from: max_on_interval;
		} 	
		add building max_of(each.aqi) to: max_on_interval;	
	}
	
	reflex create_outputs {	
		if(cycle = 0) {
			save ["Mean AQI", "Stdv AQI", "Sum AQI", "Mean max on interval"]
				type: "csv" to: result_folder + "res"+world.seed+".csv" header: false rewrite: true;	
		}	
		save [building mean_of(each.aqi), standard_deviation(building collect(each.aqi)),(building sum_of(each.aqi)),mean(max_on_interval)]
			type: "csv" to: result_folder + "res"+world.seed+".csv" rewrite: false;
	}
}

// For the purpose of scheduling agents only
species scheduler schedules: intersection + road + vehicle + pollutant_manager {}

species pollutant_manager schedules: [] {
	reflex produce_pollutants {
		float start <- machine_time;
		// Absorb pollutants emitted by vehicles
		ask active_cells parallel: true {
			list<vehicle> vehicles_in_cell <- vehicle inside self;
			loop v over: vehicles_in_cell {
				if (is_number(v.real_speed)) {
					float dist_traveled <- v.real_speed * step/ 1000;

					co <- co + dist_traveled * EMISSION_FACTOR[v.type]["CO"] / grid_cell_volume;
					nox <- nox + dist_traveled * EMISSION_FACTOR[v.type]["NOx"] / grid_cell_volume;
					so2 <- so2 + dist_traveled * EMISSION_FACTOR[v.type]["SO2"] / grid_cell_volume; 
				    pm <- pm + dist_traveled * EMISSION_FACTOR[v.type]["PM"] / grid_cell_volume;
				}
			}
		}
		time_absorb_pollutants <- machine_time - start;
		if (debug_scheduling) {
			write "Pollutants absorbed";	
		}
	}
		
	reflex calculate_aqi when: every(refreshing_rate_plot) and !(empty(line_graph_aqi)) {
 		float aqi <- max(pollutant_cell accumulate each.aqi);
		ask line_graph_aqi {
			do update(aqi);
		}
	}
	
	reflex update_building_colors {
		ask building {
			aqi <- pollutant_cell(connected_pollutant_cell).aqi;
		}
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
//			grid pollutant_cell lines: #white;
			species boundary;
			species road;
			species vehicle;
			species intersection;
			species building;

			species progress_bar;
			species param_indicator;
			species line_graph_aqi;
		}
	}
}
