/***
* Name: NewModel
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NewModel

global {
	shape_file shape_file_roads <- shape_file("../includes/roads.shp");
	shape_file shape_file_bound <- shape_file("../includes/keynote_hoankiem.shp");
	
	geometry shape <- envelope(shape_file_bound);
//	geometry shape <- envelope(shape_file_roads);
	
	init {
		create road from: shape_file_roads;
		create bound from: shape_file_bound;
	}
	
}

species road ;
species bound {
	aspect default {
		draw shape color: #blue;
	}
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display d {
			species bound;
			species road;
			
		}
	}
}
