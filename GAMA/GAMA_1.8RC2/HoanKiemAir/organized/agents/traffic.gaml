/***
* Name: traffic
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model traffic

global {
	float time_vehicles_move;
	int nb_recompute_path;
}

species road schedules: [] {
	string type;
	bool oneway;
	bool s1_close;
	bool s2_close;
	bool closed;
	
	float capacity <- 1 + shape.perimeter/30;
	
	float speed_coeff <- 1.0 min: 0.1;
	
	action update_speed_coeff(int n_cars, int n_motorbikes) {
		speed_coeff <- (n_cars + n_motorbikes <= capacity) ? 1 : exp(-(n_motorbikes + 4 * n_cars)/capacity);
	}

	aspect default {
		if (closed) {
			draw shape + 5 color: #orange;
		} else {
			draw shape+1/speed_coeff color: (speed_coeff=1.0)?#white : #red end_arrow: 10;
		}
	}
}

species vehicle skills: [moving] {
	string type;
	
	point target;
	float time_to_go;
	bool recompute_path <- false;
	graph road_network;
	
	path my_path;
	
	init {
		speed <- 30 + rnd(20) #km / #h;
		location <- one_of(building).location;
	}
	
	action update_road_network(graph new_road_network) {
		write "HERE I AM";
		road_network <- new_road_network;
		recompute_path <- true;
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
		time_vehicles_move <- time_vehicles_move + (end - start);
	}
	
	aspect default {
		switch type {
			match "car" {
				draw rectangle(10, 5) rotate: heading color: #orange depth: 2;
			}
			match "motorbike" {
				draw rectangle(5, 2) rotate: heading color: #cyan depth: 3;
			}
		}
	}
}

species building schedules: [] {
	float height;
	float norm_pollution_level;
	rgb color;
	
	init {
		if height < 0.1 {
			height <- 1.3 + rnd(0.3, 0.3);
		}
	}
	
	aspect default {
		draw shape color: #grey border: #darkgrey depth: height * 10;
	}
	
	aspect colorful {
		if (norm_pollution_level < 0.05) 	{
			color <- #green;
		} else if (norm_pollution_level < 2) {
			color <- #orange;
		} else {
			color <- # red;
		}
		draw shape color: color border: #darkgrey depth: height * 10;
	}
}

species dummy_road schedules: [] {
	int mid;
	int oneway;
	int linkToRoad;
	float density <- 5.0;
	road linked_road;
	int segments_number ;
	int aspect_size <- 5;
	list<float> segments_x <- [];
	list<float> segments_y <- [];
	list<float> segments_length <- [];
	list<point> lane_position_shift <- [];
	
	int movement_time <- 5;
	
	init {
		// Remove duplicate points
		int i <- 0;
		list<point> filtered_points <- shape.points;
		loop while: i < length(filtered_points) - 1 {
			if filtered_points[i] = filtered_points[i + 1] {
				remove from: filtered_points index: i;
			} else {
				i <- i + 1;	
			}
		}
		shape <- polyline(filtered_points);
		
		segments_number <- length(shape.points) - 1;
		loop i from: 0 to: segments_number - 1 {
			if shape.points[i+1] != shape.points[i] {
				add shape.points[i+1].x - shape.points[i].x to: segments_x;
				add shape.points[i+1].y - shape.points[i].y to: segments_y;
			}
		}
	}

	aspect default {
		point new_point;
		int lights_number <- shape.perimeter / 50;
		
		draw shape color: #grey end_arrow: 10;

		loop i from: 0 to: segments_number-1 {
			// Calculate rotation angle
			point u <- {segments_x[i] , segments_y[i]};
			point v <- {1, 0};
			float dot_prod <- u.x * v.x + u.y * v.y;
			float angle <- acos(dot_prod / (sqrt(u.x ^ 2 + u.y ^ 2) + sqrt(v.x ^ 2 + v.y ^ 2)));
			angle <- (u.x * -v.y + u.y * v.x > 0) ? angle : 360 - angle;
			
		 	loop j from:0 to: lights_number-1 {
 				new_point <- {shape.points[i].x + segments_x[i] * (j + mod(cycle, movement_time)/movement_time)/lights_number, 
 											shape.points[i].y + segments_y[i] * (j + mod(cycle, movement_time)/movement_time)/lights_number};
				draw rectangle(10, 4) at: new_point color: #yellow rotate: angle depth: 3;
			}
		}	
	}
}
