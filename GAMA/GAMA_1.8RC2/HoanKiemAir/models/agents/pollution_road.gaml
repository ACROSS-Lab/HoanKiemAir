/***
* Name: pollutionroad
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollutionroad

import "pollution.gaml"
import "buildings.gaml"

global {
	float cell_depth <- 10#m;
	float cell_radius <- 50#m;
	
	action init_pollution {
		do init_buildings;
		create road_cell from: road_cells_shape_file {
			affected_buildings <- building at_distance cell_radius;
			nbrs <- road_cell at_distance 1#cm;
		}
		create sensor from: sensors_shape_file;
		ask sensor {
			if (available) {
				closest_building <- building closest_to self;
			} else {
				do die;
			}
		}
	}
}

species road_cell schedules: [] {
	list<road_cell> nbrs;
	list<agent> affected_buildings;
	
	// Pollutant values
	map<string, float> pollutants;
//	float co <- 0.0;
//	float nox <- 0.0;
//	float so2 <- 0.0;
//	float pm <- 0.0;
	
	float cell_volume;
	bool display_radius;
	
	
	
	init {
//		if flip(0.2) {
//			display_radius <- true;
//		}
		pollutants <- ["CO"::0.0, "NOx"::0.0, "SO2"::0.0, "PM"::0.0];
		cell_volume <- circle(cell_radius).area * cell_depth;
	}
	

//	float aqi;
//	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
//																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / 4;
//	
//	reflex calculate_aqi {
//		float aqi_co <- co / ALLOWED_AMOUNT["CO"] * 100;
//		float aqi_nox <- nox / ALLOWED_AMOUNT["NOx"] * 100;
//		float aqi_so2 <- so2 / ALLOWED_AMOUNT["SO2"] * 100;
//		float aqi_pm <- pm / ALLOWED_AMOUNT["PM"] * 100;
//		aqi <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
//	}
	
	aspect {
		if display_radius {
			draw shape;
			draw circle(cell_radius) color:  rgb(#orange, 0.5);
		}
		
		draw shape color: rgb(#orange, 0.5);
	}
}
