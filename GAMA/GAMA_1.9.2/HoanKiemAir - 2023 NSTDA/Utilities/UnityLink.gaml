/**
* Name: UnityLink
* Includes actions, attributes and species facilating the link with Unity. To be used with the GAMA-Unity-VR Package for Unity
* Author: Patrick Taillandier
* Tags: Unity, VR
*/

@no_experiment
model UnityLink


global skills: [network]{
	/***************************************************
	 *
	 * PARAMETERS ABOUT THE CONNECTION AND DATA SENT
	 * 
	 ***************************************************/
	 
	//Activate the unity connection; if activated, the model will wait for an connection from Unity to start
	bool connect_to_unity <- false;
	
	// connection port
	int port <- 8000;
	
	string end_message_symbol <- "&&&";
	
	//as all data (location, rotation) are send as int, number of decimal for the data
	int precision <- 10000;
	
	//possibility to add a delay after moving the player (in ms)
	float delay_after_mes <- 0.0;
	
	//allow to reduce the quantity of information sent to Unity - only the agents at a certain distance are sent
	float player_agent_perception_radius <- 0.0;
	
	//allow to not send to Unity agents that are to close (i.e. overlapping) 
	float player_agents_min_dist <- 0.0;
	
	//the list of agents to sent to Unity. It could be updated each simulation step
//	list<agent_to_send> agents_to_send;
	
	//the list of static geometries sent to Unity. Only sent once at the initialization of the connection 
	list<geometry> background_geoms;
	
	// for each geometry sent to Unity, the height of this one.
	list<int> background_geoms_heights;
	
	// for each geometry sent to Unity, does this one has a collider (i.e. a physical existence) ? 
	list<bool> background_geoms_colliders;
	
	// for each geometry sent to Unity, its name in unity 
	list<string> background_geoms_names;
	
	
	
	
	bool do_send_world <- true;
	/*************************************** 
	 *
	 * PARAMETERS ABOUT THE PLAYER
	 * 
	 ***************************************/

	//allow to create a player agent
	bool create_player <- true;

	//let the player moves in GAMA as it moves in Unity
	bool move_player_from_unity <-true;
	
	//does the player should has a physical exitence in Unity (i.e. cannot pass through specific geometries)
	bool use_physics_for_player <- true;
	
	//init location of the player in the environment - this information will be sent to Unity to move the player accordingly
	point location_init <- {50.0, 50.0};

	//player size - only used for displaying the player in GAMA
	float player_size_GAMA <- 3.0;
	
	//player rotation - only used for displaying the player in GAMA
	int rotation_player <- 90;

	

	/* 
	 * PRIVATE VARIABLES ONLY USED INTERNALLY
	 */
	
	//message send by Unity to tell GAMA that it is ready
	string READY <- "ready" const: true;

	// should GAMA receive information from Unity 
	bool receive_information <- true;
	
	// which message GAMA should wait before receiving infomation 
	string waiting_message <- nil;
	
	// the unity clienf 
	unknown unity_client;
	
	//does the Unity client has been initialized?
	bool initialized <- false;
	
	// the player agent
	default_player the_player;
	
	//has the player just moved?
	bool move_player_event <- false;
	
	//the last received position of the player ([x,y,rotation])
	list<int> player_position <- [];
	
	
	//creation of the player agent - can be overrided
	action init_player {
		create default_player  {
			the_player <- self;
			location <- location_init;
		}
	}
	
	//add background geometries from a list of geometries, their heights, their collider usage, their outline rendered usage 
	action add_background_data(list<geometry> geoms, float height, bool collider) {
		do  add_background_data_with_names(geoms, [],  height,collider) ;
	
	}
	//add background geometries from a list of geometries, their heights, their collider usage, their outline rendered usage 
	action add_background_data_with_names(list<geometry> geoms, list<string> names, float height, bool collider) {
		background_geoms <- background_geoms + geoms;
		loop times: length(geoms) {
			background_geoms_heights << height;
			background_geoms_colliders << collider;
		}
		
		background_geoms_names  <- background_geoms_names +  names;
	}
	
	//Wait for the connection of a unity client and send the paramters to the client
	action send_init_data {
		do connect protocol: "tcp_server" port: port raw: true with_name: "server" force_network_use: true;
		write "waiting for the client to send a connection confirmed message";
		loop while: !has_more_message() {
			do fetch_message_from_network;
		}
		loop while: has_more_message() {
			message s <- fetch_message();
			unity_client <- s.sender;
		}
		do send_parameters;
		if (delay_after_mes > 0.0) {
			do wait_for_message(READY);
		}
		loop while: !has_more_message() {
			do fetch_message_from_network;
		}
		loop while: has_more_message() {
			message s <- fetch_message();
		}
		write "connection established";
		
		if not empty(background_geoms) {
			do send_geometries(background_geoms, background_geoms_heights,  background_geoms_colliders, background_geoms_names, precision);
		}
//		if do_send_world {
//			do send_world;
//		}
//		
	}
	
	//send parameters to the unity client
	action send_parameters {
		map to_send;
		to_send <+ "precision"::precision;
		to_send <+ "world"::[world.shape.width * precision, world.shape.height * precision];
		to_send <+ "delay"::delay_after_mes;
		to_send <+ "physics"::use_physics_for_player;
		
		to_send <+ "position"::[int(location_init.x*precision), int(location_init.y*precision)];
		if unity_client = nil {
			write "no client to send to";
		} else {
			do send to: unity_client contents: as_json_string(to_send) + end_message_symbol;	
		}
	}
	
	action after_sending_background ;
	
	//send the background geometries to the Unity client
	action send_geometries(list<geometry> geoms, list<int> heights, list<bool> geometry_colliders, list<string> names, int precision_) {
		map to_send;
		list points <- [];
		
		loop g over: geoms {
			loop pt over:g.points {
				points <+ map("c"::[int(pt.x*precision_), int(pt.y*precision_)]);
			}
			points <+ map("c"::[]);
		}
		
		to_send <+ "points"::points;
		to_send <+ "heights"::heights;
		to_send <+ "hasColliders"::geometry_colliders;
		to_send <+ "names"::names;
		
		if unity_client = nil {
			write "no client to send to";
		} else {
			do send to: unity_client contents: as_json_string(to_send) + end_message_symbol;	
		}
		do after_sending_background;
	}
	
	//send the new position of the player to Unity (used to teleport the player from GAMA) 
	action send_player_position {
		if (!connect_to_unity) {
			return;
		}
		player_position <- [int(the_player.location.x * precision), int(the_player.location.y * precision)];
		if (delay_after_mes > 0.0) {
			do wait_for_message(READY);
		}
	} 
	
	//set the message to wait
	action wait_for_message(string mes) {
		receive_information <- false;
		waiting_message <- mes;
	}
	
	
	//message that will be sent concerning the agents
//	list<map> message_agents(container<agent_to_send> ags_input) {
//		list<map> ags;
//		ask ags_input {
//			ags <+ to_array(precision);
//		}
//		return ags;
//	}
//	
//	//filter the agents to send according to the player_agent_perception_radius - can be overrided 
//	list<agent_to_send> filter_distance(list<agent_to_send> ags) {
//		ask the_player {
//			ags <- ags at_distance player_agent_perception_radius;
//		}
//		return ags;
//		
//	}

	//filter the agents to send to avoid agents too close to each other - can be overrided 
//	list<agent_to_send> filter_overlapping(list<agent_to_send> ags) {
//		list<agent_to_send> to_remove ;
//		ask ags {
//			if not(self in to_remove) {
//				to_remove <- to_remove + ((ags at_distance player_agents_min_dist));
//			}  
//		}
//		return ags - to_remove;	
//	}
	
	
	//send the current state of the world to the Unity Client
//	action send_world {
//		map to_send;
//		list message_ags <- [];
//		list<agent_to_send> ags <- copy(agents_to_send where not dead(each));
//			
//		if (the_player != nil) {
//			if (player_agent_perception_radius > 0) {
//				ags <- filter_distance(ags);
//			}
//			if (player_agents_min_dist > 0 ){
//				ags <- filter_overlapping(ags);
//			} 
//		}
//		message_ags<-message_agents(ags) ;
//			
//		//to_send <+ "date"::"" + current_date;
//		to_send <+ "agents"::message_ags;
//		to_send <+ "position"::player_position;
//		player_position <- [];
//		
//		if unity_client = nil {
//			write "no client to send to";
//		} else {
//			string mes <- as_json_string(to_send);
//			do send to: unity_client contents: (mes + end_message_symbol) ;	
//		}
//		do after_sending_world;
//	}
	
	action after_sending_world {
		//float t <- machine_time + 3000;
		//loop while: (machine_time < t) {
			
		//}
	}
	
	point new_player_location(point loc) {
		return loc;
	}
	
	
	//if necessary, move the player to its new location
	reflex move_player when: move_player_event{
		the_player.location <- new_player_location(#user_location);
		do send_player_position;
		move_player_event <- false;
	}

	//send the new world situtation to the Unity client
	reflex send_update_to_unity when: connect_to_unity {
		if !initialized {
			if create_player {
				do init_player;
			}
			do send_init_data;
			initialized <- true;
		}
//		if do_send_world {
//			do send_world;
//		}
		
	}
	
	action manage_message_from_unity(message s) {
		//write "s: " + s.contents;
		if (waiting_message != nil and string(s.contents) = waiting_message) {
	    	receive_information <- true;
	    } else if  the_player != nil and move_player_from_unity and receive_information {
	    	let answer <- map(s.contents);
			list<int> position <- answer["position"];
			if position != nil and length(position) = 2  {
				the_player.rotation <- int(int(answer["rotation"])/precision + rotation_player);
				the_player.location <- {position[0]/precision, position[1]/precision};
				the_player.to_display <- true;
			}
		}
	}
	//received informtation about the player from Unity
	reflex messages_from_unity when:  has_more_message() {
		loop while: has_more_message() {
			message s <- fetch_message();
			do manage_message_from_unity(s);
		}
	}	
}


//Defaut species for the player
species default_player {
	rgb color <- #red;
	int rotation;
	bool to_display <- not move_player_from_unity;
	float cone_distance <- 10.0 * player_size_GAMA;
	int cone_amplitude <- 90;
	
	aspect default {
		if to_display {
			if file_exists("../images/headset.png")  {
				draw image("../images/headset.png")  size: {player_size_GAMA, player_size_GAMA} at: location + {0, 0, 5} rotate: rotation - 90;
			
			} else {
				draw circle(player_size_GAMA/2.0) at: location + {0, 0, 5} color: color rotate: rotation - 90;
			
			}
			draw cone(rotation - cone_amplitude/2,rotation + cone_amplitude/2) inter circle(cone_distance) translated_by ({cos(rotation), sin(rotation)} * (- player_size_GAMA/4.0)) translated_by {0,0,4.9} color: rgb(#mediumpurple, 0.75);
		
		}			
	}
}

//Default species for the agent to be send to the Unity Client
//species agent_to_send skills: [moving]{
//	int index_species <- 0;
//	
//	point loc_to_send {return location;}
//	map to_array(int precision_) {
//		point loc <- loc_to_send();
//		return map("v"::[index_species, int(self), int(loc.x*precision_), int(loc.y*precision_), int(heading*precision_)]);
//	}
//}

//Default xp with the possibility to move the player
experiment vr_xp virtual: true  {
	action move_player {
		move_player_event <- true;
	}
}

