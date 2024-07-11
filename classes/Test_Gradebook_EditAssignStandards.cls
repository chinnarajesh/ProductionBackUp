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
public class Test_Gradebook_EditAssignStandards {

	public static Assignment__c createdAssignment;
	
	public static void createAssignment(){
		
		createdAssignment = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
		createdAssignment.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;
		createdAssignment.Picklist_value__c = [select id from Picklist_value__c  where RecordType.DeveloperName = 'Grade_Scale' AND Name = 'Points'  limit 1 ].id;
		createdAssignment.Possible_Points__c = 40;	
		createdAssignment.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		createdAssignment.Name_in_Gradebook__c = 'Test1';
		insert createdAssignment;
		
		Grade__c g = new Grade__c(
			Possible_points__c = createdAssignment.Possible_Points__c, 
			Student__c =testDataSetupUtil_v2.studentsList[0].id, 
			Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , 
			Time__c = testDataSetupUtil_v2.semester.id, 
			Assignment__c = createdAssignment.id,
			Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id, 
			Assignment_Weighting__c = createdAssignment.Weighting_Value__c, 
			Include_In_Standard_Grade__c = false);
		insert g;
		
	    Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = createdAssignment.Standard_Scale__c);
    	update co; 
		
	}

    static testMethod void myUnitTest() {
        TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();  
		testDataSetupUtil_v2.setupStandards();

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){

			createAssignment();
			test.startTest();
			Gradebook_EditAssignStandardsController EAS = new Gradebook_EditAssignStandardsController(createdAssignment.ID);
			
			Standard__c testStandard2 = new Standard__c();
			Standard__c testStrand2 = new Standard__c();
			testStandard2.name = 'Test Standard 2';
			testStandard2.Level__c = 2;
			testStandard2.Course__c = EAS.course;
			testStandard2.Subject__c = 'test';
			testStandard2.Identifier__c = 'testing';
			system.debug('Anson: test standard 2 course: ' + EAS.course);
			testStrand2.name = 'Test Strand 2';
			testStrand2.Level__c = 1;
			testStrand2.Course__c = EAS.course;
			testStrand2.Subject__c = 'test';
			insert testStrand2;
			testStandard2.Strand__c = testStrand2.ID;
			insert testStandard2;
			EAS.standardIdentifierSearch = 'testing*';
			EAS.standardStrandSearch = 'Test Strand 2*';
			EAS.standardParentStandardSearch = '';
			EAS.standardSubjectSearch = 'test';
			EAS.searchStandardMethods();
			
			system.debug('Anson: is there a standard grade scale?: ' + EAS.assignment.Standard_Scale__c);
			system.debug('Anson: what is in teh generalList: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList:' + EAS.searchList);
			
			EAS.standardOnly = true;			
						
			EAS.searchList[0].selected = true;
			EAS.addStandards();
			
			system.debug('Anson: what is in the standardList NOW: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList Now: ' + EAS.searchList);
			
			ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(EAS.assignment);
			Assignment_StandardsListController a_sLC = new Assignment_StandardsListController(sc);			
			
			EAS.standardList[0].selected = true;
			
			EAS.cancel();
			EAS.returnToAssignment();
		}		
		test.stopTest();      
    }
    
   static testMethod void myUnitTest2() {
		testDataSetupUtil_v2.setUPCoreData(2);	
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();  
		testDataSetupUtil_v2.setupStandards();
		
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			createAssignment();
			test.startTest();
			Gradebook_EditAssignStandardsController EAS = new Gradebook_EditAssignStandardsController(createdAssignment.ID);
			
			Standard__c testStandard2 = new Standard__c();
			Standard__c testStrand2 = new Standard__c();
			testStandard2.name = 'Test Standard 2';
			testStandard2.Level__c = 2;
			testStandard2.Course__c = EAS.course;
			testStandard2.Subject__c = 'test';
			testStandard2.Identifier__c = 'testing';
			system.debug('Anson: test standard 2 course: ' + EAS.course);
			testStrand2.name = 'Test Strand 2';
			testStrand2.Level__c = 1;
			testStrand2.Course__c = EAS.course;
			testStrand2.Subject__c = 'test';
			insert testStrand2;
			testStandard2.Strand__c = testStrand2.ID;
			insert testStandard2;
			
			system.debug('testStandard2: ' + testStandard2);
			
			Standard__c ts = [select id, Subject__c from Standard__c where id = :testStandard2.id AND Subject__c = 'test' limit 1];
			
			system.debug('Anson: what is ts: ' + ts);
			
			EAS.standardIdentifierSearch = 'testing*';
			EAS.standardStrandSearch = 'Test Strand 2*';
			EAS.standardParentStandardSearch = '';
			EAS.standardSubjectSearch = 'test';
			EAS.searchStandardMethods();
			
			system.debug('Anson: is there a standard grade scale?: ' + EAS.assignment.Standard_Scale__c);
			system.debug('Anson: what is in teh generalList: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList:' + EAS.searchList);			
						
			EAS.searchList[0].selected = true;
			EAS.addStandards();
			
			system.debug('Anson: what is in the standardList NOW: ' + EAS.standardList);
			system.debug('Anson: what is in the searchList Now: ' + EAS.searchList);
			EAS.editSaveStandards();
			EAS.standardList[0].selected = true;
			EAS.removeStandards();
			
			EAS.cancel();
			EAS.returnToAssignment();
			
		}		
		test.stopTest();      
    }
	/////
	static testMethod void mynewtest(){
		TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();  
		testDataSetupUtil_v2.setupStandards();

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){

	    createdAssignment = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
		createdAssignment.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;
		createdAssignment.Picklist_value__c = [select id from Picklist_value__c  where RecordType.DeveloperName = 'Grade_Scale' AND Name = 'Points'  limit 1 ].id;
		createdAssignment.Possible_Points__c = 40;	
		createdAssignment.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		createdAssignment.Name_in_Gradebook__c = 'Test1';
		insert createdAssignment;

		Gradebook_EditAssignStandardsController EAS = new Gradebook_EditAssignStandardsController(createdAssignment.ID);
		Map<Id,Student_Section__c> newMap = new Map<Id,Student_Section__c>();

			

			Standard__c testStandard2 = new Standard__c();
			testStandard2.name = 'Test Standard 2';
			testStandard2.Level__c = 2;
			testStandard2.Course__c = EAS.course;
			testStandard2.Subject__c = 'test';
			testStandard2.Identifier__c = 'testing';
			system.debug('Anson: test standard 2 course: ' + EAS.course);
			//testStandard2.Strand__c = testStrand2.ID;
			insert testStandard2;

			Standard__c testStrand2 = new Standard__c();
			testStrand2.name = 'Test Strand 2';
			testStrand2.Level__c = 1;
			testStrand2.Course__c = EAS.course;
			testStrand2.Subject__c = 'test';
			testStandard2.Strand__c = testStandard2.ID;
			insert testStrand2;
			
		Grade__c g = new Grade__c(
			Possible_points__c = createdAssignment.Possible_Points__c, 
			Student__c =testDataSetupUtil_v2.studentsList[0].id, 
			Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , 
			Time__c = testDataSetupUtil_v2.semester.id, 
			Assignment__c = createdAssignment.id,
			Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id, 
			Assignment_Weighting__c = createdAssignment.Weighting_Value__c,
			Entered_Grade__c='A',
			Include_In_Standard_Grade__c = false);
		insert g;
		
	    Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = createdAssignment.Standard_Scale__c);
    	update co; 

		List<Grade__c> gradeList = new List<Grade__c>();
		gradeList.add(g);
		Test.startTest();
		CT_Gradebook_ManageGradebook.checkAssignmentGradeScales(gradeList);
		CT_Gradebook_ManageGradebook.isBeforeInsert(gradeList);
		Map<ID, Grade__c> nMap = new Map<ID,Grade__c>();
		nMap.put(g.id,g);
		//CT_Gradebook_GradeUtils.bCourseGradeScalesEmpt=true;
		CT_Gradebook_ManageGradebook.isAfterUpdate(nMap, nMap);
        g.Student_Section__c=null;
		update g;
		gradeList = new List<Grade__c>();
		gradeList.add(g);
		CT_Gradebook_ManageGradebook.isAfterInsert(gradeList);

		Grade__c g2 = new Grade__c(
			Possible_points__c = createdAssignment.Possible_Points__c, 
			Student__c =testDataSetupUtil_v2.studentsList[0].id, 
			Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , 
			Time__c = testDataSetupUtil_v2.semester.id, 
			Assignment__c = createdAssignment.id,
			Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id, 
			Assignment_Weighting__c = createdAssignment.Weighting_Value__c,
			Entered_Grade__c='B',
			Include_In_Standard_Grade__c = false);
		insert g2;

		Course__c co2 = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = createdAssignment.Standard_Scale__c);
    	update co2; 

		Map<ID, Grade__c> nnMap = new Map<ID,Grade__c>();
		nnMap.put(g2.id,g2);
		CT_Gradebook_ManageGradebook.isBeforeUpdate(nMap, nnMap);

		//Student_Section__c st =[select id,name from Student_Section__c where Id =:testDataSetupUtil_v2.studSectionsList[0].id];

		Account acc = new Account();
        acc.Name='Juturi rajesh';
        acc.Active__c='true';
        acc.Site__c='Jacksonville';
        acc.Reference_Id__c='Courtney Test School';
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        insert acc;
        
        Picklist_Value__c pickvalue = new Picklist_Value__c();
        pickvalue.Name='Final';
        pickvalue.Type__c='Time';
        pickvalue.Category__c='Reporting Period';
        pickvalue.RecordTypeId=Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Time').getRecordTypeId();
        insert pickvalue;
        
        Time_Element__c timeone = new Time_Element__c();
        timeone.Name__c='2022-2023';
        timeone.Reporting_Period__c=true;
        timeone.School__c=acc.id;
        timeone.Date_Start_Date__c=system.today();
        timeone.End_Date__c=system.today();
        timeone.Picklist_Value__c=pickvalue.id;
        insert timeone;
            
        Section__c sec = new Section__c();
        sec.Name='test school section ELA/Literacy';
        sec.School__c=acc.id;
        sec.Available_Grade_Levels__c='5';
        sec.Reference_Id__c='test school section ELA/Literacy'+acc.Name;
        sec.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Published').getRecordTypeId();
        sec.Period__c='ELA/Literacy';
        sec.Active__c=true;
        sec.Reporting_Period__c=timeone.id;
        sec.Time__c=timeone.id;
		sec.Is_Section__c=true;
        insert sec;

		Contact con = new Contact();
        con.FirstName='peter';
        con.LastName='parkar';
        con.RecordTypeId=Schema.SObjectType.contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        con.Date_of_Birth__c=system.today();
        con.Active__c=true;
        insert con;
        
        Setup__c setup = new Setup__c();
        setup.School__c=acc.id;
        setup.Active__c=true;
        setup.Published__c=true;
        setup.Year__c=timeone.id;
        insert setup;
		core_triggerUtils.studentTrigger=false;
        Student__c student = new Student__c();
        student.Student_First_Name__c='peter';
        student.Student_Last_Name__c='pet';
        student.School__c=acc.id;
        student.Grade__c='5';
        student.Date_of_Birth__c=system.today();
        student.Individual__c=con.id;
        student.Active__c=true;
        student.School_Year__c=timeone.id;
        student.Actual_graduation_date__c=System.today();
        student.Setup__c=setup.id;
        student.Entry_Date__c=system.today();
        student.Local_Student_ID__c='082402M901';
        student.Student_Id__c='7345637465';
        student.Title_1_Status__c='Free';
        student.State__c='TN';
        student.Ward__c='1';
        student.Residence_After_Exiting_School__c='	Armed services';
        insert student;
	
		Student_Section__c studentSection = new Student_Section__c();
		studentSection.Student__c=student.Id;
		studentSection.Section__c=sec.Id;
		studentSection.Original_School__c=sec.School__c;
		studentSection.Reference_ID__c=sec.Reference_Id__c;
		studentSection.Active__c=True;
		insert studentSection;

		Grade__c g3 = new Grade__c(
			Possible_points__c = createdAssignment.Possible_Points__c, 
			Student__c =student.id, 
			Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , 
			Time__c = testDataSetupUtil_v2.semester.id, 
			Assignment__c = createdAssignment.id,
			Student_Section__c =studentSection.id, 
			Assignment_Weighting__c = createdAssignment.Weighting_Value__c,
			Entered_Grade__c='B',
			Standard__c=testStrand2.id,
			standard_gradebook_Grade__c=null,
			Include_In_Standard_Grade__c = false);
		insert g3;

		// newMap.put(studentSection.id,studentSection);
		// CT_Gradebook_ManageGradeBook.isafterinsert_onss(newMap, null);  

		Map<id,Grade__c> oMap = new Map<id,Grade__c>();
		oMap.put(g3.id,g3);
		CT_Gradebook_ManageGradebook.isBeforeDelete(oMap, nnMap);
		Set<ID> grades = new Set<ID>();
		Set<ID>	students = new Set<ID>();
		Set<ID> standards = new Set<ID>();
		Set<ID> strands = new Set<ID>();
		Set<ID> reportingPeriods = new Set<ID>();
		Set<ID> sections = new Set<ID>();
		Set<String> strandGradeKeys = new Set<String>();
		Set<Id> gIDs = new Set<Id>();
		Set<id> standard = new Set<Id>();
		Set<Id> sectionId = new Set<Id>();
		sectionId.add(sec.Id);
		standard.add(testStrand2.id);
		gIDs.add(g2.id); 
		students.add(student.id);
		strands.add(g3.Standard_Strand__c);
		reportingPeriods.add(g3.Time__c);
		grades.add(g.ID);
		strandGradeKeys.add(string.valueOf(g3.Student__c) + string.valueOf(g3.Standard_Strand__c) + string.valueOf(g3.Time__c));
		CT_Gradebook_ManageGradebook.deleteStrandGrades(students, strands, reportingPeriods, grades, strandGradeKeys);
		Strand_Grade__c sg = new Strand_Grade__c();
		sg.Reporting_Period__c=g3.Time__c;
		sg.Student__c =g3.Student__c;
		sg.Strand__c=g3.Standard_Strand__c;
		sg.Grade_Overridden__c=false;
		sg.Key__c=string.valueOf(g3.Student__c) + string.valueOf(g3.Standard_Strand__c) + string.valueOf('');
		insert sg;
		strandGradeKeys.add(string.valueOf(g3.Student__c) + string.valueOf(g3.Standard_Strand__c) + string.valueOf(''));
		Set<ID> reportingPeriods2 = new Set<ID>();
		CT_Gradebook_ManageGradebook.deleteStrandGrades(students, strands, reportingPeriods2, grades, strandGradeKeys);
		Set<ID> ssIDs = new Set<ID> ();
		ssIDs.add(studentSection.id);
		CT_Gradebook_ManageGradebook.deleteStandardGrades(students, standard, reportingPeriods, gIDs, strandGradeKeys);
		Set<Id> empty = new Set<id>();
		//CT_Gradebook_ManageGradebook.deleteSectionStandards(sectionId, standard, newgid);
		Section_Standard__c ss = new Section_Standard__c();
		ss.Standard__c =testStrand2.id;
		ss.Section__c=sec.Id;
		insert ss;
		Set<id> newgid = new Set<id>();
		CT_Gradebook_ManageGradebook.deleteSectionStandards(sectionId, standard, newgid);

		Set<string> allKeys = new Set<string>();
		allKeys.add(string.valueOf(g3.Student_Section__c) + '-' + string.valueOf(g3.Time__c));

		//CT_Gradebook_ManageGradebook.deleteSectionGrades(ssIDs, reportingPeriods2, gIDs, allKeys);
		Section_Grade__c cgt = new Section_Grade__c();
		cgt.Reference_ID__c=string.valueOf(g3.Student_Section__c) + '-' + string.valueOf(g3.Time__c);
		cgt.Grade_Overridden__c=false;
		cgt.Student_Section__c=g3.Student_Section__c;
		insert cgt;
		Map<id,Student_Section__c> stList = new Map<id,Student_Section__c>();
		stList.put(studentSection.id,studentSection);
		CT_Gradebook_ManageGradebook.createSectionGradesForStudents(stList);

		}
        Test.stopTest();
	}
	static testMethod void mynewtestSecond(){

        TestDataSetupUtil_v2.isGradebook = true;
        testDataSetupUtil_v2.setUPCoreData(2);
        testDataSetupUtil_v2.setUPStaffData(2);
        testDataSetupUtil_v2.setUPStudentData(2);
        testDataSetupUtil_v2.createScalesNormalizations();
        testDataSetupUtil_v2.setupStandards();
        string standardId;
		String sectionId;
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]){

        createdAssignment = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );
        createdAssignment.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;
        createdAssignment.Picklist_value__c = [select id from Picklist_value__c  where RecordType.DeveloperName = 'Grade_Scale' AND Name = 'Points'  limit 1 ].id;
        createdAssignment.Possible_Points__c = 40;
        createdAssignment.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
        createdAssignment.Name_in_Gradebook__c = 'Test1';
        insert createdAssignment;

        Gradebook_EditAssignStandardsController EAS = new Gradebook_EditAssignStandardsController(createdAssignment.ID);
        List<Standard__c> standardsToInsert = new List<Standard__c>();
        Standard__c testStandard2 = new Standard__c();
            testStandard2.name = 'Test Standard 2';
            testStandard2.Level__c = 2;
            testStandard2.Course__c = EAS.course;
            testStandard2.Subject__c = 'test';
            testStandard2.Identifier__c = 'testing';
            system.debug('Anson: test standard 2 course: ' + EAS.course);
            //testStandard2.Strand__c = testStrand2.ID;
            standardsToInsert.add(testStandard2);

            Standard__c testStrand2 = new Standard__c();
            testStrand2.name = 'Test Strand 2';
            testStrand2.Level__c = 1;
            testStrand2.Course__c = EAS.course;
            testStrand2.Subject__c = 'test';
            testStrand2.Strand__c = testStandard2.ID;
        standardsToInsert.add(testStrand2);
        insert standardsToInsert;

		for(Standard__c st :standardsToInsert){
			standardId=st.id;
		}

        Grade__c g = new Grade__c(
            Possible_points__c = createdAssignment.Possible_Points__c,
            Student__c =testDataSetupUtil_v2.studentsList[0].id,
            Course__c =testDataSetupUtil_v2.sectionsList[0].course__c ,
            Time__c = testDataSetupUtil_v2.semester.id,
            Assignment__c = createdAssignment.id,
            Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id,
            Assignment_Weighting__c = createdAssignment.Weighting_Value__c,
            Entered_Grade__c='A',
            Include_In_Standard_Grade__c = false);
        insert g;

        Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = createdAssignment.Standard_Scale__c);
        update co;
        }

        Account acc = new Account();
        acc.Name='Juturi rajesh';
        acc.Active__c='true';
        acc.Site__c='Jacksonville';
        acc.Reference_Id__c='Courtney Test School';
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        insert acc;

        Picklist_Value__c pickvalue = new Picklist_Value__c();
        pickvalue.Name='Final';
        pickvalue.Type__c='Time';
        pickvalue.Category__c='Reporting Period';
        pickvalue.RecordTypeId=Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Time').getRecordTypeId();
        insert pickvalue;

        Time_Element__c timeone = new Time_Element__c();
        timeone.Name__c='2022-2023';
        timeone.Reporting_Period__c=true;
        timeone.School__c=acc.id;
        timeone.Date_Start_Date__c=system.today();
        timeone.End_Date__c=system.today();
        timeone.Picklist_Value__c=pickvalue.id;
        insert timeone;

        List<Section__c> sectionsToInsert = new List<Section__c>();
        Section__c sec = new Section__c();
        sec.Name='test school section ELA/Literacy';
        sec.School__c=acc.id;
        sec.Available_Grade_Levels__c='5';
        sec.Reference_Id__c='test school section ELA/Literacy'+acc.Name;
        sec.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Published').getRecordTypeId();
        sec.Period__c='ELA/Literacy';
        sec.Active__c=true;
        sec.Reporting_Period__c=timeone.id;
        sec.Time__c=timeone.id;
        sec.Is_Section__c=true;
        sectionsToInsert.add(sec);

        Section__c sec2 = new Section__c();
        sec2.Name='test school section ELA/Literacy2';
        sec2.School__c=acc.id;
        sec2.Available_Grade_Levels__c='6';
        sec2.Reference_Id__c='test school section ELA/Literacy2'+acc.Name;
        sec2.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Published').getRecordTypeId();
        sec2.Period__c='ELA/Literacy';
        sec2.Active__c=true;
        sec2.Reporting_Period__c=timeone.id;
        sec2.Time__c=timeone.id;
        sec2.Is_Section__c=true;
        sectionsToInsert.add(sec2);
        insert sectionsToInsert;

		for(Section__c sct :sectionsToInsert){
			if(sct.Available_Grade_Levels__c=='5'){
				sectionId=sct.id;
			}
           System.debug('SecionId+++'+sectionId);
		}

        Contact con = new Contact();
        con.FirstName='peter';
        con.LastName='parkar';
        con.RecordTypeId=Schema.SObjectType.contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        con.Date_of_Birth__c=system.today();
        con.Active__c=true;
        insert con;

        Setup__c setup = new Setup__c();
        setup.School__c=acc.id;
        setup.Active__c=true;
        setup.Published__c=true;
        setup.Year__c=timeone.id;
        insert setup;
        
        core_triggerUtils.studentTrigger=False;
        Student__c student = new Student__c();
        student.Student_First_Name__c='peter';
        student.Student_Last_Name__c='pet';
        student.School__c=acc.id;
        student.Grade__c='5';
        student.Date_of_Birth__c=system.today();
        student.Individual__c=con.id;
        student.Active__c=true;
        student.School_Year__c=timeone.id;
        student.Actual_graduation_date__c=System.today();
        student.Setup__c=setup.id;
        student.Entry_Date__c=system.today();
        student.Local_Student_ID__c='082402M901';
        //student.Reference_Id__c='CY-642952_Courtney Test School_2022-2023';
        student.Student_Id__c='7345637465';
        student.Title_1_Status__c='Free';
        student.State__c='TN';
        student.Ward__c='1';
        student.Residence_After_Exiting_School__c='	Armed services';
        //student.Primary_Schedule_Group__c=sec.id;
        insert student;

        test.startTest();
		//core_BaseInfo_v2.cSchool_BaseInfo wrapp = new core_BaseInfo_v2.cSchool_BaseInfo();

        core_triggerUtils.studentTrigger=true;
        Student_Section__c studentSection = new Student_Section__c();
        studentSection.Student__c=student.Id;
        studentSection.Section__c=sectionId;
        studentSection.Original_School__c=sec.School__c;
        studentSection.Reference_ID__c=sec.Reference_Id__c;
        studentSection.Active__c=True;
        insert studentSection;

        Grade__c g3 = new Grade__c(
            Possible_points__c = createdAssignment.Possible_Points__c,
            Student__c =student.id,
            Course__c =testDataSetupUtil_v2.sectionsList[0].course__c ,
            Time__c = testDataSetupUtil_v2.semester.id,
            Assignment__c = createdAssignment.id,
            Student_Section__c =studentSection.id,
            Assignment_Weighting__c = createdAssignment.Weighting_Value__c,
            Entered_Grade__c='B',
            //Standard__c=testStrand2.id,
            standard_gradebook_Grade__c=null,
            Include_In_Standard_Grade__c = false);
        insert g3;

		Standard_Grade__c sg = new Standard_Grade__c();
		sg.Student__c =student.id;
		sg.Standard__c=standardId;
		sg.key__c = student.id+''+standardId;
		sg.Reporting_Period__c=g3.Time__c;
		insert sg;

		Strand_Grade__c sg1 = new Strand_Grade__c();
		sg1.Student__c=student.id;
		sg1.Strand__c=standardId;
		sg1.Reporting_Period__c=g3.Time__c;
		insert sg1;

        core_triggerUtils.studentTrigger=false;
        student.Grade__c='6';
        update student;

        core_triggerUtils.studentTrigger=true;
        Student_Section__c studentSection2 = new Student_Section__c();
        studentSection2.Student__c=student.Id;
        studentSection2.Section__c=sec2.Id;
        studentSection2.Original_School__c=sec2.School__c;
        studentSection2.Reference_ID__c=sec2.Reference_Id__c;
        studentSection2.Active__c=True;
        insert studentSection2;

		studentSection2.Student__c=student.Id;
		update studentSection2;

		core_triggerUtils.studentTrigger=false;
        student.Grade__c='5';
        update student;

		core_triggerUtils.studentTrigger=true;
		studentSection.Student__c=student.Id;
		update studentSection;

        test.stopTest();
    }
}