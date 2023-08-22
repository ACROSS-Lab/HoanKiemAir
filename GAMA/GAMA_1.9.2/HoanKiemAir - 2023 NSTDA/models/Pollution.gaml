/***
* Name: pollution
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model pollution

import "Traffic.gaml"

global {
	
	
	// Params
	
	float aqi_worst_max <- 3000.0;
	float aqi_worst_mean <- 60.0;
	float aqi_mean <- mean(cell) update: mean(cell);
	float aqi_max <- min(aqi_worst_max, max(cell)) update: min(aqi_worst_max, max(cell));
	
// Pollution diffusion
	float pollutant_decay_rate <- 0.1;
	float pollutant_diffusion <- 0.05;
	int grid_size <- 150;
	
	
	field cell <- field(grid_size, grid_size);
	
	matrix<float> mat_diff <- matrix([[pollutant_diffusion, pollutant_diffusion, pollutant_diffusion], [pollutant_diffusion, pollutant_decay_rate, pollutant_diffusion], [pollutant_diffusion, pollutant_diffusion, pollutant_diffusion]]);

	// 0 -> good ; 3 -> bad

	
	int index_of_pollution(geometry g) {
		float val <- (g is point) ? cell[point(g)] : max (cell values_in g);
		return index_of_pollution_level_against_max(val);
	}
	
	int index_of_pollution_level_against_max(float val) {
		if (val < aqi_worst_max / 4) {
			return 0;
		} else if (val < aqi_worst_max / 2) {
			return 1;
		} else if (val < aqi_worst_max * 3 / 4 ) {
			return 2;
		} else  {
			return 3;
		}
		return 0;
	}
	
	int index_of_pollution_level_against_mean(float val) {
		if (val < aqi_worst_mean / 4) {
			return 0;
		} else if (val < aqi_worst_mean / 2) {
			return 1;
		} else if (val < aqi_worst_mean * 3 / 4 ) {
			return 2;
		} else  {
			return 3;
		}
		return 0;
	}
	
//	reflex building_pollution {
//		ask building {
//			pollution_index <- myself.index_of_pollution(pollution_perception);
//		}
//	}


	reflex pollution_evolution {
		cell <- cell * 0.7;
		//diffuse the pollutions to neighbor cells
		diffuse var: pollution on: cell proportion: 0.9 propagation: gradient;
	}

	reflex produce_pollutant {
		ask agents of_generic_species(vehicle) { 
		//if the path followed is not nil (i.e. the agent moved this step), we use it to increase the pollution level of overlapping cell
			if (current_road != nil and current_road.shape != nil) {
				cell[location] <- min(aqi_worst_max, cell[location] + 20);
			}
		}
	}

}