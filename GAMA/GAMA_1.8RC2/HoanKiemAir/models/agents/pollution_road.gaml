/***
* Name: pollutionroad
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollutionroad

import "pollution.gaml"

species road_cell {
	float area;
	
	float cell_volume;
	list<road_cell> neighbors;
	list<agent> affected_buildings;
	
	init {
		cell_volume <- area * cell_depth;
	}
	
	// Pollutant values
	float co <- 0.0;
	float nox <- 0.0;
	float so2 <- 0.0;
	float pm <- 0.0;

	float aqi;
	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / 4;
	
	reflex calculate_aqi {
		float aqi_co <- co / ALLOWED_AMOUNT["CO"] * 100;
		float aqi_nox <- nox / ALLOWED_AMOUNT["NOx"] * 100;
		float aqi_so2 <- so2 / ALLOWED_AMOUNT["SO2"] * 100;
		float aqi_pm <- pm / ALLOWED_AMOUNT["PM"] * 100;
		aqi <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
	}
}
