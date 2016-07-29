
function filterForIndels(inArr)
{
	var arr = [];
	for (var i = 0; i < inArr.length ; i++)
	{
		if (inArr[i].indexOf("indel") > 0)
		{
			arr.push(inArr[i]);
		}
	}
	return arr;
}
