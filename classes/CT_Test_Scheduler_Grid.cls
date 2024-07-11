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
			gridController.setupId=testDataSetupUtil_v2.activeSetup.id;
			gridController.initScheduleGrid();
			gridController.newSection();
			gridController.newSectionMass();
			gridController.selectedCourse = testDataSetupUtil_v2.coursesList[0].id;
			gridController.section.name= 'Test Section 1';
			gridController.section.number_of_reporting_periods__c = '2';
			gridController.section.Active__c = true;
			gridController.section.Time__c=	testDataSetupUtil_v2.semester.id;
			//gridController.section.Available_Grade_Levels__c='PS; PK; K; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12';
			gridController.saveSection();
			Section_ReportingPeriod__c srp= [select id, section__c from Section_ReportingPeriod__c where section__r.name='Test Section 1' and Time__c =:testDataSetupUtil_v2.semester.id];
			section__c sec =[select id,name from section__c where name='Test Section 1'];
			sec.Available_Grade_Levels__c='PS; PK; K; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12';
			update sec;
			gridController.section=sec;
			gridController.saveSection();
			gridController.processView();
			/* New Save method for Ohio*/
			String arrayString = ';'+srp.id+';'+gridController.periodList[0].key__c+';'+testDataSetupUtil_v2.teachersList[0].id+';'+ testDataSetupUtil_v2.roomList[0].id;
			string [] deleteList = new String[]{};
			CT_scheduler_Grid.saveSections_Remote(arrayString, deleteList);
			
			List <Scheduled_Section__c> ssList = [select id from Scheduled_Section__c where section_reportingPeriod__c=:srp.id];
			ApexPages.currentPage().getParameters().put('cmc',ssList[0].id);
			ApexPages.currentPage().getParameters().put('deleteList',ssList[0].id);
			gridController.saveSections();
			Set<id> ssIdset = new Set<Id>();
			ssIdset.add(ssList[0].id);
			gridController.deleteSessions(ssIdset);
			gridController.updateSecRepPeriods(ssIdset);
			deleteList.add(ssList[0].id);
			arrayString ='';
			CT_scheduler_Grid.saveSections_Remote(arrayString, deleteList);
			
			arrayString = ';'+srp.id+';'+gridController.periodList[1].key__c+';'+testDataSetupUtil_v2.teachersList[0].id+';'+ testDataSetupUtil_v2.roomList[0].id;
			deleteList.clear();
			CT_scheduler_Grid.saveSections_Remote(arrayString, deleteList);
			
			gridController.processView();
			gridController.sectionId = srp.section__c;// gridController.rowList[0].scheduledSections[0].sectId;
			gridController.editSection();
			List<Id> newlist = new List<id>();
			newlist.add(testDataSetupUtil_v2.coursesList[0].id);
			gridController.selectedCourses=newlist;
			gridController.section=sec;
			gridController.saveSectionMass();
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
			gridController.prev();
			gridController.bOccupancyError=true;
			gridController.next();
			CT_scheduler_Grid.massStaffMultiSelector wrapp = new CT_scheduler_Grid.massStaffMultiSelector();
			List<id> staffId = new List<Id>{srp.section__c};
			wrapp.leftselected=staffId;
			wrapp.rightselected=staffId;
			wrapp.selectclick();
			wrapp.unselectclick();
			wrapp.getSelectedValues();
			wrapp.getunSelectedValues();
			List<string> gradeList = new List<string>{'4','5'};
			wrapp.addGrades(gradeList);
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