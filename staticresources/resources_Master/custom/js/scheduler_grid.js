var bSavingSection ;
var bSaving ;
var sectionDropSfdc;
var bUnchanged = true;
var bSaving = false;
var bCheckCourseLi = false;
var selectedStaffOptions =new Array(); 
var selectedRoomOptions =new Array(); 
var pName;
var sectionArrayList = [];
var deleteArrayList = [];
var arrayPos;
var bgColor;
var clickedLi;
var ssId ='';
var srpId='';
var staffId = '';
var roomId = '';
var periodKey= '';
var dailyAtt = false;
var recordAtt = false;
var parentCell ;
j$ = jQuery.noConflict();

jQuery.fn.center = function(parent) {
	this.css({
		"position": "absolute",
		"top": (((j$(document).height() - this.outerHeight()) / 3) + j$(document).scrollTop() + "px"),
		"left": (((j$(document).width() - this.outerWidth()) / 2) + j$(document).scrollLeft() + "px")
	});
	return this;
}

function resetColorPicker(){
	if (j$('#colorSelector')!=null){
		if (j$('#colorSelector').hasClass('mColorPicker')==false){
			j$('#colorSelector').mColorPicker();
			j$('#colorSelector').bind('colorpicked', function () {
				bCPInvoked=true;
				var colorVal = j$(this).val();
				j$(document).find('.tempColor').val(colorVal);
			});
		}
	}
}

function setClueTips(){
	j$("a[id$=sectionTip]").cluetip( {activation: 'click', delayedClose:5000, local: true, cursor: 'pointer', sticky: true,  closePosition: 'title'}); 
	j$("html").css('display', 'block');
}

j$(function() {
	setClueTips();
	resetTabs();
	resetDroppable();	
	resetDraggable(); 
});

function resetTabs(){
	 j$('.tabs').tabs({
		select: function(event, ui) {
			var isValid = tabConfirm;
			return isValid;
		}
	});
}
			
function toggleRoomViewJs(){
	bRoomView = !bRoomView;
}

function resetDroppable(){		   
	j$( ".targetSect" ).sortable({
		placeholder: "customHighlight", 
		tolerance: 'pointer' ,
		receive: function(event,ui){
			resetDraggable();
			resetDroppable();
			setClueTips();
			getDroppedValues(this, j$(ui.item));
		   
		}
	});		  
}

//Keep PTN 6/14
function resetDraggable(){
	j$( ".courseLi" ).draggable({
		helper:"clone", 
		connectToSortable: ".targetSect",
		appendTo: '.page',
		placeholder: "customHighlight",
		start: function(event, ui) { 
			j$(ui.helper).css('opacity','.6');
			j$(ui.helper).find('#remainingText').remove(); //When starting to drag remove the remaining text to clean up view
			j$(ui.helper).find('#pencilLink').remove(); //Also remove pencil icon
		} 
	}); 
				
	j$( "li" ).draggable({
		connectToSortable: ".targetSect",
		helper:"clone", 
		appendTo: '.page',
		placeholder: "customHighlight",
		start: function(event, ui) { 
			j$(ui.helper).css('opacity','.6');
			j$(ui.helper).find('#remainingText').remove();
			j$(ui.helper).find('#pencilLink').remove();
		}
	}); 
}	   
			
			function getDroppedValues(target,  originalLi ){
				var droppedLi =  j$(target).data().sortable.currentItem;
				console.log('droppedLi: '+j$(droppedLi));
				console.log('target: '+j$(target));
				bUnchanged=false;
				ssId ='';
				srpId='';
				staffId =  j$(target).parent().find('#staffId').html();
				roomId = j$(target).parent().find('#roomId').html();
				periodKey= j$(target).parent().find('#periodKey').html();
				dailyAtt = (j$(originalLi).find('#sectDaily').find('img').attr('title')=='Checked');
				recordAtt = (j$(originalLi).find('#sectRecord').find('img').attr('title')=='Checked');
				if (   j$(originalLi).find('#arrayPos').html()!=null&&j$(originalLi).find('#arrayPos').html()!=''){				 
					arrayPos =  j$(originalLi).find('#arrayPos').html();
					sectionArrayList.splice(parseInt(arrayPos),1);
				}
				if (j$(droppedLi).hasClass('courseLi')){
					srpId=  j$(droppedLi).attr('sfdc');
					console.log('srpId: '+srpId);
					j$(target).removeClass('courseLi');
					j$(target).addClass('disabled')
					 var rpNum = 0;
					 rpNum = j$(originalLi).find('#rpNum').html();			  
						if (rpNum > 1) {
							rpNum--;
							j$(originalLi).find('#rpNum').html(rpNum);
						} else { 
							j$(originalLi).remove();
						}
					 
						j$(target).find('.secText').find('#remainingText').remove(); //When starting to drag remove the remaining text to clean up view
						j$(target).find('#pencilLink').remove(); //Also remove pencil icon
						j$(target).find('#removeLink').show();//Show the remove X 
						j$(target).find('#sectionTip').show();//Show the magnifying glass
						if (bRoomMatters||bRoomView)	j$(target).find('#changeRoom').show();//Show the pencil
				}
				else {
					console.log('in the else');
					ssId =j$(droppedLi).find('#ssId').html();
					j$(originalLi).remove();
				}
				
				if (!bRoomView&&!bRoomMatters){
					addtoupdatelist(ssId,srpId,periodKey,staffId,roomId,dailyAtt,recordAtt);
					 j$(target).find('#arrayPos').html(arrayPos);
				}
				else {
					openRoomModal(j$(droppedLi), target);
				}
			}
			
			
			function addtoupdatelist(ssId, sectionRpId, staffId, periodKey, RoomId, dailyAtt, recordAtt){
				arrayPos=sectionArrayList.length;
				sectionArrayList.push(ssId+";"+sectionRpId+";"+staffId+";"+periodKey+";"+dailyAtt+";"+recordAtt+";"+RoomId);
			}
			
			function removeCell(liToRemove){
				var tempSsId = j$(liToRemove).find('#ssId').html();
				if(tempSsId!=null&&tempSsId!=''){
					deleteArrayList.push(tempSsId);
				}
				j$(liToRemove).remove();
			}
			
		
			
			 
			//Delete not used PTN 6/14
			function toggleGridConfirmJs(){
				if(!bUnchanged){ 
					var b = confirm('You have unsaved changes.  Press OK to  change view without saving or press Cancel to return, then click Save Schedule');
						if (b) {
							toggleRoomViewJs(); 
							showProgressBar('Toggling View'); 
							toggleViewJs();
						}
					}
				else {
					toggleRoomViewJs(); 
					showProgressBar('Toggling View'); 
					toggleViewJs();
				}
			}
			
			//Keep PTN 6/14
			function	   toggleTabConfirmJs(sChangeType, toggleId, sChangeAbbrev){
				if(!bUnchanged){ 
					var b = confirm('You have unsaved changes.  Press OK to  save changes and change view or press Cancel to return, then click Save Schedule');
					if (b) {
						showProgressBar('Changing Selected '+sChangeType);
						updatelistcheck();		  
						refreshGridJs(toggleId,sChangeAbbrev);
						bUnchanged=true;
						tabConfirm=true;
					}
					else {
						tabConfirm=false;
					}
				}
				else {
					showProgressBar('Changing Selected '+sChangeType);	  
					refreshGridJs(toggleId,sChangeAbbrev);
					bUnchanged=true;
					tabConfirm=true;
				}
			}
	
	
			function changeMainFilter(element){
			
				var sChangeAbbrev = j$(element).val().split('|')[1];
				var toggleId = j$(element).val().split('|')[0];
				if(!bUnchanged){ 
					var b = confirm('You have unsaved changes.  Press OK to  save changes and change view or press Cancel to return, then click Save Schedule');
					
					if (b) {
						showProgressBar('Changing Filter');
						updatelistcheck();		  
						refreshGridJs(toggleId,sChangeAbbrev);
					}
				}
				else {
					showProgressBar('Changing Filter');
					refreshGridJs(toggleId,sChangeAbbrev);
				}
				bUnchanged=true;
			
			}
			
			//Needs to be updated PTN
			function openRoomModal(cell, parent){
				clickedLi = cell;
				console.log('clickedLi = '+clickedLi);
				parentCell = j$(parent).parent();
				bgColor = j$(cell).css('background-color');
				configureOptionList();
				var roomNum =parseInt(j$(cell).find('#roomName').html());
				ssId = j$(clickedLi).find('#ssId').html();
				srpId = j$(clickedLi).find('#sectRpId').val();
				periodKey = j$(parentCell).find('#periodKey').html();
				staffId = j$(parentCell).find('#staffId').html();
				dailyAtt = (j$(clickedLi).find('#sectDaily').find('img').attr('title')=='Checked');
				recordAtt = (j$(clickedLi).find('#sectRecord').find('img').attr('title')=='Checked');
				console.log('ssId = '+ssId+', srpId = '+srpId+', periodKey = '+periodKey+', staffId = '+staffId+', dailyAtt = '+dailyAtt+', recordAtt = '+recordAtt);
				if (bRoomView) 
					pName = 'Room: '+j$(parentCell).find('#roomName').html();
				else 
					pName = 'Staff: '+ j$(parentCell).find('#staffName').html();
				j$(clickedLi).css('background-color','yellow');
				j$('#schedulerModal').dialog({
					title: 'Period: '+periodKey+' '+pName,
					beforeClose: function(){ j$(cell).css('background-color',bgColor); },
					open: function(event, ui) { j$(".ui-dialog-titlebar-close").hide(); },
					close: function(event, ui) { j$(this).dialog('destroy'); },
					modal :true 
				});	 
				j$("#schedulerModal").find(".selectedRoom").find('option').each(function() {
					if (j$(this).html()==roomNum)
						j$(this).attr("selected","selected") ;
				});
			}
			
			function resetOptionList(){
				j$('.selectedRoom option').each( function() {
							j$(this).attr("disabled",false);
					});
			}
			
			function configureOptionList(){

				var selectedPeriod;
				 selectedStaffOptions =new Array(); 
				var selectedRoom; 
				 selectedRoomOptions =new Array(); 
				var roomVal;
				var staffVal;
				 selectedPeriod = j$(parentCell).find('#periodKey').html();
				if (!bRoomView){
					j$('.droppableCell').each(function() {
						if (j$(this).find('#periodKey').html()==selectedPeriod ){

						var thisPeriodKey = (j$(this).find('#periodKey').html());
							j$(this).find('li').each(function() {
								
								selectedRoomOptions.push(j$(this).find('#roomNumber').html());
								
								if (j$(this).attr('sfdc')==j$(clickedLi).attr('sfdc')){
									roomVal=j$(this).find('#roomNumber').html();
									
								}   
							});
						}
					});
					var bSelected = false;
					j$('.selectedRoom option').each( function() {
						var thisOption = j$(this).val().split('|')[1];
						var selectedVal;
						if(selectedRoomOptions.indexOf(thisOption)!=-1){
							if (roomVal == thisOption){
								j$(this).attr("selected","selected");
								bSelected=true;
							}
							else{
								j$(this).attr("disabled","disabled");
							}
						}
						else {
							if (!bSelected){					
								j$(this).attr("selected","selected");
								bSelected =true;
							}
						}
					});
				}
			}
			

			function closeModal(){
				 j$('#schedulerModal').dialog('close');
				 removeCell(clickedLi);
			}
		   
			
			
			function saveModal(){
				var staff;
				var room;
				if (!bRoomView) 
					room = j$('.selectedRoom').val();
				else 
					staff =  j$('.selectedStaff').val();
				if (!bRoomView){
					j$(clickedLi).find('#roomNumber').html(room.split('|')[1]);
					j$(clickedLi).find('#roomId').val(room.split('|')[0]);
				   roomId= room.split('|')[0]
				} 
				else if (bRoomView){  
					j$(clickedLi).find('#staffName').html(staff.split('|')[1]);
					j$(clickedLi).find('#staffId').val(staff.split('|')[0]);
					staffId=staff.split('|')[0];
				}
		 
				j$('#schedulerModal').dialog('close');

				j$(clickedLi).find('.bgColor').val(bgColor);
				console.log('Daily attendance: '+dailyAtt);
				console.log('Record attendance: '+recordAtt);
				addtoupdatelist(ssId,srpId, periodKey, staffId, roomId, dailyAtt, recordAtt);
				j$(clickedLi).find('#arrayPos').html(arrayPos);
				resetOptionList();
			}
	

						 
				  
				   
				   
				   function toggleView(){
						j$('.sched').each(function (){
							if (j$(this).css('display')=='none') {
								 j$(this).css('display','inline');
							}
							else	{
								j$(this).css('display','none');
							}
					});
				   }
function checkRefreshScheduleJs(){
			if (!bErrorMessages&&bSaving) {
				bSaving = false;
				bUnchanged=true;
				showProgressBar('Refreshing Details...');
				refreshScheduleJs();
				sectionArrayList = [];
				
			}
		}   

function checkRefreshGridAfterSaveSectionJs(){
			if ((!bErrorMessages&&bSavingSection) && (bSavingSection&&j$('.messageText').html()==null)) {
				bSavingSection = false;
				refreshScheduleJs();
			}
		}
		
	
		
		function handleUpdatesCheck(result, event) {
			if(event.type == 'exception') {
				//errorJS(event.message);
			} 
			
	}
			
		


jwerty.key('enter',false);
