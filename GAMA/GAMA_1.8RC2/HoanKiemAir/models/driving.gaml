/**
* Name: Complex Road Network 
* Author: Patrick Taillandier
* Description: Model to show how to use the driving skill to represent the traffic on a road network imported from shapefiles (generated, for the city, with 
* OSM Loading Driving), with intersections and traffic lights going from red to green to let people move or stop. Two experiments are presented : one concerning a 
* a simple ring network and the other a real city network.
* Tags: gis, shapefile, graph, agent_movement, skill, transport
*/
model RoadTrafficComplex

global {

	graph road_network;
	int nb_people <- 500;
	// Load shapefiles
	string resources_dir <- "../includes/bigger_map/";
	shape_file map_boundary_rectangle_shape_file <- shape_file(resources_dir + "resize_rectangle.shp");	
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file external_nodes_shape_file <- shape_file(resources_dir + "external_nodes.shp");
	shape_file intersections_shape_file <- shape_file(resources_dir + "intersections.shp");
	shape_file dummy_roads_shape_file <- shape_file(resources_dir + "small_dummy_roads.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	shape_file buildings_admin_shape_file <- shape_file(resources_dir + "buildings_admin.shp");
	shape_file naturals_shape_file <- shape_file(resources_dir + "naturals.shp");
	geometry shape <- envelope(roads_shape_file) + 50.0;
	
	init {
	//create the intersection and check if there are traffic lights or not by looking the values inside the type column of the shapefile and linking
	// this column to the attribute is_traffic_signal. 
		create intersection from: intersections_shape_file {
			is_traffic_signal <- false;
		}

		//create road agents using the shapefile and using the oneway column to check the orientation of the roads if there are directed
		create road from: roads_shape_file {
			lanes <- 2;
			geom_display <- shape + (2.5 * lanes);
			maxspeed <-100 #km /#h;// (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km / °h;
			if(!oneway){
					create road {
						lanes <- 2;
						shape <- polyline(reverse(myself.shape.points));
						maxspeed <-100 #km /#h;
						geom_display <- myself.geom_display;
						linked_road <- myself;
						myself.linked_road <- self;
				}
			}

		}

		map general_speed_map <- road as_map (each::(each.shape.perimeter / each.maxspeed));

		//creation of the road network using the road and intersection agents
		road_network <- (as_driving_graph(road, intersection)) with_weights general_speed_map;

		//initialize the traffic light
		ask intersection {
			do initialize;
		}

		create people number: nb_people {
			max_speed <- 50 #km / #h;
			vehicle_length <- 3 #m;
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
			threshold_stucked <- int((1 + rnd(5)) #mn);
			proba_breakdown <- 0.00001;
		}

	}

}

//species that will represent the intersection node, it can be traffic lights or not, using the skill_road_node skill
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
			draw circle(5) color: color_fire;
		}
	}
}

//species that will represent the roads, it can be directed or not and uses the skill skill_road
species road skills: [skill_road] {
	geometry geom_display;
	bool oneway;

	aspect default {
		draw shape color: #white end_arrow: 5;	
	}

}

//People species that will move on the graph of roads to a target and using the driving skill
species people skills: [advanced_driving] {
	rgb color <- rnd_color(255);
	int counter_stucked <- 0;
	int threshold_stucked;
	bool breakdown <- false;
	float proba_breakdown;
	intersection target;

//	reflex breakdown when: flip(proba_breakdown) {
//		breakdown <- true;
//		max_speed <- 1 #km / #h;
//	}

	reflex time_to_go when: final_target = nil {
		target <- one_of(intersection );
		current_path <- compute_path(graph: road_network, target: target);
		if (current_path = nil) {
			location <- one_of(intersection).location;
		} 
	}

	reflex move when: current_path != nil and final_target != nil {
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
	}

	aspect default {
		draw breakdown ? square(8) : triangle(8) color: color rotate: heading + 90;
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

experiment experiment_city type: gui {
	output {
		display carte_principale type: opengl synchronized: true background: #gray{
			species road ;
			species intersection ;
			species people ;
		}
	}
}

