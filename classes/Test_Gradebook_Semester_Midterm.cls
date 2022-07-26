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
private class Test_Gradebook_Semester_Midterm {
	public static List <Grade__c> masterGradeList;
	
	static void setupData(){
		TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		//testDataSetupUtil_v2.createScalesNormalizations();
		testDataSetupUtil_v2.setupStandards();     
	}
	
	static void create4Config(){
		Picklist_Value__c qType 			= [select id from Picklist_Value__c where RecordType.DeveloperName='Time' and Name='Quarter'];
			List <Course_Weightings__c> newCwList = new List <Course_Weightings__c>();
			for (Integer i=1; i<5; i++){
				Course_Weightings__c cw = new Course_Weightings__c( course__c =testDataSetupUtil_v2.sectionsList[0].course__c, Reporting_Period_Type__c=qType.id, Key__c=string.valueOf(i), Weighting__c =25);
				newCwList.add(cw);
			}
			insert newCwList;
		testDataSetupUtil_v2.sectionsList[0].number_of_reporting_periods__c = '4';
		update testDataSetupUtil_v2.sectionsList[0];
		
	}
	
	static void createAssignment(List <Time_Element__c> rps ){
		List <Assignment__c> assList = new List <Assignment__c>();
		id pointsScale =  [select id from Picklist_value__c  where RecordType.DeveloperName = 'Grade_Scale' AND Name = 'Points'  limit 1 ].id;
		id standardScale = [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;
		for (Time_Element__c rp: rps){
		Assignment__c a = new Assignment__c(Time__c = rp.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
		a.Standard_Scale__c = standardScale;
		a.Picklist_value__c =pointsScale;
		a.Possible_Points__c = 40;	
		a.Due_Date__c = rp.Date_Start_Date__c;
		a.Name_in_Gradebook__c = 'Test1';
		a.Weighting_Value__c=1;
		a.Time__c=rp.id;
		assList.add(a);
		}
		insert assList;
		
		List <Grade__c> gList = new List <Grade__c>();
		for (Assignment__c a: assList){
		Grade__c g = new Grade__c(
			Possible_points__c = a.Possible_Points__c, 
			Student__c =testDataSetupUtil_v2.studentsList[0].id, 
			Course__c =testDataSetupUtil_v2.sectionsList[0].course__c , 
			Valid_Grade__c = true,
			Time__c = a.Time__c, 
			Assignment__c = a.id,  
			Student_Section__c =testDataSetupUtil_v2.studSectionsList[0].id, 
			Assignment_Weighting__c = a.Weighting_Value__c, 
			Standard_Times_Assignment__c = a.Weighting_Value__c,
			Include_In_Standard_Grade__c = false);
		gList.add(g);
		}
		insert gList;
		masterGradeList = gList;
	}



    static testMethod void testMidTerm() {
        testDataSetupUtil_v2.is4Rp=true;
        setupData();
		create4Config();
		Course__c course = new Course__c(id=testDataSetupUtil_v2.sectionsList[0].course__c);
		course.grade_scale_Lookup__c = [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Letter Grade'  limit 1 ].id;
		update course;
		test.startTest();
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			createAssignment(new List <Time_Element__c>{testDataSetupUtil_v2.semester,testDataSetupUtil_v2.semester2});
			masterGradeList[0].entered_grade__c='30';
			update masterGradeList[0];
			masterGradeList[1].entered_grade__c='40';
			update masterGradeList[1];
		} 
		Gradebook_Semester_Midterm_Controller calculate = new Gradebook_Semester_Midterm_Controller();
		//summer 2014 iteration 2: requires list of students
		calculate.calcSemesterMidtermGrades(testDataSetupUtil_v2.studentsList);
		test.stopTest();
		Section_Grade__c midTerm = [select grade__c, letter_grade__c from Section_Grade__c where Student_Section__c =:testDataSetupUtil_v2.studSectionsList[0].id and Reference_Id__c like  'S1%'];
		system.assertEquals(87.5, midTerm.grade__c);
		system.assertEquals(midTerm.letter_grade__c, 'B');
    } 
 

     static testMethod void test2MidTerms() {
        testDataSetupUtil_v2.is4Rp=true;
        setupData();
		create4Config();
		Course__c course = new Course__c(id=testDataSetupUtil_v2.sectionsList[0].course__c);
		course.grade_scale_Lookup__c = [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Letter Grade'  limit 1 ].id;
		update course;
		test.startTest();
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			createAssignment(new List <Time_Element__c>{testDataSetupUtil_v2.semester3,testDataSetupUtil_v2.semester4});
			masterGradeList[1].entered_grade__c='39';							
			update masterGradeList[1];
			masterGradeList[0].entered_grade__c='40';
			update masterGradeList[0];
		}
		Gradebook_Semester_Midterm_Controller calculate = new Gradebook_Semester_Midterm_Controller();
		//Sumemr 2014 iteration 2: requires a list of students
		calculate.calcSemesterMidtermGrades(testDataSetupUtil_v2.studentsList);
		test.stopTest();
		//system.assertEquals([select count () from Section_Grade__c where Student_Section__c =:testDataSetupUtil_v2.studSectionsList[0].id and Time__c=null],2);
   
   		Section_Grade__c midTerm2 = [select grade__c, letter_grade__c from Section_Grade__c where Student_Section__c =:testDataSetupUtil_v2.studSectionsList[0].id and Reference_Id__c like  'S2%'];
		system.debug('midTerm2~~~'+midTerm2);
		system.assertEquals(midTerm2.grade__c, 98.75);
		system.assertEquals(midTerm2.letter_grade__c, 'A'); 
    } 
    
}