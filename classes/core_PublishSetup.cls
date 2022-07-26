public with sharing class core_PublishSetup {

	public String 				setupId				{get;set;} // setup that is being published
	public core_SetupWrapper	cSetup				{get;set;} // setup wrapper for the setup with id setupId
	public List<RPWrapper>		reportingPeriods	{get;set;} // wrapper for reporting periods to keep publishing in order
	public List<Data_Load_Log__c> logs				{get;set;} // list of all load logs for this setup
	public String				rpId				{get;set;} // currently chosen reporting period
	
	public boolean				bProcessing			{get;set;} // indicates whether there is a batch processing or not
	public BatchWrapper			batch				{get;set;} // holds data related to the running batch
	
	public boolean				bException			{get;set;} // boolean for code coverage in test class
	public boolean				nonRPBased			{get;set;} // boolean for generic publish (for holding objs without reporting period)
		
	public core_PublishSetup(ApexPages.StandardController controller){
		try{
			//initialize variables
			bProcessing = false;
			bException = false;
			reportingPeriods = new List<RPWrapper>();
			if(System.currentPageReference().getParameters().containsKey('failed'))
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'Batch job has failed.  Please try again later.'));
			if (System.currentPageReference().getParameters().containsKey('setupId')) {
				setupId = System.currentPageReference().getParameters().get('setupId');
				cSetup= new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'publish');
				if(SetupWizard_Utils.checkPublish(cSetup.setup)){
					SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There are still records that need to be published before moving on to the next step.');
				}
				
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
				Map<ID,List<Scheduled_Section__c>> rpIdToSchedSecs = Scheduler_SoqlUtils.getScheduledSectionsForPublish(cSetup.school.id);
				Map<ID,List<HoldingObj__c>> holdingObjsByReportingPeriod = Scheduler_SoqlUtils.getHoldingObjsForPublish(cSetup.school.Reference_Id__c,cSetup.setup.Year__r.Name__c);
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
				if(SetupWizard_Utils.checkModuleSetupComplete(cSetup.setup.id)){
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
					SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There is a Module Wizard still in progress. All Module Wizards must be finalized prior to publishing. Please finalize all Module Wizards.');
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
					ApexPages.addMessage(new apexpages.message(apexpages.severity.INFO,'The school calendar has not been saved for the following reporting periods: '+errorMessage+'.  Sessions will not be created for these reporting periods.'));
				}
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while loading the page.'));
		}
	}
	
	public PageReference continueBatch(){
		try{
			boolean failed = batch.continueBatch();
			if(failed!=null) return SetupWizard_Utils.refreshPage(setupId,failed);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while checking the status of the batch.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Batch, '+batch.batchId, 'Core (Publish)', 'batch check failed', e);
			insert ge;
		}
		return null;
	}
	
	/*
		Using the data from the scheduler, create the holding objects to set up section,
		staff, and student data.
	*/ 
	public void setupPublish(){
		try{
			bProcessing = true;
			rpId = System.currentPageReference().getParameters().get('rpId');
			
			/*PU 08/03/2011 Accomodating Batch apex. Deleting all the holding records for a school before invoking the batch*/
			List<HoldingObj__c> delHoldingRecs = [SELECT ID FROM HoldingObj__c 
													WHERE  SCHOOL_DBN__c = :cSetup.school.Name ];
			if(delHoldingRecs.size() > 0) delete delHoldingRecs;
			
			BatchUpsertHoldingObj upho = new BatchUpsertHoldingObj();
			upho.cSetup = cSetup;
			upho.repPeriodId = rpId;
			Id batchId = Database.executeBatch(upho,100);
			
			batch = new BatchWrapper(batchId,setupId);
			batch.rpId = rpId;
			
			upho.cSetup.setup.Published__c = true;
			update upho.cSetup.setup;
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error handling the holding objects.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Reporting Period, '+rpId, 'Core (Publish)', 'error on holding objects batch', e);
			insert ge;
		}
	}
	
	/*
		Runs the staff, student, and session propagators sequentially in that order.
		Record any type of error received and display it to the user.
	*/
	public void publishData(){
		try{
			if(bException) throw new Error_handling.schoolForceException('test'); 
			if(System.currentPageReference().getParameters().containsKey('rpId')) rpId = System.currentPageReference().getParameters().get('rpId');
			else rpId = null;
			ApexPages.getMessages().clear();
			bProcessing = true;
			start_Propagator('Staff');	
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId, 'Core (Publish)', 'error during staff propagation', e);
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
		Id batchId = database.executeBatch(shp);
		batch = new BatchWrapper(batchId,setupId);
		if(rpId!=null) batch.rpId = rpId;
		continueBatch();
	}
	
	/*
		This is where the logic to republish sessions will go
		If a past date and attendance has been taken, do not allow session to be changed
	*/
	public void processSessions(){
		try{
			if(bException) throw new Error_handling.schoolForceException('test'); 
			bProcessing = true;
			BatchInsertSessions pubSess = new BatchInsertSessions(setupId, rpId);
			for(RPWrapper rpw: reportingPeriods){
				if(rpw.te.id==rpId){
					pubSess.holdingSource = rpw.toPublish;
				}
			}
			Id batchId = Database.executeBatch(pubSess, 50);
			batch = new BatchWrapper(batchId,setupId);
			batch.rpId = rpId;
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Reporting Period, '+rpId, 'Core (Publish)', 'error during session propagation', e);
			insert ge;
		}
	}
	
	public PageReference prev(){
		return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.STUDENT_SECTIONS,false,cSetup.setup);
	}
	
	public PageReference next(){
		if(!SetupWizard_Utils.checkPublish(cSetup.setup)) return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.ACTIVATION,true,cSetup.setup);
		else{
			SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There are still records that need to be published before moving on to the next step.');
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