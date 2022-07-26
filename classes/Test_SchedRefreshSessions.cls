@isTest
private class Test_SchedRefreshSessions {

    static testMethod void testPeriodBased() {
    	List<Period__c> periodsList = new List<Period__c>();
    	List<Schedule_Day__c> schedDays = new List<Schedule_Day__c>();
    	List<Scheduled_Section__c> scheduledSections = new List<Scheduled_Section__c>();
    	List<Datetime> startTimes = new List<Datetime>();
    	List<Datetime> endTimes = new List<Datetime>();
    	List<Datetime> newStartTimes = new List<Datetime>();
    	List<Datetime> newEndTimes = new List<Datetime>();
    	
    	testDataSetupUtil_v2.setUPCoreData(5);
    	testDataSetupUtil_v2.setUpStaffData(5);
    	testDataSetupUtil_v2.activeSetUp.Group_Based__c=false;
      		update testDataSetupUtil_v2.activeSetUp;
      
        Schedule_Template__c masterTemplate = new Schedule_Template__c(Reporting_Period__c = testDataSetupUtil_v2.semester.Id, Name='Master', setup__c=testDataSetupUtil_v2.activeSetUp.Id, is_master__c = true, has_class__c = true);
         	insert masterTemplate;
       
        Datetime endTime = Datetime.newInstance(2011, 11, 11, 09, 00, 0);
        for(Integer i = 0;i<4;i++){
        	Period__c p = new Period__c();	
        	p.Key__c = String.valueOf(i+1); 
        	p.Order__c =i;
        	p.Schedule_Template__c = masterTemplate.Id;
        	p.Start_Time__c = endTime.addMinutes(5) ;
        	p.End_Time__c = endTime.addHours(1);
        	p.Passing_Time__c = '5';
        	endTime = p.End_Time__c;
        	periodsList.add(p);
        	startTimes.add(p.Start_Time__c);
        	endTimes.add(p.End_Time__c);
        } 
        
        
        
          Schedule_Template__c halfDayTemplate = new Schedule_Template__c(Reporting_Period__c = testDataSetupUtil_v2.semester.Id, Name='Master', setup__c=testDataSetupUtil_v2.activeSetUp.Id, is_master__c = false, has_class__c = true);
         	insert halfDayTemplate;
       
         endTime = Datetime.newInstance(2011, 11, 11, 12, 00, 0);
        for(Integer i = 0;i<4;i++){
        	Period__c p = new Period__c();	
        	p.Key__c = String.valueOf(i+1); 
        	p.Order__c =i;
        	p.Schedule_Template__c = halfDayTemplate.Id;
        	p.Start_Time__c = endTime.addMinutes(5) ;
        	p.End_Time__c = endTime.addHours(1);
        	p.Passing_Time__c = '5';
        	endTime = p.End_Time__c;
        	periodsList.add(p);
        	newStartTimes.add(p.Start_Time__c);
        	newEndTimes.add(p.End_Time__c);
        } 
        
        insert periodsList;
        
        List<Section_ReportingPeriod__c> secRpList = [SELECT Id FROM Section_ReportingPeriod__c WHERE Section__c =:testDataSetupUtil_v2.sectionsList[0].Id AND Time__c = : testDataSetupUtil_v2.semester.Id];
        for(Integer i = 0;i <4;i++){
        	Scheduled_Section__c ss = new Scheduled_Section__c();
        	ss.Account__c = testDataSetupUtil_v2.school.Id;
        	ss.Course__c = testDataSetupUtil_v2.coursesList[0].Id;
        	ss.Needs_Publish__c = true;
        	ss.Period_Key__c = String.valueof(i+1);
        	ss.Reference_Id__c = testDataSetupUtil_v2.semester.Id+'-'+periodsList[i].Key__c+'-'+testDataSetupUtil_v2.teachersList[0].Id;
        	ss.Reporting_Period__c = testDataSetupUtil_v2.semester.Id;
        	ss.Section_ReportingPeriod__c = secRpList[0].Id;
        	ss.Section__c = testDataSetupUtil_v2.sectionsList[0].Id;
        	scheduledSections.add(ss);
        
        }
        
        	insert scheduledSections;
        	
        Date rpStartDate = testDataSetupUtil_v2.semester.Date_Start_Date__c;
        Date rpEndDate = testDataSetupUtil_v2.semester.End_Date__c;
        Integer i =0;
        for(Date d = rpStartDate; d < = rpEndDate;){
        	System.debug('----------DDD-------'+d);
        	
        	Schedule_Day__c sd = new Schedule_Day__c();
        	sd.Schedule_Template__c = masterTemplate.Id;
        	i++;
        	sd.Day__c = d;
        	sd.ReferenceId__c = testDataSetupUtil_v2.semester.Id + String.valueOf(d);
        	System.debug('------REFERENCEID--------'+sd.ReferenceId__c );
        	sd.Reporting_Period__c = testDataSetupUtil_v2.semester.Id;
        	schedDays.add(sd);
        	d= d.adddays(i);
        	
        }
        	insert     schedDays; 
     	  List<Section_ReportingPeriod__c> sectionRPList = new List<Section_ReportingPeriod__c>();
        Section_ReportingPeriod__c sectionRp = [SELECT RecordTypeId FROM Section_ReportingPeriod__c WHERE Section__c =: testDataSetupUtil_v2.sectionsList[0].id AND Time__c = : testDataSetupUtil_v2.semester.Id];
    	sectionRp.Period__c = '1,2,3,4';
    	sectionRp.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('Published');
    	
    	update sectionRp;
    				  
    	List<Schedule_day__c> retrieveSchedDays = new List<Schedule_day__c>();
    	retrieveSchedDays = [SELECT ID,Day__c,Schedule_Template__c,Reporting_Period__c,Schedule_Template__r.Setup__r.School__c FROM Schedule_Day__c WHERE Id in: schedDays];
    	
    	Scheduler_CreateSessions pub = new Scheduler_CreateSessions(retrieveSchedDays, null);
		sched_RefreshSessionsAfterPublish.firstRun = false;
		pub.createSessionsForPeriods(retrieveSchedDays);
		System.assertEquals(1, pub.schedTempIds.size());
		//System.assertEquals(16,pub.sessionList.size());
    	pub.publishScheduleDays(retrieveSchedDays);
    	
    	List<Session__c> sessList = new List<Session__c>();
    	sessList = [SELECT Start_DateTime__c,End_DateTime__c,Session_Date__c FROM Session__c WHERE Id in:pub.sessionList order by Session_Date__c,Start_DateTime__c];
    	i=0;
    	 for(Session__c sess: sessList){
    	     	System.assertEquals(startTimes[i].time(),sess.Start_DateTime__c.time());
    	     	System.assertEquals(endTimes[i].time(),sess.End_DateTime__c.time());
        		i++; 
        		if(i ==4) i =0;
    	 } 
    	 
    	 Schedule_Day__c sd = [SELECT Id, Schedule_Template__c,Day__c FROM Schedule_Day__c WHERE Id = : schedDays[0].Id];
    		sd.Schedule_Template__c = halfDayTemplate.Id;
    		sched_RefreshSessionsAfterPublish.firstRun = true;
    			    		test.startTest();
    		update sd;
    			    		test.stopTest();
    	
    	sessList.clear();	
    	sessList = [SELECT Start_DateTime__c,End_DateTime__c,Session_Date__c FROM Session__c WHERE Id in:pub.sessionList order by Session_Date__c,Start_DateTime__c];
    	i=0;
    	 for(Session__c sess: sessList){System.debug(sess.Session_Date__c+'$$$$'+sd.Day__c);
    	 		if(sess.Session_Date__c == sd.Day__c){
    	 			System.assertEquals(newStartTimes[i].time(),sess.Start_DateTime__c.time());
    	     		System.assertEquals(newEndTimes[i].time(),sess.End_DateTime__c.time());
    	 		}
    	 		else{
    	     	System.assertEquals(startTimes[i].time(),sess.Start_DateTime__c.time());
    	     	System.assertEquals(endTimes[i].time(),sess.End_DateTime__c.time());
    	 		}
        		i++; 
        		if(i ==4) i =0; 
    	 } 	
    }
    
    
   static testMethod void testGroupsbased() {
    	testDataSetupUtil_v2.setUPCoreData(5);
    	
    	
    	List<Schedule_Day__c> schedDays = new List<Schedule_Day__c>();
    	List<Scheduled_Section__c> scheduledSections = new List<Scheduled_Section__c>();
    	List<Datetime> startTimes = new List<Datetime>();
    	List<Datetime> endTimes = new List<Datetime>();
    	List<Datetime> newStartTimes = new List<Datetime>();
    	List<Datetime> newEndTimes = new List<Datetime>();
    	
    	
    	testDataSetupUtil_v2.setUpStaffData(5);
    	List <Section__c> scheduleGroups = testDataSetupUtil_v2.getScheduleGroups_Section();
    	testDataSetupUtil_v2.activeSetUp.Group_Based__c=true;
      		update testDataSetupUtil_v2.activeSetUp;
      
        Schedule_Template__c masterTemplate = new Schedule_Template__c(Reporting_Period__c = testDataSetupUtil_v2.semester.Id, Name='Master', setup__c=testDataSetupUtil_v2.activeSetUp.Id, is_master__c = true, has_class__c = true,Start_Time__c=Datetime.newInstance(2011, 11, 11, 09, 00, 00),End_Time__c=Datetime.newInstance(2011, 11, 11, 16, 00, 00));
         	insert masterTemplate;
       
        Schedule_Template__c halfDayTemplate = new Schedule_Template__c(Reporting_Period__c = testDataSetupUtil_v2.semester.Id, Name='Master', setup__c=testDataSetupUtil_v2.activeSetUp.Id, is_master__c = false, has_class__c = true,Start_Time__c=Datetime.newInstance(2011, 11, 11, 09, 00, 00),End_Time__c=Datetime.newInstance(2011, 11, 11, 12, 00, 00));
         	insert halfDayTemplate;
       
         Datetime endTime = Datetime.newInstance(2011, 11, 11, 09, 00, 0);
       
        
        for(Integer i = 0;i <1;i++){
        	Scheduled_Section__c ss = new Scheduled_Section__c();
        	ss.Start_Time__c = endTime.addhours(i);
        	ss.End_Time__c = ss.Start_Time__c.addhours(1);
			ss.Staff__c = testDataSetupUtil_v2.teachersList[0].Id;
			ss.Section_Reference_Id__c = Importutils.createSectionReferenceKey(testDataSetupUtil_v2.school.Id, scheduleGroups[0].id, testDataSetupUtil_v2.coursesList[0].Id, testDataSetupUtil_v2.semester.Id);
			ss.Schedule_Group_Section__c = scheduleGroups[0].id;
			ss.Reporting_Period__c = testDataSetupUtil_v2.semester.Id;
			ss.Reference_Id__c = Importutils.createScheduledSectionKey(testDataSetupUtil_v2.school.Id,  scheduleGroups[0].id, testDataSetupUtil_v2.coursesList[0].Id, testDataSetupUtil_v2.semester.Id,masterTemplate.Id);
			ss.Record_Attendance__c = true;
			ss.Needs_Publish__c = true;
			ss.Schedule_Template__c = masterTemplate.Id;
			ss.Account__c = testDataSetupUtil_v2.school.Id;
        	ss.Course__c = testDataSetupUtil_v2.coursesList[0].Id;
        	scheduledSections.add(ss);
        	startTimes.add(ss.Start_Time__c);
        	endTimes.add(ss.End_Time__c);
        }
        
        endTime = Datetime.newInstance(2011, 11, 11, 08, 00, 0);
        for(Integer i = 0;i<1;i++){
        	Scheduled_Section__c ss = new Scheduled_Section__c();
        	ss.Start_Time__c = endTime.addhours(i);
        	ss.End_Time__c = ss.Start_Time__c.addhours(1);
			ss.Staff__c = testDataSetupUtil_v2.teachersList[0].Id;
			ss.Section_Reference_Id__c = Importutils.createSectionReferenceKey(testDataSetupUtil_v2.school.Id, scheduleGroups[0].id, testDataSetupUtil_v2.coursesList[0].Id, testDataSetupUtil_v2.semester.Id);
			ss.Schedule_Group_Section__c =  scheduleGroups[0].id;
			ss.Reporting_Period__c = testDataSetupUtil_v2.semester.Id;
			ss.Reference_Id__c = Importutils.createScheduledSectionKey(testDataSetupUtil_v2.school.Id,  scheduleGroups[0].id, testDataSetupUtil_v2.coursesList[0].Id, testDataSetupUtil_v2.semester.Id,halfDayTemplate.Id);
			ss.Record_Attendance__c = true;
			ss.Needs_Publish__c = true;
			ss.Schedule_Template__c = halfDayTemplate.Id;
			ss.Account__c = testDataSetupUtil_v2.school.Id;
        	ss.Course__c = testDataSetupUtil_v2.coursesList[0].Id;
        	system.debug('ss~'+ss);
        	scheduledSections.add(ss);
         
        }
        
        	insert scheduledSections;
        	
        Date rpStartDate = testDataSetupUtil_v2.semester.Date_Start_Date__c;
        Date rpEndDate = testDataSetupUtil_v2.semester.End_Date__c;
        Integer i =0;
        for(Date d = rpStartDate; d < = rpEndDate;){
        	System.debug('----------DDD-------'+d);
        	
        	Schedule_Day__c sd = new Schedule_Day__c();
        	sd.Schedule_Template__c = masterTemplate.Id;
        	i++;
        	sd.Day__c = d;
        	sd.ReferenceId__c = testDataSetupUtil_v2.semester.Id + String.valueOf(d);
        	System.debug('------REFERENCEID--------'+sd.ReferenceId__c );
        	sd.Reporting_Period__c = testDataSetupUtil_v2.semester.Id;
        	schedDays.add(sd);
        	d= d.adddays(i);
        	
        }
        	insert     schedDays; 
        	
        	
        	Section__c section = new Section__c();
			section.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Published');
	        section.Reference_Id__c = scheduleGroups[0].name+'-'+testDataSetupUtil_v2.coursesList[0].name+testDataSetupUtil_v2.school.Name+testDataSetupUtil_v2.term.Parent_Time_Element__c;
	        section.Scheduler_Reference_Id__c = Importutils.createSectionReferenceKey(testDataSetupUtil_v2.school.Id, scheduleGroups[0].id, testDataSetupUtil_v2.coursesList[0].Id, testDataSetupUtil_v2.semester.Id);
	        section.School__c = testDataSetupUtil_v2.school.Id;
	        section.Name = scheduleGroups[0].name+'-'+testDataSetupUtil_v2.coursesList[0].name;
	        section.Is_Section__c = true;
	        section.Active__c = true; //Use Active__c homework/gradebook/etc need this
	        section.Reporting_period__c = testDataSetupUtil_v2.semester.Id;
	        section.number_of_reporting_periods__c = '2';
	       	section.time__c		= testDataSetupUtil_v2.term.Id;
	        section.Daily_Attendance__c = false;
	        section.Course__c = testDataSetupUtil_v2.coursesList[0].id;
	        section.Record_Attendance__c=true; 
	        
	        upsert  section Reference_Id__c;
	        
     	  List<Section_ReportingPeriod__c> sectionRPList = new List<Section_ReportingPeriod__c>();
        Section_ReportingPeriod__c sectionRp = [SELECT RecordTypeId FROM Section_ReportingPeriod__c WHERE Section__c =: section.Id AND Time__c = : testDataSetupUtil_v2.semester.Id];
    	sectionRp.Scheduler_ReferenceId__c = Importutils.createSectionReferenceKey(testDataSetupUtil_v2.school.Id, scheduleGroups[0].id, testDataSetupUtil_v2.coursesList[0].Id, testDataSetupUtil_v2.semester.Id);
    	sectionRp.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('Published');
    	
    	update sectionRp;
    				  
    	List<Schedule_day__c> retrieveSchedDays = new List<Schedule_day__c>();
    	retrieveSchedDays = [SELECT ID,Day__c,Schedule_Template__c,Reporting_Period__c,Schedule_Template__r.Setup__r.School__c FROM Schedule_Day__c WHERE Id in: schedDays];
    	
    	Scheduler_CreateSessions pub = new Scheduler_CreateSessions(retrieveSchedDays, null);
		sched_RefreshSessionsAfterPublish.firstRun = false;
		    	    		test.startTest();
		pub.createSessionsForScheduledSects(retrieveSchedDays);
		System.assertEquals(1, pub.schedTempIds.size());
		//System.assertEquals(4,pub.sessionList.size());
    	pub.publishScheduleDays(retrieveSchedDays);
    	
    	List<Session__c> sessList = new List<Session__c>();
    	sessList = [SELECT Start_DateTime__c,End_DateTime__c,Session_Date__c FROM Session__c WHERE Id in:pub.sessionList order by Session_Date__c,Start_DateTime__c];
    	
    	 for(Session__c sess: sessList){
    	     	System.assertEquals(startTimes[0].time(),sess.Start_DateTime__c.time());
    	     	System.assertEquals(endTimes[0].time(),sess.End_DateTime__c.time());
        		
    	 } 
    	 
    	 Schedule_Day__c sd = [SELECT Id, Schedule_Template__c,Day__c FROM Schedule_Day__c WHERE Id = : schedDays[0].Id];
    		sd.Schedule_Template__c = halfDayTemplate.Id;
    		sched_RefreshSessionsAfterPublish.firstRun = true;
    	    		
    		update sd;
    	    	test.stopTest();
    	sessList.clear();	
    	sessList = [SELECT Start_DateTime__c,End_DateTime__c,Session_Date__c FROM Session__c WHERE Session_Date__c = :sd.Day__c order by Session_Date__c,Start_DateTime__c limit 1];
    	system.debug(sessList);
    	 for(Session__c sess: sessList){
    	 	
    	     	System.assertEquals(Datetime.newInstance(2011, 11, 11, 08, 00, 0).time(),sess.Start_DateTime__c.time());
    	     	System.assertEquals(Datetime.newInstance(2011, 11, 11, 09, 00, 0).time(),sess.End_DateTime__c.time());
    	 		}   

    }
    
}