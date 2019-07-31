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
	reflex benchmark when: benchmark {
		write "Vehicles move: " + time_vehicles_move;
		write "Update network's weights: " + time_update_network_weights;
		write "Absorb pollutants: " + time_absorb_pollutants;
		write "Diffuse pollutants: " + time_diffuse_pollutants;
		write "Spread to buildings: " + time_spread_to_buildings;
		
		time_vehicles_move <- 0.0;
		time_absorb_pollutants <- 0.0;
		time_diffuse_pollutants <- 0.0;
		time_spread_to_buildings <- 0.0;
	}
	
//	reflex test_seed {
//		if (cycle < 10) {
//			write rnd(1000);
//		}
//	}
	
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
				param_val <- "Pedestrian zone active";
				break;
			}
			match 2 {
				param_val <- "Extension plan";
				break;
			}
		}
		ask first(param_indicator where (each.name = "Road management")) {
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
	
	float general_traffic_daytime {
		if(daytime_trafic_peak.keys one_matches (each.hour = current_date.hour 
			and each.minute = current_date.minute and each.second = current_date.second)){
			// Only work when only one peak per hour
			return daytime_trafic_peak[daytime_trafic_peak.keys first_with (each.hour = current_date.hour)];	
		} else {
			date fd <- (daytime_trafic_peak.keys where (each.hour > current_date.hour)) with_min_of (each.hour - current_date.hour);
			if(fd = nil){ fd <- first(daytime_trafic_peak.keys); }
			date pd <- (daytime_trafic_peak.keys where (each.hour <= current_date.hour)) with_min_of (current_date.hour - each.hour);
			if(pd = nil){ pd <- last(daytime_trafic_peak.keys); }
			
			float time_to_go_next <- ((fd.hour#h+fd.minute#mn) - (current_date.hour#h+current_date.minute#mn));
			float dist_between_time <- ((fd.hour#h+fd.minute#mn) - (pd.hour#h+pd.minute#mn));
			float blend_factor <- time_to_go_next / dist_between_time;
			
			return daytime_trafic_peak[fd] * (1-blend_factor) + daytime_trafic_peak[pd] * blend_factor;
		}	
	}
	
	reflex update_vehicle_population_according_to_daytime when:day_time_traffic {
		float t_rate <- general_traffic_daytime();
		write current_date;
		n_cars <- int(n_vehicles_max * 0.05 * t_rate);
		n_motorbikes <- int(n_vehicles_max * 0.95 * t_rate);
		write n_cars;
		write n_motorbikes;
	}
}

