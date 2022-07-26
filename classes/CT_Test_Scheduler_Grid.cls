@isTest
private  class CT_Test_Scheduler_Grid {
	static testMethod void test_SchedulerGrid(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setupStaffData(5); 
		CT_mock_setupUtil.setupScheduleTemplates(testDataSetupUtil_v2.activeSetup);
		PageReference pr2 = new PageReference('/apex/CT_scheduler_Grid?setupid='+testDataSetupUtil_v2.activeSetup.id);
		test.startTest();
			test.setCurrentPage(pr2);
			CT_scheduler_Grid gridController = new CT_scheduler_Grid();
			gridController.rpId = testDataSetupUtil_v2.semester.id;
			gridController.initScheduleGrid();
			gridController.newSection();
			gridController.selectedCourse = testDataSetupUtil_v2.coursesList[0].id;
			gridController.section.name= 'Test Section 1';
			gridController.section.number_of_reporting_periods__c = '2';
			gridController.section.Active__c = true;			
			gridController.saveSection();
			Section_ReportingPeriod__c srp= [select id, section__c from Section_ReportingPeriod__c where section__r.name='Test Section 1' and Time__c =:testDataSetupUtil_v2.semester.id];
			gridController.processView();
			/* New Save method for Ohio*/
			String arrayString = ';'+srp.id+';'+gridController.periodList[0].key__c+';'+testDataSetupUtil_v2.teachersList[0].id+';'+ testDataSetupUtil_v2.roomList[0].id;
			string [] deleteList = new String[]{};
			CT_scheduler_Grid.saveSections_Remote(arrayString, deleteList);
			
			List <Scheduled_Section__c> ssList = [select id from Scheduled_Section__c where section_reportingPeriod__c=:srp.id];
			deleteList.add(ssList[0].id);
			arrayString ='';
			CT_scheduler_Grid.saveSections_Remote(arrayString, deleteList);
			
			arrayString = ';'+srp.id+';'+gridController.periodList[1].key__c+';'+testDataSetupUtil_v2.teachersList[0].id+';'+ testDataSetupUtil_v2.roomList[0].id;
			deleteList.clear();
			CT_scheduler_Grid.saveSections_Remote(arrayString, deleteList);
			
			gridController.processView();
			gridController.sectionId =  gridController.rowList[0].scheduledSections[0].sectId;
			gridController.editSection();
			gridController.cancelSection();
			gridController.processView();
			List <Time_Element__c> teList = CT_core_SoqlUtils.getTimeElementsByTerm(testDataSetupUtil_v2.activeSetup.term__c, true);
			PageReference pr3 = new PageReference('/apex/CT_scheduler_Grid?setupid='+testDataSetupUtil_v2.activeSetup.id+'&id='+testDataSetupUtil_v2.semester2.id);
			test.setCurrentPage(pr3);
			CT_scheduler_Grid gridController2 = new CT_scheduler_Grid();
			gridController.rpId = testDataSetupUtil_v2.semester.id;
			gridController.initScheduleGrid();
			gridController2.rpId = testDataSetupUtil_v2.semester2.id;
			gridController2.initScheduleGrid();
			gridController2.selectedCopyRp = testDataSetupUtil_v2.semester.id;
			gridController2.copyScheduledSectionsForNewRp();
		test.stopTest();
		//	system.assert( gridController2.unpublishedSectionList.size()==1);
	}
	
	
	static testMethod void test_SchedulerGrid2(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setupStaffData(5); 
		CT_mock_setupUtil.setupScheduleTemplates(testDataSetupUtil_v2.activeSetup);
		testDataSetupUtil_v2.activeSetup.room_Dependent__c=true;
		Room__c r = new Room__c(School__c = testDataSetupUtil_v2.school.id, Schedulable__c=true, Reference_Id__c ='101' );
		insert r; 
		PageReference pr2 = new PageReference('/apex/CT_scheduler_Grid?setupid='+testDataSetupUtil_v2.activeSetup.id+'&id='+testDataSetupUtil_v2.semester.id);
		test.startTest();
			test.setCurrentPage(pr2);
			CT_scheduler_Grid gridController = new CT_scheduler_Grid();
			gridController.rpId = testDataSetupUtil_v2.semester.id;
			gridController.initScheduleGrid();
			gridController.newSection();
			gridController.selectedCourse = testDataSetupUtil_v2.coursesList[0].id;
			gridController.section.name= 'Test Section 1';
			gridController.section.Number_of_Reporting_Periods__c = '2';
			gridController.section.Active__c = true;			
			gridController.saveSection();
			Section_ReportingPeriod__c srp= [select id, section__c from Section_ReportingPeriod__c where section__r.name='Test Section 1' and Time__c =:testDataSetupUtil_v2.semester.id];
			ApexPages.currentPage().getParameters().put('selectedType','r');
			ApexPages.currentPage().getParameters().put('selectedTab','0');
			gridController.refreshGrid();
			gridController.sErrorMessages.add('test');
			gridController.processErrorMessages();
			gridController.selectedStaffFilter= new List <Id>{testDataSetupUtil_v2.teachersList[0].id};
			gridController.filterStaff();
			CT_scheduler_Grid.cRowWrapper cr = new CT_scheduler_Grid.cRowWrapper(testDataSetupUtil_v2.teachersList[0]);
			CT_scheduler_Grid.cRowWrapper cr2 = new CT_scheduler_Grid.cRowWrapper(r);
		test.stopTest();
	}
}