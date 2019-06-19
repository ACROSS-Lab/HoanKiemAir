/**
* Name: clean_road_network
* Author: Patrick Taillandier
* Description: shows how GAMA can help to clean network data before using it to make agents move on it
* Tags: gis, shapefile, graph, clean
*/

model clean_road_network

global {
	//Shapefile of the roads
	file road_shapefile <- file("../../includes/PatrickFiles/roads_UTM48N.shp");
//	file building_shapefile <- file("../includes/PatrickFiles/buildings1925_UTM48N.shp");
	
	
	//Shape of the environment
	geometry shape <- envelope(road_shapefile);
				
	init {
		create road from: road_shapefile;
//		create building from: building_shapefile;
		
		//clean data, with the given options
		bool split_lines <- true ;
		float tolerance <- 3.0 ;
		bool keep_main_component <- false;
		list<geometry> clean_lines <- clean_network(road_shapefile.contents,tolerance,split_lines,keep_main_component) ;
		
		list<point> crossroads <- [];
		loop g over: clean_lines {
			add first(g.points) to: crossroads;
			add last(g.points) to: crossroads;
		}
		crossroads <- remove_duplicates(crossroads);
		
		// create crossroads 
		loop p over: crossroads {
			create crossroad {
				location <- p;
			}
		}
		
		//create road from the clean lines
		create road_modified from: clean_lines {
			list<road> r <- road where(each covers self);
			write "" + self + "Roads " + r;
			if(length(r) != 1) {
				color <-#red;
			} else {				
				name <- first(r).name;
				type <- first(r).type;
				oneway <- first(r).oneway;
				can_be_closed <- first(r).can_be_closed;				
			}
		}		
    }
    
    reflex save {
		save crossroad to: "../../includes/cleanedData/crossroads.shp" type: "shp";
		save road to: "../../includes/cleanedData/roads.shp" type: "shp"
			attributes: ["name"::name,"type"::type,"oneway"::oneway, "can_be_closed"::can_be_closed];    	
    }
}

species crossroad {}

//Species to represent the roads
species road {
	string type;
	int oneway;	
	bool can_be_closed;
	
	aspect default {
		draw shape color: #black;
		draw circle(20) at_location first(shape.points) color: #red;
		draw circle(20) at_location last(shape.points) color: #red;		
	}
}

species road_modified {
	string type;
	int oneway;
	rgb color <- #white;
	bool can_be_closed;	
	
	aspect default {
		draw shape color: color;
		draw circle(5) at_location first(shape.points) color: #red;
		draw circle(5) at_location last(shape.points) color: #red;		
	}
}

experiment clean_network type: gui {

	output {
		display network {
			//species road ;
			species road_modified;
		}
	}
}
