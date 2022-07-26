@isTest
private class TestGroupAgendaView {
	public static List<Schedule_Group__c> 	schedGrpsList; //no longer used Chicago release
	public static List<Section__c>			schedGrpsList_Section;
   
   	public static void createTestData(){    	
    	TestDataSetupUtil_v2.setUPCoreData(3);
    	TestDataSetupUtil_v2.setUpStaffData(5);
    	TestDataSetupUtil_v2.setUpStudentData(5);
    	schedGrpsList_Section = TestDataSetupUtil_v2.getScheduleGroups_Section();
    }
	
    static testMethod void testScheduleTemplateForGroups_New() {
    	createTestData();
    	PageReference scheduleTemplatePage = Page.core_ScheduleTemplate;
        scheduleTemplatePage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(scheduleTemplatePage);
    	//Setup Page
		Test.startTest();
			core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
			controller.rpID = testDataSetupUtil_v2.semester.id;
			controller.initTemplate();
			controller.bIsClone = false;
			controller.schedTemplate.name = 'Master temp';
			controller.schedTemplate.Is_Master__c = true;
			controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
			controller.schedTemplate.End_Time_Text__c = '5:00 PM';
			controller.schedTemplate.Has_Class__c = true;
			controller.saveSchedGrp();
		
		Schedule_Template__c st = new Schedule_Template__c();
		st = [SELECT Name,Id, Is_Master__c ,has_class__c,Start_Time_Text__c, End_Time_Text__c FROM Schedule_Template__c WHERE Id = : controller.schedTemplate.Id];
		
		System.assertEquals('Master temp', st.Name);
		System.assertEquals(true, st.Is_Master__c);
		System.assertEquals('8:00 AM', st.Start_Time_Text__c);
		System.assertEquals('5:00 PM', st.End_Time_Text__c);
		/********************  TEST Error Messages ****************************************************************/
		controller.templateId = 	st.Id;
		controller.initTemplate();
		controller.schedTemplate.End_Time_Text__c = '';
		controller.schedTemplate.Start_Time_Text__c = '';
		controller.saveSchedGrp();
		for(ApexPages.Message m : ApexPages.getMessages()){
			if(m.getDetail() == 'You must include both a start and end time for a scheduled section.')
			System.assert(true);
		}
		
		controller.schedTemplate.End_Time_Text__c = '8:00 AM';
		controller.schedTemplate.Start_Time_Text__c = '6:00 PM';
		controller.saveSchedGrp();
		for(ApexPages.Message m : ApexPages.getMessages()){
			if(m.getDetail() == 'End Time must be greater than the Start Time')
			System.assert(true);
		}
		
    	/********************************Test Creating New Scheduled Sections***********************************************************************/
    		PageReference groupAgendaViewPage = Page.GroupAgendaView;
    		groupAgendaViewPage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        	Test.setCurrentPage(groupAgendaViewPage);
    		GroupAgendaViewController gavc = new GroupAgendaViewController();
    		gavc.schedTempId = st.id;
    		gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
    		gavc.initAgendaView();

    			/****************************** Test the list of staff, courses and rooms associated with the setup *******************************************************/
    			for(Integer i = 0;i < testDataSetupUtil_v2.roomList.size();i++){
    				system.debug(gavc.gavw);
    				system.debug(gavc.gavw.roomOptionList[i].getlabel());
    			System.assertEquals(String.valueOf(testDataSetupUtil_v2.roomList[i].Number__c), gavc.gavw.roomOptionList[i].getlabel());
    			}
    			for(Integer i = 0;i < testDataSetupUtil_v2.teachersList.size();i++){
    			//System.assertEquals(testDataSetupUtil_v2.teachersList[i].First_Name_Staff__c + ' '+testDataSetupUtil_v2.teachersList[i].Staff_Last_Name__c, gavc.gavw.staffOptionList[i].getlabel());
    			}
    			for(Integer i = 0;i < testDataSetupUtil_v2.coursesList.size();i++){
    			System.assertEquals(String.valueOf(testDataSetupUtil_v2.coursesList[i].Name), gavc.gavw.courseOptionList[i].getlabel());
    			}
    			System.debug('$$$$$Schedule_Template__c'+gavc.schedTempId);
    		
    			/* *********************************TEST ERROR MESSAGES *****************************************************************************/
    			Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
				Apexpages.currentPage().getParameters().put('startTime','');
				Apexpages.currentPage().getParameters().put('endTime','');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','false');
				Apexpages.currentPage().getParameters().put('schedId','');
				
				gavc.saveJS();
				for(ApexPages.Message m : ApexPages.getMessages()){
				if(m.getDetail() == 'Start time must be populated' || m.getDetail() == 'End time must be populated')
				System.assert(true);
				}
				
				Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
				Apexpages.currentPage().getParameters().put('startTime','10:00 AM');
				Apexpages.currentPage().getParameters().put('endTime','09:15 AM');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','false');
				Apexpages.currentPage().getParameters().put('schedId','');
				gavc.saveJS();
				for(ApexPages.Message m : ApexPages.getMessages()){
				if(m.getDetail() == 'Start Time cannot be greater than End Time')
				System.assert(true);
				}
				
				Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
				Apexpages.currentPage().getParameters().put('startTime','6:00 AM');
				Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','false');
				Apexpages.currentPage().getParameters().put('schedId','');
    			
    			gavc.saveJS();
    			
    			for(ApexPages.Message m : ApexPages.getMessages()){
				if(m.getDetail() == 'Start Time cannot be less than 8:00 AM')
				System.assert(true);
				}
    			
    			Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[2].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[2].Id);
				Apexpages.currentPage().getParameters().put('startTime','5:00 PM');
				Apexpages.currentPage().getParameters().put('endTime','7:15 PM');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','false');
				Apexpages.currentPage().getParameters().put('schedId','');
    			
    			gavc.saveJS();
    			
    			for(ApexPages.Message m : ApexPages.getMessages()){
				if(m.getDetail() == 'End Time cannot be greater than 6:00 PM')
				System.assert(true);
				}
				
				/************************  TEST NEW SCHEDULED SECTION   ***********************************************************************************/
				Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
				Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
				Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','true');
				Apexpages.currentPage().getParameters().put('schedId','');
    			
    			gavc.saveJS();
    			Scheduled_Section__c schedSec = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c,Schedule_Template__c FROM Scheduled_Section__c WHERE Schedule_Template__c = : gavc.schedTempId];
    			System.assertEquals('09:00 AM',schedSec.Rounded_Start_Time__c);
    			System.assertEquals(testDataSetupUtil_v2.school.Id+'-'+schedGrpsList_Section[0].Id+'-'+testDataSetupUtil_v2.coursesList[0].Id+'-'+testDataSetupUtil_v2.semester.Id+'-'+gavc.schedTempId,schedSec.Reference_Id__c );
    			System.debug('$$$$$Schedule_Template__c'+schedSec.Schedule_Template__c);
    			
    			/************************  TEST EDIT SCHEDULED SECTION   ***********************************************************************************/
    			//After save create another record whose end time less than the 1st schedulesection end time and course name same -result upsert happens
    			System.debug('$$$$$TEST$$$$$$$$$4');
    			//de2162 delete schedule template deletes schedSec
    			
    			
    			
    			gavc = new GroupAgendaViewController();
    			gavc.schedTempId = st.id;
    			gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
    			gavc.initAgendaView();
    			Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
				Apexpages.currentPage().getParameters().put('startTime','10:00 AM');
				Apexpages.currentPage().getParameters().put('endTime','11:15 AM');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','true');
				Apexpages.currentPage().getParameters().put('schedId',schedSec.Id);
    			
    			gavc.saveJS();
    			Scheduled_Section__c schedSec2 = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c FROM Scheduled_Section__c WHERE Id = : schedSec.Id];
    			delete st;    			
    			Test.stopTest();
    			System.assertEquals('10:00 AM',schedSec2.Rounded_Start_Time__c);
    			System.assertEquals(testDataSetupUtil_v2.school.Id+'-'+schedGrpsList_Section[0].Id+'-'+testDataSetupUtil_v2.coursesList[0].Id+'-'+testDataSetupUtil_v2.semester.Id+'-'+gavc.schedTempId,schedSec2.Reference_Id__c );   		
    			system.assertEquals([select count() from Scheduled_Section__c where id=:schedSec.id],0);

    }
    
      static testMethod void testScheduleTemplateForGroups_OverlappingTimes() {
    	createTestData();
    	//Setup Page
    	PageReference scheduleTemplatePage = Page.core_ScheduleTemplate;
        scheduleTemplatePage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(scheduleTemplatePage);
		
		Test.startTest();
		core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
		controller.rpID = testDataSetupUtil_v2.semester.id;
		controller.initTemplate();
		controller.bIsClone = false;
		controller.schedTemplate.name = 'Master temp';
		controller.schedTemplate.Is_Master__c = true;
		controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
		controller.schedTemplate.End_Time_Text__c = '5:00 PM';
		controller.schedTemplate.Has_Class__c = true;
		controller.saveSchedGrp();
		
		Schedule_Template__c st = new Schedule_Template__c();
		st = [SELECT Name,Id, Is_Master__c ,has_class__c,Start_Time_Text__c, End_Time_Text__c FROM Schedule_Template__c WHERE Id = : controller.schedTemplate.Id];
	/*************************CREATE A NEW SCHEDULED SECTION************************************************************************************/	
    	PageReference groupAgendaViewPage = Page.GroupAgendaView;
		groupAgendaViewPage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
    	Test.setCurrentPage(groupAgendaViewPage);
		GroupAgendaViewController gavc = new GroupAgendaViewController();
		gavc.schedTempId = st.id;
		gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
		gavc.initAgendaView();
    	
    	Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
		Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
		Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
		Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
		Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
		Apexpages.currentPage().getParameters().put('dailyAtt','false');
		Apexpages.currentPage().getParameters().put('recordAtt','true');
		Apexpages.currentPage().getParameters().put('schedId','');
    			
    	gavc.saveJS();
    	
    /************************ CREATE A NEW SCHED SECTION WHOSE TEST START TIME AND END TIME OVERLAPPING WITH THE FIRST SCHEDULED SECTION   ***********************************************************************************/
    			//After save create another record whose start time less than the 1st schedulesection end time and course name different -result error is thrown
		gavc = new GroupAgendaViewController();
		gavc.schedTempId = st.id;
		gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
		gavc.initAgendaView();
    			Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[1].staff__c);
				Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[1].id);
				Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[1].Id);
				Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
				Apexpages.currentPage().getParameters().put('endTime','11:15 AM');
				Apexpages.currentPage().getParameters().put('dailyAtt','false');
				Apexpages.currentPage().getParameters().put('recordAtt','true');
				Apexpages.currentPage().getParameters().put('schedId','');
    			
    			gavc.saveJS();
    			System.assertEquals(true, gavc.hasErrors);
    			for(ApexPages.Message m : ApexPages.getMessages()){
    			if(m.getDetail() == 'The start and end times conflict with'+testDataSetupUtil_v2.coursesList[0].Name)
				System.assert(true);
				}
    	Test.stopTest();
    }
    
    static testMethod void testScheduleTemplateForGroups_DeleteAndInsert() {
     	createTestData();
    	//Setup Page
    	PageReference scheduleTemplatePage = Page.core_ScheduleTemplate;
        scheduleTemplatePage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(scheduleTemplatePage);
		
		Test.startTest();
		core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
		controller.rpID = testDataSetupUtil_v2.semester.id;
		controller.initTemplate();
		controller.bIsClone = false;
		controller.schedTemplate.name = 'Master temp';
		controller.schedTemplate.Is_Master__c = true;
		controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
		controller.schedTemplate.End_Time_Text__c = '5:00 PM';
		controller.schedTemplate.Has_Class__c = true;
		controller.saveSchedGrp();
		
		Schedule_Template__c st = new Schedule_Template__c();
		st = [SELECT Name,Id, Is_Master__c ,has_class__c,Start_Time_Text__c, End_Time_Text__c FROM Schedule_Template__c WHERE Id = : controller.schedTemplate.Id];
	/*************************CREATE A NEW SCHEDULED SECTION************************************************************************************/	
    	PageReference groupAgendaViewPage = Page.GroupAgendaView;
		groupAgendaViewPage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
    	Test.setCurrentPage(groupAgendaViewPage);
		GroupAgendaViewController gavc = new GroupAgendaViewController();
		gavc.schedTempId = st.id;
		gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
		gavc.initAgendaView();
    	
    	Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
		Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
		Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
		Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
		Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
		Apexpages.currentPage().getParameters().put('dailyAtt','false');
		Apexpages.currentPage().getParameters().put('recordAtt','true');
		Apexpages.currentPage().getParameters().put('schedId','');
    			
    	gavc.saveJS();
    	
    	List<Scheduled_Section__c> schedSecList = new List<Scheduled_Section__c>();
    	schedSecList = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c FROM Scheduled_Section__c WHERE Schedule_Template__c = : gavc.schedTempId order by id];
    	System.assertEquals(1, schedSecList.size());
    	Test.stopTest();
     }
    
     static testMethod void testScheduleTemplateForGroups_Delete() {
     	createTestData();
    	//Setup Page
    	PageReference scheduleTemplatePage = Page.core_ScheduleTemplate;
        scheduleTemplatePage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(scheduleTemplatePage);

		Test.startTest();
		core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
		controller.rpID = testDataSetupUtil_v2.semester.id;
		controller.initTemplate();
		System.debug('Page URL &&&&&&&&&&&&&7'+System.currentPageReference().getUrl());
		controller.bIsClone = false;
		controller.schedTemplate.name = 'Master temp';
		controller.schedTemplate.Is_Master__c = true;
		controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
		controller.schedTemplate.End_Time_Text__c = '5:00 PM';
		controller.schedTemplate.Has_Class__c = true;
		controller.saveSchedGrp();
		
		Schedule_Template__c st = new Schedule_Template__c();
		st = [SELECT Name,Id, Is_Master__c ,has_class__c,Start_Time_Text__c, End_Time_Text__c FROM Schedule_Template__c WHERE Id = : controller.schedTemplate.Id];
	/*************************CREATE A NEW SCHEDULED SECTION************************************************************************************/	
    	PageReference groupAgendaViewPage = Page.GroupAgendaView;
		groupAgendaViewPage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
    	Test.setCurrentPage(groupAgendaViewPage);
		GroupAgendaViewController gavc = new GroupAgendaViewController();
		gavc.schedTempId = st.id;
		gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
		gavc.initAgendaView();
    	
    	Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
		Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
		Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
		Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
		Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
		Apexpages.currentPage().getParameters().put('dailyAtt','false');
		Apexpages.currentPage().getParameters().put('recordAtt','true');
		Apexpages.currentPage().getParameters().put('schedId','');
    			
    	gavc.saveJS();
    	
    	List<Scheduled_Section__c> schedSecList = new List<Scheduled_Section__c>();
    	schedSecList = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c FROM Scheduled_Section__c WHERE Schedule_Template__c = : gavc.schedTempId order by id];
    	System.assertEquals(1, schedSecList.size());
    	/************************  TEST DELETE SCHED SECTION ***********************************************************************************/
    		Apexpages.currentPage().getParameters().put('schedId_del',schedSecList[0].Id);
    		gavc.deleteJS();
    			List<Scheduled_Section__c> schedSecListdel = new List<Scheduled_Section__c>();
    			
    			schedSecListdel = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c FROM Scheduled_Section__c WHERE Id = : schedSecList[0].Id order by id];
    			System.assertEquals(0, schedSecListdel.size());
       
       /************************  TEST REFRESH GROUPS ***********************************************************************************/
    		//	System.assertEquals(true, gavc.gavw.scheduleGroupList[0].isSelected);
     		//	System.assertEquals(false, gavc.gavw.scheduleGroupList[1].isSelected);
    		Apexpages.currentPage().getParameters().put('grpId',schedGrpsList_Section[1].Id);
    			gavc.refreshGroups();
    		//	System.assertEquals(false, gavc.gavw.scheduleGroupList[0].isSelected);
     		//	System.assertEquals(true, gavc.gavw.scheduleGroupList[1].isSelected);
     		Test.stopTest();
     }
     
     static testMethod void testScheduleTemplateForGroups_AllDay() {
     	createTestData();
    	//Setup Page
    	PageReference scheduleTemplatePage = Page.core_ScheduleTemplate;
        scheduleTemplatePage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(scheduleTemplatePage);
		
		Test.startTest();
		core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
		controller.rpID = testDataSetupUtil_v2.semester.id;
		controller.initTemplate();
		controller.bIsClone = false;
		controller.schedTemplate.name = 'Master temp';
		controller.schedTemplate.Is_Master__c = true;
		controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
		controller.schedTemplate.End_Time_Text__c = '5:00 PM';
		controller.schedTemplate.Has_Class__c = true;
		controller.saveSchedGrp();
		
		Schedule_Template__c st = new Schedule_Template__c();
		st = [SELECT Name,Id, Is_Master__c ,has_class__c,Start_Time_Text__c, End_Time_Text__c FROM Schedule_Template__c WHERE Id = : controller.schedTemplate.Id];
	/*************************CREATE ALL DAY  SCHEDULED SECTION************************************************************************************/	
    	PageReference groupAgendaViewPage = Page.GroupAgendaView;
		groupAgendaViewPage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
    	Test.setCurrentPage(groupAgendaViewPage);
		GroupAgendaViewController gavc = new GroupAgendaViewController();
		gavc.schedTempId = st.id;
		gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
		gavc.initAgendaView();
    	
    	Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
		Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
		Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
		Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
		Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
		Apexpages.currentPage().getParameters().put('dailyAtt','true');
		Apexpages.currentPage().getParameters().put('recordAtt','false');
		Apexpages.currentPage().getParameters().put('noclass','false');
		Apexpages.currentPage().getParameters().put('schedId','');
    			
    	gavc.saveJS();
    	System.debug('----CURRENT SCHED SECTION-------------'+gavc.currSchedSec);
    	List<Scheduled_Section__c> schedSecList = new List<Scheduled_Section__c>();
    	schedSecList = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c,Record_Attendance__c FROM Scheduled_Section__c WHERE Schedule_Template__c = : gavc.schedTempId order by id];
    	System.assertEquals(1, schedSecList.size());
    	System.assertEquals(gavc.currSchedSec.Reference_Id__c, schedSecList[0].Reference_Id__c);
    	System.assertEquals(true, schedSecList[0].Record_Attendance__c);
    	Test.stopTest();
     }
     
     static testMethod void testScheduleTemplateConfig_Clone() {
     	createTestData();
    	//Setup Page
     	PageReference scheduleTemplatePage = Page.core_ScheduleTemplate;
        scheduleTemplatePage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
        Test.setCurrentPage(scheduleTemplatePage);

		Test.startTest();
			core_scheduleTemplateConfiguration controller = new core_scheduleTemplateConfiguration();
			controller.rpID = testDataSetupUtil_v2.semester.id;
			controller.initTemplate();
			controller.bIsClone = false;
			controller.schedTemplate.name = 'Master temp';
			controller.schedTemplate.Is_Master__c = true;
			controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
			controller.schedTemplate.End_Time_Text__c = '5:00 PM';
			controller.schedTemplate.Has_Class__c = true;
			controller.saveSchedGrp();
			
			Schedule_Template__c st = new Schedule_Template__c();
			st = [SELECT Name,Id, Is_Master__c ,has_class__c,Start_Time_Text__c, End_Time_Text__c FROM Schedule_Template__c WHERE Id = : controller.schedTemplate.Id];
			/*************************CREATE A NEW SCHEDULED SECTION************************************************************************************/	
	    	PageReference groupAgendaViewPage = Page.GroupAgendaView;
			groupAgendaViewPage.getParameters().put('setupId',testDataSetupUtil_v2.activeSetup.id);
	    	Test.setCurrentPage(groupAgendaViewPage);
			GroupAgendaViewController gavc = new GroupAgendaViewController();
			gavc.schedTempId = st.id;
			gavc.reptPeriod = testDataSetupUtil_v2.semester.id;
			gavc.initAgendaView();
	    	
	    	Apexpages.currentPage().getParameters().put('staffId',testDataSetupUtil_v2.staffSectionsList[0].staff__c);
			Apexpages.currentPage().getParameters().put('roomId',testDataSetupUtil_v2.roomList[0].id);
			Apexpages.currentPage().getParameters().put('courseId',testDataSetupUtil_v2.coursesList[0].Id);
			Apexpages.currentPage().getParameters().put('startTime','9:00 AM');
			Apexpages.currentPage().getParameters().put('endTime','10:15 AM');
			Apexpages.currentPage().getParameters().put('dailyAtt','false');
			Apexpages.currentPage().getParameters().put('recordAtt','true');
			Apexpages.currentPage().getParameters().put('schedId','');
    			
    		gavc.saveJS();
    	
	    	List<Scheduled_Section__c> schedSecList = new List<Scheduled_Section__c>();
	    	schedSecList = [SELECT Id,Reference_Id__c,Rounded_Start_Time__c FROM Scheduled_Section__c WHERE Schedule_Template__c = : gavc.schedTempId order by id];
	    	System.assertEquals(1, schedSecList.size());
	    	controller.templateId = null;
	    	controller.cloneTemplateId = st.id;
	    	controller.bIsClone = true;
	    	controller.initTemplate();

			//controller.schedTemplate = new Schedule_Template__c();
			controller.schedTemplate.name = 'Half Day';
			controller.schedTemplate.Is_Master__c = false;
			controller.schedTemplate.Start_Time_Text__c = '8:00 AM';
			controller.schedTemplate.End_Time_Text__c = '5:00 PM';
			controller.schedTemplate.Has_Class__c = true;
			controller.schedTemplate.Reporting_Period__c = testDataSetupUtil_v2.semester.Id;
			controller.saveSchedGrp();
					
			List<Scheduled_Section__c> schedSecsList2 = [SELECT ID,Reference_Id__c,Schedule_Template__c,Schedule_Template__r.Name FROM Scheduled_Section__c WHERE Schedule_Template__c = : controller.schedTemplate.Id];
	   				
	   		System.assertEquals(schedSecsList2[0].Schedule_Template__r.Name, 'Half Day'); 
	   		System.assertEquals(schedSecsList2.size(), 1);
	   	Test.stopTest(); 
     }
    
     
    public static List<Schedule_Group__c> getScheduleGroups(){
    	schedGrpsList = new List<Schedule_Group__c>();
    	    	/* deprecated for Chicago release
    	schedGrpsList.add(new Schedule_Group__c(Name = '5A',Grade_Level__c = '5',Description__c='test1',SetUp__c = testDataSetupUtil_v2.activeSetUp.Id));
    	schedGrpsList.add(new Schedule_Group__c(Name = '5B',Grade_Level__c = '5',Description__c='test2',SetUp__c = testDataSetupUtil_v2.activeSetUp.Id));
    	insert schedGrpsList;
    	System.debug('----------schedGrpsList -------------------------------'+schedGrpsList);*/
    	return schedGrpsList;
    }
    
}