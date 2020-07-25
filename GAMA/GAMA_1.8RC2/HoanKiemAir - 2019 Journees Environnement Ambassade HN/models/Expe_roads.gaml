/***
* Name: Expebaseline
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ExpebaselineRoads

import "main (road cells).gaml"

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
		result_folder <- result_folder + exp_name + "/" + "/roads/";
		
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



// Experiment on pollution model
// Parameters:
//   - diffusion model: road 
//   - pollutant_decay_rate among [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99]
//   - pollutant_diffusion  among: [0.02,0.04,0.06,0.08,0.10,0.12]
// Replications: 10 to 20
// Stop condition: (cycle > 1500)
//
// Important  :  mesurer le temps de calcul
experiment exp3 type: gui { 
	parameter  "Experiment name" var: exp_name init: "exp3";
	parameter "Benchmark" var: benchmark <- false;
	
	parameter "P Decay" var: pollutant_decay_rate init: 0.01; // among: [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99];
	parameter "P Diffu" var: pollutant_diffusion init: 0.06 ; //among: [0.02,0.04,0.06,0.08,0.10,0.12];
}

experiment exp3_batch type: batch until: (cycle > 1500)  repeat: 8 { 
	parameter  "Experiment name" var: exp_name init: "exp3";
	parameter "Benchmark" var: benchmark <- false;
	
	parameter "P Decay" var: pollutant_decay_rate init: 0.99; // among: [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99];
	parameter "P Diffu" var: pollutant_diffusion init: 0.06 ; //among: [0.02,0.04,0.06,0.08,0.10,0.12]
}