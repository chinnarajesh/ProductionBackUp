function gradebookResultsLoad(){
	/* Code to set the width of the table dynamically */
	var oTable = document.getElementById('gradebookTable'); // get the Gradebook Table
	var cellsCount = -1; // variable to calculate the no. of assignment columns in the Gradebook Table
	var assignmentWidth = 0;
	var tableWidth;
	// Iterate through any one row (should not be the first 4 rows) of the table to find out the no. of columns
	for (var i = oTable.rows.length-1, row; row = oTable.rows[i]; i++) {
		for (var j = 0, col; col = row.cells[j]; j++) {
			cellsCount++;
		}  
		break;
	}
					
	// Each assignment grade column will have a width of 85 px
	assignmentWidth = cellsCount*85;
	// 322 is the width of the first column plus scrollbar
	assignmentWidth += 322;
	// if total width if greater than 1010, set the width as 1010
	if(assignmentWidth>1010)
	{
		assignmentWidth = 1010;
	}
					
	tableWidth = assignmentWidth+'';
	/* End of Code for dynamic width */
					
	j$('#gradebook-results table').fixedHeaderTable({
		height: '530',
		width: tableWidth,
		altClass: 'odd',
		fixedColumns: 1,
		themeClass: 'gradebook',
	});
	
					
	j$('#toggle-comments').click(function(){ 
		j$('.comment-icon').toggleClass('comment-icon-hidden');
	});
	

	
	
}
