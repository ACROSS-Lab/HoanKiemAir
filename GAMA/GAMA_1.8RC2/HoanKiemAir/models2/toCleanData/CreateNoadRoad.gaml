/***
* Name: CreateNoadRoad
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CreateNoadRoad

global {

	shape_file roads_shape_file <- shape_file("../../includes/roads.shp");
	geometry shape <- envelope(roads_shape_file);

	graph network;
	
	init {
		create road from: roads_shape_file;
		network <- as_edge_graph(road);
		
		list<point> nodes <- network.vertices;
		loop p over: nodes {
			create noad with: [location::p];
		} 
		
//		geometry all_the_roads <- union(road);
//		
//		geometry noad_on_border <- line(world.shape.points) intersection all_the_roads;
//		
//		write noad_on_border.points;
//		loop pBorder over: noad_on_border.points {
//			create border_nodes with: [location::pBorder];
//		} 		
		
		save nodes type: 'shp' to: "../../includes/roads_nodes.shp";
	}
	
}

species road {
	aspect default {
		draw shape color: #red;
	}
}
species noad {
	aspect default {
		draw circle(10) color: #blue;
	}
}
species border_nodes {
	aspect default {
		draw square(10) color: #green;
	}
}

experiment CreateNoadRoad type: gui {

	output {
		display d {
			species road;
			species noad transparency: 0.7;
			species border_nodes transparency: 0.5;
			
		}
	}
}
