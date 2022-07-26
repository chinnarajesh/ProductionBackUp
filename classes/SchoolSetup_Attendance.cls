public class SchoolSetup_Attendance {
	/*************** GLOBAL NEED VARIABLES ***************/
	public core_SetupWrapper cSetup						{get;set;}
	public EOY_Progress__c progress						{get;set;}
	public boolean moduleComplete						{get;set;}
	public boolean isManaged							{get;set;}
	
	/*************** ATTENDANCE STATUS VARIABLES ***************/
	public static final ID attendanceTypeID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance');
	public String selectedPV							{get;set;}
	//public boolean disableFields						{get;set;}
	public Picklist_Value__c modalValue					{get;set;}
	public boolean bShowAttendance						{get;set;}
	public Map<ID,Picklist_Value__c> idToAttendancePV	{get;set;}
	public List<Picklist_Value__c> attendanceValues		{get;set;}
	public static final String ATTENDANCE_ERROR = 'No attendance values have been created.  Please add attendance values to continue.';
	
	/*************** PARENTAL NOTIFICATION VARIABLES ***************/
	public String selectedMV							{get;set;}
	public Value__c modalMessage						{get;set;}
	public boolean bShowMessages						{get;set;}
	public Map<String,Value__c> keyToParentalMessage	{get;set;}
	public List<Value__c> messageValues					{get;set;}
	
	/*************** ADMIN NOTIFICATION VARIABLES ***************/
	public String selectedNotification					{get;set;}
	public Notification__c modalNotification			{get;set;}
	public boolean bShowNotifications					{get;set;}
	public Map<ID,Notification__c> idToNotification		{get;set;}
	public List<Notification__c> notificationValues		{get;set;}
	public List<SelectOption> attendanceOptions			{get;set;}
	public boolean bShowThresholds						{get;set;}
	public String selectedThreshold						{get;set;}
	public Threshold__c modalThreshold					{get;set;}
	public Map<ID,Threshold__c> idToThreshold			{get;set;}
	//public List<Threshold__c> thresholdDisplay			{get;set;}
	
	public SchoolSetup_Attendance(){
		moduleComplete = false;
		isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
		
		bShowAttendance = false;
		idToAttendancePV = new Map<ID,Picklist_Value__c>();
		attendanceValues = new List<Picklist_Value__c>();
		
		bShowMessages = false;
		keyToParentalMessage = new Map<String,Value__c>();
		messageValues = new List<Value__c>();
		
		bShowNotifications = false;
		idToNotification = new Map<ID,Notification__c>();
		notificationValues = new List<Notification__c>();
		attendanceOptions = new List<SelectOption>();
		bShowThresholds = false;
		idToThreshold = new Map<ID,Threshold__c>();
		
		if (ApexPages.currentPage().getParameters().get('setupId')!=null){
			Id setupId = ApexPages.currentPage().getParameters().get('setupId');
			cSetup= new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),null);
			progress = SetupWizard_Utils.getEOYProgressRecord(cSetup.setup);
			moduleComplete = progress.Attendance_Wizard_Completed__c;
			verifyAttendanceValues(ATTENDANCE_ERROR);
			refreshParentalMessages();
			refreshNotifications();
		}
		else{
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
	}
	/********************************* SETUP CONFIGURATION *********************************/
	/*
		Saves the user's Attendance preferences on the Setup__c object.  This updates the 
		Cascade_Daily_Attendance__c and Use_Sectional_Attendance__c fields.
	*/
	public void saveConfiguration(){
		try{
			update cSetup.setup;
			progress.Attendance_Wizard_Started__c = true;
			upsert progress;
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Configuration saved successfully.');
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There was an error saving the configuration to the system.');
			globalErrorMessage('','error saving setup config',e);
		}
	}
	
	/********************************* ATTENDANCE VALUE CONFIGURATION *********************************/
	public void setPicklistValue(){
		modalValue = new Picklist_Value__c(Setup__c=cSetup.setup.id, RecordTypeId=attendanceTypeId);
		bShowAttendance=true;
		if(selectedPV!=null && selectedPV!=''){
			if(idToAttendancePV.containsKey(selectedPV)){
				modalValue = idToAttendancePV.get(selectedPV);
				if(modalValue.Setup__c==null){
					//disableFields=true;
					SetupWizard_Utils.addMEssage(apexpages.severity.INFO,'This is an org-wide attendance value and may be in use by other schools.  Please edit with caution.');
				}
			}
			else{
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This attendance value is not available to be edited.');
			}
		}
	}
	
	public void saveStatus(){
		try{
			try{
				upsert modalValue;
				progress.Attendance_Wizard_Started__c = true;
				upsert progress;
			}
			catch(Exception e){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There was an error saving the attendance value to the system.');
				throw e;
			}
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Attendance value saved!');
			refreshAttendanceValues();
			bShowAttendance=false;
		}
		catch(Exception e){
			String links='';
			if(modalValue!=null){
				if(modalValue.id!=null) links+='Picklist Value,'+modalValue.id;
			}
			
			globalErrorMessage(links,'error while saving attendance',e);
		}
	}
	
	/*
		Deletes a user-selected attendance value from the system.
		Performs validation that attendance value is not currently in use by attendance records before deleting.
	*/
	public void deletePicklistValue(){
		refreshAttendanceValues();
		if(selectedPV!='' && selectedPV!=null && idToAttendancePV.containsKey(selectedPV)){
			List<Attendance__c> inUse = [SELECT id FROM Attendance__c WHERE Picklist_Value__c=:selectedPV];
			if(inUse.size()==0){
				Picklist_Value__c toDelete = idToAttendancePV.get(selectedPV);
				delete toDelete;
				SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Attendance value deleted successfully.');
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This attendance value is currently in use on attendance records and cannot be deleted.');
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This attendance value is not available to be deleted.');
	}
	
	/********************************* PARENT NOTIFICATION CONFIGURATION *********************************/
	public void setMessage(){
		modalMessage = new Value__c(Setup__c=cSetup.setup.id);
		bShowMessages=true;
		if(selectedMV!=null && selectedMV!=''){
			for(Value__c msg: messageValues){
				if(msg.id==selectedMV) modalMessage = msg;
			}
			if(modalMessage.id==null){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'This parent notification is not available to be edited.'));
			}
		}
	}
	
	public void saveMessage(){
		try{
			try{
				String key=createValueKey(modalMessage);
				if(modalMessage.id==null && keyToParentalMessage.containsKey(key)){
					ApexPages.addMessage(new ApexPages.Message(apexpages.severity.INFO,'A parent notification for '+modalMessage.Language__c+' '+modalMessage.Communication_Type__c+' '+(modalMessage.Type__c=='Attendance Alerts'?'Absent':'Tardy')+' Alerts already exists and has been updated.'));
					//EE to keep from duplicate messages, grab existing message (with id) and copy over alert message
					Value__c tempValue = keyToParentalMessage.get(key);
					tempValue.Text_Alert__c = modalMessage.Text_Alert__c;
					modalMessage = tempValue;
				}
				upsert modalMessage;
				progress.Attendance_Wizard_Started__c = true;
				upsert progress;
			}
			catch(Exception e){
				ApexPages.addMessage(new ApexPages.Message(apexpages.severity.ERROR,'There was an error saving the parent notification to the system.'));
				throw e;
			}
			ApexPages.addMessage(new ApexPages.Message(apexpages.severity.CONFIRM,'Parent notification saved!'));
			refreshParentalMessages();
			bShowMessages=false;
		}
		catch(Exception e){
			String links='';
			if(modalMessage!=null){
				if(modalMessage.id!=null) links+='Value,'+modalMessage.id;
			}
			
			globalErrorMessage(links,'error while saving messages',e);
		}
	}
	
	public void deleteMessage(){
		if(selectedMV!='' && selectedMV!=null){
			Value__c toDelete;
			for(Value__c msg: messageValues){
				if(msg.id==selectedMV) toDelete = msg;
			}
			if(toDelete!=null){
				delete toDelete;
				refreshParentalMessages();
				SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Parent notification deleted successfully.');
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This parent notification is not available to be deleted.');
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This parent notification is not available to be deleted.');
	}
	
	/********************************* ADMIN NOTIFICATION CONFIGURATION *********************************/
	public void setNotification(){
		modalNotification = new Notification__c(Module__c='Attendance', Setup__c=cSetup.setup.id);
		bShowNotifications=true;
		if(selectedNotification!=null && selectedNotification!=''){
			if(idToNotification.containsKey(selectedNotification)){
				modalNotification = idToNotification.get(selectedNotification);
				//getThresholds();
			}
			else{
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'This notification is not available to be edited.'));
			}
		}
	}
	
	public void saveNotification(){
		try{
			try{
				upsert modalNotification;
				progress.Attendance_Wizard_Started__c = true;
				upsert progress;
			}
			catch(Exception e){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There was an error saving the notification to the system.');
				throw e;
			}
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Notification saved!');
			refreshNotifications();
			bShowNotifications=false;
		}
		catch(Exception e){
			String links='';
			if(modalNotification!=null){
				if(modalNotification.id!=null) links+='Notification,'+modalNotification.id;
			}
			
			globalErrorMessage(links,'error while saving notification',e);
		}
	}
	
	public void deleteNotification(){
		if(selectedNotification!=null && selectedNotification!=''){
			Notification__c toDelete = idToNotification.get(selectedNotification);
			if(toDelete!=null){
				List<Threshold__c> thresholds = [SELECT id FROM Threshold__c WHERE Notification__c=:toDelete.id];
				delete thresholds;
				delete toDelete;
				refreshNotifications();
				SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Notification and related thresholds have been deleted successfully.');
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This admin notification is not available to be deleted.');
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This admin notification is not available to be deleted.');
	}
	
	public void setThreshold(){
		if(selectedNotification!=null && selectedNotification!=''){
			modalThreshold = new Threshold__c(Notification__c=selectedNotification);
			bShowThresholds=true;
			if(selectedThreshold!=null && selectedThreshold!=''){
				if(idToThreshold.containsKey(selectedThreshold)){
					modalThreshold = idToThreshold.get(selectedThreshold);
				}
				else ApexPages.addMessage(new ApexPages.Message(apexpages.severity.ERROR,'This threshold is not available to be edited.'));
			}
		}
		else ApexPages.addMessage(new ApexPages.Message(apexpages.severity.ERROR,'There was an error associating the threshold to a notification.  Please try again.'));
	}
	
	public void saveThreshold(){
		try{
			try{
				upsert modalThreshold;
				progress.Attendance_Wizard_Started__c = true;
				upsert progress;
			}
			catch(Exception e){
				ApexPages.addMessage(new ApexPages.Message(apexpages.severity.ERROR,'There was an error saving the threshold to the system.'));
				throw e;
			}
			ApexPages.addMessage(new ApexPages.Message(apexpages.severity.CONFIRM,'Threshold saved!'));
			refreshNotifications();
			bShowThresholds=false;
		}
		catch(Exception e){
			String links='Notification,'+selectedNotification;
			if(modalThreshold!=null){
				if(modalThreshold.id!=null) links+='Threshold,'+modalThreshold.id;
			}
			
			globalErrorMessage(links,'error while saving threshold',e);
		}
	}
	
	public void deleteThreshold(){
		if(selectedThreshold!=null && selectedThreshold!=''){
			Threshold__c toDelete = idToThreshold.get(selectedThreshold);
			if(toDelete!=null){
				delete toDelete;
				refreshNotifications();
				SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Threshold deleted successfully.');
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This threshold is not available to be deleted.');
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This threshold is not available to be deleted.');
	}
	
	public void refreshAttendanceValues(){
		idToAttendancePV.clear();
		attendanceValues.clear();
		
		attendanceValues = core_SoqlUtils.getPlValuesList('Attendance',cSetup.setup.id);
		for(Picklist_Value__c pv: attendanceValues){
			idToAttendancePV.put(pv.id,pv);
		}
	}
	
	public void refreshParentalMessages(){
		messageValues.clear();
		keyToParentalMessage.clear();

		messageValues = [SELECT id, Communication_Type__c, Language__c, Setup__c, Text_Alert__c, Type__c FROM Value__c WHERE Setup__c=:cSetup.setup.id AND (Type__c='Attendance Alerts' OR Type__c='Tardy Alerts')];
		for(Value__c v: messageValues){
			keyToParentalMessage.put(createValueKey(v),v);
		}
	}
	
	public String createValueKey(Value__c toKey){
		return toKey.Language__c+toKey.Communication_Type__c+toKey.Type__c;
	}
	
	public void refreshNotifications(){
		refreshAttendanceValues();
		idToNotification.clear();
		notificationValues.clear();
		
		idToNotification = new Map<ID,Notification__c>([SELECT id, Daily_Tracking__c, Start_Date__c, 
			End_Date__c, Grade__c, Picklist_Value__c, Picklist_Value__r.Name, 
			(SELECT id, Consecutive__c, Cumulative__c, Time_Lost__c FROM Thresholds__r)
			FROM Notification__c WHERE Module__c='Attendance' AND Setup__c=:cSetup.setup.id]);
		notificationValues = idToNotification.values();
		
		idToThreshold.clear();
		for(Notification__c note: notificationValues){
			if(!note.Thresholds__r.isEmpty()){
				for(Threshold__c t: note.Thresholds__r){
					idToThreshold.put(t.id,t);
				}
			}
		}
		
		attendanceOptions.clear();
		for(Picklist_Value__c pv: attendanceValues) attendanceOptions.add(new SelectOption(pv.id,pv.Name));
	}
	
	/*
	
	*/
	public void completeSetup(){
		if(verifyAttendanceValues(ATTENDANCE_ERROR)){
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Congratulations!  You have completed the steps to finalize the Attendance Setup.  You may return here throughout the year to make modifications where noted.');
			EOY_Progress__c progress = SetupWizard_Utils.getEOYProgressRecord(cSetup.setup);
			progress.Attendance_Wizard_Completed__c = true;
			upsert progress;
			moduleComplete = true;
		}
		else{
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Please complete all required steps in order to finalize the Attendance Setup.');
		}
	}
	
	/*
		If the school passes validation that attendance values have been created,
		redirects the user to the previous step of the module setup process.
		
		@return the PageReference for the next page (currently unknown)
	*/
	public PageReference prev(){
		return SetupWizard_Utils.goToSchoolHome(cSetup.setup.id);
	}
	
	/*
		Verifies that attendance values have been created for this setup.
		Error message if no attendance values: "No attendance values have been added.  Please add attendance values to continue."
		
		@return a boolean indicating whether this setup is verified (true) or whether it needs attendance values (false)
	*/
	public boolean verifyAttendanceValues(String message){
		boolean bVerified=true;
		refreshAttendanceValues();
		if(attendanceValues.size()==0){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,message);
			bVerified=false;
		}
		return bVerified;
	}
	
	/*
		Creates and inserts a global error which includes the Setup__c in the links.
		
		@param links additional links relevant to the error, if any
		@param info descriptive message of when the error occurred
		@param e the exception that was thrown when the error occurred
	*/
	private void globalErrorMessage(String links, String info, Exception e){
		String linkString = 'Setup,'+cSetup.setup.id;
		if(links!=null && links!='') linkString+=';'+links;
		
		Global_Error__c ge = Error_Handling.handleError(linkString,'Attendance Configurator',info, e);
		insert ge;
	}
}