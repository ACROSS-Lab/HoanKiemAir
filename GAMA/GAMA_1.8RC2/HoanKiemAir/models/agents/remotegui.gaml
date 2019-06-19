/***
* Name: remotegui
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model remotegui
import "../global_vars.gaml"

global {
	init {
		// Connect to remote controller
		if (mqtt_connect) {
			create controller;
		}
	}
}

species controller skills: [remoteGUI] {
	int n_cars_selected;
	int n_motorbikes_selected;
	int road_scenario_selected;
	int display_mode_selected;
	
	init {
		do connect to: "localhost";
		do listen with_name: "n_cars" store_to: "n_cars_selected";
		do listen with_name: "n_motorbikes" store_to: "n_motorbikes_selected";
		do listen with_name: "road_scenario" store_to: "road_scenario_selected";
		do listen with_name: "display_mode" store_to: "display_mode_selected";
	}
	
	reflex update_n_cars when: n_cars_selected != n_cars_prev {
		n_cars <- n_cars_selected;
	}
	
	reflex update_n_motorbikes when: n_motorbikes_selected != n_motorbikes_prev {
		n_motorbikes <- n_motorbikes_selected;
	}
	
	reflex update_road_scenario when: road_scenario_selected != road_scenario_prev {
		road_scenario <- road_scenario_selected;
	}
	
	reflex update_display_mode when: display_mode_selected != display_mode_prev {
		display_mode <- display_mode_selected;
	}
}