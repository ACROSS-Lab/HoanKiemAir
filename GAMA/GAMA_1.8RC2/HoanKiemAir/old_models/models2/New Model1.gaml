/***
* Name: NewModel1
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NewModel1

/* Insert your model definition here */

global {
	init {
		write sample(#infinity * 0);
		write sample(#infinity * #infinity);
		
	}
}

experiment exp type: gui {

	
	// Define parameters here if necessary
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
	// Define inspectors, browsers and displays here
	
	// inspect one_or_several_agents;
	//
	// display "My display" { 
	//		species one_species;
	//		species another_species;
	// 		grid a_grid;
	// 		...
	// }

	}
}