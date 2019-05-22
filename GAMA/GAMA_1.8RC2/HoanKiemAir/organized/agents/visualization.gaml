/***
* Name: visualization
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model visualization

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
		
		draw rect(x, y, length_filled, height) color: #orange;
		draw rect(x + length_filled, y, length_unfilled, height) color: #white;
		
		draw(title + ": ") at: {x, y - 50} font: font(20);
		draw(left_label) at: {x - 20, y + 200} font: font(18);
		draw(right_label) at: {x + width - 20, y + 200} font: font(18);
//		do draw_bar tracked_val: nb_cars tracked_val_max: 500 x: -700 y: 1800 width: 500 height: 100 
//								title: "Cars" left_label: "0" right_label: "500";
//		do draw_bar tracked_val: nb_motorbikes tracked_val_max: 2000 x: -700 y: 2200 width: 500 height: 100 
//								title: "Motorbikes" left_label: "0" right_label: "2000";
	}
}

//species line_graph_aqi parent: line_graph {
//	float tracked_val -> aqi;
//	float x <- 2400;
//	float y <- 1400;
//	float width <- 1300;
//	float height <- 1000;
//	string label <- "Hourly AQI";
//}

species line_graph schedules: [] {
	// Params
	float x;
	float y;
	float width;
	float height;
	string label <- "";
	string unit <- "";

	list<float> val_list <- list_with(20, -1.0);
	
	point midpoint(point a, point b) {
		return (a + b) / 2;
	}
	
	action draw_line(point a, point b, int thickness <- 1, rgb color <- #yellow, int end_arrow <- 0) {
		draw line([a, b]) + thickness at: midpoint(a, b) color: color end_arrow: end_arrow;
	}
	
	action update(float new_val) {
		remove index: 0 from: val_list;
		add item: new_val to: val_list at: length(val_list);
	}
	
	aspect default {
		point origin <- {x, y + height};
		
		// Draw axis
		do draw_line a: origin b: {x, y} thickness: 5;
		do draw_line a: origin b: {x + width, y + height} thickness: 5;
		
		point prev_val_pos <- nil;
		float max_val <- max(val_list) = 0 ? 1 : max(val_list);
		loop i from: 0 to: length(val_list) - 1 {
			if (val_list[i] >= 0) {
				float val_x_pos <- origin.x + width / length(val_list) * i;
				float val_y_pos <- origin.y - (val_list[i] / max_val * height);
				point val_pos <- {val_x_pos, val_y_pos};
				// Graph the value
				draw circle(10, val_pos);		float current_val <- val_list[length(val_list) - 1];
				float current_val_height <- current_val / max_val * height;
				if (prev_val_pos != nil) {
					do draw_line a: val_pos b: prev_val_pos thickness: 3;	
				} 
				prev_val_pos <- val_pos;
			}
		}
		// Draw current value indicator
		do draw_line({x, prev_val_pos.y}, {x + width, prev_val_pos.y}, 2, #red);
		draw label + " " + string(round(val_list[length(val_list) - 1])) + " " + unit at: {x + 50,  prev_val_pos.y - 50} font: font(20) color: #orange;
	}
}

//species indicator_health_concern_level schedules: [] {
//	float x <- 3000;
//	float y <- 1000;
//	float width <-600;
//	float height <- 200;
//	rgb color;
//	rgb text_color;
//	string text;
//	
//	point anchor <- #center;
//	
//	point midpoint(point a, point b) {
//		return (a + b) / 2;
//	}
//	
//	action update {
//		anchor <- #center;
//		if (aqi < 51) {
//			color <- #seagreen;
//			text_color <- #white;
//			text <- " Good";
//		} else if (aqi < 101) {
//			color <- #yellow;
//			text_color <- #black;
//			text <- " Moderate";
//		} else if (aqi < 151) {
//			color <- #orange;
//			text_color <- #white;
//			text <- " Unhealthy for\nSensitive Groups";
//			anchor <- #bottom_center;
//		} else if (aqi < 201) {
//			color <- #crimson;
//			text_color <- #white;
//			text <- " Unhealthy";
//		} else if (aqi < 301) {
//			color <- #purple;
//			text_color <- #white;
//			text <- " Very unhealthy";
//		} else {
//			color <- #darkred;
//			text_color <- #white;
//			text <- " Hazardous";
//		}
//	}
//	
//	aspect default {
//		draw rectangle({x, y}, {x + width, y + height}) color: color;
//		point center <- midpoint({x, y}, {x + width, y + height});
//		draw text at: center color: text_color anchor: anchor font: font(20);
//		draw "Health concern" at: center - {600, 0} color: #yellow anchor: #center font: font(20);
//	}
//}