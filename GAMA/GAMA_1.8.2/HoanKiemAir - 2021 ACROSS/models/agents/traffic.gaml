/***
* Name: traffic
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model traffic
import "../global_vars.gaml"

global {
	float time_vehicles_move;
	int nb_recompute_path;
}

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
		
		
//		if (closed) {
//			draw shape + 5 color: palet[CLOSED_ROAD];
//		} else if (display_mode = 0) {
//			draw shape+2/(speed_coeff) color: (speed_coeff=1.0) ? palet[NOT_CONGESTED_ROAD] : palet[CONGESTED_ROAD] /*end_arrow: 10*/;
//		} else {
//			draw shape color: palet[ROAD_POLLUTION_DISPLAY] /*end_arrow: 10*/;
//		}
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
		time_vehicles_move <- time_vehicles_move + (end - start);
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

species decoration_building schedules: [] {
	float height;
	
	aspect default {
		draw shape color: palet[DECO_BUILDING] border: #darkgrey depth: height * 10;
	}
}

species natural schedules: [] {
	aspect default {
		draw shape color: palet[NATURAL] ; //border: #darkblue;
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
		loop j from: 0 to: segments_number - 1 {
			if shape.points[j+1] != shape.points[j] {
				add shape.points[j+1].x - shape.points[j].x to: segments_x;
				add shape.points[j+1].y - shape.points[j].y to: segments_y;
			}
		}
	}

	aspect default {
		point new_point;
		int lights_number <- int(shape.perimeter / 50);
		
		draw shape color: palet[DUMMY_ROAD] /*end_arrow: 10*/;

//		loop i from: 0 to: segments_number-1 { 
//			// Calculate rotation angle
//			point u <- {segments_x[i] , segments_y[i]};
//			point v <- {1, 0};
//			float dot_prod <- u.x * v.x + u.y * v.y;
//			float angle <- acos(dot_prod / (sqrt(u.x ^ 2 + u.y ^ 2) + sqrt(v.x ^ 2 + v.y ^ 2)));
//			angle <- (u.x * -v.y + u.y * v.x > 0) ? angle : 360 - angle;
//			
//		 	loop j from:0 to: lights_number-1 {
// 				new_point <- {shape.points[i].x + segments_x[i] * (j + mod(cycle, movement_time)/movement_time)/lights_number, 
// 											shape.points[i].y + segments_y[i] * (j + mod(cycle, movement_time)/movement_time)/lights_number};
//				draw rectangle(10, 4) at: new_point color: #yellow rotate: angle depth: 3;
//			}
//		}	
	}
}
