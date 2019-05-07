/***
* Name: map3D
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model map3D

global {
	shape_file HKA_maquette__boundaries0_shape_file <- shape_file("../../includes/map3D_190503/HKA_maquette - boundaries.shp");
	shape_file bound_without_roads_shape_file <- shape_file("../../includes/map3D_190503/g_h_ground.shp");
	shape_file buildings_shape_file <- shape_file("../../includes/map3D_190503/buildings.shp");
	shape_file buildings_admin_shape_file <- shape_file("../../includes/map3D_190503/buildings_admin.shp");
	shape_file natural_shape_file <- shape_file("../../includes/map3D_190503/naturals.shp");
	shape_file enlarged_road_shape_file <- shape_file("../../includes/map3D_190503/roads_buffer.shp");

	shape_file g_h_ground0_shape_file <- shape_file("../../includes/map3D_190503/g_h_ground.shp");

	geometry shape <- envelope(HKA_maquette__boundaries0_shape_file); 

	init {		
		//create ground from: HKA_maquette__boundaries0_shape_file;
		// create cut_ground from: first(bound_without_roads_shape_file.contents).geometries with: [height::float(read("height"))];
		create cut_ground from: bound_without_roads_shape_file.contents with: [height::float(read("height"))];
		
//		create road_enlarged from: enlarged_road_shape_file with:[height::float(read("height"))] {
//			height <- 0.3;
//		}			
//		save road type: shp to: "../../includes/map3D_190503/h_roads.shp" attributes: ["height"::height];
		
//		create building from: buildings_shape_file {
//			height <- 2.5 + rnd(-0.2,0.2);
//		}

//		save building type: shp to: "../../includes/map3D_190503/h_building.shp" attributes: ["height"::height];
		
//		create natural from: natural_shape_file with:[height::float(read("height"))]{
//			height <- 0.4;
//		}	
//		save natural type: shp to: "../../includes/map3D_190503/h_natural.shp" attributes: ["height"::height];
				
//		create building_admin from: buildings_admin_shape_file {
//			height <- 1.0;
//		}		
	
//		save (agents of_generic_species to_print) type: shp to: "../../includes/map3D_190503/g_map_ground_roads.shp" attributes: ["height"::height];
	
//		save (agents of_generic_species to_print) type: shp to: "../../includes/map3D_190503/result.shp" attributes: ["height"::height, "type"::type];
	}
}

species to_print {
	float height ;
	string type; 
	rgb color;
	
	init {
		type <- species(self) as string;
		
	}
	
	aspect default {
		draw shape color: color depth: 300 ;
	}		
}

species building_admin parent: to_print {
	rgb color <- #grey;
}
species ground parent: to_print {
	rgb color <- #red;
}
species natural parent: to_print {
	rgb color <- #green;
}
species building parent: to_print {
	rgb color <- #grey ;
}
species road parent: to_print {
	rgb color <-  #black;
}
species road_enlarged parent: to_print {
	rgb color <-  #black;
}
species cut_ground parent: to_print {
	rgb color <-  #orange;
}


experiment map3D type: gui {
	output {
		display d type: opengl {
			species ground;		
			species cut_ground;	
			species building;
			species building_admin;
			species road_enlarged;
			species natural;
			species road;
		}
	}
}
