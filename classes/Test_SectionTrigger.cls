@isTest
private class Test_SectionTrigger {

	static testMethod void beforeInsert_ExternalSection(){
        testDataSetupUtil_v2.setUPCoreData(3);
        testDataSetupUtil_v2.setUPStaffData(3);
        testDataSetupUtil_v2.setUPStudentData(3);
        Id rtId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Published');
        Id cId = testdataSetupUtil_v2.coursesList[0].Id;

        Test.startTest();
            Section__c newSect = testDataSetupUtil_v2.getSection(rtId, ' test', cId, null, null);
            newSect.Year_Name__c = testDataSetupUtil_v2.activeSetUp.year__r.name__c;
            newSect.Reporting_Period_Name__c = testDataSetupUtil_v2.semester.name__c;
            insert newSect;
            system.assert([select reporting_period__c, id from section__c where id=:newSect.id].reporting_period__c!=null);

            Section__c failedSect = testDataSetupUtil_v2.getSection(rtId, ' test', cId, null, null);
            try {
                insert failedSect;
            } catch (exception e){
                System.assert(e.getMessage()!=null);
            }
        Test.stopTest();
	}
    
    //When there are grades, should throw an error.
    //Assignments should not be deleted.
    static testMethod void beforeDeleteWithGrades(){
        testDataSetupUtil_v2.setUPCoreData(3);
        testDataSetupUtil_v2.setUPStaffData(3);
        testDataSetupUtil_v2.setUPStudentData(3);
        Section__c s = testDataSetupUtil_v2.sectionsList[0];
    	
    	Assignment__c a1 = new Assignment__c(Section__c = s.id, Time__c=testDataSetupUtil_v2.semester.id);
    	Assignment__c a2 = new Assignment__c(Section__c = s.id,Time__c=testDataSetupUtil_v2.semester.id);
    	Assignment__c a3 = new Assignment__c(Section__c = s.id,Time__c=testDataSetupUtil_v2.semester.id);
    	insert a1;
    	insert a2;
    	insert a3;
    	
    	Student__c student = testDataSetupUtil_v2.studentsList[0];
    	
    	Grade__c g1 = new Grade__c(Assignment__c = a2.id, Time__c=testDataSetupUtil_v2.semester.id, Student_Section__c=testDataSetupUtil_v2.studSectionsList[0].id, Student__c=student.Id);
    	insert g1;
    	
    	Test.startTest();
    	
    	List<Assignment__c> assign = [SELECT id FROM Assignment__c WHERE Section__c=:s.id];
    	System.assertEquals(3, assign.size());
    	try{
    		delete s;
    		System.assert(false);
    	}
    	catch(Exception e){
    		//should throw an error if attempting to delete a section whose assignments still have grades
    		System.assert(true);
    	}    	
    	//assignments should not be deleted
    	assign = [SELECT id FROM Assignment__c WHERE Section__c=:s.id];
    	System.assertEquals(3, assign.size());
    	
    	Test.stopTest();
    }
    
   
    //	When there are no grades, assignments should be deleted
    
    static testMethod void beforeDeleteNoGrades(){
    	testDataSetupUtil_v2.setUPCoreData(3);
        testDataSetupUtil_v2.setUPStaffData(3);
        Section__c s = testDataSetupUtil_v2.sectionsList[0];
    	
    	Assignment__c a1 = new Assignment__c(Section__c = s.id);
    	Assignment__c a2 = new Assignment__c(Section__c = s.id);
    	Assignment__c a3 = new Assignment__c(Section__c = s.id);
    	insert a1;
    	insert a2;
    	insert a3;
    	
    	Test.startTest();
    	
    	List<Assignment__c> assign = [SELECT id FROM Assignment__c WHERE Section__c=:s.id];
    	System.assertEquals(3, assign.size());
    	
    	delete s;
    	
    	//assignments should be deleted
    	assign = [SELECT id FROM Assignment__c WHERE Section__c=:s.id];
    	System.assertEquals(0, assign.size());
    	
    	Test.stopTest();
    }
     
    static testMethod void testStaffSectionTrigger(){
    	TestDataSetupUtil_v2.setupCoreData(5);
    	TestDataSetupUtil_v2.setUPStaffData(5);
        TestDataSetupUtil_v2.setUPStudentData(5);
        
//        Staff_Section__c ss = new Staff_Section__c(Staff__c=TestDataSetupUtil_v2.teachersList[0].id, Section__c=TestDataSetupUtil_v2.sectionsList[0].id);
//        insert ss;
        Staff_Section__c ss = [SELECT section__r.name, staff__r.Individual__r.reference_id__c, section__r.Time__r.Name__c, reference_id__c FROM Staff_Section__c WHERE Staff__c=:TestDataSetupUtil_v2.teachersList[0].id AND Section__c=:TestDataSetupUtil_v2.sectionsList[0].id order by CreatedDate ASC LIMIT 1];
        system.assertEquals(ss.staff__r.Individual__r.reference_id__c+'_'+ss.section__r.name+'_'+ss.section__r.Time__r.Name__c, ss.reference_id__c);
        //staff.Individual__r.reference_id__c+'_'+sect.name+'_'+sect.Time__r.Name__c;
        
        ss.Staff__c = TestDataSetupUtil_v2.teachersList[1].id;
        update ss;
        ss = [SELECT section__r.name, staff__r.Individual__r.reference_id__c, section__r.Time__r.Name__c, reference_id__c FROM Staff_Section__c WHERE Staff__c=:TestDataSetupUtil_v2.teachersList[1].id AND Section__c=:TestDataSetupUtil_v2.sectionsList[0].id order by CreatedDate ASC LIMIT 1];
        system.assertEquals(ss.staff__r.Individual__r.reference_id__c+'_'+ss.section__r.name+'_'+ss.section__r.Time__r.Name__c, ss.reference_id__c);
        
        ss.reference_id__c = 'banana';
        update ss;
        ss = [SELECT section__r.name, staff__r.Individual__r.reference_id__c, section__r.Time__r.Name__c, reference_id__c FROM Staff_Section__c WHERE Staff__c=:TestDataSetupUtil_v2.teachersList[1].id AND Section__c=:TestDataSetupUtil_v2.sectionsList[0].id order by CreatedDate ASC LIMIT 1];
        system.assertEquals(ss.staff__r.Individual__r.reference_id__c+'_'+ss.section__r.name+'_'+ss.section__r.Time__r.Name__c, ss.reference_id__c);
    }
    
    static testMethod void testMarkCompleted(){
    	TestDataSetupUtil_v2.setupCoreData(5);
    	TestDataSetupUtil_v2.setUPStaffData(5);
        TestDataSetupUtil_v2.setUPStudentData(5);
        Id sectionId = TestDataSetupUtil_v2.sectionsList[0].id;
        test.startTest();
        List <Section_ReportingPeriod__c> srpList = [select id, completed__c from Section_ReportingPeriod__c where section__c =:sectionId];
        srpList[0].completed__c = true;
        update srpList;
        system.assert([select completed__c from Section__c where id=:sectionId ].completed__c==false);
        srpList[1].completed__c = true;
        update srpList;
        system.assert([select completed__c from Section__c where id=:sectionId ].completed__c==true);
           srpList[0].completed__c = false;
        update srpList;
        system.assert([select completed__c from Section__c where id=:sectionId ].completed__c==false);
    }

    static testMethod void testCheckReportingPeriodDeletion(){
        TestDataSetupUtil_v2.setupCoreData(5);
        TestDataSetupUtil_v2.setUPStaffData(5);
        TestDataSetupUtil_v2.setUPStudentData(5);
        
        Id sectionId = TestDataSetupUtil_v2.sectionsList[0].id;
        List <Section_ReportingPeriod__c> srpList = [select id, Time__c, Section__c, Section__r.Name, Completed__c from Section_ReportingPeriod__c where section__c =:sectionId];
        srpList[0].completed__c = true;
        srpList[1].completed__c = true;
        update srpList;

        Assignment__c testAssignment = new Assignment__c();
        testAssignment.Name = 'hope';
        testAssignment.Section__c = testDataSetupUtil_v2.sectionsList[0].ID;
        testAssignment.Due_Date__c = Date.newInstance(system.today().year()+30, 8, 5);
        testAssignment.Weighting_Value__c = 5;
        testAssignment.Name_In_Gradebook__c = 'tHope';
        testAssignment.Include_in_Final_Grade__c = true;
        testAssignment.Time__c = srpList[0].Time__c; //testDataSetupUtil_v2.semester.ID;
        insert testAssignment;

        List<Scheduled_Section__c> ss = new List<Scheduled_Section__c>();
        for(integer i = 0; i<TestDataSetupUtil_v2.teachersList.size(); i++){
            Scheduled_Section__c s = new Scheduled_Section__c(
                Staff__c = TestDataSetupUtil_v2.teachersList[i].id,
                Staff__r = TestDataSetupUtil_v2.teachersList[i],
                Account__r = TestDataSetupUtil_v2.school,
                Room__c = TestDataSetupUtil_v2.roomList[i].id,
                Needs_Publish__c = true,
                Section__c = TestDataSetupUtil_v2.sectionsList[i].Id
            );
            Section_ReportingPeriod__c srp = srpList[Integer.valueOf(math.floor(math.random()*srpList.size()))];
            s.Period_Key__c = ''+i;
            s.Section_ReportingPeriod__c = srp.id;
            s.Section_ReportingPeriod__r = srp;
            ss.add(s);
        }
        insert ss;

        List<Session__c> lstSess = new List<Session__c>();
        for(Section_ReportingPeriod__c srp: srpList){
            lstSess.add(new Session__c(
                Name = srp.Section__r.Name.length()>60? srp.Section__r.Name.substring(0,60): srp.Section__r.Name,
                Section__c = srp.Section__c,
                Start_DateTime__c = Datetime.now(),
                Time__c = srp.Time__c));
        }
        insert lstSess;

        Test.startTest();
            String msgError = '';
            try{
                delete srpList;
            }catch(Exception e){
                msgError = e.getMessage();
            }
        Test.stopTest();
        System.assert(msgError.contains('Deletion of Section Reporting Period not allowed. Please delete all assignments & attendance related to the reporting period and section being purged'));
    }
}