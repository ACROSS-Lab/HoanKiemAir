/***
* Name: pollutiongridv1
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollutiongridv1

import "pollution.gaml"

global {
	init {
		do init_buildings;
		ask building {
			connected_pollutant_cell <- pollutant_cell closest_to self;
		}
		ask sensor {
			connected_pollutant_cell <- pollutant_cell closest_to self;
		}
	}
}

grid pollutant_cell width: grid_size height: grid_size neighbors: 8 parallel: true {
	// Pollutant values, unit g/m3 (assuming pollutants are spread uniformly in a cell)
	float co <- 0.0;
	float nox <- 0.0;
	float so2 <- 0.0;
	float pm <- 0.0;

	float aqi;
	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / 4;
	
	rgb color <- #black update: rgb(255 * norm_pollution_level, 0, 0);
	
	reflex calculate_aqi {
		float aqi_co <- co / ALLOWED_AMOUNT["CO"] * 100;
		float aqi_nox <- nox / ALLOWED_AMOUNT["NOx"] * 100;
		float aqi_so2 <- so2 / ALLOWED_AMOUNT["SO2"] * 100;
		float aqi_pm <- pm / ALLOWED_AMOUNT["PM"] * 100;
		aqi <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
	}
}
