/***
* Name: AddHeight
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model AddHeight

global {

	shape_file boundaries0_shape_file <- shape_file("../../includes/map3D_final/boundaries.shp");
//	shape_file roads_buffer0_shape_file <- shape_file("../../includes/map3D_190508/roads_buffer.shp");
//	shape_file g_h_ground0_shape_file <- shape_file("../../includes/map3D_190508/g_h_ground.shp");

//	shape_file buildings_admin0_shape_file <- shape_file("../../includes/map3D_final/buildings_admin.shp");

	shape_file buildings_admin0_shape_file <- shape_file("../../includes/map3D_190503/buildings_admin.shp");

	geometry shape <- envelope(boundaries0_shape_file);
	
	init {
	//	geometry g <- first(buildings_admin0_shape_file.contents);
		list<geometry> geoms <- buildings_admin0_shape_file.contents;//g.geometries;
		
		create to_print from: geoms {
			height <- 0.85;
		}
		
		save to_print to: "../../includes/map3D_final/buildings_admin.shp" type: "shp" attributes: ["height"::height]; 
	}

}

species to_print {
	float height;
	rgb color;
	
	aspect default {
		draw shape color: color depth: height*100;
	}
}

species ground parent: to_print {
	rgb color <- #darkgrey;
}

experiment AddHeight type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display d type: opengl {
			species to_print;
		}
	}
}
