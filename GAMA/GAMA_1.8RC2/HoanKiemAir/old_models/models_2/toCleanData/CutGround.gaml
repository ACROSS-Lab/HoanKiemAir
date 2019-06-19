/***
* Name: AddHeight
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model AddHeight

global {
	shape_file boundaries0_shape_file <- shape_file("../../includes/map3D_190508/boundaries.shp");
	shape_file roads_buffer0_shape_file <- shape_file("../../includes/map3D_190508/roads_buffer.shp");
	shape_file naturals0_shape_file <- shape_file("../../includes/map3D_190508/naturals.shp");

	geometry shape <- envelope(boundaries0_shape_file);
	
	init {
		create ground from: boundaries0_shape_file;
		create road from: roads_buffer0_shape_file;
		create natural from: naturals0_shape_file;
		
		geometry uRoads <- union(road collect each.shape);
		geometry uNaturals <- union(natural collect each.shape);
		
		geometry g <- first(ground).shape - (shape.contour +0.7#m);
		
		g <- g - uRoads;
		g <- g - uNaturals;
		
		create to_print from: g.geometries {
			height <- 0.5;
		}
		
//		list<geometry> geoms <- g.geometries;
		
//		create to_print from: geoms {
//			height <- 0.5;
//		}
		
		save to_print to: "../../includes/map3D_190508/g_ground_pluri.shp" type: "shp" attributes: ["height"::height]; 
	}

}

species to_print {
	float height <- 0.5;
	rgb color;
	
	aspect default {
		draw shape color: color depth: height*100;
	}
}

species ground parent: to_print {
	rgb color <- #darkgrey;
}

species road parent: to_print {
	rgb color <- #darkgrey;
}

species natural parent: to_print {
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
