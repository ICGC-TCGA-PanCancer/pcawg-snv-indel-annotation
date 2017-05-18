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

function flatten_nested_arrays(inputs)
{
	var flattened_array = []
	for (var i in inputs.array_of_arrays)
	{
		for (var j in inputs.array_of_arrays[i])
		{
			flattened_array.push( inputs.array_of_arrays[j])
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
