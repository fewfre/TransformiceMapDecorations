<?php
require_once 'utils.php';
define('URL_TO_CHECK_IF_SCRIPT_HAS_ACCESS_TO_ASSETS', "http://www.transformice.com/images/x_bibliotheques/x_pictos_editeur.swf");

setProgress('starting');

// Check if Atelier801 server can be accessed
$isA801ServerOnline = fetchHeadersOnly(URL_TO_CHECK_IF_SCRIPT_HAS_ACCESS_TO_ASSETS);
if(!$isA801ServerOnline['exists']) {
	setProgress('error', [ 'message' => "Update script cannot currently access the Atelier 801 servers - it may either be down, or script might be blocked/timed out" ]);
	exit;
}

////////////////////////////////////
// Core Logic
////////////////////////////////////

// Basic Resources

list($resources, $external) = updateBasicResources();

setProgress('updating');
$json = getConfigJson();
$json["packs"]["items"] = $resources;
$json["packs_external"] = $external;
saveConfigJson($json);

// Finished

setProgress('completed');
echo "Update Successful!";

sleep(10);
setProgress('idle');

////////////////////////////////////
// Update Functions
////////////////////////////////////

function updateBasicResources() {
	$resources = array();
	$external = array();

	// Normal resources
	$resources_base = array("x_pictos_editeur");
	foreach ($resources_base as $filebase) {
		// for ($i = 1; $i <= 8; $i++) {
			// setProgress('updating', [ 'message'=>"Resource: $filebase", 'value'=>$i, 'max'=>8 ]);
			// $filename = $i==1 && $filebase != "costume" ? "{$filebase}.swf" : "{$filebase}{$i}.swf";
			
			setProgress('updating', [ 'message'=>"Resource: $filebase" ]);
			$filename = "{$filebase}.swf";
			$url = "http://www.transformice.com/images/x_bibliotheques/$filename";
			$file = "../$filename";
			downloadFileIfNewer($url, $file);
			
			// Check local file so that if there's a load issue the update script still uses the current saved version
			if(file_exists($file)) {
				$resources[] = $filename;
				$external[] = $url;
			}
		// }
	}
	
	return [$resources, $external];
}