@isTest
public class Test_Gradebook_RunReportCards {
	private static List<Student_Reporting_Period__c> srps = new List<Student_Reporting_Period__c>();
	public static void setupData(){
		TestDataSetupUtil_v2.setUPCoreData(10);
		TestDataSetupUtil_v2.setUpStaffData(10);
		TestDataSetupUtil_v2.setUpStudentData(10);

		for(Student__c s:TestDataSetupUtil_v2.studentsList){
			srps.add(new Student_Reporting_Period__c(
				Student__c = s.id,
				Time__c = TestDataSetupUtil_v2.semester.id));
		}
		insert srps;

		TestDataSetupUtil_v2.studentsList[0].Home_Language__c = 'Spanish';
		update TestDataSetupUtil_v2.studentsList[0];
	}

	@isTest static void test_constructor() {
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			system.assertEquals(true, controller.bHome);
		Test.stopTest();
	}

	@isTest static void test_runGPABatch(){
  		Test.setCurrentPage(Page.Gradebook_RunReportCards);
    	Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoGPA();
			system.assertEquals(true, controller.bGPA);
			controller.runGPA();
			system.assertEquals(1, controller.gpaJobs.size());
		Test.stopTest();
	}

	@isTest static void test_documentsSetup(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			System.assertEquals(1, controller.schools.size());
			System.assertEquals(2, controller.schools[0].reportingPeriods.size());
			controller.includeInactiveSetups();
		Test.stopTest();
	}

	@isTest static void test_SectionSelection(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			controller.schools[0].selected = true;
			controller.selectedSectionSchool = controller.schools[0].setup.id;
			controller.showCurrentSections();
			controller.hideCurrentSections();
			system.assertEquals(10, controller.schools[0].sections.size());
		Test.stopTest();
	}

	@isTest static void test_AdditionalOptions(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			controller.schools[0].selected = true;
			controller.selectedSectionSchool = controller.schools[0].setup.id;
			controller.loadAdditionalOptions();
			System.assertNotEquals(null, controller.searchOptionWrapper);
			controller.searchOptionWrapper.Gifted__c = true;
			controller.saveAdditionalOptions();
			System.assertEquals(true, controller.schools[0].searchOptionWrapper.Gifted__c);
		Test.stopTest();
	}

	@isTest static void test_preGenerationSearchless(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			controller.schools[0].selected = true;
			//generally the page would take care of these two autmatically, but we have to set them in here.
			controller.schools[0].selectedReportingPeriod = controller.schools[0].reportingPeriods[0].getValue();
			controller.schools[0].selectedDocument = 'Report Card - High School';
			controller.startGeneration();
			System.assertEquals(10, controller.peopleToGenerate.size());
			//just asserting things that will be needed if the system were to continue into the generation phase.
			for(Gradebook_RunReportCardsWrapper.personWrapper s: controller.peopleToGenerate){
				System.assertNotEquals(null, s.log.id);
				System.assertNotEquals(null, s.log.Reporting_Period_Name__c);
				System.assertNotEquals(null, s.log.Document_Type__c);
				System.assertNotEquals(null, s.srp);
			}
		Test.stopTest();
	}

	@isTest static void test_StudentSearch(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			controller.schools[0].selected = true;
			//the section filter covers quite a bit of the query, so we need to load the sections list to make sure the logic covers it
			controller.selectedSectionSchool = controller.schools[0].setup.id;
			controller.showCurrentSections();
			controller.schools[0].sections[0].selected = false;
			controller.hideCurrentSections();

			controller.startSearch();
			controller.searchPeople();
			System.assertEquals(9, controller.searchResults.size());
			for(Gradebook_RunReportCardsWrapper.personWrapper s: controller.searchResults){
				s.selected = true;
			}
			controller.addStudentsToGeneration();
			System.assertEquals(9, controller.peopleToGenerate.size());
			controller.peopleToGenerate[5].selected = true;
			controller.removeStudentsFromGeneration();
			System.assertEquals(8, controller.peopleToGenerate.size());
	}

	@isTest static void test_generation(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			controller.schools[0].selected = true;
			//generally the page would take care of these two autmatically, but we have to set them in here.
			controller.schools[0].selectedReportingPeriod = controller.schools[0].reportingPeriods[0].getValue();
			controller.schools[0].selectedDocument = 'Report Card - High School';
			controller.startGeneration();
			System.assertEquals(10, controller.peopleToGenerate.size());
			controller.generateBatch();
			controller.cleanUp();
		Test.stopTest();
	}

	@isTest static void test_abort(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoDocumentGeneration();
			controller.schools[0].selected = true;
			//generally the page would take care of these two autmatically, but we have to set them in here.
			controller.schools[0].selectedReportingPeriod = controller.schools[0].reportingPeriods[0].getValue();
			controller.schools[0].selectedDocument = 'Report Card - High School';
			controller.startGeneration();
			System.assertEquals(10, controller.peopleToGenerate.size());
			controller.abortBatch();
		Test.stopTest();
	}

	@isTest static void test_singleGeneration(){
		setupData();
		PageReference pref = Page.Student_Report_Card;
		pref.getParameters().put('student', TestDataSetupUtil_v2.studentsList[0].id);
		Test.setCurrentPage(pref);
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.setupSingleGeneration();
			System.assertEquals(1, controller.studentReportingPeriods.size());
			System.assertEquals(TestDataSetupUtil_v2.semester.id, controller.studentReportingPeriods[0].Time__c);
			controller.bShowInPortal = false;
			controller.bIncludeInactiveStudentSections = false;
			controller.bIncludeTransferedSections = false;
			controller.schools[0].selectedDocument = 'Report Card';
			controller.selectedReportingPeriod = controller.studentReportingPeriods[0].id;
			controller.startGeneration();
			controller.generateBatch();
		Test.stopTest();
	}
	
	@isTest static void test_staffSearch(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoScheduleGeneration();
			controller.bStudent = false;
			controller.schools[0].selected = true;
			controller.startSearch();
			controller.staffSearchWrapper.ID__c = TestDataSetupUtil_v2.teachersList[0].ID__c; 
			controller.searchPeople();
			system.assertEquals(1,controller.searchResults.size());
			for(Gradebook_RunReportCardsWrapper.personWrapper s: controller.searchResults){
				s.selected = true;
			}
			controller.addStudentsToGeneration();
			System.assertEquals(1, controller.peopleToGenerate.size());
			controller.peopleToGenerate[0].selected = true;
			controller.removeStudentsFromGeneration();
			System.assertEquals(0, controller.peopleToGenerate.size());
		Test.stopTest();
	}
	
	@isTest static void test_staffSectionSearch(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoScheduleGeneration();
			controller.bStudent = false;
			controller.schools[0].selected = true;
			controller.selectedSectionSchool = controller.schools[0].setup.id;
			controller.showCurrentSections();
			controller.schools[0].sections[0].selected = false;
			controller.hideCurrentSections();
			controller.startGeneration();
			//EE every section has 1 staff/section, so there should be 1 staff for every section selected
			system.assertEquals(controller.schools[0].sections.size()-1,controller.peopleToGenerate.size());
			
			controller = new Gradebook_RunReportCardsController();
			controller.gotoScheduleGeneration();
			controller.bStudent = false;
			controller.schools[0].selected = true;
			controller.selectedSectionSchool = controller.schools[0].setup.id;
			controller.showCurrentSections();
			controller.schools[0].sections[0].selected = false;
			controller.hideCurrentSections();
			//EE have to run the same logic while in a search to hit certain lines
			controller.startSearch();
			controller.searchPeople();
			//EE every section has 1 staff/section, so there should be 1 staff for every section selected
			system.assertEquals(controller.schools[0].sections.size()-1,controller.searchResults.size());
		Test.stopTest();
	}
	
	@isTest static void test_staffGeneration(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoScheduleGeneration();
			controller.bStudent = false;
			controller.schools[0].selected = true;
			controller.schools[0].selectedReportingPeriod = controller.schools[0].reportingPeriods[0].getValue();
			controller.showCurrentSections();
			controller.hideCurrentSections();
			controller.startGeneration();
			System.assertEquals(TestDataSetupUtil_v2.teachersList.size(), controller.peopleToGenerate.size());
			controller.generateBatch();
			controller.cleanUp();
		Test.stopTest();
	}
	
	@isTest static void test_studentGeneration(){
		Test.setCurrentPage(Page.Gradebook_RunReportCards);
		setupData();
		Test.startTest();
			Gradebook_RunReportCardsController controller = new Gradebook_RunReportCardsController();
			controller.gotoScheduleGeneration();
			controller.schools[0].selected = true;
			controller.schools[0].selectedReportingPeriod = controller.schools[0].reportingPeriods[0].getValue();
			controller.showCurrentSections();
			controller.hideCurrentSections();
			controller.startGeneration();
			System.assertEquals(TestDataSetupUtil_v2.studentsList.size(), controller.peopleToGenerate.size());
			controller.generateBatch();
			controller.cleanUp();
		Test.stopTest();
	}
}