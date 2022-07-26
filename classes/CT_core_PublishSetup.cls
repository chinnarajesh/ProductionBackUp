public with sharing class CT_core_PublishSetup {

	public String 				setupId				{get;set;} // setup that is being published
	public CT_core_SetupWrapper	cSetup				{get;set;} // setup wrapper for the setup with id setupId
	public List<RPWrapper>		reportingPeriods	{get;set;} // wrapper for reporting periods to keep publishing in order
	public List<Data_Load_Log__c> logs				{get;set;} // list of all load logs for this setup
	public String				rpId				{get;set;} // currently chosen reporting period
	public List<String> 		termsToPublish		{get;set;}
	public List<Id> 			termIds				{get;set;}
	public List<Term__c> 		selectedTermObjectsInSetup		{get;set;}
	public Boolean				bOccupancyError		{get;set;}
	public boolean				bProcessing			{get;set;} // indicates whether there is a batch processing or not
	public CT_BatchWrapper		batch				{get;set;} // holds data related to the running batch
	
	public boolean				bException			{get;set;} // boolean for code coverage in test class
	public boolean				nonRPBased			{get;set;} // boolean for generic publish (for holding objs without reporting period)
	public boolean				bOpenModal			{get;set;}

		
	public CT_core_PublishSetup(ApexPages.StandardController controller){
		try{
			//initialize variables
			bOpenModal = false;
			bProcessing = false;
			bException = false;
			bOccupancyError = false;
			reportingPeriods = new List<RPWrapper>();
			termsToPublish = new List<String>();
			if(System.currentPageReference().getParameters().containsKey('failed'))
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'Batch job has failed.  Please try again later.'));
			if (System.currentPageReference().getParameters().containsKey('setupId')) {
				setupId = System.currentPageReference().getParameters().get('setupId');
				cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'publish');
				termIds = getSetupTermsFromTermObject();
				cSetup.reportingPeriodList = CT_core_SoqlUtils.getTimeElementsByTerms(termIds, true);
				checkTermsOccupancy();


//				if(CT_SetupWizard_Utils.checkPublish(cSetup.setup)){
//					CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There are still records that need to be published before moving on to the next step.');
//				}
				
				//create maps to relate reporting periods to:
				// 1) previous data load logs
				// 2) scheduled sections that need to be published
				// 3) holding objects
				// 4) schedule days
				logs = [SELECT id, OwnerId, LastModifiedDate, End_Time_Text__c, Type__c, Status__c, Failed_Records__c, Messages__c, Total_Records__c, Reporting_Period__c 
							FROM Data_Load_Log__c 
							WHERE Setup__c = :setupId 
							AND Class_Name__c ='CT_Scheduler_HoldingProcessor'
							ORDER BY End_Time__c ASC];
				Map<ID, List<Data_Load_Log__c>> logsByReportingPeriod = new Map<ID, List<Data_Load_Log__c>>();
				for(Data_Load_Log__c dll : logs){
					if(!logsByReportingPeriod.containsKey(dll.Reporting_Period__c)) 
						logsByReportingPeriod.put(dll.Reporting_Period__c, new List<Data_Load_Log__c>());
					logsByReportingPeriod.get(dll.Reporting_Period__c).add(dll);
				}
				Map<ID,List<Scheduled_Section__c>> rpIdToSchedSecs = CT_scheduler_SoqlUtils.getScheduledSectionsForPublish(cSetup.school.id);
				Map<ID,List<HoldingObj__c>> holdingObjsByReportingPeriod = CT_scheduler_SoqlUtils.getHoldingObjsForPublish(cSetup.school.Reference_Id__c,cSetup.setup.Year__r.Name__c);
				Set<ID> scheduleDaysByReportingPeriod = new Set<ID>();
				for(Schedule_Day__c sd: [SELECT ID, Reporting_Period__c FROM Schedule_Day__c WHERE Schedule_Template__r.Setup__c = :cSetup.setup.id]){
					scheduleDaysByReportingPeriod.add(sd.Reporting_Period__c);
				}
				List<String> noScheduleDays = new List<String>();

				//end map population
				if(cSetup.reportingPeriodList != null){
					for(Time_Element__c te : cSetup.reportingPeriodList){
						RPWrapper rpw = new RPWrapper(te);
						if(logsByReportingPeriod.containsKey(te.id))
							rpw.addLog(logsByReportingPeriod.get(te.id));
						if(rpIdToSchedSecs.containsKey(te.id)) rpw.hasSects = true;

						//from the holding objects for the reporting period, determine whether this reporting period
						//needs to be published, has already been published, or has errored during publish
						if(holdingObjsByReportingPeriod.containsKey(te.id)){
							rpw.toPublish = holdingObjsByReportingPeriod.get(te.id);
							List<HoldingObj__c> errors = new List<HoldingObj__c>();
							for(HoldingObj__c ho: holdingObjsByReportingPeriod.get(te.id)){
								if(!ho.propagated__c){
									rpw.needPublish = true; // just check that not all have been propagated
									if (ho.Error_Message__c!=null) {
										if(errors.size() > 999)
											break;
										else	
											errors.add(ho); 
									} // if theres an error then push to the errors
								}
							}

							//if there are errored holding objects
							if(errors.size()>0){

								//if some holding objects propagated and some not, possible errors involved
								//warn user to check error messages
								rpw.errors = errors;
							}
						}
						if(!scheduleDaysByReportingPeriod.contains(te.id)) noScheduleDays.add(te.Name__c);
						reportingPeriods.add(rpw);
					}
				}

				//if modules are not completed, disable all publishing
				if(CT_SetupWizard_Utils.checkModuleSetupComplete(cSetup.setup.id)){
					boolean firstEnable = true;

					//figure out which button to enable
					//unpublished scheduled sections always take precedence
					for(RPWrapper wrap : reportingPeriods){
						if(wrap.hasSects && firstEnable){
							ApexPages.addMessage(new apexpages.message(apexpages.severity.INFO, 'There are records for '+wrap.te.Name__c+' that require publish.'));
							wrap.bSetup = true;
							firstEnable = false;
						}
						else if(wrap.needPublish && !wrap.errors.isEmpty() && firstEnable){
							ApexPages.addMessage(new apexpages.message(apexpages.severity.INFO, 'There are records that still need to be published. This table will display up to 1000 records. Please review any errors and try again. '));
							wrap.bPublish = true;
							firstEnable = false;
						}
						else if(wrap.needPublish && firstEnable){
							ApexPages.addMessage(new apexpages.message(apexpages.severity.CONFIRM,'Records for '+wrap.te.Name__c+' set up successfully.'));
							wrap.bPublish = true;
							firstEnable = false;
						}
					}
					//if no reporting periods are in need of action, display confirmation message
					if(firstEnable) ApexPages.addMessage(new apexpages.message(apexpages.severity.CONFIRM,'All reporting periods have been successfully published.  No action required.'));
					
					//determine if any records are available for publish that are not related to a reporting period
					nonRPBased = false;
					if(holdingObjsByReportingPeriod.containsKey(null)){
						for(HoldingObj__c ho: holdingObjsByReportingPeriod.get(null)){
							if(!ho.Propagated__c) nonRPBased = true;
						}
					}
				}
				else{
					CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There is a Module Wizard still in progress. All Module Wizards must be finalized prior to publishing. Please finalize all Module Wizards.');
				}
				//figure out if there are scheduled sections to publish WITHOUT reporting periods--these are problems
				Integer probs = [SELECT count() FROM Scheduled_Section__c WHERE Needs_Publish__c = true AND Account__c = :cSetup.school.id AND Reporting_Period__c = null];
				if(probs > 0) ApexPages.addMessage(new apexpages.Message(apexpages.severity.error, 'There are scheduled sections that need published that are not associated with a reporting period.  These scheduled sections cannot be published until a reporting period is assigned.'));
				
				
				//DE2661 add error message for any reporting period that has no schedule days
				//inform user that they need to save the calendar
				if(!noScheduleDays.isEmpty()){
					string errorMessage = '';
					for(String s: noScheduleDays){
						if(errorMessage!='') errorMessage+=', ';
						errorMessage+=s;
					}
//					ApexPages.addMessage(new apexpages.message(apexpages.severity.INFO,'The school calendar has not been saved for the following reporting periods: '+errorMessage+'.  Sessions will not be created for these reporting periods.'));
				}
			}
			else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while loading the page.'));
		}
	}
	
	public PageReference continueBatch(){
		try{
			boolean failed = batch.continueBatch();
			System.debug('\n\n failed => ' + failed + '\n');
			if(failed!=null) return CT_SetupWizard_Utils.refreshPage(setupId,failed);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while checking the status of the batch.'));
//			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Batch, '+batch.batchId, 'Core (Publish)', 'batch check failed', e);
//			insert ge;
		}
		return null;
	}


	private void checkTermsOccupancy() {
		Boolean sectionsChecked;
		List<Time_Element__c> reportingPeriodsWithChildren = [SELECT Id, Name__c, parent_time_element__c, parent_time_element__r.Name__c,
																(SELECT Id, Name FROM Sections1__r),
																(SELECT Id, Name FROM Scheduled_Sections__r),
																(SELECT Name FROM Schedule_Templates__r)
															FROM Time_Element__c
															WHERE parent_time_element__c IN : termIds];
		for (Term__c term : selectedTermObjectsInSetup) {
			Integer countReportingPeriods = 0;
			sectionsChecked = false;
			for (Time_Element__c repPeriod : reportingPeriodsWithChildren) {
				if (term.Time_Element__r.Id == repPeriod.parent_time_element__c) {
					System.debug('\n\n repPeriod.parent_time_element__r.Name__c => ' + repPeriod.parent_time_element__r.Name__c + '\n');

					if(repPeriod.Schedule_Templates__r.isEmpty() || repPeriod.Schedule_Templates__r == null) {
						ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Scheduled Templates in  ' + repPeriod.parent_time_element__r.Name__c + ' term. Please fill them in for publication opportunities. ' + repPeriod.Name__c));
						bOccupancyError = true;
					}
					if(!sectionsChecked) {
						if(repPeriod.Sections1__r.isEmpty() || repPeriod.Sections1__r == null) {
//							ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Sections in  ' + repPeriod.parent_time_element__r.Name__c + ' term. Please fill them in for publication opportunities. ' + repPeriod.Name__c));
							bOccupancyError = true;
						}
						sectionsChecked = true;
					}

					if(repPeriod.Scheduled_Sections__r.isEmpty() || repPeriod.Scheduled_Sections__r == null) {
						ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Scheduled Sections in  ' + repPeriod.parent_time_element__r.Name__c + ' term. Please fill them in for publication opportunities. ' + repPeriod.Name__c));
						bOccupancyError = true;
					}
					countReportingPeriods++;
				}
			}
			if (countReportingPeriods == 0) {
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no Reporting Periods in  ' + term.Time_Element__r.Name__c + ' term. Please fill them in for publication opportunities.'));
				bOccupancyError = true;
			}
		}
	}

	private List<Id> getSetupTermsFromTermObject() {
		List<Id> termIds = new List<Id>();
		selectedTermObjectsInSetup = [SELECT Id, Time_Element__r.Id, Time_Element__r.Name__c FROM Term__c WHERE Setup__c=:cSetup.setup.Id AND Time_Element__c!=NULL];
		for (Term__c selectedTerm : selectedTermObjectsInSetup) {
			termIds.add(selectedTerm.Time_Element__r.Id);
			termsToPublish.add(selectedTerm.Time_Element__r.Name__c);
		}
		return termIds;
	}

	private List<Scheduled_Section__c> queryScheduleSections(List<Id> reportingPeriodsIds) {

		List<Scheduled_Section__c> scheduleSectionsList =[Select account__r.reference_Id__c ,
						staff__r.reference_Id__c,
						Type__c,
						grade_level__c,schedule_group_name__c,
						Staff__c, Section__c,
						Schedule_Template__c,
						Schedule_Group_Section__c,
						Room__c,
						Reporting_Period__c,
						Reference_Id__c,
						Period_Key__c,
						Course__c,
						course_name__c,
						Account__c,
						reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c,
						staff__r.First_Name_Staff__c,
						staff__r.Staff_Last_Name__c,
						staff__r.Individual__r.Staff_Code__c,
						No_Meeting__c,
						Section__r.No_Meeting__c,
						section_ReportingPeriod__r.Time__c,
						staff__r.Individual__r.User_Name__c,
						staff__r.Individual__r.Email,
						staff__r.Individual__r.Phone,
						staff__r.Individual__r.MailingStreet,
						staff__r.Individual__r.MailingCity,
						staff__r.Individual__r.MailingState,
						staff__r.Individual__r.MailingPostalCode,
						staff__r.Individual__r.Gender__c,
						Section__r.Section_Number__c,
						section__r.Name,
						section__r.Grade_Level__c,
						section__r.All_Grades__c,
						section__r.Period__c,
						section__r.record_Attendance__c,
						section__r.daily_attendance__c,
						section__r.reporting_period__c,
						section__r.reference_Id__c,
						section__r.time__r.Name__c,
						record_attendance__c,
						Daily_Attendance__c,
						Grade_Levels__c,
						Room__r.name
				 FROM Scheduled_Section__c WHERE Reporting_Period__c IN : reportingPeriodsIds
				 AND Needs_Publish__c = true
				 AND account__c =: cSetup.school.Id];

		return scheduleSectionsList;
	}

	public void publish() {
		try {
			List<Id> reportingPeriodIds = new List<Id>();
			for (RPWrapper rpWrapperElement : reportingPeriods) {
				reportingPeriodIds.add(rpWrapperElement.te.Id);
			}
			List<Scheduled_Section__c> scheduledSections = queryScheduleSections(reportingPeriodIds);
			CT_Scheduler_UpsertHolding upho = new CT_Scheduler_UpsertHolding(cSetup);

			if(upho.cSetup.setup.Group_Based__c) {
				System.debug('\n\n goes to true \n');
				upho.upsertHoldingRecordsForScheduledSec(scheduledSections);
			}
			else {
				System.debug('\n\n goes to false \n');
				upho.upsertHoldingRecordsForPeriods(scheduledSections);
			}

			cSetup.setup.Published__c = true;
			cSetup.setup.Verification_Status__c = 'Verified';

			System.debug('\n\n before update setup \n');
			update cSetup.setup;

			ApexPages.getMessages().clear();
			bProcessing = true;
			for(Id repPerId : reportingPeriodIds) {
				rpId = repPerId;
				System.debug('\n\n start PROPAGATOR \n');
				start_Propagator('Staff');
			}
			activateData();
		}
		catch (exception e){
			Global_Error__c ge = CT_Error_Handling.handleError('Scheduler_UpsertHoldingObject', 'Scheduler', 'Upserting to Holding Object for: '+cSetup.setup.Id, e);
			insert ge;
		}
	}


	public void activateData(){
		try{
			cSetup.setup.New_School_Year__c = false;
			cSetup.setup.Active__c = true;

			List<Setup__c> setups = [SELECT id, Active__c
									FROM Setup__c
									WHERE School__r.ParentId =: cSetup.setup.School__c
										AND Year__c =: cSetup.setup.Year__c];
			for(Setup__c s:setups){
				s.New_School_Year__c = false;
				s.Active__c = true;
			}
			setups.add(cSetup.setup);
			update setups;

			CT_Batch_ProcessEOYData processEOYBatch = new CT_Batch_ProcessEOYData('Student__c', cSetup.setup.id);
			processEOYBatch.bFlag = true;

			Id batchId = Database.executeBatch(processEOYBatch,10);
			batch = new CT_BatchWrapper(batchId,cSetup.setup.id);
			batch.needsStudents = true;
			//This method validates whether the batch has to be invoked again for another school or another mode(Student or Section)
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred'));
		}
	}


	public void openWindow() {
		bOpenModal = true;
	}

	public void closeWindow() {
		bOpenModal = false;
	}

	public void rejectPublish() {
		try {
			String rejectDescription = Apexpages.currentPage().getParameters().get('Description');
			cSetup.setup.Verification_Status__c = 'Rejected';
			cSetup.setup.Rejection_Reason__c = rejectDescription;
			update cSetup.setup;
			bOpenModal = false;

			CT_SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Publish has been rejected.');
		} catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error on rejecting publish.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Reporting Period, '+rpId, 'Core (Publish)', 'error on rejecting publish', e);
			insert ge;
		}
	}

	/*
		Using the data from the scheduler, create the holding objects to set up section,
		staff, and student data.
	*/
	public void setupPublish(){
		try{
			bProcessing = true; //cheks the batch for spinner
			rpId = System.currentPageReference().getParameters().get('rpId'); //reporting period id from page

			/*PU 08/03/2011 Accomodating Batch apex. Deleting all the holding records for a school before invoking the batch*/
			List<HoldingObj__c> delHoldingRecs = [SELECT ID FROM HoldingObj__c
													WHERE  SCHOOL_DBN__c = :cSetup.school.Name ];
			if(delHoldingRecs.size() > 0) delete delHoldingRecs;

			CT_BatchUpsertHoldingObj upho = new CT_BatchUpsertHoldingObj();
			upho.cSetup = cSetup;
			upho.repPeriodId = rpId;
			Id batchId = Database.executeBatch(upho,100);

			batch = new CT_BatchWrapper(batchId,setupId);
			batch.rpId = rpId;

			upho.cSetup.setup.Published__c = true;
			update upho.cSetup.setup;
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error handling the holding objects.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Reporting Period, '+rpId, 'Core (Publish)', 'error on holding objects batch', e);
			insert ge;
		}
	}

	/*
		Runs the staff, student, and session propagators sequentially in that order.
		Record any type of error received and display it to the user.
	*/
	public void publishData(){
		try{
			if(bException) throw new CT_Error_handling.schoolForceException('test');
			if(System.currentPageReference().getParameters().containsKey('rpId')) rpId = System.currentPageReference().getParameters().get('rpId');
			else rpId = null;
			ApexPages.getMessages().clear();
			bProcessing = true;
			start_Propagator('Staff');
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId, 'Core (Publish)', 'error during staff propagation', e);
			insert ge;
		}
	}
	/*
		Runs the propagator for staff and student holding objects
	*/
	private void start_Propagator(String mode){
		CT_Scheduler_HoldingProcessor shp = new CT_Scheduler_HoldingProcessor();
		shp.continueBatch = true;
		shp.cSetup = cSetup.setup; 
		shp.mode = mode;
		if (rpId!=null) shp.reportingPeriod = rpId;
		System.debug('\n\n shp.reportingPeriod => ' + shp.reportingPeriod + '\n');
		Id batchId = database.executeBatch(shp);
		CT_SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'All reporting periods have been successfully published.  No action required.');
//		batch = new CT_BatchWrapper(batchId,setupId);
//		if(rpId!=null) batch.rpId = rpId;
//		continueBatch();
	}
	
	/*
		This is where the logic to republish sessions will go
		If a past date and attendance has been taken, do not allow session to be changed
	*/
	public void processSessions(){
		try{
			if(bException) throw new CT_Error_handling.schoolForceException('test'); 
			bProcessing = true;
			CT_BatchInsertSessions pubSess = new CT_BatchInsertSessions(setupId, rpId);
			for(RPWrapper rpw: reportingPeriods){
				if(rpw.te.id==rpId){
					pubSess.holdingSource = rpw.toPublish;
				}
			}
			Id batchId = Database.executeBatch(pubSess, 50);
			batch = new CT_BatchWrapper(batchId,setupId);
			batch.rpId = rpId;
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Reporting Period, '+rpId, 'Core (Publish)', 'error during session propagation', e);
			insert ge;
		}
	}
	
	public PageReference prev(){
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.STUDENT_SECTIONS,false,cSetup.setup);
	}
	
	public PageReference next(){
		if(!CT_SetupWizard_Utils.checkPublish(cSetup.setup)) {
			List<HoldingObj__c> ho = [SELECT id FROM HoldingObj__c
										WHERE School_DBN__c =: cSetup.setup.School__r.Reference_Id__c
											AND School_Year__c =: cSetup.setup.Year__r.Name__c
											AND Propagated__c = false limit 1];
			if (ho.size() > 0) {
				delete ho;
			}
			return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.ACTIVATION,true,cSetup.setup);
		}
		else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There are still records that need to be published before moving on to the next step.');
			return null;
		}
	}
	/*************		WRAPPER CLASS		**************/
	public class RPWrapper{
		public Time_Element__c 			te			{get;set;} //the actual time element
		public boolean					bPublish	{get;set;} //whether to enable publish button
		public boolean					bSetup		{get;set;} //whether to enable setup button
		public boolean					hasSects	{get;set;} //whether this reporting period has scheduled sections that need published
		public boolean					needPublish	{get;set;} //whether this reporting period has holding objects that need published
		public List<HoldingObj__c>		errors		{get;set;} //if there were errors, hold them here
		public List<HoldingObj__c>		toPublish	{get;set;}
		public List<Data_Load_Log__c>	publishLog	{get;set;} //the logs from the publish for this reporting period
		
		public RPWrapper(Time_Element__c rp){
			te = rp;
			bPublish = false;
			bSetup = false;
			needPublish = false;
			hasSects = false;
			errors = new List<HoldingObj__c>();
			publishLog = new List<Data_Load_Log__c>();
		}
		
		public void addLog(List<Data_Load_Log__c> pub){
			Data_Load_Log__c staff;
			Data_Load_Log__c student;
			Data_Load_Log__c session;
			for(Data_Load_Log__c dll: pub){
				if(dll.Type__c=='Staff'){
					if(staff!=null){
						if(dll.LastModifiedDate > staff.LastModifiedDate) staff = dll;
					}
					else staff = dll;
				}
				else if(dll.Type__c=='Student'){
					if(student!=null){
						if(dll.LastModifiedDate > student.LastModifiedDate) student = dll;
					}
					else student = dll;
				}
				else{
					if(session!=null){
						if(dll.LastModifiedDate > session.LastModifiedDate) session = dll;
					}
					else session = dll;
				}
			}
			publishLog.add(staff);
			publishLog.add(student);
			publishLog.add(session);
		}
	}   

}