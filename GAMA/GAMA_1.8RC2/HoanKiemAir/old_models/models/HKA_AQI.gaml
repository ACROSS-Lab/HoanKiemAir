model HoanKiemAir

global {
	// Constants
	map<string, float> ALLOWED_AMOUNT <- ["CO"::30000 * 10e-6, "NOx"::200 * 10e-6, "SO2"::350 * 10e-6, "PM"::300 * 10e-6]; // g/m3
	map<string, map<string, float>> EMISSION_FACTOR <- [
		"motorbike"::["CO"::3.62, "NOx"::0.3, "SO2"::0.03, "PM"::0.1],  // g/km
		"car"::["CO"::3.62, "NOx"::1.5, "SO2"::0.17, "PM"::0.1]
	];
	
	// Misc params
	bool connect_to_tablet <- false;
	int display_mode;
	
	// Simulation params
	float step <- 10#s;
	int pollutant_cell_size <- 64;
	float pollutant_decay_rate <- 0.9;
	// Changeable params
	int nb_cars;
	int nb_motorbikes;
	int close_roads <- 0;
	// Pseudo params to detect value changes
	int nb_cars_prev <- nb_cars;
	int nb_motorbikes_prev <- nb_motorbikes;
	int close_roads_prev <- close_roads;

	float aqi;
	
	// Load shapefiles
	string resources_dir <- "../includes/bigger_map/";
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file dummy_roads_shape_file <- shape_file(resources_dir + "small_dummy_roads.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	
	geometry shape <- envelope(buildings_shape_file);
	float cell_width <- shape.width / 50;
	float cell_height <- shape.height / 50;
	float cell_volume <- cell_width * cell_height * 10; // in cubic meters	
	
	graph road_graph;
	
	init {
		create road from: roads_shape_file {
			// Create a reverse road if the road is not oneway
			if (!oneway) {
				create road {
					shape <- polyline(reverse(myself.shape.points));
					name <- myself.name;
					type <- myself.type;
					s1_close <- myself.s1_close;
					s2_close <- myself.s2_close;
				}
			}
		}
		
		map<road, float> road_weights <- road as_map (each::each.shape.perimeter); 
		road_graph <- as_edge_graph(road) with_weights road_weights;
		
		create dummy_road from: dummy_roads_shape_file {
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
		create building from: buildings_shape_file;
		
		geometry road_geometry <- union(road accumulate each.shape);
		ask pollutant_cell {
			active <- self overlaps road_geometry;
		}
		
		create progress_bar;
		create line_graph_aqi;
		create indicator_health_concern_level;
	}
	
	reflex update_nb_cars when: nb_cars != nb_cars_prev {
		int delta <- nb_cars - nb_cars_prev;
		if (delta < 0) {
			ask -delta among car {
				do die;
			}
		} else {
			create car number: delta;
		}
		nb_cars_prev <- nb_cars;
	}

	reflex update_nb_motorbike when: nb_motorbikes != nb_motorbikes_prev {
		int delta <- nb_motorbikes - nb_motorbikes_prev;
		if (delta < 0) {
			ask -delta among motorbike {
				do die;
			}
		} else {
			create motorbike number: delta;
		}
		nb_motorbikes_prev <- nb_motorbikes;
	}
	
	reflex update_road_graph when: close_roads != close_roads_prev {
		list<road> roads;
		switch close_roads {
			match 0 {
				roads <- list(road);
			}
			match 1 {
				roads <- road where !each.s1_close;
			}
			match 2 {
				roads <- road where !each.s2_close;
			}
		}
		map<road, float> road_weights <- roads as_map (each::each.shape.perimeter); 
		road_graph <- as_edge_graph(roads) with_weights road_weights;
		close_roads_prev <- close_roads;
		ask vehicle {
			recompute_path <- true;
		}
	}
	
	matrix<float> mat_diff <- matrix([
			[1/20,1/20,1/20],
			[1/20, 3/5 * pollutant_decay_rate,1/20],
			[1/20,1/20,1/20]]);
			
	reflex diffuse_pollutant {
		diffuse var: co on: pollutant_cell matrix: mat_diff;
		diffuse var: nox on: pollutant_cell matrix: mat_diff;
		diffuse var: so2 on: pollutant_cell matrix: mat_diff;
		diffuse var: pm on: pollutant_cell matrix: mat_diff;
	}
	
	reflex calculate_aqi when: every(1 #hour) {
		 aqi <- max(pollutant_cell accumulate each.aqi_hourly);
		 ask line_graph_aqi {
		 	do update;
		 }
		 ask indicator_health_concern_level {
		 	do update;
		 }
	}
}

species road schedules: [] {
	string type;
	bool oneway;
	bool s1_close;
	bool s2_close;
	
	float capacity <- 1 + shape.perimeter/30;
	int nb_cars_on_road -> length(car at_distance 1);
	int nb_motorbikes_on_road -> length(motorbike at_distance 1);
	int nb_vehicles_on_road -> nb_cars_on_road + nb_motorbikes_on_road;
	
	float speed_coeff <- 1.0 update: (nb_vehicles_on_road <= capacity) ? 1 : exp(-(nb_motorbikes_on_road+ 4 * nb_cars_on_road)/capacity) min: 0.1;
	
	aspect default {
		if (s1_close and close_roads = 1) or (s2_close and close_roads = 2) {
			draw shape + 5 color: #orange;
		} else {
			draw shape+1/speed_coeff color: (speed_coeff=1.0)?#white : #red end_arrow: 10;
		}
	}
}

species vehicle skills: [moving] {
	point target;
	float time_to_go;
	bool recompute_path;
	
	init {
		speed <- 30 + rnd(20) #km / #h;
		location <- one_of(building).location;
	}
	
	reflex choose_new_target when: target = nil and time >= time_to_go {
		target <- one_of(building).location;
	}
	
	reflex move when: target != nil {
		do goto target: target on: road_graph recompute_path: recompute_path;
		if location = target {
			target <- nil;
			time_to_go <- time; //+ rnd(15)#mn;
		}
		if (recompute_path) {
			recompute_path <- false;
		}
	}
}

species car parent: vehicle {
	aspect default {
		draw rectangle(10, 5) rotate: heading color: #orange depth: 3;
	}
}

species motorbike parent: vehicle {
	aspect default {
		draw rectangle(5, 2) rotate: heading color: #cyan depth: 3;
	}
}

grid pollutant_cell width: pollutant_cell_size height: pollutant_cell_size neighbors: 8 parallel: true {
	// Pollutant values
	float co <- 0.0;
	float nox <- 0.0;
	float so2 <- 0.0;
	float pm <- 0.0;

	bool active;
	int aqi_hourly;
	float norm_pollution_level -> (co / ALLOWED_AMOUNT["CO"] + nox / ALLOWED_AMOUNT["NOx"] + 
																		so2 / ALLOWED_AMOUNT["SO2"] + pm / ALLOWED_AMOUNT["PM"]) / cell_volume / 4;
	
	rgb color <- #black update: rgb(255 * norm_pollution_level * 10, 0,0);
	
	reflex absorb_pollutant when: active {
		list<vehicle> vehicles_on_cell <- union(car overlapping self, motorbike overlapping self);
		
		loop v over: vehicles_on_cell {
			if (is_number(v.real_speed)) {
				float dist_traveled <- v.real_speed * step / #km;
				string vehicle_type <- string(type_of(v));

				co <- co + dist_traveled * EMISSION_FACTOR[vehicle_type]["CO"];
				nox <- nox + dist_traveled * EMISSION_FACTOR[vehicle_type]["NOx"];
				so2 <- so2 + dist_traveled * EMISSION_FACTOR[vehicle_type]["SO2"];
			    pm <- pm + dist_traveled * EMISSION_FACTOR[vehicle_type]["PM"];
			}
		}
	}
	
	reflex calculate_aqi when: time mod 1#hour = 0 {
		float aqi_co <- (co / cell_volume) / ALLOWED_AMOUNT["CO"] * 100;
		float aqi_nox <- (nox / cell_volume) / ALLOWED_AMOUNT["NOx"] * 100;
		float aqi_so2 <- (so2 / cell_volume) / ALLOWED_AMOUNT["SO2"] * 100;
		float aqi_pm <- (pm / cell_volume) / ALLOWED_AMOUNT["PM"] * 100;
		aqi_hourly <- max(aqi_co, aqi_nox, aqi_so2, aqi_pm);
	}
}

species building schedules: [] {
	int height <- 10 + rnd(10);
	
	aspect default {
		draw shape color: #grey border: #darkgrey depth: height;
	}
}

// Species to display additional info
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

species progress_bar schedules: [] {
	geometry rect(float x, float y, float width, float height) {
		return polygon([{x, y}, {x + width, y}, {x + width, y + height}, {x, y + height}, {x, y}]);
	}
	
	action draw_bar(float tracked_val, float tracked_val_max, float x, float y, float width, float height, 
									string bar_name, string left_label, string right_label) {
		float length_filled<- width * tracked_val / tracked_val_max;
		float length_unfilled <- width - length_filled;
		
		draw rect(x, y, length_filled, height) color: #orange;
		draw rect(x + length_filled, y, length_unfilled, height) color: #white;
		
		draw(bar_name + ": ") at: {x, y - 50} font: font(20);
		draw(left_label) at: {x - 20, y + 200} font: font(18);
		draw(right_label) at: {x + width - 20, y + 200} font: font(18);
	}
	
	aspect default {	
		do draw_bar tracked_val: nb_cars tracked_val_max: 500 x: -700 y: 1800 width: 500 height: 100 
								bar_name: "Cars" left_label: "0" right_label: "500";
		do draw_bar tracked_val: nb_motorbikes tracked_val_max: 2000 x: -700 y: 2200 width: 500 height: 100 
								bar_name: "Motorbikes" left_label: "0" right_label: "2000";
	}
}

species line_graph_aqi parent: line_graph {
	float tracked_val -> aqi;
	float x <- 2400;
	float y <- 1400;
	float width <- 1300;
	float height <- 1000;
	string label <- "Hourly AQI";
}

species line_graph schedules: [] {
	// Params
	float tracked_val;
	float x;
	float y;
	float width;
	float height;
	string label <- "";
	string unit <- "";

	list<float> val_list <- list_with(20, -1.0);
	
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}
	
	action draw_line(point a, point b, int thickness <- 1, rgb color <- #yellow, int end_arrow <- 0) {
		draw line([a, b]) + thickness at: midpoint(a, b) color: color end_arrow: end_arrow;
	}
	
	action update {
		remove index: 0 from: val_list;
		add item: tracked_val to: val_list at: length(val_list);
	}
	
	aspect default {
		point origin <- {x, y + height};
		
		// Draw axis
		do draw_line a: origin b: {x, y} thickness: 5;
		do draw_line a: origin b: {x + width, y + height} thickness: 5;
		
		point prev_val_pos <- nil;
		float max_val <- max(val_list) = 0 ? 1 : max(val_list);
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] >= 0) {
				float val_x_pos <- origin.x + width / length(val_list) * i;
				float val_y_pos <- origin.y - (val_list[i] / max_val * height);
				point val_pos <- {val_x_pos, val_y_pos};
				// Graph the value
				draw circle(10, val_pos);		float current_val <- val_list[length(val_list) - 1];
				float current_val_height <- current_val / max_val * height;
				if (prev_val_pos != nil) {
					do draw_line a: val_pos b: prev_val_pos thickness: 3;	
				} 
				prev_val_pos <- val_pos;
			}
		}
		// Draw current value indicator
		do draw_line({x, prev_val_pos.y}, {x + width, prev_val_pos.y}, 2, #red);
		draw label + " " + string(round(val_list[length(val_list) - 1])) + " " + unit at: {x + 50,  prev_val_pos.y - 50} font: font(20) color: #orange;
	}
}

species indicator_health_concern_level schedules: [] {
	float x <- 3000;
	float y <- 1000;
	float width <-600;
	float height <- 200;
	rgb color;
	rgb text_color;
	string text;
	
	point anchor <- #center;
	
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}
	
	action update {
		anchor <- #center;
		if (aqi < 51) {
			color <- #seagreen;
			text_color <- #white;
			text <- " Good";
		} else if (aqi < 101) {
			color <- #yellow;
			text_color <- #black;
			text <- " Moderate";
		} else if (aqi < 151) {
			color <- #orange;
			text_color <- #white;
			text <- " Unhealthy for\nSensitive Groups";
			anchor <- #bottom_center;
		} else if (aqi < 201) {
			color <- #crimson;
			text_color <- #white;
			text <- " Unhealthy";
		} else if (aqi < 301) {
			color <- #purple;
			text_color <- #white;
			text <- " Very unhealthy";
		} else {
			color <- #darkred;
			text_color <- #white;
			text <- " Hazardous";
		}
	}
	
	aspect default {
		draw rectangle({x, y}, {x + width, y + height}) color: color;
		point center <- midpoint({x, y}, {x + width, y + height});
		draw text at: center color: text_color anchor: anchor font: font(20);
		draw "Health concern" at: center - {600, 0} color: #yellow anchor: #center font: font(20);
	}
}

experiment exp {
	parameter "Number of cars" var: nb_cars <- 0 min: 0 max: 200;
	parameter "Number of motorbikes" var: nb_motorbikes <- 0 min: 0 max: 1000;
	parameter "Close roads" var: close_roads <- 0 min: 0 max: 2;
//	parameter "AQI"  var: aqi <- 0.0;
	
	output {
		display main type: opengl background: #black {
			species road;
			species dummy_road;
			species car;
			species motorbike;
			species building;
			
			species progress_bar;
			species line_graph_aqi;
			species indicator_health_concern_level;
			
			grid pollutant_cell transparency: 0.4 elevation: norm_pollution_level * 1000 triangulation: true;
		}
	}
}