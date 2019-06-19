/***
* Name: traffic
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model traffic
import "../global_vars.gaml"

global {
	list<road> open_roads;
	list<intersection> incoming_nodes;
	list<intersection> outgoing_nodes;
	list<intersection> internal_nodes;
	
	action init_traffic {
		create intersection from: intersections_shape_file 
											with: [is_traffic_signal::(read("type") = "traffic_signals"), is_incoming::bool(read("in")), is_outgoing::bool(read("out"))] {
//			is_traffic_signal <- true;
		}
		incoming_nodes <- intersection where each.is_incoming;
		outgoing_nodes <- intersection where each.is_outgoing;
		internal_nodes <- intersection - union(incoming_nodes, outgoing_nodes);
		
		create road from: roads_shape_file {
			lanes <- 3;
			geom_display <- shape + (2.5 * lanes);
			maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km / °h;
			if (!oneway) {
				create road {
					lanes <- myself.lanes;
					shape <- polyline(reverse(myself.shape.points));
					maxspeed <- myself.maxspeed;
					geom_display <- myself.geom_display;
					linked_road <- myself;
					myself.linked_road <- self;
				}
			}
		}
		
		open_roads <- list(road);
		map<road, float> road_weights <- road as_map (each::(each.shape.perimeter));
		road_network <- as_driving_graph(road, intersection) with_weights road_weights;
		
		//initialize the traffic light
		ask intersection {
			do initialize;
		}
		
		create building from: buildings_shape_file;
		create sensor from: sensors_shape_file;
	}
	
	reflex update_network_weights {
		float start <- machine_time;
		map<road, float> road_weights <- road as_map (each::(each.shape.perimeter + length(each.all_agents) * 5));
		road_network <- road_network with_weights road_weights;
		time_update_network_weights <- machine_time - start;
	}
	
}

// Driving skill
species vehicle skills: [advanced_driving] {
	string type;
	float time_stucked <- 0.0;
	float threshold_stucked;
	intersection target;
	rgb color;
	
	init {
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
		threshold_stucked <- (1 + rnd(5)) #mn;
	}
	
	action reposition {
		if flip(0.7) {
			location <- one_of(incoming_nodes).location;
		} else {
			location <- one_of(internal_nodes).location;
		}
	}

	reflex time_to_go when: final_target = nil {
		if flip(0.7) {
			target <- one_of(outgoing_nodes);
		} else {
			target <- one_of(internal_nodes);
		}
		current_path <- compute_path(graph: road_network, target: target);
		if (current_path = nil) {
			do reposition;
		} 
	}

	reflex move when: current_path != nil and final_target != nil {
		float start <- machine_time;
		do drive;
		if (final_target != nil) {
			if real_speed < 5 #km / #h {
				time_stucked <- time_stucked + step;
				if (time_stucked mod threshold_stucked = 0) {
					proba_use_linked_road <- min([1.0, proba_use_linked_road + 0.1]);
				}
			} else {
				time_stucked <- 0.0;
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
	bool is_incoming;
	bool is_outgoing;
	
	list<list> stop;
	float time_to_change <- 100.0;
	float counter <- rnd(time_to_change);
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
		counter <- counter + step;
		if (counter >= time_to_change) {
			counter <- 0.0;
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
	
	action set_connected_cell(agent cell) {
		write(cell);
		connected_pollutant_cell <- cell;
	}
	
	aspect default {
		if (display_mode = 0) {
			draw shape color: (type = type_outArea)?palet[BUILDING_OUTAREA]:palet[BUILDING_BASE] /*border: #darkgrey*/ /*depth: height * 10*/;
		} else {
			draw shape color: (type = type_outArea)?palet[BUILDING_OUTAREA]:world.get_pollution_color(aqi) /*border: #darkgrey*/ depth: height * 10;
		}
	}
}
