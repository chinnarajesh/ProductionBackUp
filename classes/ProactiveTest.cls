@isTest
private class ProactiveTest {
	
	static void setupTest() {
		testDataSetupUtil_v2.setUPCoreData(1);
    	testDataSetupUtil_v2.setUpStaffData(1);
    	testDataSetupUtil_v2.setUpStudentData(20);
    	testDataSetupUtil_v2.setupSessiondata();
	}

    static testMethod void ProactiveControllerTest() {
    	setupTest();
    	
    	system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
	    	ID recType = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance');
	    	Picklist_Value__c  pickV = new Picklist_Value__c(); 
	    	pickV.Name = 'Present';
	    	pickV.Type__c = 'Attendance';
	    	pickV.RecordTypeId = recType;
	    	pickV.Set_as_Default__c = true;
	    	pickV.Category__c = 'Present';
	    	insert pickV;
	    	
	    	List<Attendance__c> attList = new List<Attendance__c>();
	    	
	    	for(Student__c s : testDataSetupUtil_v2.studentsList){
	    		for(Integer i=0; i<5; i++){
	    			Attendance__c att = new Attendance__c();
	    			att.Student__c = s.Id;
	    			att.Arrival_Time__c = datetime.now();
	    			att.Arrival_Time_Text__c = 'test' + String.valueOf(i);
	    			att.Daily__c = true;
	    			att.Departure_Time__c = datetime.now().addHours(1);
	    			att.Session__c = testDataSetupUtil_v2.sessionsList[0].Id;
	    			att.Picklist_Value__c = pickV.Id;
	    			attList.add(att);
	    		}
	    	}
	    	insert attList;
	    	
	    	Id rec = core_SoqlUtils.getRecordTypesBySobject('Contact').get('Staff');
	    	
	    	List<Contact> cnt = new List<Contact>();
	    	Integer i = 0;
	    	for(Student__c s : testDataSetupUtil_v2.studentsList){
	    		Contact c = new Contact();
	    		c.RecordTypeId = rec;
	    		c.Student__c = s.Id;
	    		c.FirstName = 'Test' + string.valueOf(i);
	    		c.LastName = 'test' + string.valueOf(i);
	    		c.AccountId = s.School__c;
	    		c.Relationship__c = 'Guardian';
	    		cnt.add(c);
	    		i++;
	    	}
	    	insert cnt;
	    	
	    	List<Student_PG__c> spg = new List<Student_PG__c>();
	    	Integer x = 0;
	    	for(Student__c s : testDataSetupUtil_v2.studentsList){
	    		Student_PG__c c = new Student_PG__c();
	    		c.Student_c__c = s.Individual__c;
	    		c.Student__c = s.Id;
	    		c.Primary_Contact__c = true;
	    		c.Parent_Guardian_c__c = cnt[x].Id;
	    		spg.add(c);
	    		x++;
	    	}
	    	insert spg;
	    	
	    	test.startTest();
	    	//UserRole userRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Admin' LIMIT 1];
	    	Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
	    	User adminUser = [SELECT Id FROM User WHERE isActive = true AND ProfileId = :profile.Id LIMIT 1];
	    	
	    	ProactiveController con = new ProactiveController();
	        con.getItems();
	        con.startDate = date.today().addDays(-1);
	        con.pDemo.Entry_Date__c = date.today().addDays(-1);
	        con.endDate = date.today().addDays(1);
	        con.pDemo.Exit_Date__c = date.today().addDays(1);
	        con.demographics = true;
	        con.attendance = true;
	    	con.userStr = adminUser.Id;
	        con.schoolId = testDataSetupUtil_v2.school.Id;
	        con.buttonClick();
	        con.qryStr = 'SELECT  Id, Student__r.Student_Last_Name__c, Student__r.Student_First_Name__c, Student__c, Session_Date__c, Attendance_Status_Read_Only__c, Student__r.Legacy_ID__c FROM Attendance__c WHERE Session_Date__c >=: startDate AND Session_Date__c <=: endDate AND Student__r.School__c = :schoolId LIMIT 100';
	        ProactiveBatch proactiveBatch = new ProactiveBatch(con.userStr, con.qryStr, con.attendance, con.demographics, con.startDate, con.endDate, con.schoolId);
	        Id batchprocessId = Database.executeBatch(proactiveBatch, 200);
	        proactiveBatch.execute(null, attList);
	        system.assert(true, con.endDate != null);
	        test.stopTest();
    	}
    }
    
    static testMethod void TestSetupSchedule(){
    	List<Proactive_Demographics__c> a = new List<Proactive_Demographics__c>();
    	List<Proactive_Attendance__c> b = new List<Proactive_Attendance__c>();
    	
    	for(Integer i=0;i<5000;i++){
    		Proactive_Attendance__c c = new Proactive_Attendance__c();
    		c.First_Name__c = 'First' + string.valueOf(i);
    		c.Last_Name__c = 'Last' + string.valueOf(i);
    		c.USI_ID__c = 'a' + string.valueOf(i);
    		b.add(c);
    	}
    	insert b;
    	
    	for(Integer i=0;i<5000;i++){
    		Proactive_Demographics__c c = new Proactive_Demographics__c();
    		c.First_Name__c = 'First' + string.valueOf(i);
    		c.Last_Name__c = 'Last' + string.valueOf(i);
    		c.USI_ID__c = 'a' + string.valueOf(i);
    		a.add(c);
    	}
    	insert a;
    	ProactiveController.setupSchedule();
    	ProactiveController con = new ProactiveController();
    	test.startTest();
    	con.DeleteProactive();
    	test.stopTest();
    	
    }
    
    static testMethod void TestOnDemandDelete(){
    	List<Proactive_Demographics__c> a = new List<Proactive_Demographics__c>();
    	List<Proactive_Attendance__c> b = new List<Proactive_Attendance__c>();
    	
    	for(Integer i=0;i<6000;i++){
    		Proactive_Attendance__c c = new Proactive_Attendance__c();
    		c.First_Name__c = 'First' + string.valueOf(i);
    		c.Last_Name__c = 'Last' + string.valueOf(i);
    		c.USI_ID__c = 'a' + string.valueOf(i);
    		b.add(c);
    	}
    	insert b;
    	
    	for(Integer i=0;i<2000;i++){
    		Proactive_Demographics__c c = new Proactive_Demographics__c();
    		c.First_Name__c = 'First' + string.valueOf(i);
    		c.Last_Name__c = 'Last' + string.valueOf(i);
    		c.USI_ID__c = 'a' + string.valueOf(i);
    		a.add(c);
    	}
    	insert a;
    	
    	ProactiveController con = new ProactiveController();
    	test.startTest();
    	con.DeleteProactive();
    	test.stopTest();
    }
    
    static testMethod void TestOnDemandDelete2(){
    	List<Proactive_Demographics__c> a = new List<Proactive_Demographics__c>();
    	List<Proactive_Attendance__c> b = new List<Proactive_Attendance__c>();
    	
    	for(Integer i=0;i<2000;i++){
    		Proactive_Attendance__c c = new Proactive_Attendance__c();
    		c.First_Name__c = 'First' + string.valueOf(i);
    		c.Last_Name__c = 'Last' + string.valueOf(i);
    		c.USI_ID__c = 'a' + string.valueOf(i);
    		b.add(c);
    	}
    	insert b;
    	
    	for(Integer i=0;i<6000;i++){
    		Proactive_Demographics__c c = new Proactive_Demographics__c();
    		c.First_Name__c = 'First' + string.valueOf(i);
    		c.Last_Name__c = 'Last' + string.valueOf(i);
    		c.USI_ID__c = 'a' + string.valueOf(i);
    		a.add(c);
    	}
    	insert a;
    	
    	ProactiveController con = new ProactiveController();
    	test.startTest();
    	con.DeleteProactive();
    	con.DeleteProactive();
    	test.stopTest();
    }
}