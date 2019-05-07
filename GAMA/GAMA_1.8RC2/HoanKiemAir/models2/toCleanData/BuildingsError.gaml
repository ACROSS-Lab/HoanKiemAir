model BuildingsError

global {
	shape_file HKA_maquette__boundaries0_shape_file <- shape_file("../../includes/map3D_190503/HKA_maquette - boundaries.shp");	
	shape_file buildings_union0_shape_file <- shape_file("../../includes/map3D_190503/buildings.shp");

	geometry shape <- envelope(HKA_maquette__boundaries0_shape_file); 

	ground the_ground;

	init {		
		create ground from: HKA_maquette__boundaries0_shape_file {
			height <- 0.5;
		}
		the_ground <- first(ground);
				
		create building from: buildings_union0_shape_file {
			height <- 2.5 + rnd(-0.2,0.2);
			error <- (length(shape.points) != length(remove_duplicates(shape.points)) + 1);
		}

		save building type: shp to: "../../includes/map3D_190503/building_error.shp" attributes: ["height"::height, "error"::error];		
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

