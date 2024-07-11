var j$ = jQuery.noConflict();
var originalSize;
					var originalUi;
					var originalTop;
		var bHasError = false;
		
		 function validateTime(input) {
    return Date.parseExact(input, [
            "H:m",
            "h:mt",
            "h:m t",
            "ht","h t"]) != null ||
        Date.parseExact(input, [
            "h:mtt",
            "h:m tt",
            "htt","h tt"]) != null;
};
		 
		 
		 function refreshAgendaJs() {
			j$( ".agendaRow" ).each(function() {
					var theMaxHeight =j$(this).attr('maxHeight');
					j$(this).resizable({
						handles: 'se, ne', 
						container: '#container', 
						minWidth:600, 
						maxWidth:600,
						maxHeight:theMaxHeight,
						start: function(event, ui) {
							originalSize =j$(ui).size();
						},
						resize: function(event, ui) {
							j$(this).find('#cellHeight').html(j$(event.target).height());
						},
						stop: function(event, ui) {
							originalTop = j$(ui.originalPosition.top);
							originalSize = JSON.stringify(ui.originalSize.height);
							originalUi = ui;
							console.log('ui obj:');
							console.log(ui);
							var alertMsg = '';
							var newHeight = ui.size.height;
							//if this variable is a string, user dragged farther than allowed
							//the string is the farthest that the section can be dragged before overlapping another section
							if(typeof newHeight == "string"){
								alertMsg += 'Sections may not overlap.  The new end time has been adjusted.\n\n';
								newHeight = parseInt(newHeight);
							}
							var oldHeight = ui.originalSize.height;
							var deltaHeight = newHeight-oldHeight;
							
							var newTop = ui.position.top;
							//if this variable is a string, user dragged farther than allowed
							//the string is the farthest that the section can be dragged before overlapping another section
							if(typeof newTop == "string"){
								alertMsg += 'Sections may not overlap.  The new start time has been adjusted.\n\n';
								newTop = parseInt(newTop);
							}
							var oldTop = ui.originalPosition.top;
							var deltaTop = newTop-oldTop;
							
							console.log('newHeight: '+newHeight);
							console.log('oldHeight: '+oldHeight);
							console.log('deltaHeight: '+deltaHeight);
							console.log('newTop: '+newTop);
							console.log('oldTop: '+oldTop);
							console.log('deltaTop: '+deltaTop);
							var endTime = j$(this).find('#endTime').html();
							var startTime = j$(this).find('#startTime').html();
							var ssId =  j$(this).find('#ssId').html();
							if (deltaTop==0){
								var endTime = j$(this).find('#endTime').html();
								var endTimeDate = Date.parseExact(endTime, "h:mm tt");
								var endTimeHour = endTime.split(':')[0];
								var endTimeMin = endTime.split(':')[1].split(" ")[0];
								endTimeDate.addMinutes((deltaHeight)/2);
								endTime=endTimeDate.toString('h:mm tt');
								j$(this).find('#endTime').html(endTime);
								alertMsg += 'New end time: '+endTime;
							}
							else{													  		
								var startTime = j$(this).find('#startTime').html();
								var startTimeDate = Date.parseExact(startTime, "h:mm tt");
								var startTimeHour = startTime.split(':')[0];
								var startTimeMin = startTime.split(':')[1].split(" ")[0];
								startTimeDate.addMinutes((-deltaHeight)/2);
								startTime=startTimeDate.toString('h:mm tt');
								j$(this).find('#startTime').html(startTime);
								alertMsg += 'New start time: '+startTime;
							}
							alert(alertMsg);
							// Check if in the managed package
							if(typeof SchoolForce === 'undefined'){
								console.log('Not in managed package');
								window["SchoolForce"] = {};
							 
								SchoolForce.GroupAgendaViewController = GroupAgendaViewController;
							}
 
							SchoolForce.GroupAgendaViewController.updateClass(ssId,startTime,endTime,handleUpdatesCheck);
							//Visualforce.remoting.Manager.invokeAction(
							//	'{!$RemoteAction.GroupAgendaViewController.updateClass}', 
							//	ssId,
							//	startTime, 
							//	endTime, 
							//	handleUpdatesCheck
							//);
						}
					 }); 
				} 
			);
			}
		
		 
		 
		 function handleUpdatesCheck(result, event) {
		if(event.type == 'exception') {
			//alert(event.message);
			errorJs(event.message);
			
		} 
		else {
			refreshJs();
		}
	}
	
	
	function combo(staffname) {
		j$.widget( "ui.combobox", {
			_create: function() {
				var self = this,
					select = this.element.hide(),
					selected = select.children( ":selected" ),
					value =staffname; 
				var input = this.input = j$( "<input>" )
					.insertAfter( select )
					.val( value )
					.autocomplete({
						delay: 0,
						minLength: 0,
						source: function( request, response ) {
							var matcher = new RegExp( j$.ui.autocomplete.escapeRegex(request.term), "i" );
							response( select.children( "option" ).map(function() {
								var text = j$( this ).text();
								if ( this.value && ( !request.term || matcher.test(text) ) )
									return {
										label: text.replace(
											new RegExp(
												"(?![^&;]+;)(?!<[^<>]*)(" +
												j$.ui.autocomplete.escapeRegex(request.term) +
												")(?![^<>]*>)(?![^&;]+;)", "gi"
											), "<strong>$1</strong>" ),
										value: text,
										option: this
									};
							}) );
						},
						select: function( event, ui ) {
							ui.item.option.selected = true;
							self._trigger( "selected", event, {
								item: ui.item.option
							});
						},
						change: function( event, ui ) {
							if ( !ui.item ) {
								var matcher = new RegExp( "^" + j$.ui.autocomplete.escapeRegex( j$(this).val() ) + "$", "i" ),
									valid = false;
								select.children( "option" ).each(function() {
									if ( j$( this ).text().match( matcher ) ) {
										this.selected = valid = true;
										return false;
									}
								});
								if ( !valid ) {
									// remove invalid value, as it didn't match anything
									j$( this ).val( "" );
									select.val( "" );
									input.data( "autocomplete" ).term = "";
									return false;
								}
							}
						}
					})
					.addClass( "ui-widget ui-widget-content ui-corner-left" );

				input.data( "autocomplete" )._renderItem = function( ul, item ) {
					return j$( "<li></li>" )
						.data( "item.autocomplete", item )
						.append( "<a>" + item.label + "</a>" )
						.appendTo( ul );
				};

				this.button = j$( "<button type='button'>&nbsp;</button>" )
					.attr( "tabIndex", -1 )
					.attr( "title", "Show All Items" )
					.insertAfter( input )
					.button({
						icons: {
							primary: "ui-icon-triangle-1-s"
						},
						text: false
					})
					.removeClass( "ui-corner-all" )
					.addClass( "ui-corner-right ui-button-icon" )
					.click(function() {
						// close if already visible
						if ( input.autocomplete( "widget" ).is( ":visible" ) ) {
							input.autocomplete( "close" );
							return;
						}

						// work around a bug (likely same cause as #5265)
						j$( this ).blur();

						// pass empty string as value to search for, displaying all results
						input.autocomplete( "search", "" );
						input.focus();
					});
			},

			_destroy: function() {
				this.input.remove();
				this.button.remove();
				this.element.show();
				//j$.Widget.prototype.destroy.call( this );
			}
		});
		
		j$( ".staffId" ).combobox();
	}
	
	function resetTimePickerAV(){
		  j$('.timepicker').each(function(index) { 
		    j$(this).timepicker({  
		                    showPeriod: true, 
		                    showLeadingZero: true
		                });
		  });
		} 
		
				
		

		var bCPInvoked = false;
 
		function resetColorPicker(){ 
		if (j$('#colorSelector').hasClass('mColorPicker')==false){
			j$('#colorSelector').mColorPicker();
			j$('#colorSelector').bind('colorpicked', function () {
			 	bCPInvoked=true;
		    	var colorVal = j$(this).val();
		      	j$(document).find('.tempColor').val(colorVal);
		      	});
		   		 
		   	}
		   	
		   	
	    }
		
		j$(document).ready(function() {
		   resetJquery();
	     });
	     
	     function resetJquery(){
	     setClueTips();
			resetTabs();
			resetTimePickerAV();
			resetDataTables();
			resetColorPicker();
			refreshAgendaJs();
			}
		
		function setClueTips(){
                 		  j$('a.sectionTip').cluetip({local: true, cursor: 'pointer',showTitle:false}); 
                 		  
        }
		
		function resetTabs(){
			j$(".tabs").tabs();
		}
		function resetDataTables(){
			 j$(".tablesorter").dataTable( {"bFilter": false, "bJQueryUI": true, "bPaginate":false} );
			j$(".tablesorter").css("background-color", "#1797C0");
			j$(".tablesorter tr:odd").css("background-color", "#CFEEF8");
			j$(".tablesorter tr:even").css("background-color", "#F3F3EC");
			}
			
			function hideTimes(tempStart,tempEnd){
			 		
				if(j$("#nomeet").find('.nomeet').is(':checked')){
					j$("#starttime").find('.timepicker').val('');
					j$("#endtime").find('.timepicker').val('');
					j$("#recordatt").find(".recordatt").attr('checked',false);
					j$("#dailyatt").find(".dailyatt").attr('checked',false);
					j$("#starttime").css({'display':'none'});
					j$("#starttimeheader").css({'display':'none'});
					
					j$("#endtime").css({'display':'none'});
					j$("#endtimeheader").css({'display':'none'});
					
				}
				else{
					j$("#starttime").find('.timepicker').val(tempStart);
					j$("#endtime").find('.timepicker').val(tempEnd);
					j$("#starttime").css({'display':'table-cell'});
					j$("#starttimeheader").css({'display':'table-cell'});
					
					j$("#endtime").css({'display':'table-cell'});
					j$("#endtimeheader").css({'display':'table-cell'});
				}
			
			}
	function showSchedSecPopup(staffname,roomname,coursename,start,end,dailyatt,recordatt,nomeet,id,roomFlag,color,colorflag){
			combo(staffname);
			var roomNum = roomname;
			var staffNam = staffname;
			var courseNam = coursename;
			
			if(color == '')
				color= '#FFFFFF';
			
			j$(".recrdatt").attr('checked',false);
			j$(".dailyatt").attr('checked',false);
			j$(".nomeet").attr('checked',false);
						
			j$('.ui-widget option').each( function() { j$(this).removeAttr('selected'); });
			j$(".roomid option").each( function() { j$(this).removeAttr('selected'); });
			j$(".courseId option").each( function() { j$(this).removeAttr('selected'); });
    		 
    		 
    		 
    		 j$("#starttime").find('.timepicker').val('');
    		 j$("#endtime").find('.timepicker').val('');
    		 j$("#schedSecId").find(".schedSecId").val('');
			
			if(id == null || id == ''){
			j$("#delBut").css({'display':'none'});
			j$(".courseId").attr('disabled',false);
			}
			else{
			j$("#delBut").css({'display':'inline'});
			j$(".courseId").attr('disabled',true);
			}
			
			if(roomFlag == 'false'){
				j$("#roomid").css({'display':'none'});
				j$("#roomhr").css({'display':'none'});
			}
			if(colorflag == 'false'){
				j$("#colorheader").css({'display':'none'});
				j$(document).find('.colorSelector').css({'display':'none'});
			}
			else{
					
					j$("#colorheader").css({'display':'table-cell'});
					j$(document).find('.colorSelector').css({'display':'table-cell'});
			
			}
			
			if(dailyatt == 'true'){ //alert('T');
				j$("#dailyatt").find(".dailyatt").attr('checked',true);
			}
			else
			{
			j$("#dailyatt").find(".dailyatt").attr('checked',false);
			}
			
			if(recordatt == 'true'){ //alert('T');
				j$("#recordatt").find(".recordatt").attr('checked',true);
			}
			else
			{
			j$("#recordatt").find(".recordatt").attr('checked',false);
			}
			
			if(nomeet == 'true'){ //alert('T');
				j$("#nomeet").find(".nomeet").attr('checked',true);
				j$("#starttime").css({'display':'none'});
				j$("#starttimeheader").css({'display':'none'});
					
				j$("#endtime").css({'display':'none'});
				j$("#endtimeheader").css({'display':'none'});
				
			}
			else
			{
				j$("#nomeet").find(".nomeet").attr('checked',false);
				j$("#starttime").css({'display':'table-cell'});
				j$("#starttimeheader").css({'display':'table-cell'});
					
				j$("#endtime").css({'display':'table-cell'});
				j$("#endtimeheader").css({'display':'table-cell'});
			
			}
			
			j$("#staffId").find(".staffId").find('option').each(function() {
                if (j$(this).html() == staffNam){ j$(this).attr("selected","selected") ;}
    		 });
    		 
			j$('.ui-widget').val(staffNam);
    		 
			j$("#roomid").find(".roomid").find('option').each(function() {
                if (j$(this).html() == roomNum) j$(this).attr("selected","selected") ;
    		 });
    		 
    		 j$("#courseId").find(".courseId").find('option').each(function() {
                if (j$(this).html() == courseNam) j$(this).attr("selected","selected") ;
    		 });
			
				j$("#starttime").find('.timepicker').val(start);
			
				j$("#endtime").find('.timepicker').val(end);
				
				
				j$("#schedSecId").find('.schedSecId').val(id);
				j$(document).find('.colorSelector').css({'background-color': color});
				j$(document).find('.colorSelector').val(color);
				
				setClueTips();
                j$('#editClassDetail').dialog({ autoOpen: true, modal: true, show: 'blind', width: 600,position:'top'});
                j$('#editClassDetail').dialog("open");
               
            	
    }
    
    function saveSchedSec(){
    	  
    		var staffid =  j$("#staffId").find('.staffId').val();
    	
			var roomid =  j$("#roomid").find('.roomid').val();
		
			var courseid =  j$("#courseId").find('.courseId').val();
			var start = j$("#starttime").find('.timepicker').val();
			var end =  j$("#endtime").find('.timepicker').val();
			var dailyatt =  j$("#dailyatt").find('.dailyatt').is(':checked'); 
			
			var recrdatt =  j$("#recordatt").find('.recordatt').is(':checked'); 
			var nomeet =  j$("#nomeet").find('.nomeet').is(':checked'); 

			var id = j$("#schedSecId").find('.schedSecId').val();
			var color = j$(document).find('.colorSelector').val();
			
			j$('#editClassDetail').dialog("close");
			
			saveJS(staffid,roomid,courseid,start,end,dailyatt,recrdatt,nomeet,id,color);
    }
	
	function deleteRec(){
    	
			var id = j$("#schedSecId").find('.schedSecId').val();
			j$('#editClassDetail').dialog("close");
			deleteJS(id);
			
    }
   
	jwerty.key('enter',false);
