public with sharing class CT_core_ScheduleTemplateConfiguration {
	public ApexPages.StandardController 		controller 				  						{get;set;}
	public List <Period__c>						periodList				  						{get;set;}
	public Schedule_Template__c					schedTemplate			  						{get;set;}
	public Period__c							period					  						{get;set;}
	public CT_core_SetupWrapper					cSetup					  						{get;set;}
	public List <Schedule_Template__c>			scheduleTemplateList	  						{Get;set;}
	public String								rpId					  						{get;set;}
	public string								templateId				  						{get;set;}
	public string								cloneTemplateId			  						{get;set;}
	public string								cloneGrpSchedId			  						{get;set;}
	public string								selectedRowNumber		  						{get;set;}
	public String								selectedPeriodSet		  						{get;set;} //selected Period Set templates
	public string[]								sErrorMessages			  						{get;set;}
	public boolean								bErrors					  						{get;set;}
	public boolean								bIsClone				  						{get;set;}
	public boolean								bIsNew					  						{get;set;}
	public boolean								bConfigureTemplate		  						{get;set;}
	public boolean								bPeriod					  						{get;set;}
	public List <SelectOption>					reportingPeriodOptionList 						{get;set;}
	public String 								selectedReportingPeriod	  						{get;set;}

	public Boolean isViewOnly											  						{get;set;}


	public List <Period__c>						allPeriodsListForAllTemplates 					{get;set;} //for all rows for templates to insert
	public ScheduleTemplateWrapper 				scheduleTemplateWrapper 	    				{get;set;} //one wrapper is created when page inits
	public List<ScheduleTemplateWrapper> 		scheduleTemplateWrapperList 					{get;set;} //all wrappers for templates (6 or less)
	public Boolean 								configureMassAddPanel 							{get;set;} //new panel for mass add
	public Boolean 								configureAddPanel 								{get;set;} //add to bConfigureTemplate parameter(old panel)
	public List<Schedule_Template__c> 			selectedTemplates								{get;set;} //templates from wrapper
	public List<Schedule_Template__c>  			allScheduleTemplatesForPeriods  				{get;set;}
	public List <SelectOption>					periodSetOptionList 							{get;set;}

	public List <Period__c>						periodsFromPeriodTemplates 						{get;set;} //for all rows for templates to insert

/* ========================================================= */
/*     Calendar variables
/* ========================================================= */
	public CT_ReportingPeriodCalendarWrapper repPeriodCal										{get; set;}
	public List<Schedule_Day__c> scheduleDaysList												{get; set;}
	public Id setupId																			{get; set;}
	public Id currRepPeriod																		{get; set;}
	public String currRepPeriodName																{get; set;}
	public List<CT_ReportingPeriodCalendarWrapper.FormatMonthsWrapper> calendarDays				{get; set;}
	public List<CT_ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper> scheduleTempsList	{get; set;}


	public CT_core_ScheduleTemplateConfiguration(){
		calendarDays = new List<CT_ReportingPeriodCalendarWrapper.FormatMonthsWrapper>();
		scheduleTempsList = new List<CT_ReportingPeriodCalendarWrapper.ScheduleTemplateWrapper>();

		if(ApexPages.currentPage().getParameters().containsKey('setupid')){
			setupId = ApexPages.currentPage().getParameters().get('setupId');
			init(CT_core_SoqlUtils.getSetupById(setupId));
			repPeriodCal = new CT_ReportingPeriodCalendarWrapper(setupId);
			reportingPeriodOptionList = CT_SetupWizard_Utils.getReportingPeriodOptions(cSetup.reportingPeriodList);
			if(CT_SetupWizard_Utils.checkTemplates(cSetup.setup)){
				if(cSetup.reportingPeriodList==null || cSetup.reportingPeriodList.isEmpty()){
					CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING, 'Reporting Period must be created for Setup: '+cSetup.setup.Id+'.');
				}else{
					CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING, 'The master template must be created for '+cSetup.reportingPeriodList[0].Name__c+' before moving on to the next step.');
				}
			}
		}else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		isViewOnly = false;
	}

	//added for auto save templates and go to next step
	public PageReference saveTemplateAuto(){
		if(CT_SetupWizard_Utils.checkTemplates(cSetup.setup)) {//check if exsists and create new templates 
			initTemplateMass();
			if(!cSetup.setup.Group_Based__c){
				saveSchedTemplateMass();
			}else{
				saveSchedGrp();
			}
		}

		if(!CT_SetupWizard_Utils.checkTemplates(cSetup.setup)) {
			saveSetup();
			saveSchoolCalendar();
			return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.ROOMS,true,cSetup.setup);
		}
		return null;
	}	

	public void init(Setup__c setup){
		bConfigureTemplate = false;
		bIsNew = false;
		bIsClone = false;
		bPeriod = false;
		cloneTemplateId=null;
		templateId=null;
		sErrorMessages = new string[] {};
		periodList = new List <Period__c>{};
		cSetup = new CT_core_SetupWrapper(setup,'Setup Wizard Step 3');

		configureMassAddPanel = false; //new panel for mass add
		configureAddPanel = false; //add to bConfigureTemplate parameter(old panel)
		scheduleTemplateWrapperList = new List<ScheduleTemplateWrapper>();
		allScheduleTemplatesForPeriods = new List<Schedule_Template__c>();
		allPeriodsListForAllTemplates = new List<Period__c>();
		periodsFromPeriodTemplates = new List<Period__c>();
		periodSetOptionList = new List<SelectOption>();
	}

	private void initPeriodSetPicklist() {
		List<Period_Set__c> periodSetList = [SELECT Id, Name FROM Period_Set__c];
		if(periodSetList==null || periodSetList.isEmpty()){
			periodSetList = createMainPeriodSet();
		}
		System.debug('\n\n periodSetList => ' + periodSetList + '\n');
		for (Period_Set__c periodSetItem : periodSetList) {
			periodSetOptionList.add(new SelectOption(periodSetItem.Id, periodSetItem.Name));
		}
		System.debug('\n\n periodSetOptionList => ' + periodSetOptionList + '\n');
	}

	private List<Period_Set__c> createMainPeriodSet(){
		List<Period_Set__c> mainPeriod = new List<Period_Set__c>{new Period_Set__c(Name='Main')};
		insert mainPeriod;
		return mainPeriod;
	}

	public void showPeriods(){
		List<Period_Template__c> periodTemplates = new List<Period_Template__c>();

		if (selectedPeriodSet != null) {
			periodTemplates = queryPeriodTemplateByPeriodSetId(selectedPeriodSet);
		} else if(!periodSetOptionList.isEmpty()){
			periodTemplates = queryPeriodTemplateByPeriodSetId(periodSetOptionList[0].getValue());
		}else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'Period Set(Period_Set__c) must be exsists.');
		}
		System.debug('\n\n selectedPeriodSet => ' + selectedPeriodSet + '\n');
		System.debug('\n\n periodTemplates => ' + periodTemplates + '\n');
		fillPeriodListWIthTemplates(periodTemplates);
	}

	private List<Period_Template__c> queryPeriodTemplateByPeriodSetId(Id periodSetId){
		List<Period_Template__c> periodTemplates = [SELECT Order__c
				, Key__c
				, Start_Time__c
				, End_Time__c
				, Start_Time_Text__c
				, End_Time_Text__c
				, Type__c
				, Passing_Time__c
				, Description__c
		FROM Period_Template__c
		WHERE Period_set__c =: periodSetId];
		return periodTemplates;
	}

	private void fillPeriodListWIthTemplates(List<Period_Template__c> periodTemplates){
		if(periodTemplates == null || periodTemplates.isEmpty()){
			CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING, 'Period Templates aren`t exsists.');	
		}
		periodsFromPeriodTemplates.clear();
		for (Period_Template__c periodTemplate : periodTemplates) {
			periodsFromPeriodTemplates.add(	new Period__c(Order__c = periodTemplate.Order__c,
														Key__c = periodTemplate.Key__c,
														Start_Time__c = periodTemplate.Start_Time__c,
														End_Time__c = periodTemplate.End_Time__c,
														Start_Time_Text__c = periodTemplate.Start_Time_Text__c,
														End_Time_Text__c = periodTemplate.End_Time_Text__c,
														Type__c = periodTemplate.Type__c,
														Passing_Time__c = periodTemplate.Passing_Time__c,
														Description__c = periodTemplate.Description__c));
			System.debug('\n\n periodsFromPeriodTemplates => ' + periodsFromPeriodTemplates + '\n');
		}
	}

	public void initTemplateMass(){
		bConfigureTemplate=true;
		configureMassAddPanel = true;
		//system.debug('~~~~~ no existing templates, create new ' + cSetup.cRPeriodList[1].rPeriod.Name__c);

		initPeriodSetPicklist();
		showPeriods();
		for(Integer i = 0; i < cSetup.cRPeriodList.size(); i++) {
			system.debug('~~~~~ no existing templates, create new ' + cSetup.cRPeriodList[i].rPeriod.Name__c);
//			if(cSetup.cRPeriodList[i].rPeriod.Name__c == 'Prior Year') {
				scheduleTemplateWrapper = new ScheduleTemplateWrapper(cSetup.cRPeriodList[i].rPeriod.Id, cSetup.cRPeriodList[i].rPeriod.Parent_Time_Element__r.Name__c + '-' + cSetup.cRPeriodList[i].rPeriod.Name__c + '-ScheduleTemplate' , cSetup.setup.id, true, true);
				scheduleTemplateWrapperList.add(scheduleTemplateWrapper);
//			} else {
//				scheduleTemplateWrapper = new ScheduleTemplateWrapper(cSetup.cRPeriodList[i].rPeriod.Id, cSetup.cRPeriodList[i].rPeriod.Parent_Time_Element__r.Name__c + '-' + cSetup.cRPeriodList[i].rPeriod.Name__c + '-ScheduleTemplate' , cSetup.setup.id, false, true);
//				scheduleTemplateWrapperList.add(scheduleTemplateWrapper);
//			}
		}
		//system.debug('~~~~~ scheduleTemplateWrapperList ' + scheduleTemplateWrapperList);
	}

	public void checkMastersOnTemplatesMass(List<Schedule_Template__c> selectedTemplates) {
		List<Schedule_Template__c> templatesAfterMastercChange = new List<Schedule_Template__c>();
		for(Schedule_Template__c template : selectedTemplates) {
			if(template.is_Master__c == true) {
				scheduleTemplateList = cSetup.rpScheduleTemplateMap.get(template.reporting_period__c);
				if(scheduleTemplateList!= null && scheduleTemplateList.size() > 0){
					for (Schedule_Template__c st: scheduleTemplateList){
						st.Is_Master__c=false;
					}
					templatesAfterMastercChange.addAll(scheduleTemplateList);
				}
			}
		}
		upsert templatesAfterMastercChange;
	}

	public void saveSchedTemplateMass(){
//		try{
//			if (!allPeriodsListForAllTemplates.isEmpty()) {
//				upsert allPeriodsListForAllTemplates;
//			}
//			if(selectedTemplates == null) {
//				selectedTemplates = generateTemplates();
//			}
//				checkMastersOnTemplatesMass(selectedTemplates);
//				upsert selectedTemplates;
//
//			allPeriodsListForAllTemplates.clear();
//			init(cSetup.setup);
//		}
//		catch(Exception e){
//			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the schedule template.'));
//			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving schedule template', e);
//			insert ge;
//		}
 		try{
			List<Period__c> periodsforInsert = new List<Period__c>();
			Period__c tempPeriod;

			selectedTemplates = generateTemplates();


			checkMastersOnTemplatesMass(selectedTemplates);

			upsert selectedTemplates;

			for (Schedule_Template__c schTemplate: selectedTemplates) {
				for (Period__c onePeriod : periodsFromPeriodTemplates) {
					tempPeriod = onePeriod.clone();
					tempPeriod.Schedule_Template__c = schTemplate.id;
					periodsforInsert.add(tempPeriod);
				}
			}
			insert periodsforInsert;
			init(cSetup.setup);
//			saveSchoolCalendar();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the schedule template.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+(schedTemplate!=null? schedTemplate.id: null), 'Core (Template)', 'error saving schedule template', e);
			insert ge;
		}
	}

	public List<Schedule_Template__c> generateTemplates() {
		List<Schedule_Template__c> selectedTemplates = new List<Schedule_Template__c>();
		List<Schedule_Template__c> selectedTemplatesForInsert = new List<Schedule_Template__c>();

		System.debug('scheduleTemplateWrapperList ' + scheduleTemplateWrapperList);

		for(ScheduleTemplateWrapper wrapper : scheduleTemplateWrapperList) {

			System.debug('wrapper.schedule_template.Color__c ' + wrapper.schedule_template.Color__c);
			System.debug('wrapper.schedule_template.is_Master__c ' + wrapper.schedule_template.is_Master__c);

			allScheduleTemplatesForPeriods.add(wrapper.schedule_template);
			if(wrapper.isSelected) {
				selectedTemplates.add(wrapper.schedule_template);
				if(wrapper.schedule_template.Id == null) {
					selectedTemplatesForInsert.add(wrapper.schedule_template);
				}
			}
		}

		if(periodsFromPeriodTemplates!=null && !periodsFromPeriodTemplates.isEmpty()){
			for(Schedule_Template__c template : selectedTemplatesForInsert){
				template.Start_Time__c = periodsFromPeriodTemplates[0].Start_Time__c;
				template.End_Time__c = periodsFromPeriodTemplates.get(periodsFromPeriodTemplates.size() - 1).End_Time__c;
			}
		}
		insert selectedTemplatesForInsert;

		return selectedTemplates;
	}

	public void upsertPeriodListMass(List <Period__c> thisPeriodList){//Method to call when upserting Periods for validation purposes

		sErrorMessages = new String[]{};
		DateTime validationTime;
		System.debug('selectedTemplates ' + selectedTemplates);

		for (Schedule_Template__c schTemplate: selectedTemplates) {

			for (integer i = 0; i < thisPeriodList.size(); i++) {
				Period__c p = thisPeriodList[i].clone();
				p.Schedule_Template__c = schTemplate.id;
				p.Schedule_Template__r = schTemplate;
				p.order__c = allPeriodsListForAllTemplates.size() + 1;

				System.debug('selectedTemplates ' + selectedTemplates);
				System.debug('Period__c p ' + p);
				System.debug('Period__c p.order__c ' + p.order__c);

				validateMandatoryFields(p);

				if (!bErrors) {
					if (cSetup.setup.Chronological_Periods__c) {
						if (i == 0) validationTime = CT_core_TimeUtils.processTimeText(p.end_time_text__c); else {
							//	 Commented out PTN 10/6 ELH deployment
							//PU 956
							if (validationTime > CT_core_TimeUtils.processTimeText(p.start_time_text__c)) {
								sErrorMessages.add('Period times must be chronological');
								bErrors = true;
							} else validationTime = CT_core_TimeUtils.processTimeText(p.end_time_text__c);
						}
					}
				}
				if (!bErrors) {
					p.Start_Time__c = CT_core_TimeUtils.processTimeText(p.Start_Time_Text__c);
					p.End_Time__c = CT_core_TimeUtils.processTimeText(p.End_Time_Text__c);
				}
				if (sErrorMessages.isEmpty()){
					bPeriod = false;
					allPeriodsListForAllTemplates.add(p);
				}
				else {
					processErrorMessages();
				}
			}


			System.debug('allPeriodsListForAllTemplates ' + allPeriodsListForAllTemplates);
		}
		periodList.clear();
	}

	public void cancelschedTemplateMass(){
		try{
			if(selectedTemplates !=null && !selectedTemplates.isEmpty()){
				delete selectedTemplates;
			}
			bConfigureTemplate=false;
			init(cSetup.setup);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while redirecting the page.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error redirecting to setup page', e);
			insert ge;
		}
	}


	public void deleteRowMass(){
		try{
			if (System.currentPageReference().getParameters().get('scheduleTemplateId')!=null){
				Id scheduleTemplateId = System.currentPageReference().getParameters().get('scheduleTemplateId');
				if(!allPeriodsListForAllTemplates.isEmpty()) {
					for(Integer i = 0; i < allPeriodsListForAllTemplates.size(); i++) {
						if(allPeriodsListForAllTemplates.get(i).Schedule_Template__c == scheduleTemplateId) {
							allPeriodsListForAllTemplates.remove(i);
						}
					}
				}
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while updating the period configuration.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error updating periods', e);
			insert ge;
		}
	}

	class ScheduleTemplateWrapper {
		public Boolean isSelected {get;set;}
		public Schedule_Template__c schedule_template {get;set;}

		public ScheduleTemplateWrapper(Id reporting_period, String wrName, Id setup, Boolean isMaster, Boolean hasClass) {
			schedule_template = new Schedule_Template__c(
					Reporting_Period__c = reporting_period,
					Name = wrName,
					setup__c = setup,
					is_Master__c = isMaster,
					has_Class__c = hasClass);
			this.isSelected = true;

		}

	}


	public void getReportingPeriodOptions(Id termId){
		reportingPeriodOptionList = new List<SelectOption>();
		for (Time_Element__c rp: CT_core_SoqlUtils.getTimeElementsByTerm(termId, true)){
			reportingPeriodOptionList.add(new SelectOption(rp.id, rp.Name__c)); //Populates list of possible reporting periods
		}
	}

	public void initTemplate(){
		bConfigureTemplate=true;
		configureAddPanel = true;
		if (templateId!=null && templateId!=''){
			system.debug('~~~~ templateId: '+templateId);
			schedTemplate = CT_core_SoqlUtils.getTemplateById(templateId);
			//add validation that schedule templates related to attendance can't be edited
			List<Schedule_Day__c> days = [SELECT Day__c FROM Schedule_Day__c WHERE Schedule_Template__c=:templateId];
			Set<Date> dates = new Set<Date>();
			for(Schedule_Day__c sd: days) dates.add(sd.Day__c);
			List<Attendance__c> att = [SELECT id FROM Attendance__c
			WHERE Session_Date__c IN :dates
			AND Session__r.Section__r.School__c=:cSetup.school.id
			AND Session__r.Section__r.Time__c=:cSetup.setup.Year__c];
			if(att.size()==0 || isViewOnly){
				if(!cSetup.setup.Group_Based__c) retrievePeriods(false, TemplateId);
				rpId = schedTemplate.reporting_period__c;
			}
			else if(!isViewOnly){
				CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This schedule template has attendance records submitted.  Once attendance records are submitted, you cannot edit the schedule template.  You can add new schedule templates at any time.');
				bConfigureTemplate=false;
				configureAddPanel = false;
			}
		}
		else {
			scheduleTemplateList = cSetup.rpScheduleTemplateMap.get(rpId);
			if (scheduleTemplateList==null) scheduleTemplateList = new List <Schedule_Template__c>();
			if (scheduleTemplateList.isEmpty()){
				system.debug('~~~~~ no existing templates, create new');
				schedTemplate = new Schedule_Template__c(Reporting_Period__c = rpId, Name='Master', setup__c=cSetup.setup.id, is_master__c = true, has_class__c = true);
				bIsNew = true;
			}
			else{
				if (cloneTemplateId!=null){
					bIsClone = true;
					system.debug('~~~~~ cloneTemplateId: '+cloneTemplateId);
					schedTemplate = CT_core_SoqlUtils.getTemplateById(cloneTemplateId).clone(false);
					schedTemplate.name = 'Copy - '+schedTemplate.name;
					if(!cSetup.setup.Group_Based__c)
						retrievePeriods(true, cloneTemplateId);
				}
				else {
					system.debug('~~~~~ net new template');
					schedTemplate = new Schedule_Template__c(Reporting_Period__c = rpId, Name='New', setup__c=cSetup.setup.id, is_master__c = false, has_class__c = true);
					bIsNew = true;
				}
			}
		}
	}

	public void retrievePeriods(boolean cloneMaster, string ptId){
		periodList.clear();
		integer i = 1;
		for (Period__c p: [Select Start_Time__c, Start_Time_Text__c, End_Time__c, End_Time_Text__c, Key__c, p.Type__c, p.Time__c, p.SystemModstamp, p.Schedule_Template__c, p.Passing_Time__c, p.Order__c, p.Name, p.LastModifiedDate, p.LastModifiedById, p.IsDeleted, p.Id, p.Description__c, p.CreatedDate, p.CreatedById, p.Class_Minutes__c, p.Abbreviation__c
		From Period__c p
		Where Schedule_Template__c =:ptId
		and isDeleted = false
		order by order__c asc]){
			p.order__c = i;
			if (cloneMaster) periodList.add(p.clone(false)); //If user is creating a new Period template, they want to clone the master as a base
			else periodList.add(p); //Since record actually has a period templateId bring back the acutal records and use those
			i++;
		}
	}

	public void addPeriodRow(){
		try{

			System.debug('==================================>1 ' + bPeriod);
			sErrorMessages.clear();
			System.debug('allPeriodsListForAllTemplates.isEmpty() ' + allPeriodsListForAllTemplates.isEmpty());
			System.debug('periodList.isEmpty() ' + periodList.isEmpty());
			if (!periodList.isEmpty() || !allPeriodsListForAllTemplates.isEmpty()){
				Period__c p = periodList[periodList.size()-1];
				System.debug('==================================>2 ' + bPeriod);
				validateMandatoryFields(p); //Check that the original row passes validation
				System.debug('==================================>3 ' + bPeriod);
				if (!bErrors) { //If it passes validation
					System.debug('==================================>4 ' + bPeriod);
					p.Start_Time__c=CT_core_TimeUtils.processTimeText(p.Start_Time_Text__c);
					p.End_Time__c=CT_core_TimeUtils.processTimeText(p.End_Time_Text__c);
					System.debug('==================================>5 ' + bPeriod);
					period = p.clone(false);
					if (p.End_Time__c!=null&&p.Start_Time__c!=null) {
						System.debug('==================================>6 ' + bPeriod);
						if (p.Passing_Time__c ==null) p.Passing_Time__c = '0';
						period.Start_Time__c = p.End_Time__c.addMinutes(Integer.valueOf(p.Passing_Time__c));
						period.start_Time_Text__c = period.start_time__c.format('hh:mm a');
						integer endTimeMins = CT_core_TimeUtils.getMinutes(p.End_Time__c);
						integer startTimeMins = CT_core_TimeUtils.getMinutes(p.Start_Time__c);
						integer duration = Integer.valueOf(p.Passing_Time__c)+ (endTimeMins-startTimeMins);
						period.end_Time__c = p.End_Time__c.addMinutes(duration);
						period.end_Time_Text__c = period.end_Time__c.format('hh:mm a');
						System.debug('==================================>7 ' + bPeriod);
					}
					System.debug('==================================>7 ' + bPeriod);
					period.order__c = p.order__c+1;
					period.Key__c  = string.valueOf(period.order__c);
					bPeriod = true;
				}
				else processErrorMessages();
				System.debug('==================================>8 ' + bPeriod);
			}
			else {
				System.debug('==================================>9 ' + bPeriod);
				period = new Period__c(key__c='1', Order__c=1);
				bPeriod = true;
				System.debug('==================================>10 ' + bPeriod);
			}
		}
		catch(Exception e){
			system.debug('deddddddddddddddd');
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while creating a new period.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+templateId, 'Core (Template)', 'error adding period', e);
			insert ge;
		}
	}

	public void deleteRow(){
		Period__c deleteP;
		try{
			upsertPeriodList(periodList);
			if (System.currentPageReference().getParameters().get('periodId')!=null){
				Id periodId = System.currentPageReference().getParameters().get('periodId');
				List <Period__c> pList = new List <Period__c>();
				for(Period__c p: periodList){
					if(p.id==periodId) deleteP = p;
					else pList.add(p);
				}
				if (deleteP != null)
					delete deleteP;
				upsertperiodList(pList);
			}
			retrievePeriods(false, schedTemplate.id);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while updating the period configuration.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error updating periods', e);
			insert ge;
		}
	}

	public void editRow(){
		if(ApexPages.currentPage().getParameters().containsKey('periodId')){
			Id periodId = ApexPages.currentPage().getParameters().get('periodId');
			for(Period__c p : periodList){
				if(p.id==periodId) period = p;
			}
			bPeriod = true;
		}
	}

	public void savePeriod(){
		System.debug('1 =>>' + scheduleTemplateWrapperList);
		if(configureAddPanel == true) {
			if(period.id==null) periodList.add(period);
			upsertPeriodList(periodList);
		}
		if(configureMassAddPanel == true) {
			if(period.id==null) periodList.add(period);
			System.debug('periodList ' + periodList);
			selectedTemplates = generateTemplates();
			System.debug('selectedTemplates ' + selectedTemplates);
			upsertPeriodListMass(periodList);
		}
	}

	public void validateMandatoryFields(Period__c p){
		bErrors=false;
		System.debug('first if');
		if (p.key__c==null || p.key__c=='') {
			sErrorMessages.add('Identifier must be populated');
			bErrors = true;
			System.debug('first if');
		}
		else if(p.key__c.contains(',')||p.key__c.contains(';')){
			sErrorMessages.add('Period identifiers cannot contain the "," or ";" special characters.  Please revise your period identifier.');
			bErrors=true;
			System.debug('second if');
		}
		System.debug('second if');
		System.debug('third if');
		if (p.start_time_text__c==null||p.start_time_text__c==''){
			sErrorMessages.add('Start time must be populated');
			bErrors = true;
			System.debug('third if');
		}
		System.debug('fourth if');
		if (p.end_time_text__c == null||p.end_time_text__c==''){
			sErrorMessages.add('End time must be populated');
			bErrors = true;
			System.debug('fourth if');
		}
		System.debug('fifth if');
		if (CT_core_TimeUtils.processTimeText(p.start_time_text__c ) > CT_core_TimeUtils.processTimeText(p.end_time_text__c)){
			sErrorMessages.add('End time must be greater than the start time');
			bErrors=true;
			System.debug('fifth if');
		}
	}

	public void validateTemplateMandatoryFields(Schedule_Template__c st){
		bErrors=false;

		if (st.Start_Time_Text__c == null || st.Start_Time_Text__c == ''){
			sErrorMessages.add('Start time must be populated when Has Class? is checked');
			bErrors = true;
		}

		if (st.end_time_text__c == null||st.end_time_text__c==''){
			sErrorMessages.add('End time must be populated when Has Class? is checked');
			bErrors = true;
		}
		if (!bErrors){
			if(st.Start_Time_Text__c != '' && st.end_time_text__c != '' && CT_core_TimeUtils.processTimeText(st.Start_Time_Text__c) > CT_core_TimeUtils.processTimeText(st.end_time_text__c)){
				sErrorMessages.add('End time must be greater than the start time');
				bErrors=true;
			}
		}
	}

	public void upsertPeriodList(List <Period__c> thisPeriodList){//Method to call when upserting Periods for validation purposes
		List <Period__c> rollBackList = thisPeriodList;
		Set <String> periodKeys = new Set<String>{};
		sErrorMessages = new String[]{};
		DateTime validationTime ;
		for (integer i= 0; i< thisPeriodList.size(); i++){
			Period__c p= thisPeriodList[i];
			if (schedTemplate.id==null) upsert schedTemplate;
			if (p.id==null) p.Schedule_Template__c=schedTemplate.id;
			p.order__c = i+1;
			validateMandatoryFields(p);
			if (!bErrors){
				if(cSetup.setup.Chronological_Periods__c){
					if (i ==0) validationTime = CT_core_TimeUtils.processTimeText(p.end_time_text__c);
					else {
						//	 Commented out PTN 10/6 ELH deployment
						//PU 956
						if (validationTime > CT_core_TimeUtils.processTimeText(p.start_time_text__c)){
							sErrorMessages.add('Period times must be chronological');
							bErrors=true;
						}
						else validationTime =  CT_core_TimeUtils.processTimeText(p.end_time_text__c);
					}
				}
				if (periodKeys.contains(p.key__c)) {
					sErrorMessages.add('Period Identifiers must be unique for scheduling purposes');
					bErrors=true;
				}
				else periodKeys.add(p.key__c);
			}
			if (!bErrors){
				p.Start_Time__c= CT_core_TimeUtils.processTimeText(p.Start_Time_Text__c);
				p.End_Time__c= CT_core_TimeUtils.processTimeText(p.End_Time_Text__c);
			}
		}

		if (sErrorMessages.isEmpty()){
			upsert thisPeriodList;
			bPeriod = false;
		}
		else {
			processErrorMessages();
		}
		retrievePeriods(false,schedTemplate.id);
	}

	public void processErrorMessages(){
		for (String s: sErrorMessages){
			Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, s));
			if (!bErrors) bErrors = true;
		}
	}

	public void cancelschedTemplate(){
		try{
			if(schedTemplate.id!=null&&bIsNew){
				templateId = schedTemplate.id;
				deleteTemplate();
			}
			bConfigureTemplate=false;
			init(cSetup.setup);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while redirecting the page.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error redirecting to setup page', e);
			insert ge;
		}
	}


	public void deleteTemplate(){
		try{
			schedTemplate = CT_core_SoqlUtils.getTemplateById(templateId);
			delete schedTemplate;
		}
		catch(Exception e){
		}
		init(cSetup.setup);
	}

	public void checkMastersOnTemplates(){
		scheduleTemplateList = cSetup.rpScheduleTemplateMap.get(schedTemplate.reporting_period__c);
		if(scheduleTemplateList!= null && scheduleTemplateList.size() > 0){
			for (Schedule_Template__c st: scheduleTemplateList){
				st.Is_Master__c=false;
			}
			upsert scheduleTemplateList;
		}
	}

	public void saveSchedTemplate(){
		try{
			if (schedTemplate.Is_Master__c) checkMastersOnTemplates();
			upsert schedTemplate;
			if (!periodList.isEmpty()){
				upsertPeriodList(periodList);
				system.debug('~~~~~ periodList: '+periodList);
				schedTemplate.Start_Time__c = periodList[0].Start_Time__c ;
				system.debug('~~~~~ start time: '+periodList[0].Start_Time__c );
				schedTemplate.End_Time__c = periodList[periodList.size()-1].End_Time__c;
				system.debug('~~~~~ end time: '+periodList[periodList.size()-1].End_Time__c);
				upsert schedTemplate;
			}
			if (sErrorMessages.isEmpty()) init(cSetup.setup);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the schedule template.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving schedule template', e);
			insert ge;
		}
	}

	public void saveAndNew(){
		try{
			saveSchedTemplate();
			if(!bConfigureTemplate) initTemplate();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the schedule template.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving template', e);
			insert ge;
		}
	}

	public void saveSchedGrp(){
		try{
			sErrorMessages.clear();
			List<Scheduled_Section__c> insertSSecList = new List<Scheduled_Section__c>();
			if(schedTemplate != null ){
				if(schedTemplate.Has_Class__c == true) validateTemplateMandatoryFields(schedTemplate);
				if (sErrorMessages.isEmpty()){
					if(schedTemplate.Has_Class__c == true){
						schedTemplate.Start_Time__c= CT_core_TimeUtils.processTimeText(schedTemplate.start_Time_Text__c);
						schedTemplate.End_Time__c= CT_core_TimeUtils.processTimeText(schedTemplate.End_Time_Text__c);
					}
					if (schedTemplate.Is_Master__c) checkMastersOnTemplates();//DE843
					upsert schedTemplate;
				}
				else{
					processErrorMessages();
					return;
				}
			}

			if(bIsClone && schedTemplate.Has_Class__c){
				if (cSetup.setup.Group_Based__c) core_TriggerUtils.bGroupAgenda=true;
				insertSSecList = CT_scheduler_SoqlUtils.getClonedScheduledSections(cloneTemplateId, schedTemplate.Id, schedTemplate.Reporting_Period__c);
				if(insertSSecList.size() > 0)
					upsert  insertSSecList Reference_Id__c;
			}
			init(cSetup.setup);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while updating the schedule.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting Period, '+rpId+'; Schedule Template, '+schedTemplate.id, 'Core (Template)', 'error saving schedule group', e);
			insert ge;
		}
	}

	//gather available course catalogs
	public List<Course_Catalog__c> returnAvailableCatalogs(){
		List<Course_Catalog__c> availableCatalogs = new List <Course_Catalog__c>();
		for (Course_Catalog__c cat:  [ SELECT c.Name, c.Course_Catalog_Description__c, c.LastModifiedDate, c.CreatedDate, c.Course_Catalog_Status__c, c.id
										FROM Course_Catalog__c c
										WHERE c.Course_Catalog_Status__c = true]){
			availableCatalogs.add(cat);
		}
		System.debug('\n\n availableCatalogs => ' + availableCatalogs + '\n');
		return availableCatalogs;
	}

	public void saveSetup(){
		try{
			List<Course_Catalog__c> courseCatalogs = returnAvailableCatalogs();
			if (courseCatalogs[0]!=null){
				cSetup.setup.Course_Catalog__c = courseCatalogs[0].Id;
				System.debug('\n\n cSetup.setup => ' + cSetup.setup + '\n');
				update  cSetup.setup;
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error updating the course catalog on the setup record.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, ' + cSetup.setup.id + '; Course Catalog, ' + cSetup.setup.Course_Catalog__c, 'Course Catalog', 'error updating course catalog on setup', e);
			insert ge;
		}
	}

	public void saveSchoolCalendar(){
		CT_ReportingPeriodCalendarController calendarController = new CT_ReportingPeriodCalendarController();

			for(Integer i = 0; i < cSetup.reportingPeriodList.size(); i++) {
				calendarController.currRepPeriod = cSetup.reportingPeriodList[i].Id;
				calendarController.currRepPeriodName = calendarController.repPeriodCal.repPeriodIdToName.get(calendarController.currRepPeriod);
				calendarController.refreshView();
				calendarController.save();
			}
	}
	public PageReference prev(){
//		return CT_SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.SELECTIONS,false,cSetup.setup);
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.TERMS,false,cSetup.setup);
	}

	public PageReference next(){
		if(!CT_SetupWizard_Utils.checkTemplates(cSetup.setup)) {
			saveSetup();
			saveSchoolCalendar();
			return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.ROOMS,true,cSetup.setup);
		}
//		if(!CT_SetupWizard_Utils.checkTemplates(cSetup.setup)) return CT_SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.CALENDAR,true,cSetup.setup);
		else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The master template must be created for '+cSetup.reportingPeriodList[0].Name__c+' before moving on to the next step.');
			return null;
		}
	}



	static testMethod void test_core_schedTemplateConfiguration(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		PageReference pr  = Page.core_scheduleTemplate;
		pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
		test.setCurrentPage(pr);
		Test.startTest();
		CT_core_ScheduleTemplateConfiguration controller = new CT_core_ScheduleTemplateConfiguration();
		controller.rpID = TestDataSetupUtil_v2.semester.id;
		controller.initTemplate();

		controller.schedTemplate.name = 'Test';
		controller.schedTemplate.Is_Master__c = true;
		controller.addPeriodRow();
		controller.period.key__c= 'A';
		controller.period.start_Time_text__c='08:00 AM';
		controller.period.end_time_text__c='09:00 AM';
		controller.period.Passing_Time__c = '5';
		controller.savePeriod();

		controller.addPeriodRow();
		system.assertEquals(controller.period.start_Time_text__c,'09:05 AM');
		system.assertEquals(controller.period.end_time_text__c,'10:05 AM');
		system.assertEquals(controller.period.order__c,2);
		system.assertEquals(controller.PeriodList[0].key__c,'A');
		system.assertEquals(controller.period.key__c,'2');
		controller.savePeriod();

		controller.saveschedTemplate();
		Schedule_Template__c pt = controller.schedTemplate;
		controller.TemplateID = pt.id;
		controller.initTemplate();
		controller.periodList[1].key__c = null;
		controller.saveschedTemplate();
		controller.periodList[1].key__c = 'B';
		ApexPages.currentPage().getParameters().put('periodId',controller.periodList[1].id);
		controller.saveschedTemplate();
		Schedule_Template__c pt2 =[select id, number_of_periods__c from Schedule_Template__c where id=:pt.id];
		system.assertEquals(pt2.Number_of_Periods__c,2);
		controller.TemplateID = pt2.id;
		controller.initTemplate();
		controller.editRow();
		controller.deleteRow();
		system.assertEquals(1,controller.periodList.size());
		PageReference pr2 = Page.core_scheduleTemplate;
		pr2.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
		test.setCurrentPage(pr2);
		CT_core_ScheduleTemplateConfiguration controller2 = new CT_core_ScheduleTemplateConfiguration();
		controller2.TemplateID = pt2.id;
		controller2.initTemplate();
		controller2.cancelschedTemplate();
		controller2.saveTemplateAuto();
		Test.stopTest();
	}
}