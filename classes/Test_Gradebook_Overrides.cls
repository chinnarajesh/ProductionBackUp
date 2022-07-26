@isTest
public class Test_Gradebook_Overrides {
	public static void setupData(){
		testDataSetupUtil_v2.isGradebook = true;
    	testDataSetupUtil_v2.setUPCoreData(3);
        testDataSetupUtil_v2.setUPStaffData(3);
        testDataSetupUtil_v2.setUPStudentData(3);

	}
	public static void setupGbData(string ScaleName, string goodGrade, string badGrade, double pp){
		
	Picklist_Value__c [] pgradescale = [Select Id, Name, RecordType.Name, Setup__c from Picklist_Value__c where  Name = :ScaleName];
	  Assignment__c testa = new Assignment__c(
                                                Due_Date__c = system.today(),
                                                Picklist_Value__c = pgradescale[0].Id,
                                                Include_in_Final_Grade__c = TRUE,
                                                Name_in_Gradebook__c = 'TA1',
                                                Time__c = testDataSetupUtil_v2.semester.Id,
                                                Section__c = testDataSetupUtil_v2.studSectionsList[0].Section__c,
                                                Weighting_Value__c = 2,
                                                Possible_Points__c = pp);
    insert testa;
    system.debug('Test assignment: ' + testa);
    

    Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = pgradescale[0].id);
    update co; 
    system.debug('Course: ' + co);
      test.startTest();
    Grade__c testg = new Grade__c (
    //Standards_Only_Grading__c = TRUE,
    Standard_Weighting__c = 1,
    Assignment__c = testa.id,
    Assignment_Weighting__c = 2,
    Course__c = testDataSetupUtil_v2.coursesList[0].Id,
    Time__c = testDataSetupUtil_v2.semester.Id,
    Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c,
    Possible_Points__c = pp,
    Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].Id);
    insert testg;
    system.debug('Test Grade: ' + testg);
    testg.Entered_Grade__c = goodGrade;
    update testg;
    system.debug('Test Grade after update: ' + testg);
  
          core_triggerUtils.recursiveHelper(false);
    Section_Grade__c [] checksg = [Select Letter_Grade__c, Grade_Scale__c , Grade_Override__c, Grade_Overridden__c, Grade__c, Weighted_Final_Grade__c from Section_Grade__c WHERE Student_Section__c = :testDataSetupUtil_v2.studSectionsList[0].Id];
    system.debug('checkSg~~~'+checkSg);
    try{
    checksg[0].Grade_Override__c =badGrade;
    } 
    Catch (Exception Ex) {
    system.debug(Ex);
    }
    core_triggerUtils.recursiveHelper(false);
    checksg[0].Grade_Override__c = goodGrade;
    update checksg;
    system.debug('Section Grade: ' + testg);
	}
	
	static void verifyGbData(string verifyGrade){
		 Section_Grade__c [] checksg = [
                    Select Letter_Grade__c , Section_GPA__c, Grade_Overridden__c 
                    from Section_Grade__c WHERE Student_Section__c = :testDataSetupUtil_v2.studSectionsList[0].Id];
    //Should now be B, but marked as overridden
    system.assertequals(TRUE,checksg[0].Grade_Overridden__c);
    system.assertequals(verifyGrade,checksg[0].Letter_Grade__c);
	}


    
    
        static testMethod void test_Gradebook_Standards(){
       		setupData();
            system.runAs(testDataSetupUtil_v2.staffUsersList[1]){ 
				setupGbData('Standard', '3','7',null);
				test.stopTest();
            }
            verifyGbData('3');
    }	
    
      static testMethod void test_Gradebook_Letter(){
       		setupData();
            system.runAs(testDataSetupUtil_v2.staffUsersList[1]){ 
				setupGbData('Letter Grade', 'B','X',null);
				test.stopTest();
            }
            verifyGbData('B');
    }	
    
    
    
    static testMethod void test_Gradebook_Points(){
       		setupData();
       		
       		//temporary fix, the test data does not account for loading default normalizations.
       		Grade_Normalization__c default83 = new Grade_Normalization__c(GP_Value__c = 3.5, Grade_Value__c = 83, Transformed_Grade__c = '83');
       		insert default83;
            
            system.runAs(testDataSetupUtil_v2.staffUsersList[1]){ 
				setupGbData('Points', '83','185',83);
				test.stopTest();
            } 
            verifyGbData('83');
    }	
    
    static testMethod void test_Gradebook_0_100(){
       		setupData();
            system.runAs(testDataSetupUtil_v2.staffUsersList[1]){ 
				setupGbData('0-100', '85','185',null);
				test.stopTest();
            }
            verifyGbData('85');
    }	
       
    


}