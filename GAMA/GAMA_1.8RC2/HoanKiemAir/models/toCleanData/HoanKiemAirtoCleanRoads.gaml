
model NewModel

global {

	shape_file roads_shape_file <- shape_file("../../includes/cleanedData/roads.shp");
	shape_file coupe_shape_file <- shape_file("../../includes/cleanedData/coupe.shp");
	shape_file buildings_shape_file <- shape_file("../../includes/cleanedData/buildingsCleaned.shp");
	
//	shape_file crossroads_shape_file <- shape_file("../includes/QGIS/crossroads.shp");
	
	geometry shape <- envelope(roads_shape_file);
//	geometry shape <- envelope(buildings_shape_file);

	map<string,rgb> col <- map(['footway'::#green,'residential'::#blue,'primary'::#orange,'secondary'::#yellow,'tertiary'::#indigo,'primary_link'::#black,'unclassified'::#black,'service'::#black,'living_street'::#black,'path'::#black,'secondary_link'::#black,'trunk'::#black,'pedestrian'::#darkgreen,'steps'::#black]);
	
	init {
		create road from: roads_shape_file {}
		create building from: buildings_shape_file;
//		create crossroad from: crossroads_shape_file;
		create coupe from: coupe_shape_file;
		
		write length(building);
		write "" + length(building where(each overlaps first(coupe)));
		
//		ask (building - (building where(each overlaps first(coupe))) ) {do die;}
	}

//	user_command "Kill buildings" {
//		geometry coupe <- polygon(first(coupe_shape_file.contents));
//		ask building - (building where (each covers coupe)) {do die;}
//	}

	user_command "Save buildings" {
		save building to:"../../includes/cleanedData/buildingsCleaned.shp" type: "shp";
	}

	user_command "Save roads" {
		save road to: "../../includes/cleanedData/roads.shp" type: "shp"
			attributes: ["name"::name,"type"::type,"oneway"::oneway, "close"::close];    	
	}

}

species coupe {}

species road {
	string type;
	int oneway;
	bool close <- false;
	
	aspect default {
		draw shape color: #white;
	}
	aspect lines {
		draw shape+10 color: (col[type]);
		draw shape color: (oneway = 0)? #blue : #red;
		draw circle(10) at_location first(shape.points) color: #red;
		draw circle(10) at_location last(shape.points) color: #red;
		
	}	
	
	aspect canBeClose {
		draw shape color: (close )? #blue : #red;
	}	
}

species building {
	int height <- 20 + rnd(10);
	aspect default {
		draw shape color: #grey border: #darkgrey depth: height;
	}
}


experiment exp {
	output {
		display d type: opengl background: #grey {
		//	grid pollutant_grid lines: #black;
//			species coupe;
//			species building;
	//		species road aspect: lines;
			species road aspect: canBeClose;
		}
	}
}