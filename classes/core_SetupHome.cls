public with sharing class core_SetupHome {
 	  public ApexPages.StandardController 			controller 				{get; set;}
	  public String 													setupId					{get;set;}
	  public Id														tempDeleteId			{get;set;}	
	  public string														selectedGroupId		{get;set;}						
	  public core_SetupWrapper							cSetup					{get;set;}
	
	public core_SetupHome(ApexPages.StandardController controller){
		try{
			if (System.currentPageReference().getParameters().containsKey('id')!=null) setupId = System.currentPageReference().getParameters().get('id');
			if (setupId!=null){ 
				cSetup= new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'home');
				if (cSetup.setup.Active__c){
					Integer needPublish = [SELECT count() FROM Scheduled_Section__c WHERE Needs_Publish__c = true AND Account__c = :cSetup.school.id AND reporting_period__r.parent_time_element__c=:cSetup.setup.term__c] + [SELECT count() FROM HoldingObj__c WHERE Propagated__c = false AND School_DBN__c = :cSetup.school.Name AND School_Year__c = :cSetup.setup.Year__r.Name__c];
					if(needPublish > 0) ApexPages.addMessage(new apexpages.message(apexpages.severity.INFO,'There are records for this setup record that have not yet been published.  Please publish at your earliest convenience.'));
				}
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred during initialization.'));
		} 
	}

	/*
	public Pagereference deleteTemplate(){
		try{
			tempDeleteId = System.currentPageReference().getParameters().get('tempDeleteId');
			system.debug (tempDeleteId);
			if (tempDeleteId!=null){ 
				Schedule_Template__c schedTemplate = core_SoqlUtils.getTemplateById(tempDeleteId);
				delete schedTemplate;
				PageReference pr = new PageReference('/apex/core_SetupHome?id='+cSetup.setup.id);
				pr.setRedirect(true);
				return pr;
			}
			else return null;
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while deleting the schedule template.'));
			//Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Schedule Template, '+tempDeleteId, 'Core (Setup)', 'error deleting template', e);
			//insert ge;
			return null;
		} 
	}
	*/
	
	public pageReference addScheduleGroup(){
		pageReference pr = Page.core_GroupConfiguration;
		pr.getParameters().put('setupId',cSetup.setup.id);
		pr.setRedirect(true);
		return pr;
	}
	
	public pageReference editGroup(){
		selectedGroupId=System.currentPageReference().getParameters().get('selectedGroupId');
		system.debug('selectedGroupId~~~~'+selectedGroupId);
		pageReference pr = Page.core_GroupConfiguration;
		pr.getParameters().put('setupId',cSetup.setup.id);
		pr.getParameters().put('id',selectedGroupId);
		pr.setRedirect(true);
		return pr;
	}
	
	public pageReference addStudentsToGroup(){
		selectedGroupId=System.currentPageReference().getParameters().get('selectedGroupId');
		pageReference pr = Page.core_GroupConfiguration;
		pr.getParameters().put('setupId',cSetup.setup.id);
		pr.getParameters().put('id',selectedGroupId);
		pr.getParameters().put('add','true');
		pr.setRedirect(true);
		return pr;
	}
	
	public void setReenrollmentRate() {
		try {
			BatchSnapshotSchoolCalcs calcs = new BatchSnapshotSchoolCalcs();
			Setup__c currSetup = [select id, School__c, Year__r.Date_Start_Date__c 
									from Setup__c where id = :setupId];
			Setup__c prevSetup = calcs.findPreviousSetup(currSetup);
			List<Student__c> students = calcs.getEligibleForEnrollment(prevSetup);
			Decimal rate = calcs.getEnrollmentPercent(students, currSetup);
			AggregateResult ar = [select max(Snapshot_Taken__c) maxDate
									from Snapshot_Log__c 
									where Setup__c = :prevSetup.id];
			DateTime maxDate = (DateTime)ar.get('maxDate'); 
			List<Snapshot_Summary__c> snaps = [select id, Reenrollment_Rate__c
												from Snapshot_Summary__c
												where Snapshot_ID__r.Setup__c = :prevSetup.id and
												RecordType.DeveloperName = 'School_Summary' and
												Snapshot_ID__r.Snapshot_Taken__c = :maxDate];
			if (snaps == null || snaps.size() == 0) {
				throw new Error_Handling.schoolForceException('No snapshot found');
			}
			for (Snapshot_Summary__c s : snaps) {
				s.Reenrollment_Rate__c = rate;
			}
			update snaps;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.INFO, 'Reenrollment rate set to ' + rate));
		}
		catch (Exception e) {
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, 'Reenrollment rate not set.  Make sure a snapshot exists for the previous year. (' + e + ')' ));
		}
	}

	static testMethod void test_core_SetupHome(){
		TestDataSetupUtil_v2.setUPCoreData(1);
		PageReference pr = Page.core_SetupHome;
		pr.getParameters().put('id','abcde');
		Test.setCurrentPage(pr);
		Test.startTest();
			ApexPages.StandardController con = new ApexPages.StandardController(TestDataSetupUtil_v2.activeSetup);
			core_SetupHome setupHomecontroller = new core_SetupHome(con);
			system.assertEquals('An error occurred during initialization.',ApexPages.getMessages()[0].getSummary());
			pr.getParameters().put('id',TestDataSetupUtil_v2.activeSetUp.id);
			setupHomecontroller = new core_SetupHome(con);
			system.assertEquals(setupHomecontroller.setupId, TestDataSetupUtil_v2.activeSetUp.id);
			system.assertEquals(setupHomecontroller.cSetup.reportingPeriodList.size(),2);
			
			PageReference returnPR = setupHomeController.addScheduleGroup();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,returnPR.getParameters().get('setupId'));
			
			pr.getParameters().put('selectedGroupId','testid');
			returnPR = setupHomeController.editGroup();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,returnPR.getParameters().get('setupId'));
			system.assertEquals('testid',returnPR.getParameters().get('id'));
			
			returnPR = setupHomeController.addStudentsToGroup();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,returnPR.getParameters().get('setupId'));
			system.assertEquals('testid',returnPR.getParameters().get('id'));
			system.assertEquals('true',returnPR.getParameters().get('add'));
			
			setupHomeController.setReenrollmentRate();
		Test.stopTest();
	}

}