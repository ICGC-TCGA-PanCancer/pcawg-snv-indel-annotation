function filterFileArray(str, inArr) {
	var arr = [];
	for (var i = 0; i < inArr.length; i++) {
		if (inArr[i].basename.indexOf(str) >= 0) {
			// Return the first match.
			return inArr[i]
		}
	}
	return arr;
}

function appendBam(str) {
	return str.concat(".bam")
}

function appendBai(str) {
	return str.concat(".bai")
}

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
function createArrayOfFilesForOxoG(in_data, vcfsForOxoG) {
	//TODO: Move this function to separate JS file.
	var vcfsToUse = []
	// Need to search through vcfsForOxoG (cleaned VCFs that have been zipped and index) and preprocess_vcfs/extractedSNVs to find VCFs
	// that match the names of those in in_data.inputs.associatedVCFs
	//
	var associatedVcfs = in_data.associatedVcfs
	for ( var i in associatedVcfs )
	{
		if ( associatedVcfs[i].indexOf(".snv") !== -1 )
		{
			for ( var j in vcfsForOxoG )
			{
				if ( vcfsForOxoG[j].basename.indexOf( associatedVcfs[i].replace(".vcf.gz","") ) !== -1 && /.*\.gz$/.test(vcfsForOxoG[j].basename))
				{
					vcfsToUse.push (  vcfsForOxoG[j]    )
				}
			}
		}
		if ( associatedVcfs[i].indexOf(".indel") !== -1 )
		{
			for ( var j in vcfsForOxoG )
			{
			    if ( vcfsForOxoG[j].basename.replace(".pass-filtered.cleaned.vcf.normalized.extracted-SNVs.vcf.gz","").indexOf( associatedVcfs[i].replace(".vcf.gz","") ) !== -1 && /.*\.gz$/.test(vcfsForOxoG[j].basename))
			    {
			        vcfsToUse.push (  vcfsForOxoG[j]    )
			    }
			}
		}
		//vcfsToUse.concat(extractedSnvs)
	}
	return vcfsToUse
}


function chooseINDELsForAnnotator(oxogVCFs, tumours_list)
{
	var vcfsToUse = [];
	var flattened_oxogs = flatten_nested_arrays(oxogVCFs);
	var associated_indels = tumours_list.associatedVcfs.filter( function(item)
		{
			return item.indexOf("indel") !== -1;
		});
	for (var i in associated_indels)
	{
		for (var j in flattened_oxogs)
		{
			//if ( flattened_oxogs[j].basename.indexOf(associated_indels[i].replace(".vcf.gz","")) !== -1 )
			{
				vcfsToUse.push(flattened_oxogs[j]);
			}
		}
	}
	return vcfsToUse;
}

function chooseVCFsForAnnotator(VCFs, associatedVcfs)
{
	var vcfsToUse = [];
	//this might be a nested array if it came from the OxoG output.
	var flattened_array = flatten_nested_arrays(VCFs);
	// var associated_vcfs = tumours_list.associatedVcfs.filter( function(item)
	// 	{
	// 		return item.indexOf("indel") !== -1;
	// 	});
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

function chooseMiniBamForAnnotator(tumourMinibams, tumours_record)
{
	// var minibamToUse
	for (var j in tumourMinibams )
	{
		// The minibam should be named the same as the regular bam, except for the "mini-" prefix.
		// This condition should only ever be satisfied once.
		if (tumourMinibams[j].basename.indexOf( tumours_record.bamFileName ) !== -1 )
		{
			return tumourMinibams[j]
		}
	}
	//return minibamToUse
	return undefined
}

function chooseSNVsForAnnotator(oxogVCFs, tumours_list)
{
	var vcfsToUse = []
	var flattened_oxogs = flatten_nested_arrays(oxogVCFs)
	var associated_snvs = tumours_list.associatedVcfs.filter( function(item)
		{
			return item.indexOf("snv") !== -1
		}
	)
	for (var i in associated_snvs)
	{
		for (var j in flattened_oxogs)
		{
			//if ( flattened_oxogs[j].basename.indexOf(associated_snvs[i].replace(".vcf.gz","")) !== -1 )
			{
				vcfsToUse.push(flattened_oxogs[j])
			}
		}
	}
	return vcfsToUse
}
