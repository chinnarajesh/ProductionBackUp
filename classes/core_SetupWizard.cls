public with sharing class core_SetupWizard {
	public integer 				iStep				{get;set;}
	public List <Account> 		schoolList			{get;set;}
	public Account				school				{get;set;}
	public Setup__c 			schoolSetup			{get;set;}
	public List <Time_Element__c> yearList			{get;set;}
	public Time_Element__c 		selectedYear		{get;set;}
	public String				welcomeString		{get;set;}
	public string				selectedSchoolId	{get;set;}
	public string				selectedYearId		{get;set;}
	public core_SetupWrapper	setup				{get;set;}
	public boolean 				bEditSchool			{get;set;}
	public boolean				bEditYear			{get;set;}
	public boolean				hasSummerSchool		{get;set;}
	public Account				summerSchool		{get;set;}
	
	public void checkTabStyle(){
		if (iStep==0){
			welcomeString = 'Install SchoolForce';
		}
		else if (iStep==1){
			setup.selectedTab = 'schools';
			welcomeString = 'Create New Schools';
			if(schoolList.size()==0){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'No schools have been created.  Please add a new school to continue.');
			}
		}
		else if (iStep==2){
			setup.selectedTab = 'years';
			welcomeString = 'Create New School Year';
		}
		//else if (iStep==3) setup.selectedTab = 'setups';
		
	}
	
	public core_SetupWizard(){
		if (ApexPages.currentPage().getParameters().get('iStep')!=null){
			iStep = integer.ValueOf(ApexPages.currentPage().getParameters().get('iStep'));
		}
		
		else{
			if (SchoolForce_Settings__c.getOrgDefaults().id==null) iStep=0;
			else iStep=1;
		}
		setup = new core_SetupWrapper();
		reQuery();
	}
	
	public void reQuery(){
		schoolList = SetupWizard_Utils.querySchools();
		yearList = SetupWizard_Utils.queryYears();
		//querySetups();
		checkTabStyle();
	}
	
	public void nextStep(){
		if(iStep==1 && schoolList.size()==0){
			SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'At least one school must be created before moving on to the next step.');
		}
		else{
			bEditSchool = false;
			bEditYear = false;
			iStep++;
			reQuery();
		}
	}
	
	public void prevStep(){
		bEditSchool = false;
		bEditYear = false;
		iStep--;
		reQuery();
	}
	
	public PageReference goHome(){
		return SetupWizard_Utils.goToSetupWizardHome();
	}

	public void loadOrgDefaults(){
		createIndividualAccount(); //Creates Individual Account
		testDataSetupUtil_v2.processErrorMessageData(); //Creates Default Error Messages
		testDataSetupUtil_v2.createDefaultTimeValues(); //Creates Default Time Values
		//EE 8/26 commented out as assignment types and grade scales should not be loaded on install
		//testDataSetupUtil_v2.createDefaultAssignmentTypesVoid(); //Creates Default Assignment Types
		//testDataSetupUtil_v2.createScalesNormalizations(); //Creates Default Grade Scales & Normalizations
		SchoolForce_Settings__c s = new SchoolForce_Settings__c(Enabled__c=true);
		insert s;
		iStep++;
	}

	public void createIndividualAccount(){
		Account a = new Account(Name='Individuals', recordTypeId = core_SoqlUtils.getRecordTypesBySobject('Account').get('Individuals'));
		insert a;
	}


	public void initSchool(){
		school = new Account (RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Account').get('School'));
		schoolSetup = new Setup__c();
		ID summerSchoolRT = core_SoqlUtils.getRecordTypesBySobject('Account').get('Summer_School');
		summerSchool = new Account(RecordTypeId = summerSchoolRT);
		hasSummerSchool = false;
		bEditSchool = true;
	}
	
	public void editSchool(){
		bEditSchool = true;
		school =  [select name, billingState, billingCity, billingPostalCode, BillingCountry , billingStreet, fax, phone from Account where id=:selectedSchoolId limit 1];
		schoolSetup = new Setup__c();
		ID yearID;
		try{
			Time_Element__c te = [SELECT id FROM Time_Element__c WHERE Picklist_Value__r.Name='Year' AND Current__c=true];
			yearID = te.id;
			schoolSetup = [SELECT ID, Name, Grade_Span__c FROM Setup__c WHERE School__c =: selectedSchoolId AND Year__c =: yearID];	
		} catch (Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Edit School', 'No current year record located, or more than one located', e);
			insert ge;
		}

		//EE US3514 add summer school functions
		ID summerSchoolRT = core_SoqlUtils.getRecordTypesBySobject('Account').get('Summer_School');
		try{
			summerSchool = [SELECT id, Name FROM Account WHERE ParentId=:school.id AND RecordTypeId=:summerSchoolRT LIMIT 1];
			hasSummerSchool = true;
		} catch(QueryException qe){
			summerSchool = new Account(RecordTypeId = summerSchoolRT, ParentId = school.id, Name = school.Name+' SS');
			hasSummerSchool = false;
		}
	}
	
	public void saveSchool(){
		if(!saveSchool(school, schoolSetup, false)) return;
		//EE US3514 add summer school functions
		if(hasSummerSchool){
			summerSchool.ParentId = school.id;
			summerSchool.BillingCity = school.BillingCity;
			summerSchool.BillingState = school.BillingState;
			summerSchool.BillingPostalCode = school.BillingPostalCode;
			summerSchool.BillingStreet = school.BillingStreet;
			summerSchool.BillingCountry = school.BillingCountry;
			summerSchool.Phone = school.Phone;
			summerSchool.Fax = school.Fax;
			if(!saveSchool(summerSchool, schoolSetup, true)){
				return;
			} else if(!yearList.isEmpty()) { //if the year list is empty we have nothing to base it on
				processSSForActivation();
			}
		}
		schoolList = SetupWizard_Utils.querySchools();
		bEditSchool = false;
	}

	private void processSSForActivation(){
		List<Setup__c> setups = [select id, Active__c, School__c, Grade_Span__c from Setup__c where Year__c=: yearList[0].id and (School__c =:school.id or School__c =: summerSchool.id)];
		if(setups.size()>2)
			return; //skip if unexpected stuff starts showing up
		Setup__c ssSetup;
		Setup__c mainSetup;
		for(Setup__c s:setups){
			if(s.School__c == school.id) mainSetup = s;
			else						 ssSetup = s;
		}
		if(ssSetup != null && mainSetup != null && mainSetup.Active__c){ //just in case
			ssSetup.Active__c = true;
			ssSetup.Grade_Span__c = mainSetup.Grade_Span__c;
			update ssSetup;
		}
	}
	
	private boolean saveSchool(Account school, Setup__c schoolSetup, boolean summerSchool){
		school.Reference_Id__c = school.Name;
		for(Account a: [SELECT id, Name FROM Account WHERE RecordType.Name='School' OR RecordType.Name='Summer School']){
			if(school.Name == a.Name && school.id != a.id){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'A school with the name '+school.Name+' already exists. '+(summerSchool?'Summer s':'S')+'chools must have unique names.');
				return false;
			}
		}
		upsert school;
		
		ID yearID;
		try{
			Time_Element__c te = [SELECT id FROM Time_Element__c WHERE Picklist_Value__r.Name='Year' AND Current__c=true];
			yearID = te.id;
			Setup__c queriedSetup = [SELECT ID, Grade_Span__c FROM Setup__c WHERE Year__c =: yearID AND School__c =: school.ID];
			queriedSetup.Grade_Span__c = schoolSetup.Grade_Span__c;
			upsert queriedSetup;			
		} catch (Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Save School', 'No current year record located, or more than one located', e);
			insert ge;
		}

		return true;
	}
	
	public void cancelSchool(){
		bEditSchool = false;
	}
	
	public void initYear(){
		selectedYear = new Time_Element__c (Picklist_Value__c= core_SoqlUtils.getPlStringValues('Time', null).get('Year').id);
		bEditYear = true;
	}

	public void saveYear(){
	//	selectedYear.Name__c = selectedYear.Name;
		ApexPages.getMessages().clear();
		try{
			//if(selectedYear.id == null)			selectedYear.New_School_Year__c = true;	
			upsert selectedYear;
		}
		catch (exception e){
			system.debug(e.getMessage());
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		bEditYear = false;
		yearList = SetupWizard_Utils.queryYears();
	}
	
	public void cancelYear(){
		bEditYear = false;
	}
	
	public void editYear(){
		selectedYear = [select id, name__c, date_start_date__c, end_date__c,Previous_YEar__c,New_School_Year__c from Time_Element__c where id =:selectedYearId];
		bEditYear = true;
	}


	public void setupComplete(){
		nextStep();
	}
	
	public static testMethod void testCoreSetupWizard(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		test.startTest();
		PageReference pr = new PageReference('/apex/core_setupWizard');
		core_setupWizard sw= new core_SetupWizard();
		test.setCurrentPage(pr);
		sw.selectedSchoolId = testDataSetupUtil_v2.school.id;
		sw.editSchool();
		sw.saveSchool();
		sw.initSchool();
		sw.cancelSchool();
		sw.nextStep();
		sw.selectedYearId = testDataSetupUtil_v2.term.Parent_Time_Element__c;
		sw.editYear();
		sw.saveYear();
		sw.initYear();
		sw.cancelYear();
		sw.prevStep();
		test.stopTest();
	}

}