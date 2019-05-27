model NewModel

global {
	bool connect_to_mqtt_server <- false;
	
	int DISPLAY_MODE_TRAFFIC <- 0 const: true;
	int DISPLAY_MODE_POLLUTION <- 1 const: true;
	int display_mode <- DISPLAY_MODE_TRAFFIC;
	int road_scenario <- 0;
	int road_scenario_prev <- road_scenario;
	float pollution_transparency;
	
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
	int dynamic_number_people_moto -> {sum( (vehicle where (each.type = TYPE_MOTORBIKE)) accumulate (each.nb_people))};
	int dynamic_number_people_car -> {sum( (vehicle where (each.type = TYPE_CAR)) accumulate (each.nb_people))};
	
	// Pollution en CO2
	map<string,map<int,float>> pollution_rate <- [
		"essence"::[10::98.19,20::69.17,30::56.32,40::49.3,50::45.29],
		"diesel"::[10::201.74,20::152,30::127.82,40::114.29,50::106.48]
	];

	float decrease_coeff <- 0.5 ;

	shape_file roads_shape_file <- shape_file("../includes/roads_scenario1_normal.shp");
	shape_file buildings_shape_file <- shape_file("../includes/buildings.shp");
	shape_file lakes_shape_file <- shape_file("../includes/lake.shp");
	shape_file rivers_shape_file <- shape_file("../includes/lakes.shp");

	geometry shape <- envelope(roads_shape_file);

	map<string,rgb> col <- map(['footway'::#green,'residential'::#blue,'primary'::#orange,
								'secondary'::#yellow,'tertiary'::#indigo,'primary_link'::#black,
								'unclassified'::#black,'service'::#black,'living_street'::#black,
								'path'::#black,'secondary_link'::#black,'trunk'::#black,
								'pedestrian'::#darkgreen,'steps'::#black]);
	
	graph road_graph;
	map<road,float> road_weights;
	
	list<pollutant_grid> active_cells;
	
	geometry road_geom;
	

		
	init {
		do create_roads("../includes/roads_scenario0_noClose.shp");
		road_geom <- union(road accumulate (each.shape));
		//Weights of the road
      	road_weights <- road as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(road);
		
		active_cells <- pollutant_grid where (!empty(road overlapping each));
		ask active_cells { active <- true; }
		
		create building from: buildings_shape_file;	
		create lake from: lakes_shape_file;	
		create river from: rivers_shape_file;
		  
		if (connect_to_mqtt_server) {
			create controller number: 1 {
				do connect to: "localhost";
				
				do listen with_name: "nb_people" store_to: "selected_nb_people";
				do listen with_name: "nb_moto" store_to: "selected_nb_moto";
				do listen with_name: "nb_people_car" store_to: "selected_nb_people_car";
				do listen with_name: "close_roads" store_to: "selected_close_roads";
				do listen with_name: "display_mode" store_to: "selected_display_mode";
				do listen with_name: "road_scenario" store_to: "selected_road_scenario";
			}
		}
	}
	
	action create_roads(string file_name) {
		shape_file roads_file <-  shape_file(file_name);
		create road from:  roads_file with: [close_string::read("close")] {
			close <- (close_string = "T") ? true : false;
			if(oneway = 0) {
				create road {
					shape <- polyline(reverse(myself.shape.points));
					type <- myself.type;
					close <- myself.close;
				}
			}
		}
	} 
	reflex update_compute_path when: recompute_path {
		recompute_path <- false;		
	}

	reflex update_roads when: close_roads != close_roads_prev or (close_roads = true and road_scenario != road_scenario_prev) {
		ask list(road) {
				do die;
		}
		
		string file_name;
		list<road> roads;
		if (!close_roads) {
			file_name <- "../includes/roads_scenario0_noClose.shp";
			do create_roads(file_name);
			roads <- list(road);
		} else {
			switch (road_scenario) {
				match 0 {
					file_name <- "../includes/roads_scenario1_normal.shp";
					break;
				}
				match 1 {
					file_name <- "../includes/roads_scenario2_noMusee.shp";
					break;
				}
				match 2 {
					file_name <- "../includes/roads_scenario3_avecMusee.shp";
					break;
				}
			}
			road_scenario_prev <- road_scenario;
			do create_roads(file_name);
			write file_name;
			roads <- road where (!each.close);
		}
		road_geom <- union(roads accumulate (each.shape));
		//Weights of the road
      	road_weights <- roads as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(roads);
		recompute_path <- true;
			
		ask pollutant_grid {active <- road_geom overlaps self;}
		ask vehicle {location <- any_location_in(road_geom);}
		
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
	
	reflex update_pollution_display {
		if (display_mode = DISPLAY_MODE_POLLUTION) {
			pollution_transparency <- 0.4;
		} else {
			pollution_transparency <- 1.0;
		}
	}
}

species controller skills: [remoteGUI] {
	int selected_nb_people <- nb_people_prev;
	int selected_nb_moto <- nb_moto_prev;
	int selected_nb_people_car <- nb_people_car_prev;
	bool selected_close_roads <- close_roads_prev;
	int selected_display_mode <- display_mode;
	int selected_road_scenario <- road_scenario_prev;
	
	reflex update_nb_people when: selected_nb_people != nb_people_prev {
		nb_people <- selected_nb_people;
	}
	
	reflex update_nb_moto when: selected_nb_moto != nb_moto_prev {
		nb_moto <- selected_nb_moto;
	}
	
	reflex update_nb_people_car when: selected_nb_people_car != nb_people_car_prev {
		nb_people_car <- selected_nb_people_car;
	}
	
	reflex update_roads when: selected_close_roads != close_roads_prev {
		close_roads <- selected_close_roads;
	}
	
	reflex update_display_mode when: selected_display_mode != display_mode {
		display_mode <- selected_display_mode;
	}
	
	reflex update_road_scenario when: selected_road_scenario != road_scenario_prev {
		road_scenario <- selected_road_scenario;
	}
}

species vehicle skills:[moving] {
	rgb color  ;
	string type  ;
	int nb_people;
	string carburant <- "essence";
	
	init {
		location <- any_location_in(road_geom);
	}
	
	point target <- nil ;
	float speed <- 40 #m /#s;

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
	
	float get_pollution {
		return pollution_from_speed() * coeff_vehicle[type];
	}
	
	aspect default {
		draw ((type = TYPE_CAR)?rectangle(10,5):rectangle(5,2)) rotated_by(heading) color: color border: #black depth:3;
	}
}

species lake {
	aspect default {
		draw shape color: #darkblue;
	}	
}

species river {
	aspect default {
		draw shape color: #darkblue;
	}	
}

species road {
	string type;
	int oneway;
	bool close;
	string close_string;

	float capacity <- 1 + shape.perimeter/30;
	list<vehicle> l_vec <- [] update: vehicle at_distance 1;
	

	int nb_vehicles <- 0 update: length(l_vec); //length(vehicle at_distance 1);
	
	int nb_person_moto <- 0 update: l_vec count(each.type = TYPE_MOTORBIKE); // length( (vehicle where (each.type = TYPE_MOTORBIKE)) at_distance 1);
	int nb_person_car <- 0 update: l_vec count(each.type = TYPE_CAR); //length( (vehicle where (each.type = TYPE_CAR)) at_distance 1);

	float speed_coeff <- 1.0 update: (nb_vehicles <= capacity) ? 1 : exp(-(nb_person_moto+4*nb_person_car)/capacity) min: 0.1;	
//	float speed_coeff <- 1.0 update:  exp(-nb_vehicles/capacity) min: 0.1;
	
	aspect default {
		if(close_roads and close) {
			draw shape+5 color: #orange;					
		} else if (display_mode = DISPLAY_MODE_TRAFFIC) {
			draw shape+1/speed_coeff color: (speed_coeff=1.0)?#white : #red;		
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
	float pollution_rate;
	list<pollutant_grid> pollution_cells;
	rgb color;
	
	init {
		pollution_rate <- 0.0;
		pollution_cells <- pollutant_grid overlapping self;
	}
	
	reflex update_pollution {
		pollution_rate <- sum(pollution_cells accumulate each.pollution);
		if (pollution_rate < 30) 	{
			color <- #green;
		} else if (pollution_rate < 60) {
			color <- #orange;
		} else {
			color <- # red;
		}
	}
	
	aspect default {
		draw shape color: color border: #darkgrey depth: height;
	}
}

grid pollutant_grid height: 50 width: 50 neighbors: 8/*schedules: active_cells*/ {
	rgb color <- #black;
	bool active <- false;
	
	float pollution;

	reflex pollution_increase when: active {
		list<vehicle> people_on_cell <- vehicle overlapping self;
		pollution <- pollution + sum(people_on_cell accumulate (each.get_pollution()));		
	}

	reflex diffusion {
		ask neighbors {
			pollution <- pollution + 0.05 * myself.pollution;
		}
		pollution <- pollution * (1 - 8 * 0.05 );
	}

	reflex update {
		pollution <- pollution * decrease_coeff;		
		color <- rgb(255*pollution/1000,0,0);
	}
}

experiment exp {
	parameter "Number of people" var: nb_people <- 0 min: 0 max: 2000;
	parameter "Car/motorbike ratio" var: nb_moto <- 100 min: 0 max: 100;
	parameter "Number of people in each car" var: nb_people_car <- 2 min: 1 max: 7;
	parameter "Close roads" var: close_roads <- false category: "Urban planning";
	parameter "Display mode" var: display_mode <- 0 min: 0 max: 1;
	parameter "Road scenario" var: road_scenario min: 0 max: 2;
	
	output {
		display d type: opengl background: #black {
			species lake;
			species river;
			species building;
			species road;
			species vehicle;
			grid pollutant_grid elevation:pollution/10<0?0.0:pollution/10 transparency: pollution_transparency triangulation:true;

			chart "pollution" background: #black axes: #white size: {0.7,0.5} position: {1,0} 
					x_label: "temps" y_label:"pollution"{
				data "pollution max" value: (pollutant_grid max_of(each.pollution)) color: #red marker: false;				
				data "pollution moyenne" value: mean(pollutant_grid accumulate(each.pollution)) color: #white marker: false;
			}	
			chart "vitesse"  background: #black axes: #white size: {0.7,0.5} position: {1,0.5} 
					x_label: "temps" y_label:"vitesse" {
				data "vitesse max" value: (vehicle max_of(each.real_speed)) color: #red marker: false;				
				data "vitesse moyenne" value: mean(vehicle accumulate(each.real_speed)) color: #white marker: false;				
			}	
			chart "vehicules" type: histogram background: #black axes: #white size: {0.7,0.5} position: {-1,-1} 
					x_label: "temps" y_label:"nb véhicule" {

				data TYPE_MOTORBIKE value: vehicle count(each.type = TYPE_MOTORBIKE);
				data TYPE_CAR value: vehicle count(each.type = TYPE_CAR);
				data TYPE_TRUCK value: vehicle count(each.type = TYPE_TRUCK);
			}					
		}
		monitor "nb moto" value: dynamic_number_moto;
		monitor "nb voitures" value: dynamic_number_car;
		monitor "nb personnes" value: dynamic_number_people;
		monitor "display_mode" value: display_mode;
	}
}
