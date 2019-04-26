
model NewModel

global {
	bool connect_to_mqtt_server <- false;
	
	int DISPLAY_MODE_TRAFFIC <- 0 const: true;
	int DISPLAY_MODE_POLLUTION <- 1 const: true;
	int display_mode <- DISPLAY_MODE_TRAFFIC;
	
	// Parameters
	bool close_roads;
	bool close_roads_prev;
	bool recompute_path <- false;

	string TYPE_MOTORBIKE <- "motorbyke";
	string TYPE_CAR <- "car";
	string TYPE_TRUCK <- "truck";

	// COEFF Vehicule
	float MOTORBIKE_COEF <- 1.0;
	float CAR_COEF <- 2.0;
	float TRUCK_COEF <- 2.0;
	map<string,float> coeff_vehicle <- map([TYPE_MOTORBIKE::MOTORBIKE_COEF,TYPE_CAR::CAR_COEF,TYPE_TRUCK::TRUCK_COEF]);	
	map<string,rgb> color_vehicle <- map([TYPE_MOTORBIKE::#yellow,TYPE_CAR::#blue,TYPE_TRUCK::#red]);	

	int nb_moto <- 0;
	int nb_car <- 0;
	int nb_people;

	int nb_people_moto <- 1;
	int nb_people_car <- 2;
	int nb_people_car_prev <- nb_people_car;
	
	int nb_moto_prev <- nb_moto;
	int nb_people_prev <- nb_people;

	int dynamic_number_car -> { vehicle count (each.type = TYPE_CAR) };
	int dynamic_number_moto -> { vehicle count (each.type = TYPE_MOTORBIKE) };
		
	int dynamic_number_people -> {sum(vehicle accumulate (each.nb_people))};
	int dynamic_number_people_moto -> {sum((vehicle where (each.type = TYPE_MOTORBIKE)) accumulate (each.nb_people))};
	int dynamic_number_people_car -> {sum( (vehicle where (each.type = TYPE_CAR)) accumulate (each.nb_people))};
	
	// Pollution en CO2
	map<string,map<int,float>> pollution_rate <- [
		"essence"::[10::98.19,20::69.17,30::56.32,40::49.3,50::45.29],
		"diesel"::[10::201.74,20::152,30::127.82,40::114.29,50::106.48]
	];
	
	map<string, map<string, float>> emission_factor <- [
		TYPE_MOTORBIKE::["PM"::0.1, "SO2"::0.03, "NOx"::0.3, "CO"::3.62, "benzene"::0.023],
		TYPE_CAR::["PM"::0.1, "SO2"::0.17, "NOx"::1.5, "CO"::3.62, "benzene"::0.046]
	];

	float decrease_coeff <- 0.8;
	
	shape_file simulated_roads_shape_file <- shape_file("../includes/bigger_map/simulated_roads.shp");
	shape_file dummy_roads_shape_file <- shape_file("../includes/bigger_map/smaller_dummy_roads.shp");
	shape_file buildings_shape_file <- shape_file("../includes/bigger_map/buildings.shp");
	shape_file lakes_shape_file <- shape_file("../includes/bigger_map/lakes.shp");
	shape_file pollutant_cells_shape_file <- shape_file("../includes/bigger_map/road_pollution_grid.shp");
	shape_file bound_shape_file <- shape_file("../includes/bigger_map/bound.shp");

	geometry shape <- envelope(bound_shape_file);

	map<string,rgb> col <- map(['footway'::#green,'residential'::#blue,'primary'::#orange,
								'secondary'::#yellow,'tertiary'::#indigo,'primary_link'::#black,
								'unclassified'::#black,'service'::#black,'living_street'::#black,
								'path'::#black,'secondary_link'::#black,'trunk'::#black,
								'pedestrian'::#darkgreen,'steps'::#black]);
	
	graph road_graph;
	map<road,float> road_weights;
	
	geometry road_geom;
		
	init {
		create road from: simulated_roads_shape_file {
			if (oneway = 0){
				create road {
					shape <- polyline(reverse(myself.shape.points));
					type <- myself.type;
					close <- myself.close;
				}
			}
		}
		
		
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

//					if oneway = 0 {
//						add {segments_y[i]/segments_length[i]*4,- segments_x[i]/segments_length[i]*4} to: lane_position_shift;
//					}
				}
			}
		}
		
		ask dummy_road {highlight <- true;}
		
		create building from: buildings_shape_file;
		create lake from: lakes_shape_file;
		create pollutant_cell from: pollutant_cells_shape_file {
			neighbors <- pollutant_cell at_distance 10#cm;
			affected_buildings <- building at_distance 50 #m;
		}

		road_geom <- union(road accumulate (each.shape));
      	//Weights of the road
      	road_weights <- road as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(road);
		  
		if (connect_to_mqtt_server) {
			create controller number: 1 {
				do connect to: "localhost";
				
				do listen with_name: "nb_people" store_to: "selected_nb_people";
				do listen with_name: "nb_moto" store_to: "selected_nb_moto";
				do listen with_name: "nb_people_car" store_to: "selected_nb_people_car";
				do listen with_name: "close_roads" store_to: "selected_close_roads";
				do listen with_name: "display_mode" store_to: "selected_display_mode";
			}
		}
		
		// Display additional information
		create progress_bar;
		create line_graph_mean_pollution;
	}

	reflex update_compute_path when: recompute_path {
		recompute_path <- false;		
	}


	reflex close_roads when:(close_roads != close_roads_prev) {
		list<road> roads;
		if(close_roads) {
			roads <- road where (!each.close);
		} else {
			roads <- list(road);
		}
		
		road_geom <- union( roads accumulate(each.shape));
	    road_weights <- roads as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(roads);			

		recompute_path <- true;
		close_roads_prev <- close_roads;
	}

	reflex update_rates when: (nb_moto != nb_moto_prev) {
		nb_car <- 100 - nb_moto;
	}

	reflex update_people_car when: (nb_people_car != nb_people_car_prev) {
		ask (vehicle where (each.type = TYPE_CAR)) {nb_people <- nb_people_car;}
		nb_people_car_prev <- nb_people_car;
		nb_moto_prev <- -1;
	}

	reflex nb_agents when: ((nb_moto != nb_moto_prev) or (nb_people != nb_people_prev)) {
		
		int nb_people_moto_expected <- int(nb_people * nb_moto / 100);
		int nb_moto_expected <- int(nb_people_moto_expected / nb_people_moto);

		int nb_people_car_expected <- int(nb_people * nb_car / 100);
		int nb_car_expected <- int(nb_people_car_expected / nb_people_car);

		int delta_nb_moto <- (nb_moto_expected - dynamic_number_moto);
		int delta_nb_car <- (nb_car_expected - dynamic_number_car);
	
		if(delta_nb_moto < 0) {
			ask (-delta_nb_moto) among (vehicle where (each.type = TYPE_MOTORBIKE)){ do die;}
		} else {
			create vehicle number: delta_nb_moto {
				type <- TYPE_MOTORBIKE;
				nb_people <- nb_people_moto;	
				color <- color_vehicle[type];			
			}
		}
		
		if(delta_nb_car < 0) {
			ask (-delta_nb_car) among (vehicle where (each.type = TYPE_CAR)){ do die;}
		} else {
			create vehicle number: delta_nb_car {
				type <- TYPE_CAR;
				nb_people <- nb_people_car;	
				color <- color_vehicle[type];			
			}
		}		
		
		nb_people <- dynamic_number_people;
		nb_people_prev <- nb_people;
		
		nb_moto_prev <- nb_moto;		
	}

	reflex update_road_speed  {
		road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
		road_graph <- road_graph with_weights road_weights;
	}
}

species controller skills: [remoteGUI] {
	int selected_nb_people <- nb_people_prev;
	int selected_nb_moto <- nb_moto_prev;
	int selected_nb_people_car <- nb_people_car_prev;
	bool selected_close_roads <- close_roads_prev;
	int selected_display_mode <- display_mode;
	
	reflex update_nb_people when: selected_nb_people != nb_people {
		nb_people <- selected_nb_people;
	}
	
	reflex update_nb_moto when: selected_nb_moto != nb_moto {
		nb_moto <- selected_nb_moto;
	}
	
	reflex update_nb_people_car when: selected_nb_people_car != nb_people_car {
		nb_people_car <- selected_nb_people_car;
	}
	
	reflex update_roads when: selected_close_roads != close_roads {
		close_roads <- selected_close_roads;
	}
	
	reflex update_display_mode when: selected_display_mode != display_mode {
		display_mode <- selected_display_mode;
	}
}

species vehicle skills:[moving] {
	rgb color;
	string type;
	int nb_people;
	string carburant <- "essence";
	pollutant_cell current_cell;
	
	init {
		location <- any_location_in(road_geom);
	}
	
	point target <- nil ;
	float speed <- 50 #km / #h;

	reflex move when: target != nil {
		do goto target: target on: road_graph recompute_path: recompute_path move_weights: road_weights;
		if target = location {
			target <- nil ;
		}
	}
	
	reflex choose_target when: target = nil {
		target <- any(building).location;
	}
	
	float pollution_from_speed {
		float returnedValue <- -1.0;
		loop spee over: pollution_rate[carburant].keys {
			if(real_speed < spee) {
				returnedValue <- pollution_rate[carburant][spee];
				break;
			}
		}
		return (returnedValue != -1.0) ? returnedValue : pollution_rate[carburant][last(pollution_rate[carburant].keys)];
	}
	
	reflex emit_pollutant {
		current_cell <- any(pollutant_cell overlapping self);
		if current_cell != nil {
			float dist_traveled_prev_cycle <- real_speed * step;
			loop pollutant_type over:emission_factor[type].keys {
				current_cell.pollutant_val[pollutant_type] <- current_cell.pollutant_val[pollutant_type] + 
								dist_traveled_prev_cycle * emission_factor[type][pollutant_type]  #gram / #km * 10 ^ 5;
			}
		}
	}
	
	aspect default {
		draw ((type = TYPE_CAR) ? rectangle(20, 10) : rectangle(10, 4)) rotated_by(heading) color: color border: #black depth: 3;
	}
}

species road {
	string type;
	int oneway;
	bool close;

	float capacity <- 1 + shape.perimeter/30;
	list<vehicle> l_vec <- [] update: vehicle at_distance 1;
	

	int nb_vehicles <- 0 update: length(l_vec); //length(vehicle at_distance 1);
	
	int nb_person_moto <- 0 update: l_vec count(each.type = TYPE_MOTORBIKE); // length( (vehicle where (each.type = TYPE_MOTORBIKE)) at_distance 1);
	int nb_person_car <- 0 update: l_vec count(each.type = TYPE_CAR); //length( (vehicle where (each.type = TYPE_CAR)) at_distance 1);

	float speed_coeff <- 1.0 update: (nb_vehicles <= capacity) ? 1 : exp(-(nb_person_moto+4*nb_person_car)/capacity) min: 0.1;	
//	float speed_coeff <- 1.0 update:  exp(-nb_vehicles/capacity) min: 0.1;
	
	aspect default {
		if(close_roads and close) {
			draw shape+5 color: #orange end_arrow: 2;					
		} else if (display_mode = DISPLAY_MODE_TRAFFIC) {
			draw shape+1/(speed_coeff * 2) color: (speed_coeff=1.0)?#white : #red end_arrow: 10;		
		} else {
			draw shape color: #white;
		}
	}
	
	aspect lines {
		draw shape+10 color: (col[type]);
		draw shape color: (oneway = 0)? #blue : #red;
		draw circle(10) at_location first(shape.points) color: #red;
		draw circle(10) at_location last(shape.points) color: #red;		
	}	
}

species building {
	int height <- 20 + rnd(10);
	float pollutant_sum;
	
	aspect default {
		rgb building_color;
		if (pollutant_sum < 60) 	{
			building_color <- #green;
		} else if (pollutant_sum < 150) {
			building_color <- #orange;
		} else {
			building_color <- # red;
		}
		draw shape color: building_color border: #darkgrey depth: height;
	}
}

species pollutant_cell {
	list<pollutant_cell> neighbors;
	list<building> affected_buildings;
	
	map<string, float> pollutant_val;
	float pollutant_sum;
	
	init {
		pollutant_val <- ["PM"::0.0, "SO2"::0.0, "NOx"::0.0, "CO"::0.0, "benzene"::0.0];
	}

	reflex diffusion {
		pollutant_sum <- 0;
		loop pollutant_type over: pollutant_val.keys {
			ask neighbors {
				// TODO: for Benoit : without with_precision : nan
				self.pollutant_val[pollutant_type] <- self.pollutant_val[pollutant_type] + 0.05 * myself.pollutant_val[pollutant_type]
																						with_precision 6;
			}
			
			 pollutant_val[pollutant_type] <- pollutant_val[pollutant_type] * (1 - length(neighbors) * 0.05); 
			
			pollutant_sum <- (pollutant_sum + pollutant_val[pollutant_type]) with_precision 6;
		}
	}
	
	reflex decay when: mod(time, step) = 5 #s {
		loop pollutant_type over: pollutant_val.keys {
			pollutant_val[pollutant_type] <- pollutant_val[pollutant_type] * decrease_coeff;
		}
	}
	
	reflex spread_to_buildings when: length(affected_buildings) != 0{
		loop b over: affected_buildings {
			b.pollutant_sum <- pollutant_sum;
		}
	}
}

species dummy_road schedules: [] {
	bool highlight <- false;
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
	
	float movement_time <- 5 #s;
	
	aspect default {
		if (highlight) {
			point new_point;
			int lights_number;
			
			draw shape color: #grey end_arrow: 10;
	
			loop i from: 0 to: segments_number-1 {
				// Calculate rotation angle
				point u <- {segments_x[i] , segments_y[i]};
				point v <- {1, 0};
				float dot_prod <- u.x * v.x + u.y * v.y;
				float angle <- acos(dot_prod / (sqrt(u.x ^ 2 + u.y ^ 2) + sqrt(v.x ^ 2 + v.y ^ 2)));
				angle <- (u.x * -v.y + u.y * v.x > 0) ? angle : 360 - angle;
				
				lights_number <- 3;
			 	loop j from:0 to: lights_number-1{
	 				new_point <- {shape.points[i].x + segments_x[i] * (j + mod(time, movement_time)/movement_time)/lights_number, 
	 											shape.points[i].y + segments_y[i] * (j + mod(time, movement_time)/movement_time)/lights_number};
					draw rectangle(10, 4) at: new_point color: #yellow rotate: angle depth: 3;
				}
			}	
		}
	}
}

species lake {
	aspect default {
		draw shape color: #darkblue;
	}	
}

species progress_bar {
	float x;
	float y;
	float width;
	float height;
	
	float tracked_val;
	float tracked_val_max;
	
	string bar_name;
	string left_label;
	string right_label;
	
	geometry rect(float x, float y, float width, float height) {
		return polygon([{x, y}, {x + width, y}, {x + width, y + height}, {x, y + height}, {x, y}]);
	}
	
	action draw_bar(float tracked_val, float tracked_val_max, float x, float y, float width, float height, 
									string bar_name, string left_label, string right_label) {
		float length_filled<- width * tracked_val / tracked_val_max;
		float length_unfilled <- width - length_filled;
		
		draw rect(x, y, length_filled, height) color: #orange;
		draw rect(x + length_filled, y, length_unfilled, height) color: #white;
		
		draw(bar_name) at: {x - 200, y - 50} font: font(10);
		draw(left_label) at: {x - 20, y + 200} font: font(10);
		draw(right_label) at: {x + width - 20, y + 200} font: font(10);
	}
	
	aspect default {	
		do draw_bar(nb_people, 2000, 300, 1800, 500, 100, "Number of people: ", "0", "2000");
		do draw_bar(nb_moto, 100, 300, 2200, 500, 100, "Car/motorbike ratio: ", "0", "100");
	}
}

species line_graph_mean_pollution parent: line_graph {
	float current_val -> mean(pollutant_cell accumulate(each.pollutant_sum));
	float x <- 4000;
	float y <- 1600;
	float width <- 1300;
	float height <- 1000;
	
	string label <- "Mean pollution:";
	string unit <- "grams per cell";
}

species line_graph schedules: [] {
	list<float> val_list <- list_with(200, 0.0);
	float current_val;
	
	float x;
	float y;
	float width;
	float height;
	
	string label;
	string unit;
	
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}
	
	action draw_line(point a, point b, int thickness <- 1, rgb color <- #yellow) {
		draw line([a, b]) + thickness at: midpoint(a, b) color: color;
	}
	
	aspect default {
		remove index: 0 from: val_list;
		add item: current_val to: val_list at: length(val_list);
		
		point origin <- {x, y + height};
		
		// Draw axis
		do draw_line(origin, {x, y});
		do draw_line(origin, {x + width, y + height});
		
		float max_val <- max(val_list);
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] != 0) {
				float val_x_pos <- origin.x + width / 200 * i;
				float val_height <- val_list[i] / max_val * height;
				// Graph the value
				do draw_line({val_x_pos, origin.y}, {val_x_pos, origin.y - val_height}, 3);
			}
		}
		// Draw current value indicator
		float current_val_height <- current_val / max_val * height;
		do draw_line({x, y + height - current_val_height}, {x + width, y + height - current_val_height}, 2, #red);
		draw label + " " + string(round(current_val)) + " " + unit at: {x,  y + height - current_val_height - 50} font: font(8) color: #red;
	}
}

experiment exp {
	parameter "Number of people" var: nb_people <- 0 min: 0 max: 2000;
	parameter "Car/motorbike ratio" var: nb_moto <- 100 min: 0 max: 100;
	parameter "Number of people in each car" var: nb_people_car <- 2 min: 1 max: 7;
	parameter "Close roads" var: close_roads <- false category: "Urban planning";
	
	output {
		display d type: opengl background: #black {
			species lake;
			species building;
			species road;
			species vehicle;
			species dummy_road;
			species progress_bar;
			species line_graph_mean_pollution;
			
//			chart "pollution" background: #black axes: #white size: {0.3, 0.4} position: {0.7, 0.6} 
//					x_label: "temps" y_label:"pollution"  {
//				data "pollution max" value: (pollutant_cell max_of(each.pollution)) color: #red marker: false;				
//				data "pollution moyenne" value: mean(pollutant_cell accumulate(each.pollution)) color: #white marker: false;
//			}
			
//			chart "vitesse"  background: #black axes: #white size: {0.7,0.5} position: {1,0.5} 
//					x_label: "temps" y_label:"vitesse" {
//				data "vitesse max" value: (vehicle max_of(each.real_speed)) color: #red marker: false;				
//				data "vitesse moyenne" value: mean(vehicle accumulate(each.real_speed)) color: #white marker: false;				
//			}	
//			chart "vehicules" type: histogram background: #black axes: #white size: {0.7,0.5} position: {-1,-1} 
//					x_label: "temps" y_label:"nb véhicule" {
//
//				data TYPE_MOTORBIKE value: vehicle count(each.type = TYPE_MOTORBIKE);
//				data TYPE_CAR value: vehicle count(each.type = TYPE_CAR);
//				data TYPE_TRUCK value: vehicle count(each.type = TYPE_TRUCK);
//			}					
		}
		monitor "nb moto" value: dynamic_number_moto;
		monitor "nb voitures" value: dynamic_number_car;
		monitor "nb personnes" value: dynamic_number_people;
	}
}
