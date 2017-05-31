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

function createArrayOfFilesForOxoG(inputs) {
	//TODO: Move this function to separate JS file.
	var vcfsToUse = []
	// Need to search through vcfsForOxoG (cleaned VCFs that have been zipped and index) and preprocess_vcfs/extractedSNVs to find VCFs
	// that match the names of those in in_data.inputs.associatedVCFs
	//
	var associatedVcfs = inputs.in_data.associatedVcfs
	for (var i in associatedVcfs) {
		if (associatedVcfs[i].indexOf(".snv") !== -1) {
			// Loop through the VCFs that have been prepped for OxoG - check that they should be
			// added to vcfsToUse - if their filename is in the current tumour's list of associated VCFs,
			// then add it to vcfsToUse
			for (var j in inputs.vcfsForOxoG) {
				if (inputs.vcfsForOxoG[j].basename.indexOf(associatedVcfs[i].replace(".vcf.gz", "")) !== -1 && /.*\.gz$/.test(inputs.vcfsForOxoG[j].basename)) {
					vcfsToUse.push(inputs.vcfsForOxoG[j])
				}
			}
			// Now also do same for the SNVs extracted from INDELs.
			for (var j in inputs.extractedSnvs) {
				if (inputs.extractedSnvs[j].basename.indexOf(associatedVcfs[i].replace(".vcf.gz", "")) !== -1 && /.*\.gz$/.test(inputs.extractedSnvs[j].basename)) {
					vcfsToUse.push(inputs.extractedSnvs[j])
				}
			}
		}
	}
	return vcfsToUse
}


function getListOfVcfsForAnnotator(inputs)
{
	var vcfsToUse = [];
	//return inputs.oxogVCFs[0]
	var flattened_oxogs = flatten_nested_arrays(inputs.oxogVCFs);

	var associated_indels = inputs.tumours_list.associatedVcfs.filter( function(item)
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
