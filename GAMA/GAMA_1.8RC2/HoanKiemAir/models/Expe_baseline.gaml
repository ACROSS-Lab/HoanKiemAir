/***
* Name: Expebaseline
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Expebaseline

import "main (grid cells v1).gaml"
//import "main (road cells).gaml"

global {
	
	bool extra_visualization <- false;
	
	float pollutant_decay_rate <- 0.99;
	float pollutant_diffusion <- 0.05;

	int n_cars <- max_number_of_cars;
	int n_motorbikes <- max_number_of_motorbikes;
	int road_scenario <- 0 ;
	int display_mode <- 1 ;
	float refreshing_rate_plot init: 2#mn ;

	
	int SIZE_WINDOW <- 20;
	string result_folder <- "results/";
	list<float> max_on_interval <- [];
	
	reflex update_max_on_interval {
		if(length(max_on_interval) > SIZE_WINDOW) {
			remove index: 0 from: max_on_interval;
		} 	
		add building max_of(each.aqi) to: max_on_interval;	
	}
	
	reflex create_outputs {	
		if(cycle = 0) {
			save ["Mean AQI", "Stdv AQI", "Sum AQI", "Mean max on interval"]
				type: "csv" to: result_folder + "res"+world.seed+".csv" header: false rewrite: true;	
		}	
		save [building mean_of(each.aqi), standard_deviation(building collect(each.aqi)),(building sum_of(each.aqi)),mean(max_on_interval)]
			type: "csv" to: result_folder + "res"+world.seed+".csv" rewrite: false;
	}
}

experiment exp2 type: gui autorun: true {
	
//	parameter "Number of cars" var: n_cars <- max_number_of_cars min: 0 max: max_number_of_cars;
//	parameter "Number of motorbikes" var: n_motorbikes <- max_number_of_motorbikes min: 0 max: max_number_of_motorbikes;
//	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
//	parameter "Display mode" var: display_mode <- 1 min: 0 max: 1;
//	parameter "Refreshing time plot" var: refreshing_rate_plot init: 2#mn min:1#mn max: 1#h;
		

	output {
/* 		display main type: opengl background: #black {
			grid pollutant_cell lines: rgb(#grey, 0.8);
			species boundary;
			species road;
			species vehicle;
			species intersection;
			species building;

			species progress_bar;
			species param_indicator;
			species line_graph_aqi;
		}
		*
		*/
		
		display plot {
			chart "aqi" type: series {
//				data "Max AQI" value: building max_of(each.aqi);
				data "Mean AQI" value: building mean_of(each.aqi);
//				data "Median AQI" value: median(building collect(each.aqi));
				data "Std Dev" value: standard_deviation(building collect(each.aqi));
				data "SUM AQI /1000" value: (building sum_of(each.aqi)) / 1000;	
				data "Max_on_interval" value: mean(max_on_interval) color: #black;			
			}
		}
	}
}

/*
 * 	HEADLESS
 * ---
 * Every experiment below that point are only for headless exploration purpose
 */
experiment expSensi type: gui autorun: true {
	
	parameter "step" var: step init: 16#s among: [16#s, 30#s, 1#mn, 2#mn, 3#mn, 5#mn];
	parameter "Folder for CSV" var: result_folder init: "results/";
	
	output {}
}
experiment headless_ClosingRoads type: gui {
	parameter "Closing Roads" var: road_scenario init: 1 among: [1, 2];
	parameter "Folder for CSV" var: result_folder init: "results/";
}


experiment shortExplo_GridV1 type: gui {
	parameter "P Decay" var: pollutant_decay_rate init: 0.01 among: [0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.99];
	parameter "P Diffu" var: pollutant_diffusion init: 0.02 min: 0.02 max: 0.11 step: 0.02;
	parameter "Folder for CSV" var: result_folder init: "results/";
}