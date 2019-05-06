/***
* Name: GridOnMap
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model GridOnMap

global {
	shape_file g_map_ground_roads0_shape_file <- shape_file("../../includes/map3D_190503/g_map_ground_roads.shp");

	geometry shape <- envelope(g_map_ground_roads0_shape_file);

	init {
		create obj from: g_map_ground_roads0_shape_file;
	}
}

grid cell height: 4 width: 7 {
	aspect default {
		draw shape border: #black empty: true;
	}
}

species obj {
	float height;
	
	init {
		if(height = 0.0) {
			height <- 0.5;
		}
	}
	
	aspect default {
		draw shape color: #grey border: #black depth: height * 50;
	}
}

experiment GridOnMap type: gui {
	output {
		display d type: opengl {
			species obj;
			species cell;
		}
	}
}
