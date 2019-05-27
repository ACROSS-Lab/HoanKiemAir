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
		
		float pollutant_decay_rate <- 0.8;
		int grid_size <- 50;
		int grid_depth <- 10; // cubic meters
		
		graph road_network;
}

