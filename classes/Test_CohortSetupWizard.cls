@isTest
private class Test_CohortSetupWizard
{
	//Testing an existing cohort
	static testMethod void testWiz()
	{
		testDataSetupUtil_v2.setUPCoreData(3);
		testDataSetupUtil_v2.setUPStaffData(3);
		testDataSetupUtil_v2.setUPStudentData(3);
		
		Account school = testDataSetupUtil_v2.school;
		
		Cohort__c coh = new Cohort__c();
		coh.School__c = school.Id;
		coh.Year__c = '2012';
		coh.Name = 'blah';
		insert coh;
		
		Student__c stud = [SELECT Cohort__c , Individual__c	FROM Student__c WHERE 	School__c = :school.Id LIMIT 1];
		Contact con = 		[SELECT id 	, cohort__c				FROM Contact 		 WHERE 	Id=:Stud.individual__c	 ];
		con.Cohort__c = coh.Id;
		update con;
		
		Test.startTest();
		
		Cohort_SetupWizard wiz = new Cohort_SetupWizard(new ApexPages.StandardController(coh));
		System.debug('schools = ' + wiz.schools);
		wiz.cohort.School__c = wiz.schools[1].getValue();
		wiz.saveCohort();
		wiz.changeStudents();
		wiz.searchStuds();
		wiz.editCohort();
		wiz.cancelAddToCohort();
		for (Cohort_SetupWizard.StudentWrapper wrap: wiz.wrapper)
		{
			wrap.isSelected = true;
		}
		wiz.addCohorts();

		wiz.currentCohorts[0].isSelected = true;
		wiz.removeCohorts();
		wiz.editCohort();
		wiz.cancelAddToCohort();
		System.assertEquals(1, wiz.currentCohorts.size());
		System.assertEquals(1, wiz.wrapper.size());
		wiz.getRequirements(); 
		wiz.createRequirement();
		Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Course__c');
		Course__c c=  [SELECT Name FROM Course__c WHERE RecordTypeId = :rtMap.get('Subject_Area') limit 1];
		wiz.cohReq.subjectId = c.id;
		wiz.selectedCourseOption = testDataSetupUtil_v2.coursesList[0].id;
		wiz.cohReq.dCredits =3;
		wiz.saveRequirement();
		Test.stopTest();
	}
	
	//Testing a new Cohort
	static testMethod void testEmptyWiz()
	{
		testDataSetupUtil_v2.setUPCoreData(3);
		testDataSetupUtil_v2.setUPStaffData(3);
		testDataSetupUtil_v2.setUPStudentData(3);
		
		Test.startTest();
		Cohort_SetupWizard wiz = new Cohort_SetupWizard(new ApexPages.StandardController(new Cohort__c()));
		wiz.createCohort();
		wiz.saveCohort();
		System.assertEquals(null, wiz.cohort.Id);
		wiz.cohort.Year__c = '2012';
		wiz.cohort.Name = 'Some Test';
		try {
			wiz.cohort.School__c = 'alw301825304525281';
			wiz.saveCohort();
		}
		catch (exception e){
			
		}
		System.assertEquals(null, wiz.cohort.Id);
		wiz.cohort.School__c = wiz.schools[1].getValue();
		wiz.changeCohort();
		System.assertEquals(null, wiz.cohort.Id);
		wiz.saveCohort();
		System.assertNotEquals(null, wiz.cohort.Id);
		wiz.changeStudents();
		wiz.student.Date_of_Birth__c = System.today();
		wiz.student.Entry_Date__c = System.today();
		wiz.searchStuds();
		Test.stopTest();
	}
	
	//Testing cohort without any setup in order to get errors
	static testMethod void testWithoutSetup()
	{
		Test.startTest();
		Cohort_SetupWizard wiz = new Cohort_SetupWizard(new ApexPages.StandardController(new Cohort__c()));
		System.assert(wiz.critError);
		Test.stopTest();
	}
}