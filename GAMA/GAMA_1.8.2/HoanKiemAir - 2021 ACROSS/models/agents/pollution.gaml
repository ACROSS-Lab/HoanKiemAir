/***
* Name: pollution
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollution
import "../global_vars.gaml"

global {
	// Constants
	map<string, float> ALLOWED_AMOUNT <- ["CO"::30000 * 10e-6, "NOx"::200 * 10e-6, "SO2"::350 * 10e-6, "PM"::300 * 10e-6]; // Unit: g/m3
	map<string, map<string, float>> EMISSION_FACTOR <- [
		"motorbike"::["CO"::3.62, "NOx"::0.3, "SO2"::0.03, "PM"::0.1],  // Unit: g/km
		"car"::["CO"::3.62, "NOx"::1.5, "SO2"::0.17, "PM"::0.1]
	];
	
	// Params
	float cell_volume <- (shape.width / grid_size) * (shape.height / grid_size) * grid_depth;  // Unit: cubic meters	
}

grid pollutant_cell width: grid_size height: grid_size neighbors: 8 parallel: true {
	// Pollutant values
	float co <- 0.0;
	float nox <- 0.0;
	float so2 <- 0.0;
	float pm <- 0.0;

	float aqi;
	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / cell_volume / 4;
	
	rgb color <- #black update: rgb(255 * norm_pollution_level, 0, 0);
	
	reflex calculate_aqi {
		float aqi_co <- (co / cell_volume) / ALLOWED_AMOUNT["CO"] * 100;
		float aqi_nox <- (nox / cell_volume) / ALLOWED_AMOUNT["NOx"] * 100;
		float aqi_so2 <- (so2 / cell_volume) / ALLOWED_AMOUNT["SO2"] * 100;
		float aqi_pm <- (pm / cell_volume) / ALLOWED_AMOUNT["PM"] * 100;
		aqi <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
	}
}

species road_cell {
	list<road_cell> neighbors;
	list<agent> affected_buildings;
	
	// Pollutant values
	float co <- 0.0;
	float nox <- 0.0;
	float so2 <- 0.0;
	float pm <- 0.0;

	float aqi;
	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / cell_volume / 4;
	
	reflex calculate_aqi {
		float aqi_co <- (co / cell_volume) / ALLOWED_AMOUNT["CO"] * 100;
		float aqi_nox <- (nox / cell_volume) / ALLOWED_AMOUNT["NOx"] * 100;
		float aqi_so2 <- (so2 / cell_volume) / ALLOWED_AMOUNT["SO2"] * 100;
		float aqi_pm <- (pm / cell_volume) / ALLOWED_AMOUNT["PM"] * 100;
		aqi <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
	}
}

