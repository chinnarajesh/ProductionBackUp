/*
	This class is the controller for the Activate Data step in the School Setup - Core Setup wizard.
	  Its main function is to run the Batch_ProcessEOYData batch to activate data (Students, Sections, Staff/Sections,
	 Student/Sections) and to set the current setup to Active.
	
	@author Elizabeth Ellis <eellis@acumensolutions.com>
	@since	2013-04-10
*/
public class SchoolSetup_ActivateData {
	public Setup__c schoolSetup			{get;set;} //the current setup
	public BatchWrapper batch			{get;set;} //the wrapper that contains the running batch's data
	public boolean bDisable				{get;set;} //boolean indicating whether or not to disable the button
	public boolean bProcessing			{get;set;} //boolean indicating that a batch is currently processing
	public List<Data_Load_Log__c> logs	{get;set;} //list of logs populated from previous run of activation, if applicable
	
	/*
		Constructor
		Checks to see if a setupId was passed to the page.  If not, error message.
		Populates the global schoolSetup variable using the passed in setupId.
		Using the global schoolSetup, finds the most recent previous year (End Date < this year's Start Date, ordered by Start Date desc).
		This is passed to check if there is a setup for the previous school year and, if so, that it has completed the EOY process.
		If EOY is not complete, error.
		Else check to see if the setup has already had its data activated.  If so, get the data logs to display.
		Otherwise, warning message to activate data.
	*/
	public SchoolSetup_ActivateData(){
		bProcessing = false;
		bDisable = false;
		if(System.currentPageReference().getParameters().containsKey('setupid')){
			Id setupId = System.currentPageReference().getParameters().get('setupid');
			if(setupId!=null){
				schoolSetup = SetupWizard_Utils.getSetupById(setupId);
				Time_Element__c prevYear;
				try{
					prevYear = [SELECT id, Name__c FROM Time_Element__c WHERE Picklist_Value__r.Name='Year' AND End_Date__c < :schoolSetup.Year__r.Date_Start_Date__c ORDER BY Date_Start_Date__c desc limit 1];
				} catch(QueryException qe){
					prevYear = null;
				}
				if(prevEOYComplete(prevYear)){
					if(!SetupWizard_Utils.checkActivation(schoolSetup)){
						SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Your data has been activated.  No further action is required.');
						getLogs();
					}
					else{
						SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'School data must be activated before the setup process can be completed.');
					}
				}
				else{
					bDisable = true;
					SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Your school has not completed the EOY process for the '+prevYear.Name__c+' school year.  Please complete this process before activating your data.');
				}
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
	}
	
	/*
		If a year was found, checks to see if there is a setup for the same school (schoolSetup.School__c) for the previous year.
		If a setup was found, checks to see if the EOY process is complete.
		If either a year or a setup is not found, returns true.

		For summer school we check the completion of the main year.
		
		@param prevYear the most recent previous year element in the org
		@return boolean to determine whether or not the previous year's EOY process is complete
	*/
	public boolean prevEOYComplete(Time_Element__c prevYear){
		if(prevYear!=null){
			try{
				EOY_Progress__c eoy = [SELECT id, Is_Complete__c FROM EOY_Progress__c WHERE Year__c=:prevYear.id AND RecordType.Name='EOY' and School__c = null and (Module_Name__c = 'SchoolForce' or Module_Name__c = null)];
				return eoy.Is_Complete__c;
			} catch(QueryException qe){
				//if an EOY progress record doesn't exist, school never went through EOY process
				return false;
			}
		}
		else return true;
	}
	
	/*
		Gets the most recent log of each type (Section__c, Student__c, Staff_Section__c, Student_Section__c) for this setup.
		These are saved to the logs variable for display to the user on the page.
	*/
	public void getLogs(){
		logs = new List<Data_Load_Log__c>();
		Map<String,Data_Load_Log__c> logsByType = new Map<String,Data_Load_Log__c>();
		for(Data_Load_Log__c dll: [SELECT id, Type__c, Start_Time_Text__c, End_Time_Text__c, Total_Records__c, Failed_Records__c, Messages__c, LastModifiedDate FROM Data_Load_Log__c WHERE Setup__c=:schoolSetup.id AND Class_Name__c='Batch_ProcessEOYData']){
			system.debug('~~~~~ log: Type='+dll.Type__c+', LastModifiedDate='+dll.LastModifiedDate);
			if(logsByType.containsKey(dll.Type__c)){
				if(dll.LastModifiedDate > logsByType.get(dll.Type__c).LastModifiedDate)
					logsByType.put(dll.Type__c,dll);
			}
			else logsByType.put(dll.Type__c,dll);
		}
		if(!logsByType.isEmpty()){
			//alphabetize logs by type
			List<String> types = new List<String>();
			types.addAll(logsByType.keySet());
			types.sort();
			for(String s: types){
				logs.add(logsByType.get(s));
			}
		}
	}
	
	/*
	
	*/
	public PageReference continueBatch(){
		try{
			boolean failed = batch.continueBatch();
			if(failed!=null) return SetupWizard_Utils.refreshPage(schoolSetup.id,failed);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while checking the status of the batch.'));
			createGlobalError('batch check failed',e);
		}
		return null;
	}
	
	/*
	
	*/
	public void processData(){
		try{
			bProcessing = true;
			
			schoolSetup.New_School_Year__c = false;
			schoolSetup.Active__c = true;

			List<Setup__c> setups = [select id, Active__c from Setup__c where School__r.ParentId =: schoolSetup.School__c and Year__c =: schoolSetup.Year__c];
			for(Setup__c s:setups){
				s.New_School_Year__c = false;
				s.Active__c = true;
			}
			setups.add(schoolSetup);
			update setups;
			
			Batch_ProcessEOYData processEOYBatch = new Batch_ProcessEOYData('Student__c');  
			processEOYBatch.setupId = schoolSetup.id;
			processEOYBatch.bFlag = true;
			processEOYBatch.continueBatch = true;
			
			Id batchId = Database.executeBatch(processEOYBatch,10);
			batch = new BatchWrapper(batchId,schoolSetup.id);
			batch.needsStudents = true;
			//This method validates whether the batch has to be invoked again for another school or another mode(Student or Section)
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred'));
			createGlobalError('error during activating new year data', e);
		}
	}
	
	/*
	
	*/
	public PageReference prev(){
		return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.PUBLISH,false,schoolSetup);
	}
	
	/*
	
	*/
	public PageReference next(){
		if(!SetupWizard_Utils.checkActivation(schoolSetup)) return SetupWizard_Utils.goToSchoolHome(schoolSetup.id);
		else{
			SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'School data must be activated before the setup process can be completed.');
			return null;
		}
	}
	
	public void createGlobalError(String message, Exception e){
		String links='';
		if(batch!=null) links+='Batch,'+batch.batchId;
		if(schoolSetup!=null){
			if(links!='') links+=';';
			links+='Setup,'+schoolSetup.id;
		}
		Global_Error__c ge = Error_Handling.handleError(links, 'Activate Data', message, e);
		insert ge;
	}
}