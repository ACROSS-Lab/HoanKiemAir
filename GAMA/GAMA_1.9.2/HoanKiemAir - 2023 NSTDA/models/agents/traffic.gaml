/***
* Name: traffic
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model traffic
import "../global_vars.gaml"
 
species road schedules: [] {
	string type;
	bool oneway;
	bool s1_closed;
	bool s2_closed;
	
	bool closed;
	float capacity <- 1 + shape.perimeter/30;
	float speed_coeff <- 1.0 min: 0.1;
	
	action update_speed_coeff(int n_cars_on_road, int n_motorbikes_on_road) {
		speed_coeff <- (n_cars_on_road + n_motorbikes_on_road <= capacity) ? 1 : exp(-(n_motorbikes_on_road + 4 * n_cars_on_road)/capacity);
	}

	aspect default {
		if(display_mode = 0)  {
			if (closed) {
				draw shape + 5 color: palet[CLOSED_ROAD_TRAFFIC];
			} else {
				draw shape+2/(speed_coeff) color: (speed_coeff=1.0) ? palet[NOT_CONGESTED_ROAD] : palet[CONGESTED_ROAD] /*end_arrow: 10*/;		
			}		
		} else {
			if (closed) {
				draw shape + 5 color: palet[CLOSED_ROAD_POLLUTION];
			}			
		}
		
	}
}

species vehicle skills: [moving] {
	string type;
	
	point target;
	float time_to_go;
	bool recompute_path <- false;
	
	path my_path;
	
	init {
		speed <- 30 + rnd(20) #km / #h;
		location <- one_of(building).location;
	}
	
	
	reflex choose_new_target when: target = nil and time >= time_to_go {
		target <- road_network.vertices closest_to any(building);
	}
	
	reflex move when: target != nil {
		float start <- machine_time;
		do goto target: target on: road_network recompute_path: recompute_path;
		if location = target {
			target <- nil;
			time_to_go <- time; //+ rnd(15)#mn;
		}
		if (recompute_path) {
			recompute_path <- false;
		}
		float end <- machine_time; 
	}
	
	aspect default {
		switch type {
			match "car" {
				draw rectangle(10, 5) rotate: heading color: palet[CAR] depth: 2;
			}
			match "motorbike" {
				draw rectangle(5, 2) rotate: heading color: palet[MOTOBYKE] depth: 3;
			}
		}
	}
}

species building schedules: [] {
	float height;
	string type;
	float aqi;
	rgb color;
	
	agent p_cell;
	
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

species natural schedules: [] {
	aspect default {
		draw shape color: palet[NATURAL] ; //border: #darkblue;
	}	
}

