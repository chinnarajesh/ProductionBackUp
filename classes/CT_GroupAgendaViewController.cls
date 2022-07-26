global with sharing class CT_GroupAgendaViewController {
	public CT_GroupAgendaViewWrapper gavw			{get;set;}
	public Scheduled_Section__c currSchedSec	{get;set;}
	public string[] sErrorMessages				{get;set;}
	public string	errorMsg					{get;set;} //added for Chicago
	public Boolean bErrors 						{get;set;}
	public boolean bAgendaView					{get;set;}
	public Id setupId							{get;set;}
	public Id schedTempId						{get;set;}
	public Id reptPeriod						{get;set;}
	public Id grpId								{get;set;}
	public CT_core_SetupWrapper  cSetup			{get;set;}
	public Boolean haserrors					{get;set;}
	//EE 4/3 adding for US3024
	public List<SelectOption> reportingPeriods	{get;set;}
	public List<SelectOption> scheduleTemplates	{get;set;}
	
	public CT_GroupAgendaViewController(){
		if(ApexPages.currentPage().getParameters().containsKey('setupid')){
			setupId = ApexPages.currentPage().getParameters().get('setupId');
			cSetup = new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'template');
			reportingPeriods = CT_SetupWizard_Utils.getReportingPeriodOptions(cSetup.reportingPeriodList);
			if(reportingPeriods.size()==0)
				CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are no reporting periods set up for your school.  Please return to the Term Selection step to create reporting periods.');
			else{
				reptPeriod = reportingPeriods[0].getValue();
				getTemplates();
			}
			bAgendaView=false;
			CT_SetupWizard_Utils.checkSchedule(cSetup.setup);
		}
		else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
	}
	
	public void getTemplates(){
		bAgendaView=false;
		scheduleTemplates = new List<SelectOption>();
		if(reptPeriod!=null){
			List<Schedule_Template__c> templates = cSetup.rpScheduleTemplateMap.get(reptPeriod);
			if(templates.size()>0){
				for(Schedule_Template__c st: templates){
					if(st.Has_Class__c) scheduleTemplates.add(new SelectOption(st.id,st.Name));
				}
				if(scheduleTemplates.size()==0)
					CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are no schedule templates marked to have class for the selected reporting period.  Please return to the Schedule Template Creation step to mark templates to have class.');
				else
					schedTempId = scheduleTemplates[0].getValue();
			}
			else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are no schedule templates created for the selected reporting period.  Please return to the Schedule Template Creation step to create templates for this reporting period.');
		}
		else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'No reporting period selected.  Please select a reporting period.');
	}
	
	public void initAgendaView(){
		bAgendaView=true;
		currSchedSec = new	Scheduled_Section__c();
		if(reptPeriod!=null){
			if(schedTempId!=null){
				gavw = new CT_GroupAgendaViewWrapper(setUpId,schedTempId);
			}
			else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'No schedule template selected.  Please select a reporting period and a schedule template to view the agenda for your schedule groups.');
		}
		else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'No reporting period selected.  Please select a reporting period and a schedule template to view the agenda for your schedule groups.');
	}
		
	public void refreshGroups(){
		try{
			if(Apexpages.currentPage().getParameters().get('grpId') != null)
				grpId = Apexpages.currentPage().getParameters().get('grpId');
			gavw.currentGroup = grpId;
			gavw.getSchedSectionsByCurrGroupId();
		}
		catch(Exception e){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while refreshing Scheduled Sections for Group:'+grpId));
				Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId, 'Scheduler-Group Agenda', 'Refresh Scheduled Sections failed for the Reporting Period'+reptPeriod+'GroupId:'+grpId+'ScheduleTemplate'+schedTempId, e);
				insert ge;
		} 
		
	}
		public void handleError(){
			String msg = errorMsg;
			integer parser  = msg.indexOf(',');
			if (msg!=null){
				if(parser>0){
					msg		 = msg.substring(parser+1);
				}
				integer parser2 = msg.indexOf(':');
				if(parser2>0){
					msg		 = 'ERROR: ' + msg.substring(0, parser2);
				}
					Apexpages.addMessage(new apexpages.message(apexpages.severity.error, msg));
					gavw.refreshClasses();
				}
		}
		
		
			@RemoteAction
	global static List <String> updateClass (String ssId, String startTime, String endTime) {
		List<String> retList = new List<String>();
		try{
			Scheduled_Section__c ss = [select id,Start_Time_Text__c,  Start_Time__c, end_Time_Text__c, End_Time__c from Scheduled_Section__c where id=:ssId];
			ss.Start_Time_Text__c = startTime;
			ss.Start_Time__c			= CT_core_TimeUtils.processTimeText(startTime);
			ss.end_Time_Text__c = endTime;
			ss.End_Time__c			= CT_core_TimeUtils.processTimeText(endTime);
			CT_core_triggerUtils.bGroupAgenda=true;
			update ss;
		}
		catch (exception e){
			system.debug('#### error in groupAgenda = '+e);
			if(e.getTypeName() == 'System.DmlException'){
				for (Integer i = 0; i < e.getNumDml(); i++) {
					if(e.getDmlMessage(i).length()>18){//In case error is not bad entered grade
						throw e;
					}
					retList.add(e.getDmlMessage(i));
				}
				system.debug('#### retlistA = '+retList);
				return retList;
			}
			else{
				throw e;
			}
		}
		return retList;
	}
		
		
		
		public Pagereference saveJS(){
			try{	
				Datetime exactStartTime;
				Datetime exactEndTime;
				Datetime ssStartTime;
				Datetime ssEndTime;
				haserrors = false;
				Boolean option = false;
				String refKey = '';
				String sectionRefKey ='';
				String staffId ='';
				String roomId ='';
				String courseId ='';
				String startTime ='';
				String endTime ='';
				Boolean dailyAtt = false;
				Boolean recordAtt = false;
				Boolean noclass = false;
				String schedId ='';
				String color ='';
				sErrorMessages = new string[]{};
				
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('staffId')))
					staffId  	=	Apexpages.currentPage().getParameters().get('staffId');
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('roomId')))
					roomId  		=	Apexpages.currentPage().getParameters().get('roomId');
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('courseId')))
					courseId  	=	Apexpages.currentPage().getParameters().get('courseId');
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('startTime')))
					startTime  	=	Apexpages.currentPage().getParameters().get('startTime');
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('endTime')))
					endTime  	=	Apexpages.currentPage().getParameters().get('endTime');
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('dailyAtt')))
					dailyAtt  	=	Boolean.valueOf(Apexpages.currentPage().getParameters().get('dailyAtt'));
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('recordAtt')))
					recordAtt  	=	Boolean.valueOf(Apexpages.currentPage().getParameters().get('recordAtt'));
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('noclass')))
					noclass  	=	Boolean.valueOf(Apexpages.currentPage().getParameters().get('noclass'));
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('schedId')))
					schedId		=	Apexpages.currentPage().getParameters().get('schedId');
				if(!CT_StringUtils.isBlank(Apexpages.currentPage().getParameters().get('color')))
					color		=	Apexpages.currentPage().getParameters().get('color');
			
			system.debug('~~~~~ staffId '+staffId);
			system.debug('~~~~~ roomId '+roomId);
			system.debug('~~~~~ courseId '+courseId);
			system.debug('~~~~~ startTime '+startTime);
			system.debug('~~~~~ endTime '+endTime);
			system.debug('~~~~~ dailyAtt '+dailyAtt);
			system.debug('~~~~~ recordAtt '+recordAtt);
			system.debug('~~~~~ noclass '+noclass);
			system.debug('~~~~~ schedId '+schedId);
			system.debug('~~~~~ color '+color);
			//if(!noclass && !recordAtt && !dailyAtt) Commented out per US1251
				//sErrorMessages.add('Please select atleast one of the following:1. Daily Attendance 2. Record Attendance 3. No Meeting');
			if((noclass && dailyAtt) || (noclass && recordAtt))
				sErrorMessages.add('Please select only one of the following: 1. Daily Attendance 2. Sectional Attendance 3. No Meeting Class');
				
			if(!sErrorMessages.isEmpty()){
				processErrorMessages();
				return null;
			}
			if(!noclass&&!dailyAtt)
				validateDateFields(startTime, endTime);
				
			if (!sErrorMessages.isEmpty()){ 
				processErrorMessages();
				return null;
			}
			if(!noclass){	
				exactStartTime = CT_core_TimeUtils.processTimeText(startTime);
				exactEndTime =CT_core_TimeUtils.processTimeText(endTime);
				
				ssStartTime = CT_core_TimeUtils.getRoundedTextTime(startTime);
				ssEndTime = CT_core_TimeUtils.getRoundedTextTime(endTime);
			}	
				refKey  = CT_ImportUtils.createScheduledSectionKey(cSetup.setup.School__c, gavw.currentGroup,courseId,reptPeriod,schedTempId);
				sectionRefKey = CT_ImportUtils.createSectionReferenceKey(cSetup.setup.School__c,gavw.currentGroup,courseId,reptPeriod);
				populateSchedSection(refKey,sectionRefKey,staffId,roomId,courseId,dailyAtt,recordAtt,noclass,exactStartTime,exactStartTime,exactEndTime,exactEndTime,color);
				
				CT_core_triggerUtils.bGroupAgenda=true;
				upsert currSchedSec Reference_Id__c;
		//Retrieve scheduled sections and refresh  maps and lists
				gavw.refreshClasses();
				
				return null;
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while saving the scheduled section for Group:'+grpId));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId, 'Scheduler-Group Agenda', 'An error has occurred while saving the scheduled section for the Reporting Period'+reptPeriod+'GroupId:'+grpId+'ScheduleTemplate'+schedTempId, e);
			hasErrors = true;
			insert ge;
			return null;			
			}	
		}
		
		public void refreshAfterSave(){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.CONFIRM, 'Class times updated successfully!'));
				gavw.refreshClasses();
		}
		
		
	
		
		
		public void populateSchedSection(String refKey,String sectionRefKey,String staffId,String roomId,String courseId,Boolean dailyAtt,Boolean recordAtt,Boolean noclass,Datetime ssStartTime,Datetime exactStartTime,Datetime ssEndTime,Datetime exactEndTime,String col) {
			currSchedSec = new Scheduled_Section__c();
			currSchedSec.Reference_Id__c = refKey;
			currSchedSec.Section_Reference_Id__c = sectionRefKey;
			currSchedSec.Account__c = gavw.cSetup.setUp.School__c; 
			currSchedSec.Schedule_Group_Section__c = gavw.currentGroup;//Updated for Chicago
			currSchedSec.Schedule_Template__c = gavw.schedTemp.Id;
			currSchedSec.Reporting_Period__c = reptPeriod;
			currSchedSec.Staff__c = staffId;
		if(col != '')
			currSchedSec.Color__c = col;
		else
			currSchedSec.Color__c = '#FFFFFF';	
		if(roomid.length() > 0)
			currSchedSec.Room__c = roomId;
			currSchedSec.Course__c = courseId;
			currSchedSec.Daily_Attendance__c = dailyAtt;
		if(dailyAtt)
			currSchedSec.Record_Attendance__c = true;
		else
			currSchedSec.Record_Attendance__c = recordAtt;
			currSchedSec.No_Meeting__c = noclass;
		if(ssStartTime != null && !noclass)	
			currSchedSec.Rounded_Start_Time__c = ssStartTime.format('hh:mm a');
		else
			currSchedSec.Rounded_Start_Time__c = '';
		if(exactStartTime != null && !noclass){	
			currSchedSec.Start_Time__c = exactStartTime;
			currSchedSec.Start_Time_Text__c = exactStartTime.format('hh:mm a');
			
		}
		else{
			currSchedSec.Start_Time__c = null;
			currSchedSec.Start_Time_Text__c = '';
		
		}
		
		if(ssEndTime != null && !noclass)
			currSchedSec.Rounded_End_Time__c = ssEndTime.format('hh:mm a');
		else
			currSchedSec.Rounded_End_Time__c = '';
		if(exactEndTime != null && !noclass){
			currSchedSec.End_Time__c = exactEndTime;
			currSchedSec.End_Time_Text__c = exactEndTime.format('hh:mm a');
		}
		else{
			currSchedSec.End_Time__c = null;
			currSchedSec.End_Time_Text__c = '';
		
		}
			currSchedSec.Needs_Publish__c = true;
		}
		
		public void processErrors(String crsName){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'The start and end times conflict with '+crsName));
		}
		
		
		
		public Pagereference deleteJS(){
			try{	
				Scheduled_Section__c delete_schedSec = [SELECT Id,Section_Reference_Id__c,Schedule_Template__c FROM Scheduled_Section__c
														 WHERE Id =: Apexpages.currentPage().getParameters().get('schedId_del')];
				if(delete_schedSec !=null){
					deleteSessions(delete_schedSec);
					if(sErrorMessages.size() > 0){
						processErrorMessages();
						return null;
					}
					else
						delete delete_schedSec;
				 }
				//Retrieve scheduled sections and refresh  maps and lists
				gavw.refreshClasses();
				return null;
			}
			catch(Exception e){
					ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while deleting the scheduled sections for Group:'+grpId));
					Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId, 'Scheduler-Group Agenda', 'Delete Scheduled Sections failed for :Reporting Period'+reptPeriod+'GroupId:'+grpId+'ScheduleTemplate'+schedTempId, e);
					insert ge;
					return null;
			}
		}
		
		public void deleteSessions(Scheduled_Section__c ss){
		Set<Date> scheduleDaysSet = new Set<Date>();	
	 	String schedulerRefKey = ss.Section_Reference_Id__c;
	 	Id schedTemp = ss.Schedule_Template__c;
	 	sErrorMessages = new string[]{};
	 	
	 	List<Session__c> sessionsToDelete = new List<Session__c>();
	 	List<Section_ReportingPeriod__c> updateSectRps = new List<Section_ReportingPeriod__c>();
		
		for(Schedule_Day__c sd :[SELECT Id,day__c FROM Schedule_Day__c 
								 WHERE Schedule_Template__c = : schedTemp 
								 AND Reporting_Period__c = :reptPeriod]){
			
			scheduleDaysSet.add(sd.Day__c);
		}
		
		
		for(Session__c sess : [SELECT Id FROM Session__c WHERE Section__r.Scheduler_Reference_Id__c =: schedulerRefKey 
							   AND Session_Date__c in : scheduleDaysSet]){
		
			sessionsToDelete.add(sess);
		}
		
		if(sessionsToDelete.size() > 0){
			Integer attRecsCnt = [SELECT COUNT() FROM Attendance__c WHERE Session__c in : sessionsToDelete];
			if(attRecsCnt == 0){
				delete sessionsToDelete; 
			}
			else{
				sErrorMessages.add('The sessions related to the scheduled section have attendance records. The scheduled section cannot be deleted.');
			}
			
		}
		
	}
		
		public void validateDateFields(String starttime, String endtime){
				Datetime tempStartTime = CT_core_TimeUtils.processTimeText(gavw.schedTemp.Start_Time_Text__c);
				Datetime tempEndTime = CT_core_TimeUtils.processTimeText(gavw.schedTemp.End_Time_Text__c);
				if (starttime == null || starttime == ''){
					sErrorMessages.add('You must include both a start and end time for a scheduled section.');
					
				}
				if (endtime == null || endtime == ''){
					sErrorMessages.add('You must include both a start and end time for a scheduled section.');
					
				}
				
				if (starttime.length() > 0 && endtime.length() > 0){
				 	if(CT_core_TimeUtils.processTimeText(starttime) > CT_core_TimeUtils.processTimeText(endtime)){
					sErrorMessages.add('End Time cannot be before Start Time');
				 	}	
				 
				 	if(CT_core_TimeUtils.processTimeText(starttime) < tempStartTime){
						sErrorMessages.add('Start Time cannot be before '+tempStartTime.format('hh:mm a'));
					}
					
					if(CT_core_TimeUtils.processTimeText(endtime) > tempEndTime){
						sErrorMessages.add('End Time cannot be after '+tempEndTime.format('hh:mm a'));
					}
				}
				
		}
		
		public void processErrorMessages(){
			for (String s: sErrorMessages){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, s));
			}
		}
		
	public PageReference prev(){
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.GROUP_CONFIG,false,cSetup.setup);
	}
	
	public PageReference next(){
		if(!CT_SetupWizard_Utils.checkSchedule(cSetup.setup)) return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.STUDENT_SECTIONS,true,cSetup.setup);
		else return null;
	}
}