/***
* Name: pollution
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pollution

import "../Contantes and Parameters/Pollution param and constants.gaml"

global { 
	int get_pollution_threshold(float aqi) {
		int threshold <- 0;
		loop thr over: thresholds_pollution.keys {
			if(aqi > thr) {
				threshold <- thr;
			}
		}
		return threshold;
	}
	
	string get_pollution_state(float aqi) {
		return thresholds_pollution[get_pollution_threshold(aqi)];
	}
	
	rgb get_pollution_color(float aqi) {
		return zone_colors[thresholds_pollution[get_pollution_threshold(aqi)]];		
	}	
}


species sensor {
	bool available;
	agent connected_pollutant_cell;
	agent closest_building;
}

