
function filterForIndels(inArr)
{
	var arr = [];
	for (var i = 0; i < inArr.length ; i++)
	{
		if (inArr[i].basename.indexOf("indel") > 0)
		{
			arr.push(inArr[i]);
		}
	}
	return arr;
}

function filterFor(workflowName, vcfType, inArr)
{
	var arr = [];
	for (var i = 0; i < inArr.length; i++)
	{
		if (inArr[i].basename.indexOf(workflowName) > 0 && inArr[i].basename.indexOf(vcfType) > 0)
		{
			arr.push(inArr[i])
		}
	}
	return arr;
}
