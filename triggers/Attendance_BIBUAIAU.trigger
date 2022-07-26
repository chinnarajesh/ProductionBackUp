trigger Attendance_BIBUAIAU on Attendance__c (before insert, before update, after insert, after update) {
	if (!core_triggerUtils.bTriggersDisabled()){
	   if(Trigger.isInsert && Trigger.isBefore){
	        Attendance_ManageStudentAttendance.isbeforeinsert(Trigger.New); 
	    }
	
	    if(Trigger.isUpdate && Trigger.isBefore){
	        Attendance_ManageStudentAttendance.isbeforeupdate(Trigger.NewMap, Trigger.OldMap); 
	    }
	
		if(!core_triggerUtils.b){
		    if(Trigger.isInsert && Trigger.isAfter){
		        core_triggerUtils.recursiveHelper(true);
		        Attendance_ManageStudentAttendance.isafterinsert(Trigger.NewMap, Trigger.OldMap); 
		    }
		
		    if(Trigger.isUpdate && Trigger.isAfter){
		        core_triggerUtils.recursiveHelper(true);    
		     Attendance_ManageStudentAttendance.isafterupdate(Trigger.NewMap, Trigger.OldMap); 
		    }
		}
	}
}