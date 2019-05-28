/***
* Name: visualization
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model visualization

import "../global_vars.gaml"

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
		
		draw rect(x, y, length_filled, height) color: #orange at: {x+ length_filled / 2, y + height / 2, 0.2};
		draw rect(x + length_filled, y, length_unfilled, height) color: #white at: {(x+ length_filled) + length_unfilled / 2, y + height / 2, 0.2};
		
		draw(title + ": ") at: {x, y - 50, 0.2} font: font(20);
		draw(left_label) at: {x - 20, y + 200, 0.2} font: font(18);
		draw(right_label) at: {x + width - 20, y + 200, 0.2} font: font(18);
	}
}

species param_indicator {
	float x;
	float y;
	float size;
	string name;
	string value;
	
	action update(string new_val) {
		value <- new_val;
	}
	
	aspect default {
		draw(name + ": " + value) font: font(size) at: {x, y, 0.2};
	}
}

species line_graph_aqi parent: line_graph {
	list<float> thresholds;
	float good <- 50;
	float moderate <- 100;
	float unhealthy_sensitive <- 150;
	

	action draw_zones {
		loop i from: 0 to: length(thresholds) - 2 {
			float h <- thresholds[i + 1] - thresholds[i];
			draw rectangle(width, h) at: {x + width / 2, thresholds[i] + h / 2, 0.4} color: rgb(zone_colors[length(thresholds) - 2 - i]/*, 0.5*/);
		}
	}
	
	float calculate_val_y_pos(float value) {
		return origin.y - (value / max_val * height);
	}
	
	reflex update_thresholds {
		thresholds <- [origin.y];
		if (good < max_val) {
			add calculate_val_y_pos(good) to: thresholds at: 0;
		}
		if (moderate < max_val) {
			add calculate_val_y_pos(moderate) to: thresholds at: 0;
		}
		add calculate_val_y_pos(max_val) to: thresholds at: 0;
	}
	
	aspect default {
		// Draw axis
		do draw_line a: origin b: {x, y, 0.2} thickness: 5;
		do draw_line a: origin b: {x + width, y + height, 0.2} thickness: 5;
		
		point prev_val_pos <- nil;
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] >= 0) {
				float val_x_pos <- origin.x + width / length(val_list) * i;
				float val_y_pos <- origin.y - (val_list[i] / max_val * height);
				point val_pos <- {val_x_pos, val_y_pos, 0.2};
				// Graph the value
				draw circle(10, val_pos) ;		
				float current_val <- val_list[length(val_list) - 1];
				float current_val_height <- current_val / max_val * height;
				if (prev_val_pos != nil) {
					do draw_line a: val_pos b: prev_val_pos thickness: 3;	
				} 
				prev_val_pos <- val_pos;
			}
		}
		do draw_zones;
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

	point origin <- {x, y + height, 0.2};
	list<float> val_list <- list_with(20, -1.0);
	float max_val -> max(max(val_list), 50.0);
	
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}
	
	action draw_line(point a, point b, int thickness <- 1, rgb col <- #white, int end_arrow <- 0) {
		draw line([a, b]) + thickness at: midpoint(a, b) color: col end_arrow: end_arrow;
	}
	
	action update(float new_val) {
		remove index: 0 from: val_list;
		add item: new_val to: val_list at: length(val_list);
	}
	
	aspect default {
		// Draw axis
		do draw_line a: origin b: {x, y, 0.2} thickness: 5;
		do draw_line a: origin b: {x + width, y + height, 0.2} thickness: 5;
		
		point prev_val_pos <- nil;
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] >= 0) {
				float val_x_pos <- origin.x + width / length(val_list) * i;
				float val_y_pos <- origin.y - (val_list[i] / max_val * height);
				point val_pos <- {val_x_pos, val_y_pos, 0.2};
				// Graph the value
				draw circle(10, val_pos) ;		
				float current_val <- val_list[length(val_list) - 1];
				float current_val_height <- current_val / max_val * height;
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
		anchor <- #center;
		if (aqi < 51) {
			color <- #seagreen;
			text_color <- #white;
			text <- " Good";
		} else if (aqi < 101) {
			color <- #yellow;
			text_color <- #black;
			text <- " Moderate";
		} else if (aqi < 151) {
			color <- #orange;
			text_color <- #white;
			text <- " Unhealthy for\nSensitive Groups";
			anchor <- #bottom_center;
		} else if (aqi < 201) {
			color <- #crimson;
			text_color <- #white;
			text <- " Unhealthy";
		} else if (aqi < 301) {
			color <- #purple;
			text_color <- #white;
			text <- " Very unhealthy";
		} else {
			color <- #darkred;
			text_color <- #white;
			text <- " Hazardous";
		}
	}
	
	aspect default {
		draw rectangle(width, height) color: color at: {x + width / 2, y + height / 2, 0.2};
		point center <- midpoint({x, y, 0.3}, {x + width, y + height, 0.3});
		draw text at: center color: text_color anchor: anchor font: font(20);
		draw "Health concern \n level" at: center - {650, 0, 0} color: #yellow anchor: #bottom_center font: font(20);
	}
}

species boundary {
	
	reflex disappear when: (cycle > 1) {
		do die;
	}
	
	aspect {
		draw (shape + 100) - shape empty:false color: #pink;
	}
}

species background schedules: [] {
	float x;
	float y;
	float width;
	float height;
	float alpha <- 0.1;
	
	aspect default {
		draw rectangle(width, height) color: rgb(#black, alpha) at: {x + width / 2, y + height / 2, 0.1};
	}
}