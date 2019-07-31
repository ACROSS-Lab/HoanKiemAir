/***
* Name: pollution
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollution
import "../misc/global_vars.gaml"

global {
	// Constants
	map<string, float> ALLOWED_AMOUNT <- ["CO"::30000, "NOx"::200, "SO2"::350, "PM"::300]; // Unit: ug/m3
	map<string, map<string, float>> EMISSION_FACTOR <- [
		"motorbike"::["CO"::3.62 * 10e6, "NOx"::0.3 * 0.05 * 10e6, "SO2"::0.03 * 10e6, "PM"::0.1 * 10e6],  // Unit: ug/km
		"car"::["CO"::3.62 * 10e6, "NOx"::1.5 * 0.05 * 10e6, "SO2"::0.17 * 10e6, "PM"::0.1 * 10e6]
	];
	
	// Params
	// Pollution diffusion
	float pollutant_decay_rate <- 0.99;
	float pollutant_diffusion <- 0.05;
	int grid_size <- 64;
	int cell_depth <- 10; //  meters
	float grid_cell_volume <- (shape.width / grid_size) * (shape.height / grid_size) * cell_depth;  // Unit: cubic meters
	
	action init_buildings {
		create building from: buildings_shape_file {
			if (shape.area < 1) {
				 do die;
			}
		}
	}
}

species sensor {
	string name;
	bool available;
	agent connected_pollutant_cell;
	agent closest_building;
}

species building schedules: [] {
	float height;
	string type;
	rgb color;
	
	map<string, float> pollutants <- ["CO"::0.0, "NOx"::0.0, "SO2"::0.0, "PM"::0.0];
	
//	float co <- 0.0;
//	float nox <- 0.0;
//	float so2 <- 0.0;
//	float pm <- 0.0;
	
	agent connected_pollutant_cell;
	float aqi;
	
	init {
		if height < min_height {
			height <- mean_height + rnd(0.3, 0.3);
		}
	}
	
	action calculate_aqi {
		list<float> aqi_x <- [];
		
		loop p_type over: pollutants.keys {
			add pollutants[p_type] / ALLOWED_AMOUNT[p_type] * 100 to: aqi_x;
		}
		
		aqi <- max(aqi_x);
	}
	
	aspect default {
		if (display_mode = 0) {
			draw shape color: (type = type_outArea)?palet[BUILDING_OUTAREA]:palet[BUILDING_BASE] /*border: #darkgrey*/ /*depth: height * 10*/;
		} else {
			draw shape color: (type = type_outArea)?palet[BUILDING_OUTAREA]:world.get_pollution_color(aqi) /*border: #darkgrey*/ depth: height * 10;
		}
	}
}
