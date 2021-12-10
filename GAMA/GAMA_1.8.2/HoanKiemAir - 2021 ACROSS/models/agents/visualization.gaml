/***
* Name: visualization
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model visualization

import "../global_vars.gaml"

global {
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}	
}

species progress_bar schedules: [] {
	float val;
	float max_val;
	// Position and size
	float x;
	float y;
	float width;
	float height;
	// Descriptions
	string title;
	string left_label;
	string right_label;
	int size_title <- 20;
	int size_labels <- 16; 
	
	geometry rect(float rect_x, float rect_y, float rect_width, float rect_height) {
		return polygon([{rect_x, rect_y}, {rect_x + rect_width, rect_y}, {rect_x + rect_width, rect_y + rect_height}, 
									{rect_x, rect_y + rect_height}, {rect_x, rect_y}]);
	}
	
	action update(float new_val) {
		val <- new_val;
	}
	
	aspect default {	
		float length_filled<- width * val / max_val;
		float length_unfilled <- width - length_filled;
		
		draw rect(x, y, length_filled, height) color: #orange at: {x+ length_filled / 2, y + height / 2, Z_LVL2};
		draw rect(x + length_filled, y, length_unfilled, height) color: #white at: {(x+ length_filled) + length_unfilled / 2, y + height / 2, Z_LVL2};
		
		draw(title + ": ") at: {x, y - 50, Z_LVL2} font: font(size_title) color: palet[TEXT_COLOR];
		draw(left_label) at: {x - 20, y + 160, Z_LVL2} font: font(size_labels) color: palet[TEXT_COLOR];
		draw(right_label) at: {x + width - 20, y + 160, Z_LVL2} font: font(size_labels) color: palet[TEXT_COLOR];
	}
}

species param_indicator {
	float x;
	float y;
	float width;
	float height;
	float size;
	string name;
	string value;
	rgb col <- palet[TEXT_COLOR];
	bool with_RT <- false;
	bool with_box <- false;
	
	action update(string new_val) {
		value <- new_val;
	}
	
	aspect default {		
		if(with_box) {
			draw rectangle(width, height) color: rgb(#black,0.5) at: {x + width/2, y + height/2, Z_LVL1};
			point center <- world.midpoint({x, y, Z_LVL3}, {x + width, y + height, Z_LVL2});
			draw (name + ": " + (with_RT?"\n":"") + value) at: center color: col anchor: #center font: font(size);
		} else {
			draw(name + ": " + (with_RT?"\n":"") + value) font: font(size) at: {x, y, Z_LVL2} color: col;			
		}
	}
}

species line_graph_aqi parent: line_graph {
	list<float> thresholds;

	action draw_zones {
		// Calculate threshold lines' y-pos 
		thresholds <- [];
		loop thr over: thresholds_pollution.keys {
			if(thr < max_val) {
				add calculate_val_y_pos(float(thr)) to: thresholds at: 0;
			}
		}
		add calculate_val_y_pos(max_val) to: thresholds at: 0;
		
		// Draw the AQI level zones
		loop i from: 0 to: length(thresholds) - 2 {
			float h <- thresholds[i + 1] - thresholds[i];
			draw rectangle(width, h) at: {x + width / 2, thresholds[i] + h / 2, 0.1} color: zone_colors.values[length(thresholds) - 2 - i]/*, 0.5*/;
		}
	}
	
	action update(float new_val) {
		invoke update(new_val);
	}
	
	float calculate_val_y_pos(float value) {		
		return origin.y - (value / max_val * height);
	}
	
	aspect default {
		do draw_zones;
		// Draw axis
		do draw_line a: origin b: {x, y, Z_LVL2} thickness: 5 col: palet[AQI_CHART];
		do draw_line a: origin b: {x + width, y + height, Z_LVL2} thickness: 5 col: palet[AQI_CHART];
		
		point prev_val_pos <- origin;
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] >= 0) {
				float val_x_pos <- origin.x + width / length(val_list) * i;
				float val_y_pos <- origin.y - (val_list[i] / max_val * height);
				point val_pos <- {val_x_pos, val_y_pos, Z_LVL3};
				// Graph the value
				draw circle(10, val_pos) color: palet[AQI_CHART];		

				do draw_line a: val_pos b: prev_val_pos thickness: 3 col: palet[AQI_CHART];	
				
				prev_val_pos <- val_pos;
			}
		}
	}
}

species line_graph schedules: [] {
	// Params
	float x;
	float y;
	float width;
	float height;
	string label <- "";
	string unit <- "";

	point origin <- {x, y + height, Z_LVL2};
	list<float> val_list <- list_with(20, -1.0);
	float max_val -> max(max(val_list), 50.0);

	action draw_line(point a, point b, int thickness <- 1, rgb col <- #white, int end_arrow <- 0) {
		draw line([a, b]) + thickness at: world.midpoint(a, b) color: col end_arrow: end_arrow;
	}
	
	action update(float new_val) {
		remove index: 0 from: val_list;
		add item: new_val to: val_list at: length(val_list);
	}
	
	aspect default {
		// Draw axis
		do draw_line a: origin b: {x, y, Z_LVL2} thickness: 5;
		do draw_line a: origin b: {x + width, y + height, Z_LVL2} thickness: 5;
		
		point prev_val_pos <- nil;
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] >= 0) {
				float val_x_pos <- origin.x + width / length(val_list) * i;
				float val_y_pos <- origin.y - (val_list[i] / max_val * height);
				point val_pos <- {val_x_pos, val_y_pos, Z_LVL2};
				// Graph the value
				draw circle(10, val_pos) color: #white;		
				if (prev_val_pos != nil) {
					do draw_line a: val_pos b: prev_val_pos thickness: 3;	
				} 
				prev_val_pos <- val_pos;
			}
		}
		// Draw current value indicator
//		do draw_line({x, prev_val_pos.y}, {x + width, prev_val_pos.y}, 2, #red);
//		draw label + " " + string(round(val_list[length(val_list) - 1])) + " " + unit at: {x + 50,  prev_val_pos.y - 50, 0.2} font: font(20) color: #orange;
	}
}

species indicator_health_concern_level schedules: [] {
	float x <- 3000.0;
	float y <- 1000.0;
	float width <- 600.0;
	float height <- 200.0;
	rgb color;
	rgb text_color;
	string text;
	
	point anchor <- #center;
	
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}

	action update(float aqi) {		
		color <- world.get_pollution_color(aqi);
		text <- world.get_pollution_state(aqi);
		text_color <-(text = THRESHOLD_MODERATE)?#black:#white;
		anchor <- (text = THRESHOLD_UNHEALTHY_SENSITIVE)?#bottom_center : #center;
	}
	
	aspect default {
		draw rectangle(width, height) color: color at: {x + width / 2, y + height / 2, Z_LVL2};
		point center <- midpoint({x, y, 0.3}, {x + width, y + height, Z_LVL3});
		draw text at: center color: text_color anchor: anchor font: font(20);
	//	draw "Health concern \n level" at: center - {650, 0, 0} color: #yellow anchor: #bottom_center font: font(20);
	}
}

species boundary {
	
	reflex disappear when: (cycle > 1) {
		do die;
	}
	
	aspect {
		draw (shape + 100) - shape wireframe:false color: #pink;
	}
}

species background schedules: [] {
	float x;
	float y;
	float width;
	float height;
	float alpha <- 0.1;
	
	aspect default {
		draw rectangle(width, height) color: rgb(#black, alpha) at: {x + width / 2, y + height / 2, Z_LVL1};
	}
}