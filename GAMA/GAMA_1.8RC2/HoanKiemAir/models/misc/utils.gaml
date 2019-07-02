/***
* Name: utils
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model utils

import "global_vars.gaml"
import "visualization.gaml"
import "../agents/traffic.gaml"

global {
	reflex benchmark when: benchmark and every(10 #cycle) {
		write "Vehicles move: " + time_vehicles_move;
		write "Update network's weights: " + time_update_network_weights;
		write "Absorb pollutants: " + time_absorb_pollutants;
		write "Diffuse pollutants: " + time_diffuse_pollutants;
		time_vehicles_move <- 0.0;
		time_absorb_pollutants <- 0.0;
		time_diffuse_pollutants <- 0.0;
	}
	
	string get_time {
		int h <- current_date.hour;
		int m <- current_date.minute;
		int s <- current_date.second;
		string hh <- ((h < 10) ? "0" : "") + string(h);
		string mm <- ((m < 10) ? "0" : "") + string(m);
		string ss <- ((s < 10) ? "0" : "") + string(s);
		return hh + ":" + mm + ":" + ss;
	}
		
	reflex update_time {
		string t <- get_time();
		ask (param_indicator where (each.name = "Time")) {
			do update(t);
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
		do update_road_network;
		
		string param_val;
		switch road_scenario {
			match 0 {
				param_val <- "No closed road";
				break;
			}
			match 1 {
				param_val <- "Lake border closed";
				break;
			}
			match 2 {
				param_val <- "Lake border with \n extra roads closed";
				break;
			}
		}
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
}

