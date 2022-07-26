@isTest
private class Test_OverrideGradeTriggers {

    public static void createTestData(){
    	TestDataSetupUtil_v2.isGradebook=true;
        TestDataSetupUtil_v2.setUPCoreData(2);
        testDataSetupUtil_v2.setUPStaffData(2);       
        TestDataSetupUtil_v2.setUpStudentData(2);  
     	Picklist_Value__c stdPlV =   [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ];
        	Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = stdPlV.id);
    		update co; 
    }

    static testMethod void testFinalGrade_BU() {
        test.startTest();
        createTestData();
        Student__c student = TestDataSetupUtil_v2.studentsList[0];
        Course__c course = TestDataSetupUtil_v2.coursesList[0];
        Final_Grade__c finalgrade = new Final_Grade__c(Student__c=student.Id, Final_Grade_Value__c = 80, Course__c=course.Id, Grade_Overridden__c = false,  Final_Grade_Letter_v2__c = 'A', Unweighted_GPA__c =4.0, Weighted_GPA__c=4.0);
        insert finalgrade;
        finalgrade.Grade_Override__c = '4';
        update finalgrade;
        Student__c s=[select id, Grades_Overridden__c from Student__c where ID = :student.Id];
        system.assert(s.Grades_Overridden__c==true);
        test.stopTest();
    }
    
    static testMethod void testSectionGrade_BU() {
        
        createTestData();
        test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
	        Student_Section__c studentsection = TestDataSetupUtil_v2.studSectionsList[0];
	        Section_Grade__c sectiongrade = new Section_Grade__c(Student_Section__c=studentsection.Id, Grade__c = 80, Grade_Overridden__c = false);
	        insert sectiongrade;
	        sectiongrade.Grade_Override__c = 'B';
	        system.debug('sectionGrade ID: ' + sectiongrade.Id);
	        update sectiongrade;
	        system.debug('sectionGrade overridden: ' + sectiongrade.Grade_Overridden__c);
	        //US1284 quarters
	        List<Section_Grade__c> sg = [select id, Grade_Overridden__c from Section_Grade__c where Id =: sectiongrade.Id AND (RecordTypeID = null OR RecordType.Name = 'Quarter')];
	        
	        //it's broken 4/27/2012, it doesn't make sense that it cannot find the data in the above query
	        //used this for now (@isTest(seeAllData=true)
	        system.assert(sg[0].Grade_Overridden__c==true);   
        }     
        test.stopTest();
    }
    
    static testMethod void testStandardGrade_BU() {
        test.startTest();
        createTestData();
        Student__c student = TestDataSetupUtil_v2.studentsList[0];
        Standard__c standard = new Standard__c();
        insert standard;
        Standard_Grade__c standardgrade = new Standard_Grade__c(Student__c=student.Id, Standard__c=standard.Id, Grade_Override__c = 80, Grade_Overridden__c = false);
        insert standardgrade;
        standardgrade.Grade_Override__c = 85;
        update standardgrade;
        Standard_Grade__c sg=[select id, Grade_Overridden__c from Standard_Grade__c where Id = :standardgrade.Id];
        system.assert(sg.Grade_Overridden__c==true);
        test.stopTest();
    }
    
    static testMethod void testStrandGrade_BU() {
        test.startTest();
        createTestData();
        Student__c student = TestDataSetupUtil_v2.studentsList[0];
        Standard__c strand = new Standard__c();
        insert strand;
        Strand_Grade__c strandgrade = new Strand_Grade__c(Student__c=student.Id, Strand__c=strand.Id, Grade__c = 3.5, Grade_Overridden__c = false);
        insert strandgrade;
        strandgrade.Grade_Override__c = 3.2;
        update strandgrade;
        Strand_Grade__c sg=[select id, Grade_Overridden__c from Strand_Grade__c where Id = :strandgrade.Id];
        system.assert(sg.Grade_Overridden__c==true);
        test.stopTest();
    }
}