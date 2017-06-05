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
		if (item.isArray)
		{
			// recursively flatten subarrays.
			flattened_array = flattened_array.concat(flatten_nested_arrays(item))
		}
		else
		{
			flattened_array.push(item)
		}
	}
	return flattened_array
}

function createArrayOfFilesForOxoG(in_data, vcfsForOxoG, extractedSnvs) {
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
			// for ( var j in inputs.extractedSnvs )
			// {
			//     if ( inputs.extractedSnvs[j].basename.replace(".pass-filtered.cleaned.vcf.normalized.extracted-SNVs.vcf.gz","").indexOf( associatedVcfs[i].replace(".vcf.gz","") ) !== -1 && /.*\.gz$/.test(inputs.extractedSnvs[j].basename))
			//     {
			//         vcfsToUse.push (  inputs.extractedSnvs[j]    )
			//     }
			// }
		}
		vcfsToUse.concat(extractedSnvs)
	}
	return vcfsToUse
}


function chooseINDELsForAnnotator(oxogVCFs, tumours_list)
{
	var vcfsToUse = [];
	//return inputs.oxogVCFs[0]
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

function chooseMiniBamsForAnnotator(tumourMinibams, tumours_list)
{
	// var minibamToUse
	for (var j in tumourMinibams )
	{
		// The minibam should be named the same as the regular bam, except for the "mini-" prefix.
		// This condition should only ever be satisfied once.
		if (tumourMinibams[j].basename.indexOf( tumours_list.bamFileName ) !== -1 )
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
