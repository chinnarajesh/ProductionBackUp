@isTest 
private class Test_PublishSetup {


	static testMethod void test_PublishGroup(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUpStaffData(5);
    	TestDataSetupUtil_v2.setUpStudentData(5);
    	TestDataSetupUtil_v2.activeSetUp.Group_Based__c=true;
		update TestDataSetupUtil_v2.activeSetUp;
      
		List <Section__c> schGroups = TestDataSetupUtil_v2.getScheduleGroups_Section();
		
		List <Student__c> stuList = new List <Student__c>();
		for (Student__c s: TestDataSetupUtil_v2.studentsList){
			s.Primary_Schedule_Group__c = schGroups[0].id;
			stuList.add(s);
		}
		update stuList;
		
		Schedule_Template__c st = new Schedule_Template__c(Setup__c=TestDataSetupUtil_v2.activeSetUp.id, has_class__c = true,Reporting_Period__c= TestDataSetupUtil_v2.semester.id, Is_Master__c=true  );
		st.start_time__c =  dateTime.newInstance(system.today().year(), system.today().month(), system.today().day(), 9,0,0);
		st.end_time__c =  st.start_time__c.addHours(8);
		insert st;
		
		Scheduled_Section__c ss = new Scheduled_Section__c( );
		ss.Staff__c = TestDataSetupUtil_v2.teachersList[0].id;
		ss.course__c = TestDataSetupUtil_v2.coursesList[0].id;
		ss.Account__c = TestDataSetupUtil_v2.school.id;
		ss.Start_Time__c = dateTime.newInstance(system.today().year(), system.today().month(), system.today().day(), 10,0,0);
		ss.End_Time__c = ss.Start_Time__c.addHours(1);
		ss.Room__c = TestDataSetupUtil_v2.roomList[0].id;
		//ss.Schedule_Group__c = sg.id;
		ss.Schedule_Group_Section__c = schGroups[0].id;
		ss.Reporting_Period__c = TestDataSetupUtil_v2.semester.id;
		ss.Needs_Publish__c = true;
		ss.Schedule_Template__c = st.id;
		ss.Section_Reference_Id__c = ss.Account__c + '-' + ss.Schedule_Group_Section__c + '-'+ss.course__c + '-' + TestDataSetupUtil_v2.semester.id;
		ss.Reference_Id__c= ss.Account__c + '-' + ss.Schedule_Group_Section__c + '-'+ss.course__c + '-' + TestDataSetupUtil_v2.semester.id+ '-'+st.id;
		insert ss;
		
		Schedule_Day__c sd = new Schedule_Day__c(Reporting_Period__c= TestDataSetupUtil_v2.semester.id, Day__c = Date.newInstance(system.today().year(), system.today().month(), system.today().day()), schedule_Template__c = st.id);
		sd.referenceId__c =  TestDataSetupUtil_v2.semester.id+String.valueOf(sd.day__c);
		insert sd;

		PageReference pr = new PageReference('/apex/core_publishSetup?setupId='+TestDataSetupUtil_v2.activeSetUp.id);
    	Test.setCurrentPage(pr);
    	ApexPages.StandardController con = new ApexPages.StandardController(TestDataSetupUtil_v2.activeSetup);
		

		Test.startTest();
			core_PublishSetup publishController = new core_PublishSetup(con);
			
			system.assertEquals(publishController.reportingPeriods.size(), 2);
			system.assert(publishController.reportingPeriods[0].bSetup);
			ApexPages.currentPage().getParameters().put('rpId',  TestDataSetupUtil_v2.semester.id);
			core_SetupWrapper temp = publishController.cSetup; 
			publishController.cSetup = null;
			publishController.setupPublish();
			publishController.cSetup = temp;
			publishController.setupPublish();
			
			AsyncApexJob batch = [SELECT ID, ApexClassId, Status, TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE id=:publishController.batch.batchId];
			String className = [SELECT Name FROM ApexClass WHERE id=:batch.ApexClassId].Name;
			system.assertEquals('BatchUpsertHoldingObj', className);

			pr = new PageReference('/apex/core_publishSetup?setupId='+TestDataSetupUtil_v2.activeSetUp.id);
			Test.setCurrentPage(pr);
			con = new ApexPages.StandardController(TestDataSetupUtil_v2.activeSetup);
			publishController = new core_PublishSetup(con);
			ApexPages.currentPage().getParameters().put('rpId',  TestDataSetupUtil_v2.semester.id);
			publishController.publishData();
			
			publishController.bException = false;
			publishController.batch.batchId = null;
			publishController.continueBatch();			
			publishController.publishData();
			
			batch = [SELECT ID, ApexClassId, Status, TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE id=:publishController.batch.batchId];
			className = [SELECT Name FROM ApexClass WHERE id=:batch.ApexClassId].Name;
			system.assertEquals('CT_Scheduler_HoldingProcessor', className);
			
			publishController.bException = true;
			publishController.processSessions();
			publishController.bException = false;
			publishController.processSessions();
			batch = [SELECT ID, ApexClassId, Status, TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE id=:publishController.batch.batchId];
			className = [SELECT Name FROM ApexClass WHERE id=:batch.ApexClassId].Name;
			system.assertEquals('BatchInsertSessions', className);
			
			HoldingObj__c ho = new HoldingObj__c(Propagated__c=false, Reporting_Period_Id__c=TestDataSetupUtil_v2.semester.id, 
				Type__c='Staff', School_DBN__c=TestDataSetupUtil_v2.school.Reference_Id__c,
				School_Year__c=TestDataSetupUtil_v2.activeSetUp.Year__r.Name__c);
			insert ho;
			ho = new HoldingObj__c(Propagated__c=true, Reporting_Period_Id__c=TestDataSetupUtil_v2.semester.id, 
				Type__c='Staff', School_DBN__c=TestDataSetupUtil_v2.school.Reference_Id__c,
				School_Year__c=TestDataSetupUtil_v2.activeSetUp.Year__r.Name__c);
			insert ho;
			
			pr = new PageReference('/apex/core_publishSetup?setupId='+TestDataSetupUtil_v2.activeSetUp.id);
			Test.setCurrentPage(pr);
			con = new ApexPages.StandardController(TestDataSetupUtil_v2.activeSetup);
			publishController = new core_PublishSetup(con);
			
			system.assert(publishController.reportingPeriods[0].needPublish);
			
		Test.stopTest();
	}

}