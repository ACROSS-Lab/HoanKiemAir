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
	map<string, float> ALLOWED_AMOUNT <- ["CO"::30000 * 10e-6, "NOx"::200 * 10e-6, "SO2"::350 * 10e-6, "PM"::300 * 10e-6]; // Unit: g/m3
	map<string, map<string, float>> EMISSION_FACTOR <- [
		"motorbike"::["CO"::3.62, "NOx"::0.3, "SO2"::0.03, "PM"::0.1],  // Unit: g/km
		"car"::["CO"::3.62, "NOx"::1.5, "SO2"::0.17, "PM"::0.1]
	];
	
	// Params
	// Pollution diffusion
	float pollutant_decay_rate <- 0.99;
	float pollutant_diffusion <- 0.05;
	int grid_size <- 64;
	int cell_depth <- 10; // cubic meters
	float grid_cell_volume <- (shape.width / grid_size) * (shape.height / grid_size) * cell_depth;  // Unit: cubic meters
	
	action init_buildings {
		create building from: buildings_shape_file {
			if (shape.area < 1) {
				 do die;
			}
		}
		create sensor from: sensors_shape_file;
	}
}

species sensor {
	agent connected_pollutant_cell;
}

species building schedules: [] {
	float height;
	string type;
	rgb color;
	
	agent connected_pollutant_cell;
	float aqi;
	
	init {
		if height < min_height {
			height <- mean_height + rnd(0.3, 0.3);
		}
	}
	
	aspect default {
		if (display_mode = 0) {
			draw shape color: (type = type_outArea)?palet[BUILDING_OUTAREA]:palet[BUILDING_BASE] /*border: #darkgrey*/ /*depth: height * 10*/;
		} else {
			draw shape color: (type = type_outArea)?palet[BUILDING_OUTAREA]:world.get_pollution_color(aqi) /*border: #darkgrey*/ depth: height * 10;
		}
	}
}
