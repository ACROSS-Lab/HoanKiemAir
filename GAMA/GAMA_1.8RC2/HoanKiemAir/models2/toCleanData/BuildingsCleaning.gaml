/***
* Name: BuildingsCleaning
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BuildingsCleaning

global {
//	shape_file buildings0_shape_file <- shape_file("../../includes/SHP_demonstrator/buildings.shp");
	shape_file env_roads0_shape_file <- shape_file("../../includes/SHP_demonstrator/roads.shp");
	shape_file buildings0_test_shape_file <- shape_file("../../includes/map3D/buildings_test.shp");

	shape_file buildings0_shape_file <- shape_file("../../includes/map3D/HKA_maquette - buildings.shp");
	shape_file roads0_shape_file <- shape_file("../../includes/map3D/HKA_maquette - roads.shp");
	
	geometry shape <- envelope(env_roads0_shape_file);
	
	init {
		create road from: roads0_shape_file {
			shape <- shape + 5#m;
		}
		
		create building from: buildings0_shape_file;
		create building_test from: buildings0_test_shape_file;
		
		
//		ask building {
//			write "" + int(self)+ self.shape;
//			
//		}
//		ask building where (length(each.shape.geometries) > 1) {
//			do die;
//		}
//		write "" + building count(length(each.shape.geometries) > 1);
		
//		geometry min <- world.shape - union(road accumulate each.shape);
//		write length(min.geometries);
//		loop g over: min.geometries {
//			create new_building {
//				shape <- g;
//				if(shape = nil) {do die;}
//				write sample(shape);
//			}
//		}
		
//		ask new_building {
//			list<geometry> l <- to_rectangles(self, {5#m, 10#m});
//			loop g over: l {
//				create tiny_building  {
//					shape <- g;
//				}
//			}
//		}
		
		ask building {
			create new_building {
				building_test b <- first(building_test overlapping myself);
				shape <- (b intersection myself);
			}
		}

		save new_building where(each.shape != nil) type: "shp" to: "../../includes/map3D/new_buildings.shp";		
//		save tiny_building type: "shp" to: "../../includes/map3D/new_buildings.shp";
	}
	
}

species building {
	aspect default {
		draw shape color: #grey;
	}
}

species road {
	aspect default {
		draw shape color: #black;
	}
}

species new_building {
	rgb color <- rnd_color(255);
	aspect default {
		draw shape color: color;
	}	
}

species building_test {
	
	aspect default {
		draw shape color: rnd_color(255);
	}	
}

experiment exp {
	output {
		display d {
			species building_test;
			species building;
			species new_building transparency: 0.5;
			species road;
		}
	}
}