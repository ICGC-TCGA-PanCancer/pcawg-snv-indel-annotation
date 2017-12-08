
/**
 * Filters an array of files. Returns an array that only contains files that contain "indel" in their name.
 * @param inArr - the array.
 * @return a filtered array - it will only contain files whose names contain the string "indel".
 */
function filterForIndels(inArr)
{
	var arr = [];
	for (var i = 0; i < inArr.length ; i++)
	{
		if (inArr[i].basename.indexOf("indel") >= 0)
		{
			arr.push(inArr[i]);
		}
	}
	return arr;
}

/**
 * This function will filter an array of files and select only files that match
 * workflowName and vcfType.
 * @param workflowName - the name of the workflow to filter for.
 * @param vcfType - the type of VCF (snv, indel, etc...)
 * @param inArr - an array of files (File[]) to search through.
 * @return an array that has been filtered.
 */
function filterFor(workflowName, vcfType, inArr)
{
	var arr = [];
	for (var i = 0; i < inArr.length; i++)
	{
		if (typeof(inArr[i]) == "string") //("class" in inArr[i] && inArr[i].class == "File")
		{
			if (inArr[i].indexOf(workflowName) >= 0 && inArr[i].indexOf(vcfType) >= 0)
			{
				arr.push(inArr[i])
			}
		}
		else
		{
			if ("class" in inArr[i] && inArr[i].class == "File")
			{
				if (inArr[i].basename.indexOf(workflowName) >= 0 && inArr[i].basename.indexOf(vcfType) >= 0)
				{
					arr.push(inArr[i])
				}
			}
		}
	}
	return arr;
}
