/***
* Name: staticvars
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model staticvars

global {
	// Simulation parameters
	int n_cars;
	int n_motorbikes;
	int road_scenario;
	int display_mode;
	// Save params' old values to detect value changes
	int n_cars_prev;
	int n_motorbikes_prev;
	int road_scenario_prev;
	int display_mode_prev;
	
	// Pollution diffusion
	float pollutant_decay_rate <-  0.999999; //0.99;
	float pollutant_diffusion <- 0.05;
	int grid_size <- 50;
	int grid_depth <- 10; // cubic meters
	
	graph road_network;
	
	// Buildings
	float min_height <- 0.1;
	float mean_height <- 1.3;
	string type_outArea <- "outArea";	
	
	// Daytime color blender
	bool day_time_color_blender <- true;
	map<date,rgb> day_time_colors <- [
		date("00 00 00", "HH mm ss")::#midnightblue,
		date("06 00 00","HH mm ss")::#deepskyblue,
		date("14 00 00","HH mm ss")::#gold,
		date("18 00 00","HH mm ss")::#darkorange,
		date("19 00 00","HH mm ss")::#blue
	];
	float day_time_color_blend_factor <- 0.1;


	// Pollution threshold 
	string THRESHOLD_HAZARDOUS <- " Hazardous";
	string THRESHOLD_VERY_UNHEALTY <- " Very Unhealthy";
	string THRESHOLD_UNHEALTHY <- " Unhealty";
	string THRESHOLD_UNHEALTHY_SENSITIVE <- " Unhealthy for \nSensitive Groups";
	string THRESHOLD_MODERATE <- " Moderate";
	string THRESHOLD_GOOD <- " Good";
	
	map<string,rgb> zone_colors <- [
		THRESHOLD_GOOD::rgb(104,225,66,255), 
		THRESHOLD_MODERATE::rgb(255,255,83,255), 
		THRESHOLD_UNHEALTHY_SENSITIVE::rgb(240,131,51,255),
		THRESHOLD_UNHEALTHY::rgb(218,56,50,255), 
		THRESHOLD_VERY_UNHEALTY::rgb(116,49,121,255),
		THRESHOLD_HAZARDOUS::rgb(66,18,39,255)
	];
	map<int,string> thresholds_pollution <- [
		0::THRESHOLD_GOOD,
		51::THRESHOLD_MODERATE,
		101::THRESHOLD_UNHEALTHY_SENSITIVE,
		151::THRESHOLD_UNHEALTHY,
		201::THRESHOLD_VERY_UNHEALTY,
		301::THRESHOLD_HAZARDOUS
	];

	
	// Color 
	string BUILDING_BASE <- "building_base";
	string BUILDING_OUTAREA <- "building_outArea";
	string DECO_BUILDING <- "deoc_building";
	string NATURAL <- "naturals";
	string DUMMY_ROAD <- "dummy_road";
	string CAR <- "car";
	string MOTOBYKE <- "motobyke";
	string CLOSED_ROAD <- "closed_road";
	string NOT_CONGESTED_ROAD <- "not congested roads";
	string CONGESTED_ROAD <- " congested_roads";
	string ROAD_POLLUTION_DISPLAY <- "road pollution";
	
	map<string,rgb> palet <- [
		BUILDING_BASE::#white,
		BUILDING_OUTAREA::rgb(60,60,60),
		DECO_BUILDING::rgb(60,60,60),
		NATURAL::rgb (165, 199, 238,255),
		DUMMY_ROAD::#grey,
		CAR:: #orange,
		MOTOBYKE:: #cyan,
		CLOSED_ROAD:: #darkblue,
		NOT_CONGESTED_ROAD:: #white,
		CONGESTED_ROAD::#red,
		ROAD_POLLUTION_DISPLAY:: #white
	];


	int get_pollution_threshold(float aqi) {
		int threshold <- 0;
		loop thr over: thresholds_pollution.keys {
			if(aqi > thr) {
				threshold <- thr;
			}
		}
		return threshold;
	}
	
	string get_pollution_state(float aqi) {
		return thresholds_pollution[get_pollution_threshold(aqi)];
	}
	
	rgb get_pollution_color(float aqi) {
		return zone_colors[thresholds_pollution[get_pollution_threshold(aqi)]];		
	}
}

