/***
* Name: map3D
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model map3D

global {
	shape_file HKA_maquette__boundaries0_shape_file <- shape_file("../../includes/map3D_250419/HKA_maquette - boundaries.shp");

	shape_file boundarie0_shape_file <- shape_file("../../includes/map3D_250419/boundarie.shp");
	
	shape_file buildings_union0_shape_file <- shape_file("../../includes/map3D_250419/buildings.shp");
	shape_file HKA_maquette__buildings_admin0_shape_file <- shape_file("../../includes/map3D_250419/buildings_admin.shp");
	shape_file HKA_maquette__natural0_shape_file <- shape_file("../../includes/map3D_250419/naturals.shp");
	shape_file HKA_maquette__roads0_shape_file <- shape_file("../../includes/map3D_250419/roads.shp");

	geometry shape <- envelope(HKA_maquette__boundaries0_shape_file); 

	ground the_ground;

	init {		
		create ground from: HKA_maquette__boundaries0_shape_file {
			height <- 0.5;
		}
		the_ground <- first(ground);
		
		create cut_ground from: boundarie0_shape_file {
			height <- 0.5;			
		}
		save cut_ground type: shp to: "../../includes/map3D_250419/h2_ground.shp" attributes: ["height"::height];

		create road from: HKA_maquette__roads0_shape_file {
			shape <- shape + 5#m;
			height <- 0.3;
		}	
		save road type: shp to: "../../includes/map3D_250419/h_roads.shp" attributes: ["height"::height];
		
		create building from: buildings_union0_shape_file {
			height <- 2.5 + rnd(-0.2,0.2);
		}
		save building type: shp to: "../../includes/map3D_250419/h_building.shp" attributes: ["height"::height];
		
		create natural from: HKA_maquette__natural0_shape_file {
			height <- 0.4;
		}	
		save natural type: shp to: "../../includes/map3D_250419/h_natural.shp" attributes: ["height"::height];
				
		create building_admin from: HKA_maquette__buildings_admin0_shape_file {
			height <- 0.4;
		}		
		save building_admin type: shp to: "../../includes/map3D_250419/h_building_admin.shp" attributes: ["height"::height];
	
		save cut_ground type: shp to: "../../includes/map3D_250419/h3_ground.shp" attributes: ["height"::height];
		save ground type: shp to: "../../includes/map3D_250419/h3_gg.shp" attributes: ["height"::height];
		
//		do cut_by_ground;
//		do cut_by_roads;
//		do cut_ground;	

//		save (agents of_generic_species to_print) type: shp to: "../../includes/map3D_250419/result.shp" attributes: ["height"::height, "type"::type];
	}
	
	action cut_by_ground {
		ask (agents of_generic_species to_print) - the_ground {
			shape <- shape inter the_ground.shape;
		}
	}
	
//	action cut_ground {
//		geometry sh <- the_ground.shape;
//		sh <- sh - union(road collect each.shape);
//		sh <- sh - union(natural collect each.shape);
//		
//		the_ground.shape <- sh;
//	}
	
	action cut_by_roads {
		geometry roadies <- union(road collect (each.shape));
		ask ( ((agents - the_ground) - road) of_generic_species to_print)  {
			shape <- (shape - roadies);
		}		
	}
}

species to_print {
	float height;
	string type; 
	
	init {
		type <- species(self) as string;
	}
}

species building_admin parent: to_print {
	aspect default {
		draw shape color: #green;
	}	
}
species natural parent: to_print {
	aspect default {
		draw shape color: #green;
	}		
}
species building parent: to_print {
	aspect default {
		draw shape color: #grey border: #darkgrey;
	}		
}
species road parent: to_print {
	aspect default {
		draw shape color: #black;
	}
}

species ground parent: to_print {
	aspect default {
		draw shape empty:true;
	}
}

species cut_ground parent: to_print {
	aspect default {
		draw shape empty:true;
	}
}

experiment map3D type: gui {
	output {
		display d {
			species ground;			
			species building;
			species building_admin;
			species natural;
			species road;
		}
	}
}
