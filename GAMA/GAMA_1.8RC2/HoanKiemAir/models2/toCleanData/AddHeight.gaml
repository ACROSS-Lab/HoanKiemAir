/***
* Name: AddHeight
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model AddHeight

global {
	shape_file roads_buffer0_shape_file <- shape_file("../../includes/map3D_190508/roads_buffer.shp");

	geometry shape <- envelope(roads_buffer0_shape_file);
	
	init {
		create to_print from: roads_buffer0_shape_file {
			height <- 0.3;
		}
		
		save to_print to: "../../includes/map3D_190508/roads_buffer.shp" type: "shp" attributes: ["height"::height]; 
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
