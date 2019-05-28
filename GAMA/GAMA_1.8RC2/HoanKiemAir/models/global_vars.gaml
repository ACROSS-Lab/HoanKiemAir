/***
* Name: staticvars
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model staticvars

global {
	// Simulation parameters
	int n_cars;
	int n_motorbikes;
	int road_scenario;
	int display_mode;
	// Save params' old values to detect value changes
	int n_cars_prev;
	int n_motorbikes_prev;
	int road_scenario_prev;
	int display_mode_prev;
	
	float pollutant_decay_rate <- 0.999999;
	int grid_size <- 50;
	int grid_depth <- 10; // cubic meters
	
	graph road_network;
	
	// Buildings
	float min_height <- 0.1;
	float mean_height <- 1.3;
	string type_outArea <- "outArea";	
	
	// Daytime color blender
	bool day_time_color_blender <- true;
	map<date,rgb> day_time_colors <- 
		[date("00 00 00", "HH mm ss")::#midnightblue,
			date("06 00 00","HH mm ss")::#deepskyblue,
			date("14 00 00","HH mm ss")::#gold,
			date("18 00 00","HH mm ss")::#darkorange,
			date("19 00 00","HH mm ss")::#blue
		];
	float day_time_color_blend_factor <- 0.1;

}

