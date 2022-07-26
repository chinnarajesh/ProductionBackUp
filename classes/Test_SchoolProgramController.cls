/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_SchoolProgramController {
	
	private static Account school;
	
	static testMethod void testConstructor(){
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			system.assert(!spc.hasUnsavedChanges);
			system.assert(!spc.bProgram);
			system.assertEquals(0,spc.areas.size());
			system.assertEquals(0,spc.sites.size());
			system.assertEquals(0,spc.schools.size());
			system.assertEquals('No schools are available for your user.',ApexPages.getMessages()[0].getSummary());
			
			setupData();
			spc = new SchoolProgramController();
			system.assertEquals(4,spc.areas.size());
			system.assertEquals(2,spc.requiredPrograms.size());
			system.assertEquals(2,spc.optionalPrograms.size());
			system.assertEquals(2,spc.sites.size());
			system.assertEquals(2,spc.schools.size());
			
			Profile p = [SELECT id FROM Profile WHERE Name LIKE '%Site Admin%' LIMIT 1];
			User user = TestDataUtil.createUser('ApexTestUser',p.id);
			user.Site__c = 'Boston';
			insert user;
			List<Account> schools = [SELECT Id, Site__c FROM Account WHERE Site__c = 'Boston'];
			schools[0].OwnerId = user.Id;
			update schools;
			system.runAs(user){
				spc = new SchoolProgramController();
				system.assertEquals(1,spc.SchoolsDisplay.size());
				system.assertEquals(1,spc.sites.size());
			}
		Test.stopTest();
	}
	
	static testMethod void testGetAreaOptions(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			List<SelectOption> areas = spc.getAreaOptions();
			system.assertEquals(4, areas.size());
		Test.stopTest();
	}
	
	static testMethod void testCreateProgram(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.createProgram();
			system.assert(spc.bProgram);
			system.assert(spc.newProgram.Active__c);
			system.assertEquals(null,spc.newProgram.id);
		Test.stopTest();
	}
	
	static testMethod void testSaveProgram(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.createProgram();
			spc.newProgram = TestDataUtil.createPrograms(1, true, spc.areas[0])[0];
			spc.saveProgram();
			system.assertEquals(3,spc.requiredPrograms.size());
			system.assert(!spc.bProgram);
		Test.stopTest();
	}
	
	static testMethod void testCancelProgram(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.createProgram();
			system.assert(spc.bProgram);
			spc.cancelProgram();
			system.assert(!spc.bProgram);
		Test.stopTest();
			
	}
	
	static testMethod void testSelectSchool(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.selectedSchool = school.id;
			spc.selectSchool();
			//if not enrolled in programs, all required will be checked
			for(SchoolProgramController.ProgramWrapper pw: spc.requiredProgramsDisplay) system.assert(pw.checked);
			for(SchoolProgramController.ProgramWrapper pw: spc.optionalProgramsDisplay) system.assert(!pw.checked);
		Test.stopTest();
	}
	
	static testMethod void testReadyExclusionReasons(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.readyExclusionReasons();
			system.assertEquals('No school selected.',ApexPages.getMessages()[0].getSummary());
			spc.selectedSchool = school.id;
			spc.readyExclusionReasons();
			//two required programs need exclusion reasons
			system.assertEquals(2,spc.needsReasons.size());
		Test.stopTest();
	}
	
	static testMethod void testValidateReasons(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.selectedSchool = school.id;
			spc.readyExclusionReasons();
			for(SchoolProgramController.ProgramWrapper pw: spc.needsReasons) pw.exclusionReason='';
			spc.validateReasons();
			system.assertEquals('Please enter reasons for excluding required programs.',ApexPages.getMessages()[0].getSummary());
		Test.stopTest();
	}
	
	static testMethod void testUpdateSchool(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.selectedSchool = school.id;
			spc.selectSchool();
			spc.updateSchool();
			system.assert(spc.hasUnsavedChanges);
			system.assertEquals(2,spc.changes.size());
		Test.stopTest();
	}
	
	static testMethod void testSaveChanges(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			spc.selectedSchool = school.id;
			spc.selectSchool();
			spc.updateSchool();
			spc.saveChanges();
			system.assert(!spc.hasUnsavedChanges);
			system.assertEquals('Your changes have been saved.',ApexPages.getMessages()[0].getSummary());
		Test.stopTest();
	}
	
	static testMethod void testResetPage(){
		setupData();
		Test.startTest();
			SchoolProgramController spc = new SchoolProgramController();
			PageReference pr = spc.resetPage();
			system.assert(pr.getURL().contains('IM_AddSchoolsToPrograms'));
		Test.stopTest();
	}
	
	static void setupData(){
		TestDataUtil.setupSharingControls();
		TestDataUtil.setupTime();
		school = TestDataUtil.createSchool('ApexTestSchool1');
		school.Site__c = 'Boston';
		List<Account> schools = new List<Account>{ school };
		schools.add(TestDataUtil.createSchool('ApexTestSchool2'));
		insert schools;
		List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
		insert ia;
		List<Program__c> programs = TestDataUtil.createPrograms(1,true,ia[0]);
		programs.addAll(TestDataUtil.createPrograms(1,true,ia[1]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[2]));
		programs.addAll(TestDataUtil.createPrograms(1,false,ia[3]));
		insert programs;
	}
}