/***
* Name: mainroadcells
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model main

import "agents/traffic.gaml"
import "agents/pollution_road.gaml"
import "misc/remotegui.gaml"
import "misc/utils.gaml"
import "misc/visualization.gaml"

global {
//	float pollutant_decay_rate <- 0.7;
	float step <- 16#s;
	
	geometry shape <- envelope(roads_shape_file);
	
	init {
		do init_traffic;
		create road_cell from: road_cells_shape_file {
			affected_buildings <- building at_distance 50#m;
			neighbors <- road_cell at_distance 1#cm;
		}
	}
	
	reflex produce_pollutant when: false {
		// Absorb pollutants emitted by vehicles
		ask building parallel: true {
			aqi <- 0.0;
		}
		ask road_cell {
			float start <- machine_time;
			list<vehicle> vehicles_in_cell <- vehicle inside self;
			loop v over: vehicles_in_cell {
				if (is_number(v.real_speed)) {
					float dist_traveled <- v.real_speed * step / 1000;
	
					co <- co + dist_traveled * EMISSION_FACTOR[v.type]["CO"] / cell_volume;
					nox <- nox + dist_traveled * EMISSION_FACTOR[v.type]["NOx"] / cell_volume;
					so2 <- so2 + dist_traveled * EMISSION_FACTOR[v.type]["SO2"] / cell_volume;
				    pm <- pm + dist_traveled * EMISSION_FACTOR[v.type]["PM"] / cell_volume;
				}
			}
			time_absorb_pollutants <- time_absorb_pollutants + (machine_time - start);
			// Diffuse pollutants to neighbor cells
			start <- machine_time;
			ask neighbors {
				self.co <- self.co + pollutant_diffusion * myself.co;
				self.nox <- self.nox + pollutant_diffusion * myself.nox;
				self.so2 <- self.so2 + pollutant_diffusion * myself.so2;
				self.pm <- self.pm + pollutant_diffusion * myself.pm;
			}
			co <- co * (1 - pollutant_diffusion * length(neighbors));
			nox <- nox * (1 - pollutant_diffusion * length(neighbors));
			so2 <- so2 * (1 - pollutant_diffusion * length(neighbors));
			pm <- pm * (1 - pollutant_diffusion * length(neighbors));
			// Decay pollutants
			co <- pollutant_decay_rate * co;
			nox <- pollutant_decay_rate * nox;
			so2 <- pollutant_decay_rate * so2;
			pm <- pollutant_decay_rate * pm;
			time_diffuse_pollutants <- time_diffuse_pollutants + (machine_time - start);
			
			// Update the AQI for buildings
			list<building> buildings <- list<building>(self.affected_buildings);
			ask buildings {
				self.aqi <- self.aqi + myself.aqi;
			}
		}
	}
	
	reflex calculate_aqi when: every(refreshing_rate_plot) {
		 float aqi <- max(road_cell accumulate each.aqi);
		 ask line_graph_aqi {
		 	do update(aqi);
		 }
	}
}

species scheduler schedules: intersection + road + vehicle + road_cell {}

experiment exp {
	parameter "Number of cars" var: n_cars <- 700 min: 0 max: 700;
	parameter "Number of motorbikes" var: n_motorbikes <- 2000 min: 0 max: 2000;
	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
	parameter "Display mode" var: display_mode <- 0 min: 0 max: 1;
	parameter "Refreshing time plot" var: refreshing_rate_plot init: 2#mn min:1#mn max: 1#h;
	
	output {
		display main type: opengl background: #black {
			species vehicle;
			species intersection;
			species road;
//			species building;
			species progress_bar;
			species line_graph_aqi;
		}
	}
}