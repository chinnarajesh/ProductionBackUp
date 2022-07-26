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
 
 //Mean, Median, Mode, Highest, Most Recent, Law of Decaying Average, Power Law
 
@isTest
public with sharing class Test_Gradebook_CalculationTypes {

	public static void RunBasicTest() {
			//add a standard
			Standard__c testStandard = new Standard__c();
			testStandard.name = 'Test Standard';
			testStandard.Level__c = 1;
			testStandard.Course__c = testDataSetupUtil_v2.coursesList[0].id;
			insert testStandard;

			Assignment__c testAssignment = new Assignment__c();
			testAssignment.Name = 'hope';
			testAssignment.Section__c = testDataSetupUtil_v2.sectionsList[0].ID;
			testAssignment.Due_Date__c = Date.newInstance(system.today().year()+30, 8, 5);
			testAssignment.Weighting_Value__c = 5;
			testAssignment.Name_In_Gradebook__c = 'tHope';
			testAssignment.Include_in_Final_Grade__c = true;
			//testAssignment.Assignment_Library__c;
			testAssignment.Time__c = testDataSetupUtil_v2.semester.ID;
			testAssignment.Picklist_Value__c = [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Letter Grade' limit 1 ].id;
			testAssignment.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;  //Display code was change to 'testxx' in TestDataSetupUtil_V2
			insert testAssignment;
			
			Standard_Grade__c sg1 = new Standard_Grade__c();
			sg1.Student__c = testDataSetupUtil_v2.studentsList[0].ID;
			sg1.Standard__c = testStandard.ID;
			sg1.Key__c = (String)sg1.Student__c + (String)sg1.Standard__c;
			insert sg1;
			
			Grade__c grade1 = new Grade__c();
			grade1.Course__c = testDataSetupUtil_v2.coursesList[0].ID;
			grade1.Entered_Grade__c = '3';
			grade1.Grade_Number__c = 3.0;
			grade1.Valid_Grade__c = true;
			grade1.Weighted_Grade_Value__c = 15.0;
			grade1.Grade_With_Standard__c = true;
			grade1.Standards_Only_Grading__c = true;
			//grade1.Strand_Grade__c = sg1.ID;
			grade1.Standard_Times_Assignment__c = 5;
			grade1.Standard_Weighting__c = 1;
			grade1.Assignment_Weighting__c = 5;
			grade1.Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].ID;
			grade1.Time__c = testDataSEtupUtil_v2.semester.ID;
			grade1.Standard__c = testStandard.ID;
			grade1.Student__c = testDataSetupUtil_v2.studentsList[0].ID;
			
			//updating test class here
			grade1.Include_In_Standard_Grade__c = true;
			
			grade1.Assignment__c = [SELECT ID, Time__c FROM Assignment__c WHERE Name = 'hope' LIMIT 1][0].ID;
			insert grade1;	
			Set<ID> Students = new Set<ID>{testDataSetupUtil_v2.studentsList[0].ID};
			Set<ID> Standards = new Set<ID>{testStandard.ID};
			
			test.startTest();
			Gradebook_CalculationTypes.determineCalculationNow(students, standards, new Set<ID>{grade1.Assignment__r.Time__c});
			Gradebook_CalculationTypes.calculateLater(students, standards, new Set<ID>{grade1.Assignment__r.Time__c}, false); 
			test.stopTest();				
	}

    static testMethod void myUnitTest0() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Mean';

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        			
			RunBasicTest();	 				   	
		}
		
        
    }
    
    static testMethod void myUnitTest1() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Median';

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        
			RunBasicTest();			 				   	
		}
    }    
    
    static testMethod void myUnitTest2() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Mode';
    	
		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        
			RunBasicTest();			 				   	
		}
    }    
    
    static testMethod void myUnitTest3() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Most Recent';

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        
			RunBasicTest();			 				   	
		}
    }     
    
    static testMethod void myUnitTest4() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Highest';

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        
			RunBasicTest();			 				   	
		}
    }     
    
    static testMethod void myUnitTest5() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Power Law';

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        
			RunBasicTest();			 				   	
		}
    }  
    
    static testMethod void myUnitTest6() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Law of Decaying Average';
    	testDataSetupUtil_v2.activeSetUp.Law_of_Decaying_Average_Weight__c = 75;

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        
			RunBasicTest();			 				   	
		}
    }      
    
    static testMethod void myUnitTest7() {
		setupStandardBasedSchool();
    	
    	testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Mean';

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){        			
			//add a standard
			Standard__c testStandard = new Standard__c();
			testStandard.name = 'Test Standard';
			testStandard.Level__c = 1;
			testStandard.Course__c = testDataSetupUtil_v2.coursesList[0].id;
			insert testStandard;

			Assignment__c testAssignment = new Assignment__c();
			testAssignment.Name = 'hope';
			testAssignment.Section__c = testDataSetupUtil_v2.sectionsList[0].ID;
			testAssignment.Due_Date__c = Date.newInstance(system.today().year()+30, 8, 5);
			testAssignment.Weighting_Value__c = 5;
			testAssignment.Name_In_Gradebook__c = 'tHope';
			testAssignment.Include_in_Final_Grade__c = true;
			//testAssignment.Assignment_Library__c;
			testAssignment.Time__c = testDataSetupUtil_v2.semester.ID;
			testAssignment.Picklist_Value__c = [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Letter Grade' limit 1 ].id;
			testAssignment.Standard_Scale__c =  [select id from Picklist_value__c where RecordType.DeveloperName = 'Grade_Scale' AND name = 'Standard' limit 1 ].id;  //Display code was change to 'testxx' in TestDataSetupUtil_V2
			insert testAssignment;
			
			Standard_Grade__c sg1 = new Standard_Grade__c();
			sg1.Student__c = testDataSetupUtil_v2.studentsList[0].ID;
			sg1.Standard__c = testStandard.ID;
			sg1.Key__c = (String)sg1.Student__c + (String)sg1.Standard__c;
			insert sg1;
			
			Grade__c grade1 = new Grade__c();
			grade1.Course__c = testDataSetupUtil_v2.coursesList[0].ID;
			grade1.Entered_Grade__c = '3';
			grade1.Grade_Number__c = 3.0;
			grade1.Valid_Grade__c = true;
			grade1.Weighted_Grade_Value__c = 15.0;
			grade1.Grade_With_Standard__c = true;
			grade1.Standards_Only_Grading__c = true;
			//grade1.Strand_Grade__c = sg1.ID;
			grade1.Standard_Times_Assignment__c = 5;
			grade1.Standard_Weighting__c = 1;
			grade1.Assignment_Weighting__c = 5;
			grade1.Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].ID;
			grade1.Time__c = testDataSEtupUtil_v2.semester.ID;
			grade1.Standard__c = testStandard.ID;
			grade1.Student__c = testDataSetupUtil_v2.studentsList[0].ID;
			
			//updating test class here
			grade1.Include_In_Standard_Grade__c = true;
			
			grade1.Assignment__c = [SELECT ID FROM Assignment__c WHERE Name = 'hope' LIMIT 1][0].ID;
			insert grade1;	
			Set<ID> Students = new Set<ID>{testDataSetupUtil_v2.studentsList[0].ID};
			Set<ID> Standards = new Set<ID>{testStandard.ID};
			
			test.startTest();
			//Gradebook_CalculationTypes.CalculateLaterBatch(students, standards, testDataSEtupUtil_v2.activeSetUp.Calculation_Type__c, 75.0);
			test.stopTest(); 				   	
		}
		
        
    }      
    
    public static void setupStandardBasedSchool() {
    	//steps inorder to populate a standard based school, going with SO_Gradebook
    	//this function creates: the school, Time Elements, Courses, and setup for the school.
    	//it also creates info for gradebook, behaviors, and homework modules
    	
		//before running setupcoredata, you need to change some default values, setting isgradebook true will fire
		//off the setupPreGradebookData stuff, tho i do not think standards are accounted for anything
    	//testDataSetupUtil_v2.isGradebook = true;
    	//run the setup, interesting tidbits: creates the courses here, they are standard base courses by default, idky
    	testDataSetupUtil_v2.setUPCoreData(2);
    	//you must run setupstaffdata next, for some reason standards are created in here? creates staff/section records here
    	testDataSetupUtil_v2.setUPStaffData(2);
    	//creates student/section records here
    	testDataSetupUtil_v2.setUpStudentData(5);
    	testDataSetupUtil_v2.createScalesNormalizations();
    	//after running the above steps, there should be courses with sections, students and staff members in sections, 
    	//course catalog, scale catalog, grade scales, etc...
    	//testDataSetupUtil_v2.activeSetUp.Calculation_Type__c = 'Mean';
    	
    }  
}