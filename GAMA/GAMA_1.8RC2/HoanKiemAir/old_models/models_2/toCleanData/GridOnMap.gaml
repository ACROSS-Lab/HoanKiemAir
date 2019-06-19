/***
* Name: GridOnMap
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model GridOnMap

global {

	shape_file resize_rectangle0_shape_file <- shape_file("../../includes/map3D_final/resize_rectangle.shp");

//	shape_file boundaries_shape_file <- shape_file("../../includes/map3D_final/boundaries.shp");
	
	shape_file buildings_admin_shape_file <- shape_file("../../includes/map3D_final/buildings_admin.shp");
	shape_file buildings_shape_file <- shape_file("../../includes/map3D_final/buildings.shp");
	
	shape_file bound_without_roads_shape_file <- shape_file("../../includes/map3D_final/g_ground_pluri.shp");
	shape_file natural_shape_file <- shape_file("../../includes/map3D_final/naturals.shp");
	
	shape_file enlarged_road_shape_file <- shape_file("../../includes/map3D_final/roads_buffer.shp");

	geometry shape <- envelope(resize_rectangle0_shape_file); 

	font f <- font("Arial", 40);

	init {				
		create obj from: bound_without_roads_shape_file with: [height::float(read("height"))];
		create obj from: enlarged_road_shape_file with:[height::float(read("height"))] ;
		create obj from: buildings_shape_file  with:[height::float(read("height"))] ;
		create obj from: buildings_admin_shape_file with:[height::float(read("height"))] ;
		create obj from: natural_shape_file with:[height::float(read("height"))];
	}
}


grid cell height: 4 width: 7 {
	aspect default {
		draw shape border: #black empty: true;
		draw "" + grid_x + " - " + grid_y font: f color: #white;
	}
}

species obj {
	float height;
	
	aspect default {
		draw shape color: #grey border: #black depth: height * 50;
	}
}

experiment GridOnMap type: gui {
	output {
		display d  {
			species obj;
			species cell;
		}
	}
}
