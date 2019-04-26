/***
* Name: map3D
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model map3D

global {
	shape_file HKA_maquette__boundaries0_shape_file <- shape_file("../../includes/map3D_250419/HKA_maquette - boundaries.shp");	
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
		
//		save cut_ground type: shp to: "../../includes/map3D_250419/h2_ground.shp" attributes: ["height"::height];

		create road from: HKA_maquette__roads0_shape_file {
			shape <- shape + 5#m;
			height <- 0.3;
		}	
		save road type: shp to: "../../includes/map3D_250419/h_roads.shp" attributes: ["height"::height];
		
		ask road {
			the_ground.shape <- the_ground.shape - self.shape;
		}
		
//		save ((ground + road) as list<to_print>) type: shp to: "../../includes/map3D_250419/h_toto.shp" attributes: ["height"::height];
		
		create building from: buildings_union0_shape_file {
			height <- 2.5 + rnd(-0.2,0.2);
			error <- (length(shape.points) != length(remove_duplicates(shape.points)) + 1);
		}
		
/* 		ask building {			
			if(length(shape.points) != length(remove_duplicates(shape.points)) + 1) {
				write sample(self);		
				do die;	
			}
		}					
*/

		create natural from: HKA_maquette__natural0_shape_file {
			height <- 0.4;
		}	


//		save building type: shp to: "../../includes/map3D_250419/building_error.shp" attributes: ["height"::height, "error"::error];
	
		save ((ground + road + natural + (building where(! each.error)) ) as list<to_print>) type: shp to: "../../includes/map3D_250419/h_tyty.shp" attributes: ["height"::height];
	
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
	bool error;
	
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
