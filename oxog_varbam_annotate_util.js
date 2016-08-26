function filterFileArray(str, inArr)
{
	var arr = [];
	for (var i = 0; i < inArr.length; i++)
	{
		if (inArr[i].basename.indexOf(str) >= 0)
		{
			// arr.push(inArr[i])
			// Return the first match.
			return inArr[i]
		}
	}
	return arr;
}
