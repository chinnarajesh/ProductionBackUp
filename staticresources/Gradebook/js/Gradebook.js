	var j$ = jQuery.noConflict();
	var gradeArray = [];
	var stringlist;
	var lockArray = [];
	var closepop = false;
	var locklist;
	var gcommentid;
	var bShowComment = false;
	var preEl ;
	var preTable;
	var orgClass;
	var commentToggleId;

	j$(document).ready(function(){j$('.comment').dialog({ autoOpen: false, modal: true, show: 'blind'});});
	
	window.onbeforeunload = function(){if(closepop==true){return "Please save your work!";}}
	    
	function toggleComments(comingFromSGComments){
		if(comingFromSGComments) {
			bShowComment = true;
		}
		else {
			bShowComment = !bShowComment;		
	    }
		if (j$('.comment-icon').css('display')=='none') {
	    	j$('.comment-icon').css('display','inline');
	        j$('.comment-legend').css('display','block');
	    }
	    else{
	        j$('.comment-icon').css('display','none');
	        j$('.comment-legend').css('display','none');
	    }    
	    if (bShowComment){
	        j$('#hideCommentText').html('Hide Comments');
	    }
	    else {
	        j$('#hideCommentText').html('Show Comments/Drop Grades');
	    }
	}
	 
/*	function HighLightTR(el){        
		if(typeof(preEl)!='undefined'){
	    	preEl.setAttribute("class", orgClass);
	        preTable.rows[preEl.rowIndex].setAttribute("class", orgClass);
	    }
	    orgClass = el.getAttribute("class");
	    el.setAttribute("class", "clicked");
	    var theTable = document.getElementById('gradebook-results');        
	    theTable.rows[el.rowIndex].setAttribute("class", "clicked");        
	    preTable = theTable;
	    preEl = el;
		$('tbody tr').removeClass('clicked');
		$(el).toggleClass('clicked');
	}*/
	    
	function toggleGrade(){
		if(j$('.numGrade').css('display')=='none'){
	    	j$('.numGrade').show();
	        j$('.letGrade').hide();
	    }
	    else{
	    	j$('.numGrade').hide();
	        j$('.letGrade').show();
	    }
	}
	    
	
	function handleCommentQuery(result, event){
		if(event.type == 'exception') {
			errorJS(event.message);
		} 
		else {
			var commentgrade = result;
			if(window.location.href.indexOf('schoolforce')!=-1)
        	{
				j$('.comment').find('.commentText').val(commentgrade.SchoolForce__Comment__c);       
				j$('.comment').find('.commentPublish').prop('checked', commentgrade.SchoolForce__Publish_Comment__c);
				j$('.comment').find('.exclude').prop('checked',commentgrade.SchoolForce__exclude_From_Section_Grade__c);
				j$('.comment').find('.enteredGrade').val(commentgrade.SchoolForce__Entered_Grade__c);
				j$('.comment').find('.include').prop('checked', commentgrade.SchoolForce__Include_In_Standard_Grade__c);
				if(!commentgrade.SchoolForce__Grade_With_Standard__c)
				{
					j$('.optionalStandardGrade').hide();
				}
			}
			else {
				j$('.comment').find('.commentText').val(commentgrade.Comment__c);       
				j$('.comment').find('.commentPublish').prop('checked', commentgrade.Publish_Comment__c);
				j$('.comment').find('.exclude').prop('checked',commentgrade.exclude_From_Section_Grade__c);
				j$('.comment').find('.enteredGrade').val(commentgrade.Entered_Grade__c);
				j$('.comment').find('.include').prop('checked', commentgrade.Include_In_Standard_Grade__c);
				if(!commentgrade.Grade_With_Standard__c)
				{
					j$('.optionalStandardGrade').hide();
				}			
			}
			j$('.comment').dialog("open");
		}
	}
	
	

	

	function handleComments(result, event) {
		if(event.type == 'exception') {
			errorJS(event.message);
		} 
		else {
			j$('.comment').dialog("close");
			var commentgrade = result;
	        if(commentgrade.Comment__c!=""){
	            j$('a#' + commentgrade.Id).css('background-position','-33px -16px');
	        }
	        else{
	            j$('a#' + commentgrade.Id).css('background-position','-49px 0px');
	        }
		}
	}

	
	
/* SEE ABOVE
	function handleComments(result, event) {
		if(event.type == 'exception') {
			errorJS(event.message);
		} 
		else {
			j$('.comment').dialog("close");
			var commentgrade = result;
	        if(commentgrade.Comment__c!=""){
	            j$('.bubble_b'+gcommentid).css('display','none');
	            j$('.bubble_g'+gcommentid).css('display','inline');
	        }
	        else{
	            j$('.bubble_g'+gcommentid).css('display','none');
	            j$('.bubble_b'+gcommentid).css('display','inline');
	        }
		}
	}
*/
	
	function addtoupdatelist(gid, gval){
		gradeArray.push(gid+";"+gval);
		j$('#highlight_'+gid).next().css({'border-style':'solid','border-color':'#999', 'border-width':'1px'});
	}
	
	function addtoupdatelist(gid, gval, gDropped){
		gradeArray.push(gid+";"+gval+";"+gDropped);
		j$('#highlight_'+gid).next().css({'border-style':'solid','border-color':'#999', 'border-width':'1px'});
	}

	

	
			
			
	function handleUpdatesCheck2(result, event) {
			if(event.type == 'exception') {
				errorJS(event.message);
			} 
			else {		
				if(result.length>0){
					var splitPos = 0;
					var splitNeeded = false;		
					
					for(var s in result){
					
						if(result[s] == '::'){
							splitNeeded = true;
							break;
						}
						else{
							splitPos++;
						}
					}
					
					if(splitPos>0 && splitNeeded == true){
						alert("Please enter valid values for the highlighted grades.");
						for(var temp in result.slice(0,splitPos)){
							j$('#highlight_'+result[temp]).next().css({'border-style':'solid','border-color':'red', 'border-width':'3px'}); 
							j$('#highlight_'+result[temp]).next().attr('title','Invalid grade for this scale'); 
						}
					}
					else{
					var r=confirm("You entered grades on the following assignment(s) that are outside the Possible Points range:"+result.slice(splitPos+1,result.length)+"  Click Ok to submit anyway.  Click Cancel to go back and fix your grades.")
					if (r==true)
				  	{
					  showProgressBar('Submitting Grades');
					  updatelist();
				  	}
					else{			
						}
					}
				}
				else{
					showProgressBar('Submitting Grades');
					updatelist();
				}
			}
	}
	

	
	function handleUpdatesCheck2_SO(result, event) {
				if(event.type == 'exception') {
				errorJS(event.message);
			} 
			else {		
				if(result.length>0){
					var splitPos = 0;
					var splitNeeded = false;

					for(var s in result){
					
						if(result[s] == '::'){
							splitNeeded = true;
							break;
						}
						else{
							splitPos++;
							
						}
					}

					if(splitPos>0 && splitNeeded == true){
						alert("Please enter valid values for the highlighted grades.");
						for(var temp in result.slice(0,splitPos)){
							j$('#highlight_'+result[temp]).next().css({'border-style':'solid','border-color':'red', 'border-width':'3px'}); 
							j$('#highlight_'+result[temp]).next().attr('title','Invalid grade for this scale'); 
						}
					}

					else{
					var r=confirm("You entered grades on the following assignment(s) that are outside the Possible Points range:"+result.slice(splitPos+1,result.length)+"  Click Ok to submit anyway.  Click Cancel to go back and fix your grades.")
					if (r==true)
				  	{
					  showProgressBar('Submitting Grades');
					  updatelist_SO();
				  	}
					else{			
						}
					}
				}
				else{
					showProgressBar('Submitting Grades');
					updatelist_SO();
				}
			}
	}
	
	
	function handleUpdatesCheck(result, event) {
		if(event.type == 'exception') {
			errorJS(event.message);
		} 
		else if(result.length>0){
			alert("Your grades did not save.  Please fix the grades that are marked by a red border.");
			for (var temp in result){ 
				j$('#highlight_'+result[temp]).next().css({'border-style':'solid','border-color':'red', 'border-width':'3px'}); 
				j$('#highlight_'+result[temp]).next().attr('title','Invalid grade for this scale'); 
			}
			setTimeout('hideProgressBar()',1000);
		}
		else {
			goJS();
			gradeArray = [];
			closepop=false;
		}
	}
	
	function handleUpdatesCheck_SO(result, event) {
		if(event.type == 'exception') {
			errorJS(event.message);
		}
		else if(result.length>0){
			alert("Your grades did not save.  Please fix the grades that are marked by a red border.");
			for (var temp in result){ 
				j$('#highlight_'+result[temp]).next().css({'border-style':'solid','border-color':'red', 'border-width':'3px'}); 
				j$('#highlight_'+result[temp]).next().attr('title','Invalid grade for this scale'); 
			}
			setTimeout('hideProgressBar()',1000);
		} 
		else {
			goJS();
			gradeArray = [];
			closepop=false;
		}
	}
	
	
	function copydown(link){
			//console.log(link);
			closepop=true;
			var copy = j$(link).attr('copycode');
			//console.log(copy);
	  		var copytext = j$(link).val();      		
	   		j$('#gradebook-results').find('td[copycode="'+copy+'"]').find('.tabCol').val(copytext);
	   		j$('#gradebook-results').find('td[copycode="'+copy+'"]').find('.tabCol').prev('.copydownupdate').each(function(i){addtoupdatelist(j$(this).attr('value'),copytext);});
	}
	
	
	function handleLockUpdate(result, event) {
		if(event.type == 'exception') {
			errorJS(event.message);
		} 
		else {
			goJS();
			lockArray = [];
		}
	}
	    