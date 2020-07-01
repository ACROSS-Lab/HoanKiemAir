  /***
* Name: traffic
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model traffic

import "../Contantes and Parameters/global_vars.gaml"
import  "../misc/utils.gaml"

global {
	// params
	int car_multiplier <- 1;
	int motorbike_multiplier <- 1;
	int n_vehicles_max <- 5000;
	
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
			lanes <- 4;
			geom_display <- shape + lanes;
			maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km / °h;
			capacity <- shape.perimeter * lanes * 0.4;
			default_weight <- shape.perimeter - lanes * 2 - maxspeed * 0.5;
			if (!oneway) {
				create road {
					lanes <- myself.lanes;
					shape <- polyline(reverse(myself.shape.points));
					capacity <- myself.capacity;
					maxspeed <- myself.maxspeed;
					geom_display <- myself.geom_display;
					s1_closed <- myself.s1_closed;
					s2_closed <- myself.s2_closed;
					default_weight <- myself.default_weight;
					
					linked_road <- myself;
					myself.linked_road <- self;
					
				}
			}
		}
		
		map<road, float> road_weights <- road as_map (each::each.default_weight);
		road_network <- as_driving_graph(road, intersection) with_weights road_weights;
		
		//initialize the traffic light
		ask intersection {
			do initialize;
		}
		
		do update_road_scenario;
	}
	
	action reset_traffic {
		ask vehicle {
			final_target <- nil;
			do reposition;
		}
	}
	
	action update_road_network {
		list<road> open_roads;
		list<road> closed_roads;
		
		switch road_scenario {
			match 0 {
				closed_roads <- [];
				break;
			}
			match 1 {
				closed_roads <- road where each.s1_closed;
				break;
			}
			match 2 {
				closed_roads <- road where each.s2_closed;
				break;
			}
		}
		// Change the display of roads
		open_roads <- road - closed_roads;
		ask open_roads {
			closed <- false;
		}
		ask closed_roads {
			closed <- true;
		}
		write "Open roads: " + length(open_roads);
		write "Closed roads: " + length(closed_roads);

		// Either add/remove roads
		map<road, float> road_weights <- open_roads as_map (each::each.current_weight);
		road_network <- as_driving_graph(open_roads, intersection) with_weights road_weights;
		
		list<intersection> unreachable_nodes <- intersection where ((road_network degree_of each) = 0);
		internal_nodes <- intersection - incoming_nodes - outgoing_nodes - unreachable_nodes;
		write "Internal nodes: " + length(internal_nodes);
		write "Unreachable nodes: " + length(unreachable_nodes);
		
		// Move vehicles inside pedestrian zone elsewhere
		list<vehicle> vehicles_in_pedestrian_zone <- list<vehicle>(closed_roads accumulate (each.all_agents));
		write "Vehicles to be moved outside: " + length(vehicles_in_pedestrian_zone);
		ask vehicles_in_pedestrian_zone {
			do reposition;
		}
		
		
		// Ask vehicles going to pedestrian zone to choose another targets
		list<vehicle> vehicles_going_to_pedestrian_zone <- vehicle where (unreachable_nodes contains each.target);
		write "Vehicles going to another target: " + length(vehicles_going_to_pedestrian_zone);
		ask vehicles_going_to_pedestrian_zone {
			final_target <- nil;
		}
		
		// Ask all vehicles to recompute their path 
		ask vehicle {
			do recompute_path;
		}
	}
	
	action update_vehicle_population(string vehicle_type, int delta) {
		list<vehicle> vehicles <- vehicle where (each.type = vehicle_type);
		if (delta < 0) {
			ask -delta among vehicles {
				if current_road != nil {
					ask road(current_road) {
						do unregister(myself);
					}	
				}
				do die;
			}
		} else {
			create vehicle number: delta {
				self.type <- vehicle_type;
				if (type = "car") {
					self.vehicle_length <- 4.7#m;
					self.max_speed <- (rnd(50.0) + 10.0) #km / #h;
					self.proba_respect_stops <- [1.0];
					self.color <- #orange;
				} else {
					self.vehicle_length <- 2.0#m;
					self.max_speed <- (rnd(40.0) + 10.0) #km / #h;
					self.proba_respect_stops <- [0.7];
					self.color <- #cyan;
				}
			}
		}
	}
}

// Driving skill
species vehicle skills: [advanced_driving] schedules: [] {
	string type;
	float time_stucked <- 0.0;
	float threshold_stucked;
	intersection target;
	rgb color;
	road road_prev;
	
	init {
		right_side_driving <- true;
		proba_lane_change_up <- 0.1 + (rnd(500) / 500);
		proba_lane_change_down <- 0.5 + (rnd(500) / 500);
		location <- one_of(intersection).location;
		security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
		proba_respect_priorities <- 1.0 - rnd(200 / 1000);
		proba_respect_stops <- [1.0];
		proba_block_node <- 0.0;
		proba_use_linked_road <- 0.0;
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
	
	action recompute_path {
		current_path <- compute_path(graph: road_network, target: target);
		if (current_path = nil) {
			location <- one_of(intersection).location;
		} 
	}
	
	reflex choose_new_target when: final_target = nil  {
		if flip(0.7) {
			target <- one_of(outgoing_nodes);
		} else {
			target <- one_of(internal_nodes);
		}
		
		do recompute_path;
	}
	
	reflex check_for_encumbered_road when: current_path != nil and current_road != road_prev {
		list<road> edges <- list<road>(current_path.edges);
		if (current_index + 1 < length(edges)) and (road(edges[current_index + 1]).is_encumbered) and flip (0.7) {
			current_path <- compute_path(graph: road_network, target: target);
		}
		road_prev <- road(current_road);
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
		if debug_scheduling and (name < "vehicle10") {
			write name + "moved";	
		}
	}

	aspect default {
		point loc <- calcul_loc();
		draw rectangle(1,vehicle_length) + triangle(1) rotate: heading + 90 depth: 1 color: color at: loc;
//		draw triangle(8) color: color rotate: heading + 90;
	}

	point calcul_loc {
		if (current_road = nil) {
			return location;
		} 
		
		float val;
		if (road(current_road).oneway) {
			val <- (current_lane - mean(range(road(current_road).lanes - 1))) / (road(current_road).lanes - 1) * 4;
		} else {
			val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? -val : val;
		}
		return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
	} 
}

//species that will represent the roads, it can be directed or not and uses the skill skill_road
species road skills: [skill_road] schedules: [] {
	geometry geom_display;
	bool oneway;
	int osm_id;
	bool s1_closed;
	bool s2_closed;
	bool closed;
	
	float capacity;
	float congestion_factor <- 0.0;
	float encumbered_threshold <- 0.5;
	bool is_encumbered;
	
	float default_weight;
	float current_weight;
	
	reflex update_congestion_factor when: !closed {
		int n_cars_on_road <- all_agents count (vehicle(each).type = "car");
		int n_motorbikes_on_road <- all_agents count (vehicle(each).type = "motorbike");
		congestion_factor <- (n_cars_on_road * 4.7 * 2 + n_motorbikes_on_road * 2) / capacity * 1.5;
		
		if congestion_factor > encumbered_threshold {
			is_encumbered <- true;
			current_weight <- default_weight + congestion_factor * 100;
		} else {
			is_encumbered <- false;
			current_weight <- default_weight;
		}
		road_network <- road_network with_weights [self::current_weight];
	}

	aspect default {
		if(display_mode = 0)  {
			if (closed) {
				draw geom_display color: palet[CLOSED_ROAD_TRAFFIC];
			} else {
				draw geom_display color: rgb(255, (1 - congestion_factor ) * 255, (1 - congestion_factor) * 255);		
			}		
		} else {
			if (closed) {
				draw shape + 5 color: palet[CLOSED_ROAD_POLLUTION];
			}			
		}
	}
}

species intersection skills: [skill_road_node] schedules: [] {
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
