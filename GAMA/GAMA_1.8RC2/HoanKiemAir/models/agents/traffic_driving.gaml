/***
* Name: trafficdriving
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model trafficdriving
import "../global_vars.gaml"

global {
	float time_vehicles_move;
}

// Driving skill
species vehicle skills: [advanced_driving] {
	string type;
	int counter_stucked <- 0;
	int threshold_stucked;
	intersection target;
	
	init {
		max_speed <- 50 #km/#h;
		right_side_driving <- true;
		proba_lane_change_up <- 0.1 + (rnd(500) / 500);
		proba_lane_change_down <- 0.5 + (rnd(500) / 500);
		location <- one_of(intersection).location;
		security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
		proba_respect_priorities <- 1.0 - rnd(200 / 1000);
		proba_respect_stops <- [1.0];
		proba_block_node <- 0.0;
		proba_use_linked_road <- 0.5;
		max_acceleration <- 5 / 3.6;
		speed_coeff <- 1.2 - (rnd(400) / 1000);
		threshold_stucked <- int((1 + rnd(5)) #mn);
	}

	reflex time_to_go when: final_target = nil {
		target <- one_of(intersection);
		current_path <- compute_path(graph: road_network, target: target);
		if (current_path = nil) {
			location <- one_of(intersection).location;
		} 
	}

	reflex move when: current_path != nil and final_target != nil {
		float start <- machine_time;
		do drive;
		if (final_target != nil) {
			if real_speed < 5 #km / #h {
				counter_stucked <- counter_stucked + 1;
				if (counter_stucked mod threshold_stucked = 0) {
					proba_use_linked_road <- min([1.0, proba_use_linked_road + 0.1]);
				}
	
			} else {
				counter_stucked <- 0;
				proba_use_linked_road <- 0.0;
			}
		}
		time_vehicles_move <- time_vehicles_move + (machine_time - start);
	}

	aspect default {
		point loc <- calcul_loc();
		draw rectangle(1,vehicle_length) + triangle(1) rotate: heading + 90 depth: 1 color: color at: loc;
//		draw triangle(8) color: color rotate: heading + 90;
	}

	point calcul_loc {
		if (current_road = nil) {
			return location;
		} else {
			float val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? -val : val;
			if (val = 0) {
				return location;
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
	} 
}

//species that will represent the roads, it can be directed or not and uses the skill skill_road
species road skills: [skill_road] {
	geometry geom_display;
	bool oneway;
	int osm_id;

	aspect default {
//		draw geom_display color: #lightgray;
		draw shape color: #white end_arrow: 5;
	}
}

species intersection skills: [skill_road_node] {
	bool is_traffic_signal;
	list<list> stop;
	int time_to_change <- 100;
	int counter <- rnd(time_to_change);
	list<road> ways1;
	list<road> ways2;
	bool is_green;
	rgb color_fire;

	action initialize {
		if (is_traffic_signal) {
			do compute_crossing;
			stop << [];
			if (flip(0.5)) {
				do to_green;
			} else {
				do to_red;
			}
		}
	}

	action compute_crossing {
		if (length(roads_in) >= 2) {
			road rd0 <- road(roads_in[0]);
			list<point> pts <- rd0.shape.points;
			float ref_angle <- float(last(pts) direction_to rd0.location);
			loop rd over: roads_in {
				list<point> pts2 <- road(rd).shape.points;
				float angle_dest <- float(last(pts2) direction_to rd.location);
				float ang <- abs(angle_dest - ref_angle);
				if (ang > 45 and ang < 135) or (ang > 225 and ang < 315) {
					ways2 << road(rd);
				}
			}
		}

		loop rd over: roads_in {
			if not (rd in ways2) {
				ways1 << road(rd);
			}
		}
	}

	action to_green {
		stop[0] <- ways2;
		color_fire <- #green;
		is_green <- true;
	}

	action to_red {
		stop[0] <- ways1;
		color_fire <- #red;
		is_green <- false;
	}

	reflex dynamic_node when: is_traffic_signal {
		counter <- counter + 1;
		if (counter >= time_to_change) {
			counter <- 0;
			if is_green {
				do to_red;
			} else {
				do to_green;
			}
		}
	}

	aspect default {
		if (is_traffic_signal) {
			draw box(1, 1, 10) color: #black;
			draw sphere(3) at: {location.x, location.y, 10} color: color_fire;
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


