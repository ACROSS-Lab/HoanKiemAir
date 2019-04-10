
model NewModel

global {
	// Parameters
	bool close_lake <- true;
	bool prev_close_lake;
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

	int nb_moto <- 100;
	int nb_car <- 0;
	int nb_people <- 2000;

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

	shape_file roads_shape_file <- shape_file("../includes/roads_scenario1_normal.shp"); // shape_file("../includes/roads.shp");	
	shape_file buildings_shape_file <- shape_file("../includes/buildings.shp");
	shape_file lakes_shape_file <- shape_file("../includes/lake.shp");
	shape_file rivers_shape_file <- shape_file("../includes/lakes.shp");
//	shape_file traffic_show_shape_file <- shape_file("../includes/traffic_show.shp");
	shape_file node_generator_trafic0_shape_file <- shape_file("../includes/node_generator_trafic.shp");


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
	list<node_generator> sources <- [];
	list<node_generator> targets <- [];
	bool has_generators <- false;
		
	init {
		create road from: roads_shape_file with: [close::(string(read("close")) = "T") ? true : false] {
			if(oneway = 0){
				create road {
					shape <- polyline(reverse(myself.shape.points));
					type <- myself.type;
					close <- myself.close;
				}
			}
		}
		create building from: buildings_shape_file;	
		create lake from: lakes_shape_file;	
		create river from: rivers_shape_file;
		create node_generator from: node_generator_trafic0_shape_file with: [
			in::(string(read("IN")) = "T") ? true : false, 
			out::(string(read("OUT")) = "T") ? true : false
		];

		sources <- node_generator where(each.in);
		targets <- node_generator where(each.out);
		has_generators <- !empty(node_generator);

		road_geom <- union(road accumulate(each.shape));
				
		active_cells <- pollutant_grid where (!empty(road overlapping each));
		ask active_cells { active <- true; }
		
      	//Weights of the road
      	road_weights <- road as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(road);
		      	
		do update_close_roads;		      	
		do update_and_create_agents;
	}

	reflex update_compute_path when: recompute_path {
		recompute_path <- false;		
	}


	action update_close_roads {		
		list<road> roads;
		if(close_lake) {
			roads <- road where (!each.close);
		} else {
			roads <- list(road);
		}
		
		road_geom <- union( roads accumulate(each.shape));		
		ask pollutant_grid {active <- road_geom overlaps self;}
		
	    road_weights <- roads as_map (each::each.shape.perimeter);
		road_graph <- as_edge_graph(roads);			

		recompute_path <- true;
		prev_close_lake <- close_lake;		
	}

	reflex close_roads when:(close_lake != prev_close_lake) {
		do update_close_roads;
	}
	

	reflex update_rates when: (nb_moto != nb_moto_prev) {
		nb_car <- 100 - nb_moto;
	}

	reflex update_people_car when: (nb_people_car != nb_people_car_prev) {
		ask (vehicle where (each.type = TYPE_CAR)) {nb_people <- nb_people_car;}
		nb_people_car_prev <- nb_people_car;
		nb_moto_prev <- -1;
	}

	action update_and_create_agents {
		int nb_people_moto_expected <- int(nb_people * nb_moto / 100);
		int nb_moto_expected <- int(nb_people_moto_expected / nb_people_moto);

		int nb_people_car_expected <- int(nb_people * nb_car / 100);
		int nb_car_expected <- int(nb_people_car_expected / nb_people_car);

		int delta_nb_moto <- (nb_moto_expected - dynamic_number_moto);
		int delta_nb_car <- (nb_car_expected - dynamic_number_car);
	
/* 		write sample(nb_people);
		write sample(nb_moto);
		write sample(nb_people_moto_expected);
		write sample(nb_moto_expected);
		write sample(nb_people_car_expected);
		write sample(nb_car_expected);
		write sample(delta_nb_moto);
		write sample(delta_nb_car);	
*/
		
		if(delta_nb_moto < 0) {
			ask (-delta_nb_moto) among (vehicle where (each.type = TYPE_MOTORBIKE)){ do die;}
		} else {
//			create vehicle number: delta_nb_moto {
			create vehicle number: min([delta_nb_moto,10]) {				
				type <- TYPE_MOTORBIKE;
				nb_people <- nb_people_moto;	
				color <- color_vehicle[type];	
				
				location <- (has_generators)? any(sources).location : any_location_in(road_geom);
//				target <- (has_generators)? any(targets).location : any_location_in(road_geom);				
//				target <- (has_generators)? any(targets).location : any_location_in(road_geom);				
			}
		}
		
		if(delta_nb_car < 0) {
			ask (-delta_nb_car) among (vehicle where (each.type = TYPE_CAR)){ do die;}
		} else {			
//			create vehicle number: delta_nb_car {
			create vehicle number: min([delta_nb_car,10]) {
				type <- TYPE_CAR;
				nb_people <- nb_people_car;	
				color <- color_vehicle[type];
				location <- any_location_in(road_geom);

				location <- (has_generators)? any(sources).location : any_location_in(road_geom);
//				target <- (has_generators)? any(targets).location : any_location_in(road_geom);							
			}
		}		
		
//		nb_people <- dynamic_number_people;
//		nb_people_prev <- nb_people;
		nb_people_prev <- dynamic_number_people;
		
		nb_moto_prev <- nb_moto;			
	}

	reflex nb_agents when: ((nb_moto != nb_moto_prev) or (nb_people != nb_people_prev) or (nb_people != dynamic_number_people)) {
		do update_and_create_agents;	
	}

	reflex update_road_speed  {
		road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
		road_graph <- road_graph with_weights road_weights;
	}
}

species vehicle skills:[moving] {
	rgb color  ;
	string type  ;
	int nb_people;
	string carburant <- "essence";
	
	point target <- nil ;
	float speed <- 40 #m /#s;
	bool target_in_building <- true;
		
	init {	}

	reflex move when: target != nil {
		do goto target: target on: road_graph recompute_path: recompute_path move_weights: road_weights;
		if target = location {
			target <- nil ;
		}
	}
	
	reflex choose_target when: target = nil {
//		target <- any(building).location;
		target <- any(targets).location;
		
		if(has_generators) {
			target <- (target_in_building)? any(building).location : any(targets).location;
		} else {
			target <- any(building).location;
		}
		//				target <- (has_generators)? any(targets).location : any_location_in(road_geom);							
		target_in_building <- !target_in_building ;
		
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
//		draw ((type = TYPE_CAR)?rectangle(10,5):rectangle(5,2)) rotated_by(heading) color: color border: #black depth:3;
		draw circle(6) color: #white border: #black depth:3;
		
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

	float capacity <- 1 + shape.perimeter/30;
	list<vehicle> l_vec <- [] update: vehicle at_distance 1;
	

	int nb_vehicles <- 0 update: length(l_vec); //length(vehicle at_distance 1);
	
	int nb_person_moto <- 0 update: l_vec count(each.type = TYPE_MOTORBIKE); // length( (vehicle where (each.type = TYPE_MOTORBIKE)) at_distance 1);
	int nb_person_car <- 0 update: l_vec count(each.type = TYPE_CAR); //length( (vehicle where (each.type = TYPE_CAR)) at_distance 1);

	float speed_coeff <- 1.0 update: (nb_vehicles <= capacity) ? 1 : exp(-(nb_person_moto+4*nb_person_car)/capacity) min: 0.1;	
//	float speed_coeff <- 1.0 update:  exp(-nb_vehicles/capacity) min: 0.1;
	
	aspect default {
		draw shape color: #white;
	}
	
	aspect traffic {
		if(close_lake and close) {
			draw shape+5 color: #orange end_arrow: 2;					
		} else {
			draw shape+1/speed_coeff color: (speed_coeff=1.0)?#white : #red end_arrow: 10;		
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
	aspect default {
		draw shape color: #grey border: #darkgrey depth: height;
	}
}

species node_generator {
	bool in;
	bool out;
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


experiment expScenario {
//	parameter "Nombre de personne" var: nb_people <- 0 min: 0 max: 2000;
//	parameter "voiture <-> moto" var: nb_moto <- 100 min: 0 max: 100;
//	parameter "Nombre de personne par voiture" var: nb_people_car <- 2 min: 1 max: 7;
//	parameter "Fermer bord lac" var: close_lake <- true category: "Urban planning";
	

	shape_file roads_scenario0_noClose0_shape_file <- shape_file("../includes/roads_scenario0_noClose.shp");
//	shape_file roads_scenario1_normal0_shape_file <- shape_file("../includes/roads_scenario1_normal.shp");
	shape_file roads_scenario2_noMusee0_shape_file <- shape_file("../includes/roads_scenario2_noMusee.shp");
	shape_file roads_scenario3_avecMusee0_shape_file <- shape_file("../includes/roads_scenario3_avecMusee.shp");
	
	init {
		create simulation with: [roads_shape_file::roads_scenario0_noClose0_shape_file];
		create simulation with: [roads_shape_file::roads_scenario2_noMusee0_shape_file];
		create simulation with: [roads_shape_file::roads_scenario3_avecMusee0_shape_file];		
	}
	
	output {		
		display d type: java2D background: #black {
			species lake;
			species river;
			species building;
			species road aspect: traffic;
			species vehicle;
			grid pollutant_grid elevation:pollution/10<0?0.0:pollution/10 transparency: 0.4 triangulation:true ;

//			chart "pollution" background: #black axes: #white size: {0.7,0.5} position: {1,0} 
//					x_label: "temps" y_label:"pollution"{
//				data "pollution max" value: (pollutant_grid max_of(each.pollution)) color: #red marker: false;				
//				data "pollution moyenne" value: mean(pollutant_grid accumulate(each.pollution)) color: #white marker: false;
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
//		monitor "nb moto" value: dynamic_number_moto;
//		monitor "nb voitures" value: dynamic_number_car;
//		monitor "nb personnes" value: dynamic_number_people;
	}
}

experiment exp {
	parameter "Nombre de personne" var: nb_people <- 0 min: 0 max: 5000;
	parameter "voiture <-> moto" var: nb_moto <- 100 min: 0 max: 100;
	parameter "Nombre de personne par voiture" var: nb_people_car <- 2 min: 1 max: 7;
	parameter "Fermer bord lac" var: close_lake <- false category: "Urban planning";

	output {
		display d type: opengl background: #black {
			species lake;
			species river;
			species building;
			species road aspect: traffic;
			species vehicle;
			grid pollutant_grid elevation:pollution/10<0?0.0:pollution/10 transparency: 0.4 triangulation:true ;

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
	}
}