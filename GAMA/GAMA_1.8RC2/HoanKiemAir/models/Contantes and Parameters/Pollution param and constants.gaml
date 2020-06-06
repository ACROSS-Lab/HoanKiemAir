/***
* Name: ParametersConstants
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ParametersConstants

global {
	//////////////////////////////////////////////////////////////////////////
	// Constants
	//////////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////////	
	// Pollution-related constants
	
	// Pollutants
	map<string, float> ALLOWED_AMOUNT <- ["CO"::30000.0, "NOx"::200.0, "SO2"::350.0, "PM"::300.0]; // Unit: ug/m3
	map<string, map<string, float>> EMISSION_FACTOR <- [
		"motorbike"::["CO"::3.62 * 10e6, "NOx"::0.3 * 0.05 * 10e6, "SO2"::0.03 * 10e6, "PM"::0.1 * 10e6],  // Unit: ug/km
		"car"::["CO"::3.62 * 10e6, "NOx"::1.5 * 0.05 * 10e6, "SO2"::0.17 * 10e6, "PM"::0.1 * 10e6]
	];

	// Pollution categories 
	string THRESHOLD_HAZARDOUS <- " Hazardous";
	string THRESHOLD_VERY_UNHEALTY <- " Very Unhealthy";
	string THRESHOLD_UNHEALTHY <- " Unhealty";
	string THRESHOLD_UNHEALTHY_SENSITIVE <- " Unhealthy for \nSensitive Groups";
	string THRESHOLD_MODERATE <- " Moderate";
	string THRESHOLD_GOOD <- " Good";
	
	// Colors corresponding to each pollution threshold
	map<string,rgb> zone_colors <- [
		THRESHOLD_GOOD:: #green, //rgb(104,225,66,255), 
		THRESHOLD_MODERATE:: #yellow, //rgb(255,255,83,255), 
		THRESHOLD_UNHEALTHY_SENSITIVE::#orange,//rgb(240,131,51,255),
		THRESHOLD_UNHEALTHY::#red, //rgb(218,56,50,255), 
		THRESHOLD_VERY_UNHEALTY::rgb(116,49,121,255),
		THRESHOLD_HAZARDOUS::rgb(66,18,39,255)
	];
	
	// Definition of the pollution categories
	map<int,string> thresholds_pollution <- [
		0::THRESHOLD_GOOD,
		51::THRESHOLD_MODERATE,
		101::THRESHOLD_UNHEALTHY_SENSITIVE,
		151::THRESHOLD_UNHEALTHY,
		201::THRESHOLD_VERY_UNHEALTY,
		301::THRESHOLD_HAZARDOUS
	];

	//////////////////////////////////////////////////////////////////////////	
	// Parameters
	//////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////
	// Pollution diffusion
	float pollutant_decay_rate <- 0.99;
	float pollutant_diffusion <- 0.05;
	int grid_size <- 64;
	int cell_depth <- 10; //  meters
	float grid_cell_volume <- (shape.width / grid_size) * (shape.height / grid_size) * cell_depth;  // Unit: cubic meters
	
}
