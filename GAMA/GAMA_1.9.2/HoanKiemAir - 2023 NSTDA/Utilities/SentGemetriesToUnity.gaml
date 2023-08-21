/**
* Name: sendGeometriesToUnity
* Author: Patrick Taillandier
* Description: A simple model allow to send geometries to Unity. To be used with the "Load geometries from GAMA"
* Tags: gis, shapefile, unity, geometry, 
*/
model sendGeometriesToUnity

import "../models/UnityLink.gaml"


global {
	
	
	//Shapefile of the bound
	shape_file bounds_shape_file <- shape_file("../data/buildings.shp");

	//Shapefile of the buildings
	file building_shapefile <- file("../data/buildings.shp");
	//Shapefile of the roads
	file road_shapefile <- file("../data/roads.shp") ;
	//Shape of the environment

	bool create_player <- false;
	bool do_send_world <- false;
	
	geometry shape <- envelope(bounds_shape_file) ;
	
	
	float lane_width <- 1.0;
	
	
	init {
		//Initialization of the building using the shapefile of buildings
		create building from: building_shapefile;

		//Initialization of the road using the shapefile of roads
		create road from: road_shapefile {
			float dist <- (building closest_to self) distance_to self;
			width <- min(5.0, max(2.0,  dist - 0.5));
		}

		ask road {
			agent ag <- (building ) closest_to self;
			float dist <- ag = nil ? 8.0 : max(min( ag distance_to self - 5.0, 8.0), 2.0);
			num_lanes <- int(dist / lane_width);
		}
		//do add_background_data_with_names(building collect each.shape,  building collect each.name, 10.0, true);
		do add_background_data(road collect (each.shape buffer (each.num_lanes * lane_width)), 0.2, false);
		
	}
	
	action after_sending_background {
		do pause;
	}
}

	//Species to represent the buildings
species building {

	aspect default {
		draw shape color: darker(#darkgray).darker depth: rnd(10) + 2;
	}

}
//Species to represent the roads
species road {
	int num_lanes;
	float width;
	aspect default {
		draw (shape + width) color: #white;
	}

}

experiment sendGeometriesToUnity_batch type: batch until: cycle = 10;

experiment sendGeometriesToUnity type: gui autorun: true  {
	float minimum_cycle_duration <- 0.1;
	output{
		display carte type: 3d axes: false background: #black {
			species road refresh: false;
			species building refresh: false;
		}

	}

}
