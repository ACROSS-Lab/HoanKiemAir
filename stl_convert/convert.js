var fs = require('fs');
var shp2stl = require('shp2stl');

var input_path = process.argv[2];
var output_path = process.argv[3];

shp2stl.shp2stl(input_path,
	{
		width: 1110, //in STL arbitrary units, but typically 3D printers use mm
		height: 25,
		extraBaseHeight: 0,
		extrudeBy: "height",
		simplification: 0,
		
		binary: true,
		cutoutHoles: false,
		verbose: true,
		extrusionMode: 'straight'
	},
	function(err, stl) {
		fs.writeFileSync(output_path,  stl);
	}
);
