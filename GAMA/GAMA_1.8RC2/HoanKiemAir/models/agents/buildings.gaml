/***
* Name: buildings
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model buildings

import "../Contantes and Parameters/global_vars.gaml"
import "pollution.gaml"

global {
	action init_buildings {
		create building from: buildings_shape_file {
			if (shape.area < 1) {
				 do die;
			}
		}
	}	
}

species building schedules: [] {
	float height;
	string type;
	rgb color;

	// List of pollutants
	map<string, float> pollutants <- ["CO"::0.0, "NOx"::0.0, "SO2"::0.0, "PM"::0.0];
	
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
