/***
* Name: Expebaseline
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ExpebaselineGrid
 
import "main (grid cells).gaml" 
 
global {
	string exp_name <- "";
		
	float pollutant_decay_rate <- 0.99;
	float pollutant_diffusion <- 0.05;

	float nb_vehicle_multi <- 1.0;
	int n_cars <- int(max_number_of_cars * nb_vehicle_multi);
	int n_motorbikes <- int(max_number_of_motorbikes * nb_vehicle_multi);
	int road_scenario <- 0 ;
	bool day_time_traffic <- false;
	float step   <- 16#s;
	
	string result_folder <- "results/";
 
	int SIZE_WINDOW <- 20;
	list<float> max_on_interval <- [];
	list<float> min_on_interval <- [];

	init {
		result_folder <- result_folder + exp_name + "/";
		
		if(exp_name = "exp2") {
			result_folder <- result_folder + step + "/";			
		} else if  (exp_name = "exp3") {
			result_folder <- result_folder + "Decay-"  + (pollutant_decay_rate) + "--" + "Diffusion-" + (pollutant_diffusion) + "/";
		} else if(exp_name = "exp4")  {
			result_folder <- result_folder + "MultiVehicle-" + nb_vehicle_multi  + "/";
		} else if(exp_name  = "exp5") {
			result_folder <- result_folder + "daytime-" + day_time_traffic + "/";
		} else if(exp_name = "exp61") {
			result_folder <- result_folder + "daytime-true--roadScenario-" + road_scenario + "/";
		} else if(exp_name = "exp62") {
			result_folder <- result_folder + "daytime-false--roadScenario-" + road_scenario + "/";
		} else if(exp_name = "exp63") {
			result_folder <- result_folder + "daytime-true--objective_scenario-" + objective_scenario + "/";
		} else if(exp_name = "exp64") {
			result_folder <- result_folder + "daytime-false--objective_scenario-" + objective_scenario + "/";	
		}	
	}

	
	int modif_scenario_day <- 1;
	int objective_scenario  <- 0;
	
	reflex update_scenario_daytime when: day_time_traffic and (modif_scenario_day != current_date.day) and ((current_date.day - starting_date.day) mod 3 = 0) {
		modif_scenario_day <- current_date.day;
		if(cycle >  0) {
			if(road_scenario = 0) {
				road_scenario <- objective_scenario;
			} else {
				road_scenario <- 0;
			}
		}
	}
	
	reflex update_scenario_maxTraffic when: not(day_time_traffic) and (cycle mod 800 = 0) {
		if(cycle >  0) {
			if(road_scenario = 0) {
				road_scenario <- objective_scenario;
			} else {
				road_scenario <- 0;
			}
		}
	}	
	
	reflex update_max_on_interval {
		if(length(max_on_interval) > SIZE_WINDOW) {
			remove index: 0 from: max_on_interval;
		} 	
		add building max_of(each.aqi) to: max_on_interval;	
	}

	reflex update_min_on_interval {
		if(length(min_on_interval) > SIZE_WINDOW) {
			remove index: 0 from: min_on_interval;
		} 	
		add building min_of(each.aqi) to: min_on_interval;	
	}	

	reflex create_outputs {	
		if(cycle = 0) {
			save ["Mean AQI", "Stdv AQI", "Sum AQI", "Mean max on interval","Mean min on interval"]
				type: "csv" to: result_folder + "res"+world.seed+".csv" header: false rewrite: true;	
		}	
		save [building mean_of(each.aqi), standard_deviation(building collect(each.aqi)),(building sum_of(each.aqi)),mean(max_on_interval),mean(min_on_interval)]
			type: "csv" to: result_folder + "res"+world.seed+".csv" rewrite: false;
	}
}

// Small  number  of replications (4 or 8) with stop condition = 10.000 steps
// Replications: 4 or 8
// Stop  condition: (cycle > 10000)
experiment exp11 type: gui {
	parameter "Experiment name" var: exp_name init: "exp11";
}

// Huge  number  of replications (100) with stop condition = 3000 steps
// Replications: 100
// Stop  condition: (cycle > 3000)
experiment exp12 type: gui {
	parameter  "Experiment name" var: exp_name init: "exp12";
}

// Experiment on  step duration
// Parameters:
//   - step  among  [16#s, 30#s, 1#mn, 2#mn, 3#mn, 5#mn]
// Replications: 10 to 20
// Stop condition: (cycle > 1500)
experiment exp2 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp2";
	
	parameter "step" var: step init: 16#s ; // among: [16#s, 30#s, 1#mn, 2#mn, 3#mn, 5#mn];
}

// Experiment on pollution model
// Parameters:
//   - diffusion model: grid / road 
//   - pollutant_decay_rate among [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99]
//   - pollutant_diffusion  among: [0.02,0.04,0.06,0.08,0.10,0.12]
// Replications: 10 to 20
// Stop condition: (cycle > 1500)
//
// Important  :  mesurer le temps de calcul
experiment exp3 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp3";
	
	parameter "P Decay" var: pollutant_decay_rate init: 0.01; // among: [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99];
	parameter "P Diffu" var: pollutant_diffusion init: 0.02 ; //among: [0.02,0.04,0.06,0.08,0.10,0.12];
}

// Experiment on nb vehicles
// Parameters:
//   - nb_vehicle_multi among: [0.5, 1.0, 1.5, 2.0, 5.0];
// Replications: 10 to 20
// Stop condition: (cycle > 1500)
experiment exp4 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp4";
	
	parameter "Vehicle multiply" var: nb_vehicle_multi init: 0.5; // among: [0.5, 1.0, 1.5, 2.0, 5.0];
}

// Experiment on traffic scenario
// Parameters:
//   - day_time_traffic among: true;
//   - step  = 5#min
// Replications: 10 to 20
// Stop condition: (cycle > 3000)
experiment exp5 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp5";
	
	parameter "Day time traffic?" var: day_time_traffic init: true; 
	parameter "Time step" var:step init: 5#mn;	
}

// Experiment on pedestrian area scenario (en mode daytime)
// Parameters:
//   - road_scenario among: [0, 1, 2];
//   - day_time_traffic : true
//   - step : 5#min
// Replications: 10 to 20
// Stop condition: (cycle > 3000)
experiment exp61 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp61";
	
	parameter "Closing Roads" var: road_scenario init: 0 among: [0, 1, 2];
	parameter "Day time traffic?" var: day_time_traffic init: true;
	parameter "Time step" var:step init: 5#mn;
	parameter "Starting time" var:starting_date_string init:"05 00 00";
}

// Experiment on pedestrian area scenario  (en mode max traffic)
// Parameters:
//   - road_scenario among: [0, 1, 2];
//   - day_time_traffic : false
//   - step : 16#s
// Replications: 10 to 20
// Stop condition: (cycle > 3000)
experiment exp62 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp62";
	
	parameter "Closing Roads" var: road_scenario init: 0 among: [0, 1, 2];
	parameter "Day time traffic?" var: day_time_traffic init: false;
	parameter "Time step" var:step init: 16#s;
}

// Experiment on change  of pedestrian area scenario  (en mode daytime)
// Parameters:
//   - objective_scenario among: [1, 2];
//   - initial objective_scenario: 0
//   - day_time_traffic : true
//   - step : 5#mn
// Replications: 10
// Stop condition: (cycle > 3000)
experiment exp63 type: gui {
	parameter  "Experiment name" var: exp_name init: "exp63";
	
	parameter "Daytime traffic" var: day_time_traffic init:true;
	parameter "Closing Roads" var: road_scenario init: 0;
	parameter "Objective scenario" var: objective_scenario <- 1 among: [1,2];
	
	parameter "Time step" var:step init:5#mn;
	parameter "Starting time" var:starting_date_string init:"05 00 00";
}

experiment exp63_batch type: batch until: (cycle > 3000) repeat: 10 {
	parameter  "Experiment name" var: exp_name init: "exp63";
	
	parameter "Daytime traffic" var: day_time_traffic init:true;
	parameter "Closing Roads" var: road_scenario init: 0;
	parameter "Objective scenario" var: objective_scenario <- 1 among: [1,2];
	
	parameter "Time step" var:step init:5#mn;
	parameter "Starting time" var:starting_date_string init:"05 00 00";
}

// Experiment on change  of pedestrian area scenario  (en mode max traffic)
// Parameters:
//   - objective_scenario among: [1, 2];
//   - initial objective_scenario: 0
//   - day_time_traffic : falsse
//   - step : 5#mn
// Replications: 10
// Stop condition: (cycle > 3000)
experiment exp64 type: gui {
	parameter  "Experiment name" var: exp_name init: "exp64";
	
	parameter "Daytime traffic" var: day_time_traffic init: false;
	parameter "Closing Roads" var: road_scenario init: 0;
	parameter "Objective scenario" var: objective_scenario <- 1 ;
	
	parameter "Time step" var:step init: 16#s;
	parameter "Starting time" var:starting_date_string init:"05 00 00";
}

experiment exp64_batch type: batch until: (cycle > 3000) repeat: 10 {
	parameter  "Experiment name" var: exp_name init: "exp64";
	
	parameter "Daytime traffic" var: day_time_traffic init: false;
	parameter "Closing Roads" var: road_scenario init: 0;
	parameter "Objective scenario" var: objective_scenario <- 1 among: [1,2];
	
	parameter "Time step" var:step init: 16#s;
	parameter "Starting time" var:starting_date_string init:"05 00 00";
}
