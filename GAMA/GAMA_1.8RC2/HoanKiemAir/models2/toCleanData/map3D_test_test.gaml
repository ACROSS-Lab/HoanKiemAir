/***
* Name: map3D
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model map3D

global {
	shape_file boundaries_shape_file <- shape_file("../../includes/map3D_test/boundaries.shp");
	
	shape_file buildings_admin_shape_file <- shape_file("../../includes/map3D_test/buildings_admin.shp");
	shape_file buildings_shape_file <- shape_file("../../includes/map3D_test/buildings.shp");
	
	shape_file bound_without_roads_shape_file <- shape_file("../../includes/map3D_test/g_ground_pluri.shp");
	shape_file natural_shape_file <- shape_file("../../includes/map3D_test/naturals.shp");
	
	shape_file enlarged_road_shape_file <- shape_file("../../includes/map3D_test/roads_buffer.shp");

	geometry shape <- envelope(boundaries_shape_file); 

	init {		
//		create dummy {
//			shape <- rectangle(5292,3024) at_location {2646,1512};
//		}
//		save dummy type: shp to: "../../includes/map3D_190508/resize_rectangle.shp" ;	
		
		
		create cut_ground from: bound_without_roads_shape_file with: [height::float(read("height"))];
		
		create road_enlarged from: enlarged_road_shape_file with:[height::float(read("height"))] ;

		create building from: buildings_shape_file  with:[height::float(read("height"))] 
		{
			if(height < 0.1) {
				height <- 1.3 + rnd(-0.3,0.3);		
			}
	//		error <- (length(shape.points) != length(remove_duplicates(shape.points)) + 1);
		}
		
		create building_admin from: buildings_admin_shape_file with:[height::float(read("height"))] ;
//		{
//			height <- 0.8 ;
//		}
		save building_admin type: shp to: "../../includes/map3D_final/buildings_admin.shp" attributes: ["height"::height];	
		
		create natural from: natural_shape_file with:[height::float(read("height"))];
//		{
//			height <- 0.3;
//		}	
		
		
//		save natural type: shp to: "../../includes/map3D_190503/h_natural.shp" attributes: ["height"::height];
//		save building type: shp to: "../../includes/map3D_190508/buildings.shp" attributes: ["height"::height];	

//		save building_admin type: shp to: "../../includes/map3D_190508/buildings_admin.shp" attributes: ["height"::height];	


		save (agents of_generic_species to_print) type: shp to: "../../includes/map3D_test/map3D_test.shp" attributes: ["height"::height];
	
//		save (agents of_generic_species to_print) type: shp to: "../../includes/map3D_190503/result.shp" attributes: ["height"::height, "type"::type];


	}
}

species dummy {
	
}

species to_print {
	float height ;
	string type; 
	rgb color <- #green;
	
	init {
		type <- species(self) as string;
		
	}
	
	aspect default {
		draw shape color: color depth: height * 100 ;
	}		
}

species building_admin parent: to_print {
	rgb color <- #red;
}
species ground parent: to_print {
	rgb color <- #red;
}
species natural parent: to_print {
	rgb color <- #darkblue;
}
species building parent: to_print {
	rgb color <- #grey ;
	bool error;
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
			species to_print;			
		}
	}
}
