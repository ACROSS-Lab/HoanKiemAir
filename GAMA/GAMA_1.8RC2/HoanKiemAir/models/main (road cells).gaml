/***
* Name: mainroadcells
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model main

import "agents/traffic.gaml"
import "agents/pollution_road.gaml"
import "misc/remotegui.gaml"
import "misc/utils.gaml"
import "misc/visualization.gaml"

global {
	float cell_depth <- 200#m;
	float cell_radius <- 50#m;
	float pollutant_decay_rate <- 0.9;
	
	float step <- 16#s;
	
	// For batch simulation
	map<string, matrix<float>> real_data;
	map<string, matrix<float>> simulated_data;
	float mae_pollutants;
	
	int compare_day;
	int compare_month;
	
	// misc
	bool read_first_time <- false;

	geometry shape <- envelope(roads_shape_file);
	
	init {
		starting_date <- date(starting_date_string,"HH mm ss");
		
		mae_pollutants <- 0.0;
		do init_traffic;
		do init_pollution;
		
		create pollutant_manager;
		
//		loop s over: sensor {
//			save ["time", "CO", "NOx", "SO2", "PM"] to: "../output/sensors/" + s.name + ".csv" type: csv rewrite: true;
//		}
		do init_visualization;
		do load_aqi_data;
	}
	
	action load_aqi_data {
		loop s over: sensor {
			loop p_type over: ["CO", "NO2", "PM10"] {
				string fpath <-  resources_dir + "concentration/" + s.name + "/" + p_type + ".csv";
				file f <- csv_file(fpath);
				matrix data <- matrix(f);
				
				list<float> col <- [];
				loop i from: 1 to: data.rows - 1 {
					date d <- date(string(data[0, i]), "yyyy-MM-dd HH:mm");

					if d.day = compare_day and d.month = compare_month {
						add float(data[1, i]) to: col;
					}
				}
				
				if real_data[s.name] = nil {
					real_data[s.name] <- matrix(col);
				} else {
					real_data[s.name] <- real_data[s.name] append_vertically matrix(col);
				}
			}
			real_data[s.name] <- transpose(real_data[s.name]);
		}
	}
	
	reflex update_aqi_graph when: every(refreshing_rate_plot) and !empty(line_graph_aqi) {
		 float aqi <- max(building accumulate each.aqi);
		 ask line_graph_aqi {
		 	do update(aqi);
		 }
	}
	
	reflex read_sensors  when: (time > 10#mn and !read_first_time) or (every(1#hour) and read_first_time) {
		read_first_time <- true;
		loop s over: sensor {
			list<float> col <- [];
			
			building b <- building(s.closest_building);
			loop p_type over: b.pollutants.keys {
				if (p_type != "SO2") {
					add b.pollutants[p_type] to: col;
				}
			}
			
			if simulated_data[s.name] = nil {
				simulated_data[s.name] <- matrix(col);
			} else {
				simulated_data[s.name] <- simulated_data[s.name] append_vertically matrix(col);
			}
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

// SCHEDULING
species scheduler schedules: intersection + road + vehicle + pollutant_manager + road_cell {}

species pollutant_manager schedules: [] {
	reflex produce_pollutant {
		float start <- machine_time;
		
		ask road_cell {
			list<vehicle> vehicles_in_cell <- vehicle inside self;
			
			loop v over: vehicles_in_cell {
				int multiplier <- (v.type = "car") ? car_multiplier : motorbike_multiplier;
				if (is_number(v.real_speed)) {
					float dist_traveled <- v.real_speed * step / 1000;
					
					loop p_type over: pollutants.keys {
						pollutants[p_type] <- pollutants[p_type] + (dist_traveled * EMISSION_FACTOR[v.type][p_type] / cell_volume) * multiplier; 
					}
				}
			}
		}
		
		time_absorb_pollutants <- machine_time - start;
	}

	reflex decay_pollutant {
		ask road_cell {
			loop p_type over: pollutants.keys {
				pollutants[p_type] <- pollutants[p_type] * pollutant_decay_rate;
			}
		}
	}
	
	reflex spread_to_buildings {
		float start <- machine_time;
		ask building {
			loop p_type over: pollutants.keys {
				pollutants[p_type] <- 0.0;
			}
		}
		ask road_cell {
			ask list<building>(self.affected_buildings) {
				loop p_type over: pollutants.keys {
					self.pollutants[p_type] <- self.pollutants[p_type] + myself.pollutants[p_type] ;
				}
			}
		}
		ask building {
			do calculate_aqi;
		}
		
		time_spread_to_buildings <- time_spread_to_buildings + (machine_time - start);
	}
}

experiment normal {
	parameter "Number of cars" var: n_cars <- 700 min: 0 max: max_number_of_cars;
	parameter "Number of motorbikes" var: n_motorbikes <- 2000 min: 0 max: max_number_of_motorbikes;
	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
	parameter "Display mode" var: display_mode <- 1 min: 0 max: 1;
	parameter "Refreshing time plot" var: refreshing_rate_plot init: step min:1#s max: 1#h;
	parameter "Starting time" var:starting_date_string init:"00 00 00";
	parameter "Step" var: step init: 2#mn;
	
	output {
		display main type: opengl background: #black {
			species intersection;
			species road;
			species building;
//			species road_cell;
			species vehicle;
			
			species progress_bar;
			species line_graph_aqi;
			species param_indicator;
		}
		
		display hang_dau {
			chart "CO" type: series size: {1, 1/3} position: {0, 0} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 0 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 0 : []] 
							color: [#red, #blue];
			}
			chart "NO2" type: series size: {1, 1/3} position: {0, 1/3}{
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 1 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 1 : []] 
							color: [#red, #blue];
			}
			chart "PM10" type: series size: {1, 1/3} position: {0, 2/3} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 2 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 2 : []] 
							color: [#red, #blue];
			}
		}
		
		display hoan_kiem {
			chart "CO" type: series size: {1, 1/3} position: {0, 0} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 0 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 0 : []] 
							color: [#red, #blue];
			}
			chart "NO2" type: series size: {1, 1/3} position: {0, 1/3}{
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 1 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 1 : []] 
							color: [#red, #blue];
			}
			chart "PM10" type: series size: {1, 1/3} position: {0, 2/3} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 2 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 2 : []] 
							color: [#red, #blue];
			}
		}
	}
}

experiment charts_only {
	parameter "Daytime traffic" var: day_time_traffic init:true;
	parameter "Starting time" var: starting_date_string init:"00 00 00";
	
	parameter "Compare day" var: compare_day init: 15;
	parameter "Compare month" var: compare_month init: 7;
	parameter "Road scenario" var: road_scenario init: 0;
	
	// Parameter to explore
	parameter "Time step" var: step init: 2#mn;
	parameter "Pollutant decay rate" var: pollutant_decay_rate init: 0.2;
	parameter "Cell radius" var: cell_radius init: 35#m;
	parameter "Cell depth" var: cell_depth init: 260#m;
//	parameter "Car multiplier" var: car_multiplier min: 8 max: 10 step: 1;
//	parameter "Motorbike multiplier" var: motorbike_multiplier min: 10 max: 15 step: 1;
	parameter "Max number of vehicles" var: n_vehicles_max init: 10000;
	output {
		display d {
			chart "hang_dau" type: series size: {1, 0.5} position: {0, 0} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 0 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 0 : []] 
							color: [#red, #blue];
			}
			chart "hoan_kiem" type: series size: {1, 0.5} position: {0, 0.5} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 0 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 0 : []] 
							color: [#red, #blue];
			}
		}
	}
}

experiment daytime parent: normal  {	
	parameter "Daytime traffic" var:day_time_traffic init:true;
	parameter "Time step" var:step init:5#mn min:1#mn max:30#mn;
	parameter "Refreshing time plot" var: refreshing_rate_plot init: 1#h min:1#mn max: 1#h;
	parameter "Starting time" var:starting_date_string init:"00 00 00";
}

experiment explore type: batch repeat: 1 until:  time > 23#h {
	parameter "Daytime traffic" var: day_time_traffic init:true;
	
	parameter "Starting time" var: starting_date_string init:"00 00 00";
	
	// Parameter to explore
	parameter "Time step" var: step min: 2.5#mn max: 4#mn step: 0.5#mn;
	parameter "Pollutant decay rate" var: pollutant_decay_rate min: 0.1 max: 0.3 step: 0.05;
	parameter "Cell radius" var: cell_radius min: 30#m max: 60#m step: 5#m;
	parameter "Cell depth" var: cell_depth min: 200#m max: 300#m step: 10#m;
//	parameter "Car multiplier" var: car_multiplier min: 8 max: 10 step: 1;
//	parameter "Motorbike multiplier" var: motorbike_multiplier min: 10 max: 15 step: 1;
	parameter "Max number of vehicles" var: n_vehicles_max init: 10000;
	
	action _step_ {
		loop s over: sensor {
			matrix diff <- real_data[s.name] - simulated_data[s.name];
			loop i from: 0 to: diff.rows - 1 {
				loop j from: 0 to: diff.columns -1 {
					diff[j, i] <- abs(diff[j, i]);
				}
			}
			mae_pollutants <- mae_pollutants + sum(diff);
		}
	}
	
	output {
		display hang_dau {
			chart "CO" type: series size: {1, 1/3} position: {0, 0} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 0 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 0 : []] 
							color: [#red, #blue];
			}
			chart "NO2" type: series size: {1, 1/3} position: {0, 1/3}{
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 1 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 1 : []] 
							color: [#red, #blue];
			}
			chart "PM10" type: series size: {1, 1/3} position: {0, 2/3} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hang_dau"] != nil) ? simulated_data["hang_dau"]  column_at 2 : [],
										(real_data["hang_dau"] != nil) ? real_data["hang_dau"]  column_at 2 : []] 
							color: [#red, #blue];
			}
		}
		
		display hoan_kiem {
			chart "CO" type: series size: {1, 1/3} position: {0, 0} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 0 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 0 : []] 
							color: [#red, #blue];
			}
			chart "NO2" type: series size: {1, 1/3} position: {0, 1/3}{
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 1 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 1 : []] 
							color: [#red, #blue];
			}
			chart "PM10" type: series size: {1, 1/3} position: {0, 2/3} {
				datalist ["Simulated", "Real"] 
							value: [(simulated_data["hoan_kiem"] != nil) ? simulated_data["hoan_kiem"]  column_at 2 : [],
										(real_data["hoan_kiem"] != nil) ? real_data["hoan_kiem"]  column_at 2 : []] 
							color: [#red, #blue];
			}
		}
	}
	
	method tabu iter_max: 15 tabu_list_size: 3 minimize: mae_pollutants;
//	method exhaustive minimize: mae_pollutants;
}

experiment shortExplo_Road type: gui {
	parameter "P Decay" var: pollutant_decay_rate init: 0.01 among: [0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.99];
	parameter "Folder for CSV" var: result_folder init: "results/";
}