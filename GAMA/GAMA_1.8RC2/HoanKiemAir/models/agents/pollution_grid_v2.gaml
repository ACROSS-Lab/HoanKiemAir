/***
* Name: pollutiongridv2
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollutiongridv2

import "buildings.gaml"
import "pollution.gaml"

global {
	float diffu_factor(float d1, float d2) {
		return min(max(0.1 * (d1-d2) + 1.0, 0.0), 1.0);
	}
	
	init {
		do init_buildings;
		ask building {
			connected_pollutant_cell <- pollutant_cell closest_to self;
		}
		ask sensor {
			connected_pollutant_cell <- pollutant_cell closest_to self;
		}
		
		ask pollutant_cell {
			list<building> overlapping_buildings <- building overlapping self;
			loop b over: overlapping_buildings {
				if (inter(b, self) != nil) {
					building_density <- building_density + inter(b, self).area * b.height;
				}
			}
		}
		
		ask pollutant_cell {
			loop neighbor over: nbrs {
				diffusion_rates[neighbor] <- pollutant_diffusion * myself.diffu_factor(building_density, neighbor.building_density);
			}
		}
	}
}

grid pollutant_cell width: grid_size height: grid_size neighbors: 8 parallel: true {
	list<pollutant_cell> nbrs <- neighbors;
	// Pollutant values, unit g/m3 (assuming pollutants are spread uniformly in a cell)
	float building_density <- 0.0;
	
	map<pollutant_cell,  float> diffusion_rates;
	
	float co <- 0.0;
	float nox <- 0.0;
	float so2 <- 0.0;
	float pm <- 0.0;

	float aqi;
	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / 4;
	
	rgb color <- #black update: rgb(255 * norm_pollution_level, 0, 0);
	
	reflex diffuse {
		float start <- machine_time;
		ask nbrs {
			self.co <- self.co + myself.diffusion_rates[self] * myself.co;
			self.nox <- self.nox + myself.diffusion_rates[self] * myself.nox;
			self.so2 <- self.so2 + myself.diffusion_rates[self] * myself.so2;
			self.pm <- self.pm + myself.diffusion_rates[self] * myself.pm;
		}
		
		co <- co * (1 - sum(diffusion_rates));
		nox <- nox * (1 - sum(diffusion_rates));
		so2 <- so2 * (1 - sum(diffusion_rates));
		pm <- pm * (1 - sum(diffusion_rates));
		
		// Decay pollutants
		co <- pollutant_decay_rate * co;
		nox <- pollutant_decay_rate * nox;
		so2 <- pollutant_decay_rate * so2;
		pm <- pollutant_decay_rate * pm;
		time_diffuse_pollutants <- time_diffuse_pollutants + (machine_time - start);
	}
	
	reflex calculate_aqi {
		float aqi_co <- co / ALLOWED_AMOUNT["CO"] * 100;
		float aqi_nox <- nox / ALLOWED_AMOUNT["NOx"] * 100;
		float aqi_so2 <- so2 / ALLOWED_AMOUNT["SO2"] * 100;
		float aqi_pm <- pm / ALLOWED_AMOUNT["PM"] * 100;
		aqi <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
	}
}
