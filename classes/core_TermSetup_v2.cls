public with sharing  class core_TermSetup_v2 {

	public List <cTimeWrapper> 			availableTerms {get;set;}
	public Map <Id, Time_Element__c> 	timeElementMap {get;set;}
	public string						selectedTermIdForSetup {get;set;}
	public string						selectedTermId {get;set;}
	public string						selectedRpId {get;set;}
	public Time_Element__c				selectedYear				{get;set;}
	public Time_Element__c 				selectedTermTimeElement {get;set;}
	public cReportingPeriod				reportingPeriodElement {get;set;}
	public cTermWrapper 				selectedTermWrapper {get;set;}
	public boolean						bShowTerms		{get;set;}
	public boolean						bShowTermDetails		{get;set;}
	public boolean						bConfigureTerm {get;set;} //Boolean to hide show the terms available
	public boolean						bReadOnlyYear		{get;set;}
	public boolean						bConfigureRp			{get;set;}
	public boolean 						bReportingPeriods		{get;set;}
	public id							setupId							{get;set;}
	public core_SetupWrapper			cSetup							{get;set;}
	public string[]						sErrorMessages{get;set;}

	/* Initialize the page variables*/
	public core_TermSetup_v2(){
		try{
			sErrorMessages = new String[]{};
			 if ( ApexPages.currentPage().getParameters().get('setupId')!=null){
				SetupId = ApexPages.currentPage().getParameters().get('setupId');
				cSetup= new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'term');
				selectedTermId = cSetup.setup.Term__c;
				bConfigureTerm = false;
				bReportingPeriods = false;
				bShowTerms = true;
				returnAvailableTimeElements();
				if(availableTerms.size()==0){
					SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There are no terms created for this school year.  Please create a term.');
				}
				else verifyData();
			}
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred during initialization.');
		} 
	}
	
	public  void setTerm(){
		try{
	 		if (System.currentPageReference().getParameters().get('selectedTermIdForSetup')!=null){
				 selectedTermIdForSetup = System.currentPageReference().getParameters().get('selectedTermIdForSetup');
				}
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while setting the term.');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermIdForSetup, 'Core (Term)', 'error setting term', e);
			insert ge;
			} 
	}
	
	public void saveSetup(){
		try{
			if (selectedTermIdForSetup!=null){	
				cSetup.setup.Term__c=selectedTermIdForSetup;
				update  cSetup.setup;
				cSetup= new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'term');
				selectedTermId = selectedTermIdForSetup;
				bShowTerms=true;
			}
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while saving the setup.');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermIdForSetup, 'Core (Term)', 'error saving term to setup', e);
			insert ge;
		} 
	}
	
	public void processErrorMessages(){
		for (String s: sErrorMessages){
			SetupWizard_Utils.addMessage(apexpages.severity.fatal, s);
		}
	}
	
	public void viewReportingPeriods(){
		returnTermDetails();
		bShowTerms = false;
		bConfigureTerm = false;
		bReportingPeriods = true;
	}
	
	public void cancelViewReportingPeriods(){
		bShowTerms = true;
		bReportingPeriods = false;
	}

	/*Gets all available time elements in system, should not be over 1000 ever, but may need to scale this
		Sets up the map to reference throughout class later; also sets up available term list */

		
	public void returnAvailableTimeElements(){
		availableTerms = new List <cTimeWrapper>();//Initialize a new list of TimeWrappers
		timeElementMap = new Map<Id, Time_Element__c>();
		if (cSetup.setup.Year__c!=null){  //Ensure that the user selecteed a Year in order to display the appropriate data
			selectedYear = core_SoqlUtils.getTimeElementById(cSetup.setup.Year__c);
			for (Time_Element__c te: core_SoqlUtils.getTimeElementsByTerm(selectedYear.Id, false)){
				timeElementMap.put(te.id, te);
				cTimeWrapper ctw = new cTimeWrapper(te); //Initialize a Time Element Wrapper because need to set booleans for whether they can be edited or even displayed
				if (cSetup.setup.published__c) ctw.bEdit=false; //If the setup the record is related to is already published; do not allow edit ability
				availableTerms.add(ctw);
			}
		}
		bShowTerms=true;
	}
	

	
	
	/*Sets up the selectedTermWrapper for the term user clicks 'View' next to the list of available terms*/
	public void returnTermDetails(){
		if (selectedTermId!=null){
			bConfigureTerm = true;
			bShowTerms = false;	
			selectedTermTimeElement = timeElementMap.get(selectedTermId);
			selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
		}
	}
	
	/*Sets up a new sTermWrapper for selectedTermWrapper the term user clicks 'New Term  */
	public void configureNewTerm(){
		try{
			bConfigureTerm = true;
			bShowTerms = false;
			selectedTermWrapper = new cTermWrapper(null, selectedYear);
			system.debug('~~~~~ selectedTermWrapper.term '+selectedTermWrapper.term);
		}
		catch(Exception e){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while configuring a new term.');
				Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Year, '+selectedYear.id, 'Core (Term)', 'error configuring term for year', e);
			insert ge;
			} 
	}
	
	public void cancelTermDetails(){
		bShowTerms = true;
		bConfigureTerm = false;
		returnAvailableTimeElements();
	}
	
	public void editTermDetails(){
		bShowTerms = false;
		bConfigureTerm = true;
		if (System.currentPageReference().getParameters().get('selectedTermId')!=null){
			selectedTermTimeElement = timeElementMap.get(selectedTermId);
			selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
			selectedTermWrapper.cQasw = new cQuickAddSchedWrapper(selectedTermTimeElement);
			selectedTermWrapper.reportingPeriod = new cReportingPeriod(selectedTermTimeElement, null);
		}
	}
	
	/*Toggles the view for the detail/Edit term information*/
	
	public void populateTermDetailTable(){
			bConfigureTerm = true;
	}	
	/*Saves information entered for the Term Config*/
	public void saveTermConfig(){
		try{
			selectedTermWrapper.term.Parent_Time_Element__c = selectedYear.Id;
			selectedTermWrapper.term.Picklist_Value__c=core_SoqlUtils.getPlStringValues('Time', null).get('Term').id;
			selectedTermWrapper.term.Days_of_Week__c = selectedTermWrapper.cQasw.days.DaystoString();
			selectedTermWrapper.term = core_TimeUtils.translateTimeText(selectedTermWrapper.term);
			upsert selectedTermWrapper.term; //Insert the term first to set it as the parent of the child terms
			upsert selectedTermWrapper.timeElementList; //Upsert the necessary time elements
			
			returnAvailableTimeElements(); //requery the database to setup the map for all
			selectedTermTimeElement = selectedTermWrapper.term;
			cancelTermDetails(); //resets boolean variables on screen so that user is returned to all terms view
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while saving the term details.');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermWrapper.term.id, 'Core (Term)', 'error saving term', e);
			insert ge;
		} 
	}
	/*End Save Term Config*/

	/*Start wrapper class construction and instantiation*/
	public void initReportingPeriod(){
		try{
			reportingPeriodElement = new cReportingPeriod(selectedTermWrapper.term, null);
			bConfigureRp = true;
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while initializing the reporting periods');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermWrapper.term.id, 'Core (Term)', 'error init reporting period', e);
			insert ge;
		} 
	}
	
	public void validateReportingPeriod (Time_Element__c te){
		if (te.Date_Start_Date__c != null && te.End_Date__c != null){	
			if (te.Date_Start_Date__c >= te.End_Date__c){
				sErrorMessages.add('Reporting Period Start Date must be earlier than End Date');
			}
		}
	}
	
	public void addReportingPeriod(){
		try{
			//Save & Add reporting period
			saveReportingPeriod();
			initReportingPeriod();
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while adding the reporting period.');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Term, '+selectedTermWrapper.term.id, 'Core (Term)', 'error adding reporting period', e);
			insert ge;
			} 
	}
	
	public void cancelAddReportingPeriod(){
		bConfigureRp = false;
		bReportingPeriods = true;
	}
	
	public void editReportingPeriod(){
		try{
			if (System.currentPageReference().getParameters().get('selectedRpId')!=null){
				selectedRpId = System.currentPageReference().getParameters().get('selectedRpId');
				reportingPeriodElement = new cReportingPeriod(selectedTermWrapper.term, core_SoqlUtils.getTimeElementById(selectedRpId));
				bConfigureRp = true;
				reportingPeriodElement.selectedReportingPeriodType = selectedTermWrapper.term.Reporting_Period_Value__c;
			}
		}
		catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while retrieving reporting period details.');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting period, '+selectedRpId, 'Core (Term)', 'error getting reporting period', e);
		insert ge;
			} 
	}
	/* Deprecated Chesapeake, should not have this ability until we verify that the term is truly able to be deleted
	public void deleteReportingPeriod(){
		try{
			if (System.currentPageReference().getParameters().get('selectedRpId')!=null){
				selectedRpId = System.currentPageReference().getParameters().get('selectedRpId');
				delete core_SoqlUtils.getTimeElementById(selectedRpId);
				 
				  
				//PU: 08/04/2011 - On rerender the refreshing the selectedTermWrapper List after delete
				selectedTermId = System.currentPageReference().getParameters().get('selectedTermId');
				selectedTermTimeElement = timeElementMap.get(selectedTermId);
				selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while deleting the reporting period.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting period, '+selectedRpId, 'Core (Term)', 'error deleting reporting period', e);
			insert ge;
		} 
	}*/
	
	public void saveReportingPeriod (){
		try{
			sErrorMessages.clear();
			validateReportingPeriod(reportingPeriodElement.te);
			if (sErrorMessages.isEmpty()){
				//saveTermConfig();
				reportingPeriodElement.selectedReportingPeriodType = selectedTermWrapper.term.Reporting_Period_Value__c;
				reportingPeriodElement.te.picklist_Value__c=reportingPeriodElement.selectedReportingPeriodType;
				reportingPeriodElement.te.parent_time_Element__c = selectedTermWrapper.term.id;
				upsert reportingPeriodElement.te;
				bConfigureRp = false;
				selectedTermWrapper = new cTermWrapper(selectedTermTimeElement, selectedYear);
				viewReportingPeriods();
			}
			else processErrorMessages();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the reporting period.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Reporting period, '+reportingPeriodElement.te.id, 'Core (Term)', 'error saving reporting period', e);
			insert ge;
		} 
	}
	
	public PageReference goHome(){
		return SetupWizard_Utils.goToSchoolHome(setupId);
	}
	
	public PageReference next(){
		if(verifyData()) return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.SELECTIONS,true,cSetup.setup);
		else return null;
	}
	
	public boolean verifyData(){
		if(SetupWizard_Utils.checkTerm(cSetup.setup)){
			if(cSetup.setup.Term__c==null) SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'A term must be selected before moving on to the next step.');
			else verifyReportingPeriods();
			return false;
		}
		else if(verifyReportingPeriods()) return false;
		else return true;
	}
	
	public boolean verifyReportingPeriods(){
		ID termId = cSetup.setup.Term__c;
		Time_Element__c term = [SELECT id, Name__c, Reporting_Period_Value__c FROM Time_Element__c WHERE id=:termId];
		List<Time_Element__c> rps = [SELECT id FROM Time_Element__c WHERE Reporting_Period__c=true AND Parent_Time_Element__c=:termId];
		Picklist_Value__c termType = [SELECT id, Name, Corresponding_Value__c FROM Picklist_Value__c WHERE id=:term.Reporting_Period_Value__c];
		boolean bError = false;
		//number of reporting periods term has should match the corresponding value on the picklist value
		if(termType.Corresponding_Value__c!=rps.size()){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The term '+term.Name__c+' does not have the correct number of reporting periods for the '
				+termType.Name+' reporting period value.  Expected '+termType.Corresponding_Value__c+' reporting periods, found '
				+rps.size()+' reporting periods.');
			bError=true;
		}
		return bError;
	}
	
	public class cTermWrapper{

		public Time_Element__c 					term 			{get;set;}
		public cReportingPeriod					reportingPeriod {get;set;}
		public List <Time_Element__c>			timeElementList	{get;set;}
		public cQuickAddSchedWrapper			cQasw					{get;set;}
		public List <SelectOption>				reportingPeriodOptionList	{get;set;}
		
		public cTermWrapper(Time_Element__c parentTerm, Time_Element__c year){
			timeElementList = new List <Time_Element__c> ();
			reportingPeriodOptionList = new List <SelectOption>();
			Set <String> timeTypes = new Set <String>();
			for (Picklist_Value__c pl: [select id, name from Picklist_Value__c where category__c='Reporting Period'
										and RecordType.Name ='Time']){
				if (!timeTypes.contains(pl.name)){
					reportingPeriodOptionList.add(new SelectOption(pl.id, pl.name));
					timeTypes.add(pl.name);
				}
			}
			if (parentTerm ==null){
				this.term = new Time_Element__c(Picklist_Value__r=  core_SoqlUtils.getPlStringValues('Time', null).get('Term') );
				this.cQasw = new cQuickAddSchedWrapper(null); 
				this.term.Date_Start_Date__c= year.Date_Start_Date__c;
				this.term.End_Date__c = year.End_Date__c;

			}
			else {
				this.cQasw = new cQuickAddSchedWrapper(parentTerm); 
				this.term = parentTerm;
				for (Time_element__c te: core_SoqlUtils.getTimeElementsByTerm(parentTerm.id, true)){
					this.timeElementList.add(te);
				}
				this.reportingPeriod = new cReportingPeriod(this.term, null);
			}
		}
	}
	
		
	public class cReportingPeriod {
		public List <SelectOption>				reportingPeriodOptionList {get;set;}
		public string 								selectedReportingPeriodType {get;set;}
		public Time_Element__c					te	{get;set;}
		public cReportingPeriod(Time_Element__c ParentTe, Time_Element__c rpTe){
			reportingPeriodOptionList = new List <SelectOption>();
			if (rpTe==null){
				this.te = new Time_Element__c(parent_time_element__c=ParentTe.id, Reporting_Period__c = true, Days_of_week__c=ParentTe.days_of_week__c);	
			}
			else this.te = rpTe;
			for (Picklist_Value__c pl: core_SoqlUtils.getPlValuesList('Time', null)){
				reportingPeriodOptionList.add(new SelectOption(pl.id, pl.name));
			}
			if (ParentTe.reporting_period_value__c!=null) {
				parentTe = core_SoqlUtils.getTimeElementById(ParentTe.id);
				reportingPeriodOptionList.add(new SelectOption(ParentTe.reporting_period_value__c, ParentTe.reporting_period_value__r.name));
			}
		}
	}
	
	public class cQuickAddSchedWrapper {
			public Time_Element__c inputTimeElement {get;set;}	
			public core_UtilDays 	days	{get;set;}
			public integer	iDuration	{get;set;}
			public integer	iBreak		{get;set;}
			public cQuickAddSchedWrapper(Time_Element__c inputTimeElement){

			if (inputTimeElement==null){
				this.iDuration = 60;
				this.iBreak = 5;
				this.inputTimeElement = new Time_Element__c( );
				//this.inputTimeElement.StartTime__c = '08:00 AM'; Not needed Chesapeake PN
				//this.inputTimeElement.EndTime__c = '05:00 PM'; Not needed Chesapeake PN
					this.days = new core_UtilDays();
			}
			else {
					if (inputTimeElement.days_of_week__c!=null) this.days = new core_UtilDays(inputTimeElement.days_of_week__c);
					else this.days = new core_UtilDays();
			}
		}
		public cQuickAddSchedWrapper(){
			this.days = new core_UtilDays(); // Use the days class if user is entering details; day of week still applies
		}
	}
	
	
	public class cTimeWrapper {
		public Time_Element__c timeElement	{get;set;}
		public boolean	 bEdit						{get;set;}
		public boolean bDisplay					{get;set;}
		public cTimeWrapper(Time_Element__c te){
			this.timeElement = te;
			this.bEdit = true;
			this.bDisplay = true;
		}
	}
	
	static testMethod void test_core_TermSetup_v2(){
		string termId;
		testDataSetupUtil_v2.setUPCoreData(2);
		PageReference  p = Page.core_TermSetup_v2;
		testDataSetupUtil_v2.activeSetUp.Year__c= testDataSetupUtil_v2.term.Parent_Time_Element__c;
		Test.setCurrentPage(p);
		ApexPages.currentPage().getParameters().put('setupId', testDataSetupUtil_v2.activeSetUp.id);
		
		Test.startTest();
		core_TermSetup_v2 c = new core_TermSetup_v2(	);
		c.configureNewTerm();
		c.selectedTermWrapper.term.name__c = 'Test for Apex';
		c.selectedTermWrapper.term.date_start_Date__c = TestDataSetupUtil_v2.masterYear.Date_Start_Date__c;
		c.selectedTermWrapper.term.end_Date__c = TestDataSetupUtil_v2.masterYear.End_Date__c;
		c.saveTermConfig();
		termId = c.selectedTermWrapper.term.id;
		PageReference  p2 = Page.core_TermSetup_v2;
		Test.setCurrentPage(p2);
		ApexPages.currentPage().getParameters().put('setupId', testDataSetupUtil_v2.activeSetUp.id);
		ApexPages.currentPage().getParameters().put('selectedTermId', termId);
		core_TermSetup_v2 c2 = new core_TermSetup_v2(	);
		c2.selectedTermId = termId;
		c2.viewReportingPeriods();
		system.assertEquals(c2.selectedTermWrapper.timeElementList.size(),0); // Check that there are no reporting periods for the new term
		system.assert(c2.selectedTermWrapper.cQasw.days.hasMon()); // Verify it has monday enabled - default for the wrapper
		c2.initReportingPeriod(); //Add a new Rp
		c2.cancelAddReportingPeriod(); //Verify cancel
		c2.initReportingPeriod(); //Add a new Rp
		c2.addReportingPeriod(); // Save a new one.. 
		system.assertEquals(c2.selectedTermWrapper.timeElementList.size(),0); //verify it throws an error
		c2.reportingPeriodElement.te.name__c = 'Test RP';
		c2.reportingPeriodElement.te.date_start_date__c = system.today();
		c2.reportingPeriodElement.te.end_date__c = system.today();	
		c2.addReportingPeriod();	//Save and add new
		system.assertEquals(c2.selectedTermWrapper.timeElementList.size(),0); //verify it still throws an error for overlap
		c2.reportingPeriodElement.te.name__c = 'Test RP'; 
		c2.reportingPeriodElement.te.date_start_date__c = c2.selectedTermWrapper.term.date_Start_date__c.addDays(2);
		c2.reportingPeriodElement.te.end_date__c = c2.reportingPeriodElement.te.date_start_date__c.addDays(4);
		c2.addReportingPeriod();	 //Save, should actually work this time
		system.assertEquals(c2.selectedTermWrapper.timeElementList.size(),1); //Yup, got one
		ApexPages.currentPage().getParameters().put('selectedTermIdForSetup', c2.selectedTermWrapper.term.id); 
		c2.setTerm();  //Select the term from the radio
		c2.saveSetup(); //Save it
		system.assertEquals(c2.cSetup.setup.term__c, c2.selectedTermIdForSetup);
		Test.stopTest();
	}

		/*End wrapper class construction and instantiation*/


}