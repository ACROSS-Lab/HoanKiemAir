/***
* Name: maingridcells
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model UI

import "Pollution.gaml"

global {
	//Devices
	string PROJECTOR <- "Projector1920x1080";
	string MACBOOKPRO <- "MBP2056x1329";
	string DELL34 <- "Dell3440x1440";
	
	
	//Colors and icons
	string images_dir <- "../images/";
	list<rgb> pal <- palette([#green, #yellow, #orange, #red]);
	map<rgb, string>
	legends <- [color_inner_building::"District Buildings", color_outer_building::"Outer Buildings", color_road::"Roads", color_closed::"Closed Roads", color_lake::"Rivers & lakes", color_car::"Cars", color_moto::"Motorbikes"];
	rgb color_car <- #lightblue;
	rgb color_moto <- #cyan;
	rgb color_road <- #lightgray;
	rgb color_closed <- #mediumpurple;
	rgb color_inner_building <- rgb(100, 100, 100);
	rgb color_outer_building <- rgb(60, 60, 60);
	rgb color_lake <- rgb(165, 199, 238, 255);

	// Buttons
	map<string, map<string, float>>
	screen_configurations <- [
		
		DELL34::["diameter"::140, "left"::-1082, "gap"::190, "line1"::782, "line2"::1124, "line3"::1111, "line4"::1820], 
		MACBOOKPRO::["diameter"::140, "left"::-1455, "gap"::190, "line1"::782, "line2"::1124, "line3"::1470,"line4"::1816], 
		PROJECTOR::["diameter"::170, "left"::-1372, "gap"::220, "line1"::1022, "line2"::1450, "line3"::1870,"line4"::2190]];
		
		
	// Flags for selection
	bool minus_density_selected <- true;
	bool plus_density_selected <- false;
	bool plus_plus_density_selected <- false;
	bool minus_zone_selected <- true;
	bool plus_zone_selected <- false;
	bool plus_plus_zone_selected <- false;
	bool show_selected <- true;
	bool show_traffic_selected <- true;
	point change_vehicles_event <- nil;
	int change_scenario_event <- -1;
	bool move_player_event <- false;
	
	bool select_button_on_device (string device) {
		map<string, float> values <- screen_configurations[device];
		return select_button_on(values);
	}

	bool select_button_on (map<string, float> screen) {
		float diam <- screen["diameter"];
		float left_x <- screen["left"];
		float button_gap <- screen["gap"];
		float line1_y <- screen["line1"];
		float line2_y <- screen["line2"];
		float line3_y <- screen["line3"];
		float line4_y <- screen["line4"];
		point minus_zone <- {left_x + diam / 2, line1_y};
		point plus_zone <- {left_x + button_gap + diam / 2, line1_y};
		point plus_plus_zone <- {left_x + 2 * button_gap + diam / 2, line1_y};
		point minus_density <- {left_x + diam / 2, line2_y};
		point plus_density <- {left_x + button_gap + diam / 2, line2_y};
		point plus_plus_density <- {left_x + 2 * button_gap + diam / 2, line2_y};
		point show_aqi <- {left_x + diam / 2, line3_y};
		point show_traffic <- {left_x + diam / 2, line4_y};
		point p <- #user_location;
		if (p distance_to minus_density) < diam / 2 {
			if (change_vehicles_event != nil) {
				return true;
			}
			minus_density_selected <- true;
			plus_density_selected <- false;
			plus_plus_density_selected <- false;
			change_vehicles_event <- {500, 1000};
			return true;
		} else if (p distance_to plus_density) < diam / 2 {
			if (change_vehicles_event != nil) {
				return true;
			}
			minus_density_selected <- false;
			plus_density_selected <- true;
			plus_plus_density_selected <- false;
			change_vehicles_event <- {3000, 4000};
			return true;
		} else if (p distance_to plus_plus_density) < diam / 2 {
			if (change_vehicles_event != nil) {
				return true;
			}
			minus_density_selected <- false;
			plus_density_selected <- false;
			plus_plus_density_selected <- true;
			change_vehicles_event <- {5000, 10000};
			return true;
		} else if (p distance_to minus_zone) < diam / 2 {
			if (change_scenario_event != -1) {
				return true;
			}
			minus_zone_selected <- true;
			plus_zone_selected <- false;
			plus_plus_zone_selected <- false;
			change_scenario_event <- 0;
			return true;
		} else if (p distance_to plus_zone) < diam / 2 {
			if (change_scenario_event != -1) {
				return true;
			}
			minus_zone_selected <- false;
			plus_zone_selected <- true;
			plus_plus_zone_selected <- false;
			change_scenario_event <- 1;
			return true;
		} else if (p distance_to plus_plus_zone) < diam / 2 {
			if (change_scenario_event != -1) {
				return true;
			}
			minus_zone_selected <- false;
			plus_zone_selected <- false;
			plus_plus_zone_selected <- true;
			change_scenario_event <- 2;
			return true;
		} else if (p distance_to show_aqi < diam / 2) {
			show_selected <- !show_selected;
			return true;
		} else if (p distance_to show_traffic < diam / 2) {
			show_traffic_selected <- !show_traffic_selected;
			return true;
		}

		return false;
	}

	action update_legend {
		legends[color_car] <- "Cars (" + length(vehicle where (each.type = CAR)) + ")";
		legends[color_moto] <- "Motorbikes (" + length(vehicle where (each.type = MOTO)) + ")";
	} }

experiment "Control" autorun: true virtual: true {
	map<rgb, string> pollutions <- [#green::"Good", #yellow::"Average", #orange::"Bad", #red::"Hazardous"];
	map<rgb, string> traffic <- [#green::"Fluid", #yellow::"Average", #orange::"Bad", #red::"Jammed"];

	font small <- font("Arial", 14, #bold);
	font text <- font("Arial", 24, #bold);
	font title <- font("Arial", 48, #bold);
	image minus_on <- image(images_dir + "minus.png");
	image minus_off <- image(images_dir + "minusblack.png");
	image plus_on <- image(images_dir + "plus.png");
	image plus_off <- image(images_dir + "plusblack.png");
	image plus_plus_on <- image(images_dir + "plusplus.png");
	image plus_plus_off <- image(images_dir + "plusplusblack.png");
	image show_on <- image(images_dir + "show.png");
	image show_off <- image(images_dir + "showblack.png");
	image ird_logo <- image(images_dir + "ird.png");
	output synchronized: true {
		layout #stack;
		display "Controls" virtual: true type: opengl background: #black axes: false {
			species decoration_building refresh: false {
				draw self.shape color: color_outer_building border: #darkgrey;
			}

			species natural refresh: false {
				draw self.shape color: color_lake;
			}

			species road {
				draw self.shape + 4 color: closed ? color_closed : color_road;
			}

			overlay position: {0 #px, 0 #px} size: {1 #px, 1 #px} rounded: false {
				draw rectangle(1000 #px, 3000 #px) color: #black at: {2100 #px, 0 #px};
				float x_start <- 1600 #px;
//				draw "Hoan Kiem Air" color: rgb(102, 102, 102) font: title at: {x_start + 50 #px, 100 #px} anchor: #top_left;
//				draw ird_logo at: {x_start + 225 #px, 200 #px} size: {350 #px, 82 #px};
				float width <- 40 #px;
				float y_start <- 450 #px;
				float x_shift <- 2 * width;
				float diameter <- 60 #px;
				float y <- y_start - diameter;
				loop p over: legends.pairs {
					draw square(40 #px) at: {x_start + x_shift, y} color: p.key;
					draw p.value at: {x_start + x_shift + width, y} anchor: #left_center color: #white font: text;
					y <- y + 40 #px;
				}

				draw rectangle(1000 #px, 3000 #px) color: #black at: {0 #px, 0 #px};
				x_start <- 150 #px;
				y <- y_start;
				draw "Pedestrian zones" font: text color: #white anchor: #left_center at: {x_start + diameter * 2 - diameter / 2, y - diameter};
				draw minus_zone_selected ? minus_on : minus_off size: {diameter, diameter} at: {x_start + diameter * 2, y};
				draw plus_zone_selected ? plus_on : plus_off size: {diameter, diameter} at: {x_start + diameter * 3 + 40, y};
				draw plus_plus_zone_selected ? plus_plus_on : plus_plus_off size: {diameter, diameter} at: {x_start + diameter * 4 + 80, y};
				y <- y + diameter * 2 + diameter / 2;
				draw "Traffic density" font: text color: #white anchor: #left_center at: {x_start + diameter * 2 - diameter / 2, y - diameter};
				draw minus_density_selected ? minus_on : minus_off size: {diameter, diameter} at: {x_start + diameter * 2, y};
				draw plus_density_selected ? plus_on : plus_off size: {diameter, diameter} at: {x_start + diameter * 3 + 40, y};
				draw plus_plus_density_selected ? plus_plus_on : plus_plus_off size: {diameter, diameter} at: {x_start + diameter * 4 + 80, y};
				y <- y + diameter * 2 + diameter / 2;
				draw "Air Quality" font: text color: #white anchor: #left_center at: {x_start + diameter * 2 - diameter / 2, y - diameter};
				draw show_selected ? show_on : show_off size: {diameter, diameter} at: {x_start + diameter * 2, y};
				draw show_selected ? "Hide" : "Show" font: text color: #grey anchor: #left_center at: {x_start + diameter * 3, y};
				y_start <- y;
				x_start <- 1600 #px;
				draw "Air Quality Index" font: text color: #white anchor: #left_center at: {x_start + diameter, y - diameter};
				loop p over: reverse(pollutions.pairs) {
					draw square(width) at: {x_start + x_shift, y} color: p.key;
					draw p.value at: {x_start + x_shift + width, y} anchor: #left_center color: #white font: text;
					y <- y + width;
				}

				rgb color_max <- pal[index_of_pollution_level_against_max(aqi_max)];
				rgb color_mean <- pal[index_of_pollution_level_against_mean(aqi_mean)];
				float height <- width * length(pollutions);
				float y_max <- (y_start + height - (height * (aqi_max / aqi_worst_max))) - width / 2;
				float y_mean <- (y_start + height - (height * (aqi_mean / aqi_worst_mean))) - width / 2;
				draw triangle(20 #px) rotated_by 90 at: {x_start + 50 #px, y_max} color: color_max;
				draw "MAX" font: small color: color_max anchor: #left_center at: {x_start + 10 #px, y_max};
				draw triangle(20 #px) rotated_by 90 at: {x_start + 50 #px, y_mean} color: color_mean;
				draw "AVG" font: small color: color_mean anchor: #left_center at: {x_start + 10 #px, y_mean};
			}

		}

	}

}

