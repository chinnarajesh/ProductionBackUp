public with sharing class ReportingPeriodCalendarController {
	
		public ReportingPeriodCalendarWrapper repPeriodCal			{get; set;}
		public List<Schedule_Day__c> scheduleDaysList				{get; set;}
		public Id setUpId											{get; set;}
		public Id currRepPeriod											{get; set;}
		public String currRepPeriodName											{get; set;}
		public List<ReportingPeriodCalendarWrapper.FormatMonthsWrapper> calendarDays				{get;set;}
		public List<ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper> scheduleTempsList				{get; set;}
		/*****************************************Constructor**************************************8*/
		/* Initialize the ReportingPeriodCalendar Wrapper and invoke buildCalendar*/	
		public ReportingPeriodCalendarController(){
			try{
			  	calendarDays = new List<ReportingPeriodCalendarWrapper.FormatMonthsWrapper>();
			  	scheduleTempsList = new List<ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper>();
			 	/* Retrieve the setupId from the current page url and set the setupId*/
			    if (ApexPages.currentPage().getParameters().get('setupId')!=null){
			    	setupId = ApexPages.currentPage().getParameters().get('setupId');
			    }
			  /* Instatiate the Wrapper Class and invoke the buildCalender method. 
			     Input parameter to the buildCalender method is the  reporting period
			  */
				repPeriodCal = new ReportingPeriodCalendarWrapper(setUpId);
				refreshCals();
				if(SetupWizard_Utils.checkCalendar(repPeriodCal.cSetup.setup)){
					SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The calendar must be saved for '+repPeriodCal.cSetup.reportingPeriodList[0].Name__c+' before moving on in the setup process.');
				}
			}
			catch(Exception ex){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while initializing Calendar.'));
			}		
				
		}
		
		/* This method rebuilds the calendar based on the reporting period selected from the dropdown list on the page */
		public void refreshCals(){
				if(Apexpages.currentPage().getParameters().get('rpId') != null)
					currRepPeriod = Apexpages.currentPage().getParameters().get('rpId');
				else {
					currRepPeriod = repPeriodCal.timeList[0].Id;
				}
				currRepPeriodName = repPeriodCal.repPeriodIdToName.get(currRepPeriod);
			try{
				refreshView();
			}
			catch(Exception e){
					ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while refreshing the calendar for reporting period: '+currRepPeriodName));
		    		Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId, 'Scheduler-Calendar ', 'Refresh Calendar day failed for the Reporting Period'+currRepPeriodName, e);
					insert ge;
			}
		}
		
		public void getCalendarViewByRP(){
			
		  	if(repPeriodCal.rpIdToFormatWrapperList.containskey(currRepPeriod))
				calendarDays =  repPeriodCal.rpIdToFormatWrapperList.get(currRepPeriod);
		}
		
		public void getScheduleTempsByRP(){
			scheduleTempsList = new List<ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper>();
		  	if(repPeriodCal.rpIdToScheduleClassesList.containskey(currRepPeriod))
				scheduleTempsList = repPeriodCal.rpIdToScheduleClassesList.get(currRepPeriod);
		}
		
		public void refreshView(){
			ApexPages.getMessages().clear();
			repPeriodCal.getCalendarDaysByRP();
			getScheduleTempsByRP();
			if (!scheduleTempsList.isEmpty()){
				getCalendarViewByRP();
			}
			else {
				calendarDays = new List<ReportingPeriodCalendarWrapper.FormatMonthsWrapper>();
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'No Schedule Templates created for '+currRepPeriodName+ ' please create at least a master template then retry.'));
			}
			
		
		}
	/*
		This method upserts the scheduled sections based on the unique key Reference Id
		Loop through the list of Months -> List of Weeks for each month - > List of Days for each week
		and create a list of scheduleDays to for upsert based on the reference Id.
	*/
	public void save(){
		system.debug(' repPeriodCal.currentRP'+ repPeriodCal.currentRP);
		system.debug(' currRepPeriod'+currRepPeriod);
		try{	
			scheduleDaysList = new List<Schedule_Day__c>();
			for(ReportingPeriodCalendarWrapper.FormatMonthsWrapper f : calendarDays){
				for(ReportingPeriodCalendarWrapper.MonthWrapper m : f.monthsList){
					for(ReportingPeriodCalendarWrapper.WeekWrapper w : m.weeksList){
						for(ReportingPeriodCalendarWrapper.DayWrapper d : w.dayWrapperList){
							if(d.schedDayId.length() > 0){
								if(d.schedDay.ReferenceId__c == null){
									d.schedDay.Schedule_Template__c = d.schedDayId;
									d.schedDay.Day__c = d.day;
									d.schedDay.ReferenceId__c = repPeriodCal.cSetup.setup.id+'-'+ String.valueOf(d.day);
									d.schedDay.Reporting_Period__c = currRepPeriod;
									scheduleDaysList.add(d.schedDay);
								}
								else {
									//if(d.schedDay.Schedule_Template__c != d.schedDayId){
									d.schedDay.Schedule_Template__c = d.schedDayId;
									d.schedDay.Day__c = d.day;
									d.schedDay.Reporting_Period__c = currRepPeriod;
									scheduleDaysList.add(d.schedDay);
									//	}
								}
							}
						}
					}
				}
			}
			system.debug('---------NUMBER OF SCHEDULE DAYS SAVED------'+scheduleDaysList.size());
			upsert scheduleDaysList ReferenceId__c ;
			SetupWizard_Utils.addMessage(ApexPages.Severity.Confirm, currRepPeriodName+' calendar has been saved.  You can edit your calendar throughout the year.');
			refreshView();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while saving Calendar  for the reporting period: '+currRepPeriodName));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId, 'Scheduler-Calendar ', 'Save Calendar Days failed for the Reporting Period'+currRepPeriodName, e);
			insert ge;
		}
	}
	
	public PageReference prev(){
		return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.TEMPLATES,false,repPeriodCal.cSetup.setup);
	}
	
	public PageReference next(){
		if(!SetupWizard_Utils.checkCalendar(repPeriodCal.cSetup.setup)) return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.COURSE_CATALOG,true,repPeriodCal.cSetup.setup);
		else{
			SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The calendar must be saved for '+repPeriodCal.cSetup.reportingPeriodList[0].Name__c+' before moving on in the setup process.');
			return null;
		}
	}
}