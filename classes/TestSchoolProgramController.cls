@isTest
private class TestSchoolProgramController {
/*
	static testMethod void myUnitTest() {
		TestDataUtil.setupData(2);
		User sysAdmin = TestDataUtil.testData[0].sysAdmin.userRecord;
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c(Name = 'IA');	
		insert ia;
		List<Program__c> programs = new List<Program__c>();
		programs.add(new Program__c(Name = 'Program', Required_Program__c =true, Status__c = 'Approved',Indicator_Area__c = ia.Id, Active__c=true));
		programs.add(new Program__c(Name = 'Not Required Program', Required_Program__c =false, Status__c = 'Approved',Indicator_Area__c = ia.Id, Active__c=true));
		insert programs;
		test.startTest();
		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			SchoolProgramController cont = new SchoolProgramController();
			cont.selectedSchool = school_1.id;
			cont.getIAList();
			cont.selectSchool();
			system.assert(cont.getHasChanges());
			cont.readyExclusionReasons();
			cont.updateSchool();
		}
		test.stopTest();
	}

	static testMethod void testProgramCreation(){
		TestDataUtil.setupData(2);
		User sysAdmin = TestDataUtil.testData[0].sysAdmin.userRecord;
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c(Name = 'IA');	
		insert ia;

		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			Test.startTest();
				SchoolProgramController controller = new SchoolProgramController();
				//this would be called from the page on load
				controller.getAreaOptions();

				controller.createProgram();
				system.assert(controller.bProgram, 'Expected bProgram to be true.');
				controller.newProgram.Name = 'Program';
				controller.newProgram.Required_Program__c = true;
				controller.newProgram.Status__c = 'Approved';
				controller.newProgram.Indicator_Area__c = ia.Id;
				system.assert(controller.newProgram.Active__c, 'Expected the new program to be active');

				controller.saveProgram();
				system.assertNotEquals(null, controller.newProgram.ID, 'If the program saved, it should have an ID.');
				system.assertEquals(1, [select id from Program__c where ID=:controller.newProgram.ID].size(),'We should have been able to find the program in the database.');

				controller.createProgram();
				controller.cancelProgram();
				system.assertEquals(false, controller.bProgram,'bProgram should be false after we cancel.');
			Test.stopTest();
		}
	}

	static testMethod void testAccountProgramCreation(){
		TestDataUtil.setupData(2);
		User sysAdmin = TestDataUtil.testData[0].sysAdmin.userRecord;
		Account school_1 = TestDataUtil.testData[0].school;
		Account school_2 = TestDataUtil.testData[1].school;
		Indicator_Area__c ia = new Indicator_Area__c(Name = 'IA');	
		insert ia;
		List<Program__c> programs = new List<Program__c>();
		programs.add(new Program__c(Name = 'Program', Required_Program__c =true, Status__c = 'Approved',Indicator_Area__c = ia.Id, Active__c=true));
		programs.add(new Program__c(Name = 'Not Required Program', Required_Program__c =false, Status__c = 'Approved',Indicator_Area__c = ia.Id, Active__c=true));
		insert programs;

		system.runAs(TestDataUtil.testData[0].sysAdmin.userRecord) {
			Test.startTest();
				SchoolProgramController controller = new SchoolProgramController();
				controller.getAreaOptions();

				controller.selectedSchool = TestDataUtil.testData[0].school.ID;
				controller.selectSchool();

				system.assertEquals(1, controller.requiredProgramsDisplay.size(),'Expected there to be at least one required program.');
				controller.requiredProgramsDisplay[0].checked = false;
				controller.requiredProgramsDisplay[0].exclusionReason = 'You can\'t make me';
				controller.updateSchool();
				controller.validateReasons();
				controller.readyExclusionReasons();

				controller.saveChanges();
			Test.stopTest();
		}
	}
	*/
}