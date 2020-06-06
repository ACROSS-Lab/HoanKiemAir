/***
* Name: globalvars
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model globalvars

import "Pollution param and constants.gaml"

global {
	float seed <- 1.0;
	// Dev parameter
	bool mqtt_connect <- false;
	bool benchmark <- false;
	bool debug_scheduling <- false;
	bool extra_visualization <- true;
	
	// Shapefiles
	string resources_dir <- "../includes/driving/";
	shape_file roads_shape_file <- shape_file(resources_dir + "roads.shp");
	shape_file road_cells_shape_file <- shape_file(resources_dir + "rc.shp");
	shape_file intersections_shape_file <- shape_file(resources_dir + "intersections.shp");
	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
	shape_file buildings_admin_shape_file <- shape_file(resources_dir + "buildings_admin.shp");
	shape_file sensors_shape_file <- shape_file(resources_dir + "sensors.shp");
	
	
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
	
	// Benchmark
	float time_vehicles_move;
	float time_absorb_pollutants;
	float time_diffuse_pollutants;
	float time_update_network_weights;
	float time_spread_to_buildings;
	
	
	// Parameter of visualization to avoid z fighting
	float Z_LVL1 <- 0.1;
	float Z_LVL2 <- 0.2;
	float Z_LVL3 <- 0.3;
	
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
	int max_number_of_cars <- 700 const:true;
	int max_number_of_motorbikes <- 2000 const:true;
	bool day_time_traffic <- false;
	map<date,float> daytime_trafic_peak <- [
		date("00 00 00", "HH mm ss")::0.000689655172413793,
		date("01 00 00", "HH mm ss")::0.005517241379310344,
		date("02 00 00", "HH mm ss")::0.005517241379310344,
		date("03 00 00", "HH mm ss")::0.017241379310344827,
		date("04 00 00", "HH mm ss")::0.034482758620689655,
		date("05 00 00", "HH mm ss")::0.12413793103448276,
		date("06 00 00", "HH mm ss")::0.603448275862069,
		date("07 00 00", "HH mm ss")::1.0,
		date("08 00 00", "HH mm ss")::0.4482758620689655,
		date("09 00 00", "HH mm ss")::0.27241379310344827,
		date("10 00 00", "HH mm ss")::0.2896551724137931,
		date("11 00 00", "HH mm ss")::0.6206896551724138,
		date("12 00 00", "HH mm ss")::0.2689655172413793,
		date("13 00 00", "HH mm ss")::0.3275862068965517,
		date("14 00 00", "HH mm ss")::0.2689655172413793,
		date("15 00 00", "HH mm ss")::0.15862068965517243,
		date("16 00 00", "HH mm ss")::0.503448275862069,
		date("17 00 00", "HH mm ss")::0.6896551724137931,
		date("18 00 00", "HH mm ss")::0.2,
		date("19 00 00", "HH mm ss")::0.1206896551724138,
		date("20 00 00", "HH mm ss")::0.1103448275862069,
		date("21 00 00", "HH mm ss")::0.08275862068965517,
		date("22 00 00", "HH mm ss")::0.041379310344827586,
		date("23 00 00", "HH mm ss")::0.017241379310344827
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
}

