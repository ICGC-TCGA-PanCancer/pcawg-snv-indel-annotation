
function flatten_nested_arrays(array_of_arrays)
{
	var flattened_array = []
	for (var i in array_of_arrays)
	{
		var item = array_of_arrays[i]
		if (item instanceof Array)
		{
            // console.log("found subarray")
			// recursively flatten subarrays.
			var flattened_sub_array = flatten_nested_arrays(item)
			for (var k in flattened_sub_array)
			{
                flattened_array.push(flattened_sub_array[k])
			}
		}
		else
		{
			flattened_array.push(item)
		}
	}
	return flattened_array
}

function chooseVCFsForAnnotator(VCFs, associatedVcfs)
{
	var vcfsToUse = [];
	//this might be a nested array if it came from the OxoG output.
	var flattened_array = flatten_nested_arrays(VCFs);

	var associated_vcfs = associatedVcfs
	for (var i in associated_vcfs)
	{
		for (var j in flattened_array)
		{
			if ( flattened_array[j].basename.indexOf(associated_vcfs[i].replace(".vcf.gz","")) !== -1 )
			{
				//console.log("OK "+flattened_array[j].basename + " was in "+associated_vcfs[i] +" so it will be annotated!")
				vcfsToUse.push( flattened_array[j] );
			}
			else
			{
				//console.log("Not OK "+ flattened_array[j].basename + " was NOT in "+associated_vcfs[i] +" so it will NOT be annotated!")
			}
		}
	}
	return vcfsToUse;
}

function chooseBamForAnnotator(tumourBams, tumours_record)
{
	// var BamToUse
	for (var j in tumourBams )
	{
		// The Bam should be named the same as the regular bam, except for the "mini-" prefix.
		// This condition should only ever be satisfied once.
		if (tumourBams[j].basename.indexOf( tumours_record.bamFileName ) !== -1 )
		{
			return tumourBams[j]
		}
	}
	//return BamToUse
	return undefined
}
