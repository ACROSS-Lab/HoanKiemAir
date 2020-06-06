///***
//* Name: Pollutantmanager
//* Author: ben
//* Description: 
//* Tags: Tag1, Tag2, TagN
//***/
//
model Pollutantmanager
//
//import "traffic.gaml"
//import "buildings.gaml"
//
//
//// Grid cells v1 . gaml
//species pollutant_manager schedules: [] {
//	reflex produce_pollutants {
//		float start <- machine_time;
//		// Absorb pollutants emitted by vehicles
//		ask active_cells {
//			list<vehicle> vehicles_in_cell <- vehicle inside self;
//			loop v over: vehicles_in_cell {
//				if (is_number(v.real_speed)) {
//					float dist_traveled <- v.real_speed * step/ 1000;
//
//					co <- co + dist_traveled * EMISSION_FACTOR[v.type]["CO"] / grid_cell_volume;
//					nox <- nox + dist_traveled * EMISSION_FACTOR[v.type]["NOx"] / grid_cell_volume;
//					so2 <- so2 + dist_traveled * EMISSION_FACTOR[v.type]["SO2"] / grid_cell_volume; 
//				    pm <- pm + dist_traveled * EMISSION_FACTOR[v.type]["PM"] / grid_cell_volume;
//				}
//			}
//		}
//		time_absorb_pollutants <- machine_time - start;
//		if (debug_scheduling) {
//			write "Pollutants absorbed";	
//		}
//	}
//		
//	matrix<float> mat_diff <- matrix([
//						[pollutant_diffusion,pollutant_diffusion,pollutant_diffusion],
//						[pollutant_diffusion, (1 - 8 * pollutant_diffusion) * pollutant_decay_rate, pollutant_diffusion],
//						[pollutant_diffusion,pollutant_diffusion,pollutant_diffusion]]);
//						
//	reflex disperse_pollutants {
//		// Diffuse pollutants to neighbor cells
//		float start <- machine_time;
//		diffuse var: co on: pollutant_cell matrix: mat_diff;
//		diffuse var: nox on: pollutant_cell matrix: mat_diff;
//		diffuse var: so2 on: pollutant_cell matrix: mat_diff;
//		diffuse var: pm on: pollutant_cell matrix: mat_diff;
//		time_diffuse_pollutants <- machine_time - start;
//		if (debug_scheduling) {
//			write "Pollutants dispersed";
//		}
//	}
//	
//	reflex calculate_aqi when: every(refreshing_rate_plot) {
// 		float aqi <- max(pollutant_cell accumulate each.aqi);
//		ask line_graph_aqi {
//			do update(aqi);
//		}
//	}
//	
//	reflex update_building_colors {
//		ask building {
//			aqi <- pollutant_cell(connected_pollutant_cell).aqi;
//		}
//	}
//}
//
//
//// Grid cell v2 
//species pollutant_manager schedules: [] {
//	reflex produce_pollutants {
//		float start <- machine_time;
//		// Absorb pollutants emitted by vehicles
//		ask active_cells parallel: true {
//			list<vehicle> vehicles_in_cell <- vehicle inside self;
//			loop v over: vehicles_in_cell {
//				if (is_number(v.real_speed)) {
//					float dist_traveled <- v.real_speed * step/ 1000;
//
//					co <- co + dist_traveled * EMISSION_FACTOR[v.type]["CO"] / grid_cell_volume;
//					nox <- nox + dist_traveled * EMISSION_FACTOR[v.type]["NOx"] / grid_cell_volume;
//					so2 <- so2 + dist_traveled * EMISSION_FACTOR[v.type]["SO2"] / grid_cell_volume; 
//				    pm <- pm + dist_traveled * EMISSION_FACTOR[v.type]["PM"] / grid_cell_volume;
//				}
//			}
//		}
//		time_absorb_pollutants <- machine_time - start;
//		if (debug_scheduling) {
//			write "Pollutants absorbed";	
//		}
//	}
//		
//	reflex calculate_aqi when: every(refreshing_rate_plot) {
// 		float aqi <- max(pollutant_cell accumulate each.aqi);
//		ask line_graph_aqi {
//			do update(aqi);
//		}
//	}
//	
//	reflex update_building_colors {
//		ask building {
//			aqi <- pollutant_cell(connected_pollutant_cell).aqi;
//		}
//	}
//}
//
//// Roads cell 
//
//species pollutant_manager schedules: [] {
//	reflex produce_pollutant {
//		float start <- machine_time;
//		
//		ask road_cell {
//			list<vehicle> vehicles_in_cell <- vehicle inside self;
//			
//			loop v over: vehicles_in_cell {
//				int multiplier <- (v.type = "car") ? car_multiplier : motorbike_multiplier;
//				if (is_number(v.real_speed)) {
//					float dist_traveled <- v.real_speed * step / 1000;
//					
//					loop p_type over: pollutants.keys {
//						pollutants[p_type] <- pollutants[p_type] + (dist_traveled * EMISSION_FACTOR[v.type][p_type] / cell_volume) * multiplier; 
//					}
//				}
//			}
//		}
//		
//		time_absorb_pollutants <- machine_time - start;
//	}
//
//	reflex decay_pollutant {
//		ask road_cell {
//			loop p_type over: pollutants.keys {
//				pollutants[p_type] <- pollutants[p_type] * pollutant_decay_rate;
//			}
//		}
//	}
//	
//	reflex spread_to_buildings {
//		float start <- machine_time;
//		ask building {
//			loop p_type over: pollutants.keys {
//				pollutants[p_type] <- 0.0;
//			}
//		}
//		ask road_cell {
//			ask list<building>(self.affected_buildings) {
//				loop p_type over: pollutants.keys {
//					self.pollutants[p_type] <- self.pollutants[p_type] + myself.pollutants[p_type] ;
//				}
//			}
//		}
//		ask building {
//			do calculate_aqi;
//		}
//		
//		time_spread_to_buildings <- time_spread_to_buildings + (machine_time - start);
//	}
//}
//
