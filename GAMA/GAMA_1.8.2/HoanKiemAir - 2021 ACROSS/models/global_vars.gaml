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
	
	// Parameter of visualization to avoid z fighting
	float Z_LVL1 <- 0.1;
	float Z_LVL2 <- 0.2;
	float Z_LVL3 <- 0.3;
	
	
	// Pollution diffusion
	float pollutant_decay_rate <-  0.99; //0.99;
	float pollutant_diffusion <- 0.05;
	int grid_size <- 50;
	int grid_depth <- 10; // cubic meters
	
	graph road_network;
	
	// Buildings
	float min_height <- 0.1;
	float mean_height <- 1.3;
	string type_outArea <- "outArea";	
	
	// Daytime management
	string starting_date_string <- "00 00 00";
	float refreshing_rate_plot <- 1#mn;
	
	// Daytime color blender
	bool day_time_color_blender <- false;
	map<date,rgb> day_time_colors <- [
		date("00 00 00", "HH mm ss")::#midnightblue,
		date("06 00 00","HH mm ss")::#deepskyblue,
		date("14 00 00","HH mm ss")::#gold,
		date("18 00 00","HH mm ss")::#darkorange,
		date("19 00 00","HH mm ss")::#blue
	];
	float day_time_color_blend_factor <- 0.2;
	
	// Daytime traffic demand
	int max_number_of_cars <- 500 const:true;
	int max_number_of_motorbikes <- 1000 const:true;
	bool day_time_traffic <- false;
	map<date,float> daytime_trafic_peak <- [
		date("01 00 00", "HH mm ss")::0.1,
		date("04 00 00", "HH mm ss")::0.1,
		date("07 00 00", "HH mm ss")::1.0,
		date("08 00 00", "HH mm ss")::1.0,
		date("09 00 00", "HH mm ss")::0.6,
		date("10 00 00", "HH mm ss")::0.5,
		date("11 30 00", "HH mm ss")::1.0,
		date("13 00 00", "HH mm ss")::0.8,
		date("16 00 00", "HH mm ss")::0.4,
		date("17 00 00", "HH mm ss")::1.0,
		date("18 00 00", "HH mm ss")::1.0,
		date("19 00 00", "HH mm ss")::0.85,
		date("20 00 00", "HH mm ss")::0.75,
		date("22 30 00", "HH mm ss")::0.6,
		date("23 30 00", "HH mm ss")::0.5
	];


	// Pollution threshold 
	string THRESHOLD_HAZARDOUS <- " Hazardous";
	string THRESHOLD_VERY_UNHEALTY <- " Very Unhealthy";
	string THRESHOLD_UNHEALTHY <- " Unhealty";
	string THRESHOLD_UNHEALTHY_SENSITIVE <- " Unhealthy for \nSensitive Groups";
	string THRESHOLD_MODERATE <- " Moderate";
	string THRESHOLD_GOOD <- " Good";
	
	map<string,rgb> zone_colors <- [
		THRESHOLD_GOOD:: #green, //rgb(104,225,66,255), 
		THRESHOLD_MODERATE:: #yellow, //rgb(255,255,83,255), 
		THRESHOLD_UNHEALTHY_SENSITIVE::#orange,//rgb(240,131,51,255),
		THRESHOLD_UNHEALTHY::#red, //rgb(218,56,50,255), 
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
	string CLOSED_ROAD_TRAFFIC <- "closed_road_traffic";
	string CLOSED_ROAD_POLLUTION <- "closed_road_pollution";
	string NOT_CONGESTED_ROAD <- "not congested roads";
	string CONGESTED_ROAD <- " congested_roads";
	string ROAD_POLLUTION_DISPLAY <- "road pollution";
	string TEXT_COLOR <- "Text color";
	string AQI_CHART <- "AQI Charts";
	
	map<string,rgb> palet <- [
		BUILDING_BASE::#white,
		BUILDING_OUTAREA::rgb(60,60,60),
		DECO_BUILDING::rgb(60,60,60),
		NATURAL::rgb (165, 199, 238,255),
		DUMMY_ROAD::#grey,
		CAR:: #orange,
		MOTOBYKE:: #cyan,
		CLOSED_ROAD_TRAFFIC:: #darkblue,		
		CLOSED_ROAD_POLLUTION:: #white,
		NOT_CONGESTED_ROAD:: #white,
		CONGESTED_ROAD::#red,
		ROAD_POLLUTION_DISPLAY:: #white,
		TEXT_COLOR::#white,
		AQI_CHART::#black
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

