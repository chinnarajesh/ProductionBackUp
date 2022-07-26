@isTest
private class Test_Gradebook_Calculations {
    static testMethod void test_Gradebook_calc1(){
    	testDataSetupUtil_v2.isGradebook = true;
        testDataSetupUtil_v2.setUPCoreData(3);
        testDataSetupUtil_v2.setUPStaffData(3);
        testDataSetupUtil_v2.setUPStudentData(3);
        Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c'); 

		test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[1]){

			Picklist_Value__c [] pgradescale = [Select Id, Name, RecordType.Name, Setup__c from Picklist_Value__c where Name = '0-100'];
			Assignment__c testa = new Assignment__c(
			Due_Date__c = system.today(),
			Picklist_Value__c = pgradescale[0].Id,
			Include_in_Final_Grade__c = TRUE,
			Name_in_Gradebook__c = 'TA1',
			Time__c = testDataSetupUtil_v2.semester.Id,
			Section__c = testDataSetupUtil_v2.studSectionsList[0].Section__c,
			Weighting_Value__c = 2);
			
			insert testa;
			
			Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = testa.Picklist_Value__c);
    		update co; 
			
	
			Grade__c testg = new Grade__c (
			Assignment__c = testa.id,
			Assignment_Weighting__c = 2,
			Course__c = testDataSetupUtil_v2.coursesList[0].Id,
			Time__c = testDataSetupUtil_v2.semester.Id,
			Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c,
			Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].Id);
			
			insert testg;
			system.debug('Test Grade: ' + testg);
			testg.Entered_Grade__c = '85';
			
			update testg;
			system.debug('Test Grade: ' + testg);
			testa.Weighting_Value__c = 3;
			update testa;
	
			Grade__c [] testgrades = [Select Id, Student__c, Weighted_Grade_Value__c, Grade_Number__c FROM Grade__c where Student_Section__c = :testDataSetupUtil_v2.studSectionsList[0].Student__c];
			system.debug('PNC5' + testgrades);

			Database.DeleteResult results = Database.delete(testa,false);
			system.assert(!results.isSuccess(),'Expected the assignment delete to fail because of entered grades.');

			testg.Entered_Grade__c = null;
			update testg;

			results = Database.delete(testa);
			system.assert(results.isSuccess(),'Expected the assignment delete to pass after clearing entered grade.');

	
			//check grades are also deleted
			testgrades = [Select Id, Student__c, Weighted_Grade_Value__c, Grade_Number__c FROM Grade__c where Student_Section__c = :testDataSetupUtil_v2.studSectionsList[0].Student__c];
			system.assertequals(0,testgrades.size());
			
		}
		test.stopTest();
	}
	
	static testMethod void test_Gradebook_Include_Exclude(){
		//Used to test US2794
		testDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(3);
		testDataSetupUtil_v2.setUPStaffData(3);
		testDataSetupUtil_v2.setUPStudentData(3);
		Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c'); 

		ID batchprocessid;
		AsyncApexJob aaj;
			
		test.startTest();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){

			Picklist_Value__c [] pgradescale = [Select Id, Name, RecordType.Name, Setup__c from Picklist_Value__c where  Name = '0-100'];
			
			Grade_Normalization__c [] checkvals = [Select Id, Picklist_Value__c, Name from Grade_Normalization__c];
			
			Assignment__c testa = new Assignment__c(
			Due_Date__c = system.today(),
			Picklist_Value__c = pgradescale[0].Id,
			Include_in_Final_Grade__c = FALSE,
			Name_in_Gradebook__c = 'TA1',
			Time__c = testDataSetupUtil_v2.semester.Id,
			Section__c = testDataSetupUtil_v2.studSectionsList[0].Section__c,
			Weighting_Value__c = 2);
			insert testa;
			
			Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = testa.Picklist_Value__c);
    		update co; 

			Grade__c testg = new Grade__c (
			Exclude_From_Section_Grade__c = TRUE,
			Assignment__c = testa.id,
			Assignment_Weighting__c = 2,
			Course__c = testDataSetupUtil_v2.coursesList[0].Id,
			Time__c = testDataSetupUtil_v2.semester.Id,
			Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c,
			Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].Id);
			insert testg;
			
			testg.Entered_Grade__c = '85';
			update testg;

			system.assertEquals(null, [select grade__c from Section_Grade__c where time__c=:testDataSetupUtil_v2.semester.id and student_section__c = :testDataSetupUtil_v2.studSectionsList[0].id limit 1].grade__c);
			testa.Include_in_Final_Grade__c = true;
			update testa;
			system.assertEquals(85,[select grade__c from Section_Grade__c where time__c=:testDataSetupUtil_v2.semester.id and student_section__c = :testDataSetupUtil_v2.studSectionsList[0].id  limit 1].grade__c);
			
		}

		test.stopTest();

	} //end te

	static testMethod void test_Gradebook_Current(){
		testDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(3);
		testDataSetupUtil_v2.setUPStaffData(3);
		testDataSetupUtil_v2.setUPStudentData(3);
		Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c'); 

		ID batchprocessid;
		AsyncApexJob aaj;
			
		test.startTest();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){

			Picklist_Value__c [] pgradescale = [Select Id, Name, RecordType.Name, Setup__c from Picklist_Value__c where Name = '0-100'];
			
			Grade_Normalization__c [] checkvals = [Select Id, Picklist_Value__c, Name from Grade_Normalization__c];
			
			Assignment__c testa = new Assignment__c(
			Due_Date__c = system.today(),
			Picklist_Value__c = pgradescale[0].Id,
			Include_in_Final_Grade__c = TRUE,
			Name_in_Gradebook__c = 'TA1',
			Time__c = testDataSetupUtil_v2.semester.Id,
			Section__c = testDataSetupUtil_v2.studSectionsList[0].Section__c,
			Weighting_Value__c = 2);
			insert testa;
			
				Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = testa.Picklist_Value__c);
    		update co; 

			Grade__c testg = new Grade__c (
			Assignment__c = testa.id,
			Assignment_Weighting__c = 2,
			Course__c = testDataSetupUtil_v2.coursesList[0].Id,
			Time__c = testDataSetupUtil_v2.semester.Id,
			Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c,
			Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].Id);
			insert testg;
			
			testg.Entered_Grade__c = '85';
			update testg;

			Final_Grade__c [] CheckFinalGrade = [Select  Current_Grade_Letter_v2__c, Current_Grade_Value__c from Final_Grade__c where Student__c = :testDataSetupUtil_v2.studSectionsList[0].Student__c];
			system.assertequals(0, CheckFinalGrade.size());
			
			Gradebook_CurrentCourseGradeCalculation fg = new Gradebook_CurrentCourseGradeCalculation ();
			fg.query = 'Select Id from Student__c where ID = \'' + testDataSetupUtil_v2.studSectionsList[0].Student__c + '\' ';
			batchprocessid = Database.executeBatch(fg,1);
			
			aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
			    FROM AsyncApexJob WHERE ID =: batchprocessid ];
			system.assertequals('Queued',aaj.Status);
		}

		test.stopTest();
		//Once batch runs, should now be records
	
		aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
		    FROM AsyncApexJob WHERE ID =: batchprocessid ];
		system.assertequals('Completed',aaj.Status);
		
		Final_Grade__c CheckFinalGrade = [Select  Current_Grade_Letter_v2__c, Current_Grade_Value__c from Final_Grade__c where Student__c = :testDataSetupUtil_v2.studSectionsList[0].Student__c];
		system.assertequals(CheckFinalGrade.Current_Grade_Value__c, 85);
		//system.assertequals(CheckFinalGrade.Current_Grade_Letter_v2__c, 'B');
	} //end test

	static testMethod void test_Gradebook_FinalSG(){
		testDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(3);
        testDataSetupUtil_v2.setUPStaffData(3);
        testDataSetupUtil_v2.setUPStudentData(3);

		ID batchprocessid;
		AsyncApexJob aaj;
		
		test.startTest();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){

			Picklist_Value__c [] pgradescale = [Select Id, Name, RecordType.Name, Setup__c from Picklist_Value__c where Name = '0-100'];
			Picklist_Value__c [] stdsgradeScale = [Select Id, Name, RecordType.Name, Setup__c from Picklist_Value__c where Name = 'Standard' and Category__c='Standards'];

			Assignment__c testa = new Assignment__c(
			Due_Date__c = system.today(),
			Picklist_Value__c = pgradescale[0].Id,
			Include_in_Final_Grade__c = TRUE,
			Name_in_Gradebook__c = 'TA1',
			Time__c = testDataSetupUtil_v2.semester.Id,
			Section__c = testDataSetupUtil_v2.studSectionsList[0].Section__c,
			Weighting_Value__c = 2);
			insert testa;
Picklist_value__c termPlv;
for (Picklist_Value__c pl: [select id, corresponding_Value__c , name from Picklist_Value__c where RecordType.DeveloperName = 'Time']){
				//if (pl.name=='Semester')semesterPlv=pl;
				if (pl.name=='Term') termPlv=pl;
			}
			Course_Weightings__c cw = new Course_Weightings__c(course__c=testDataSetupUtil_v2.sectionsList[0].course__c, reporting_period_type__c=termPlv.id, key__c='1', weighting__c=100);
			insert cw;
			testDataSetupUtil_v2.sectionsList[0].number_of_reporting_periods__c='1';
			update testDataSetupUtil_v2.sectionsList[0];
	
			Course__c co = new Course__c (Id = testDataSetupUtil_v2.coursesList[0].Id, Grade_scale_lookup__c = testa.Picklist_Value__c);
    		update co; 

			Grade__c testg = new Grade__c (
			Assignment__c = testa.id,
			Assignment_Weighting__c = 2,
			Course__c = testDataSetupUtil_v2.coursesList[0].Id,
			Time__c = testDataSetupUtil_v2.semester.Id,
			Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c,
			Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].Id);
			insert testg;

			testg.Entered_Grade__c = '85';
			update testg;
			
			Student_Reporting_Period__c srp = new Student_Reporting_Period__c(Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c, Time__c = testDataSetupUtil_v2.semester.id);
			insert srp;
			Student_Reporting_Period__c srp2 = new Student_Reporting_Period__c(Student__c = testDataSetupUtil_v2.studSectionsList[0].Student__c, Time__c = testDataSetupUtil_v2.semester2.id);
			insert srp2;
			
			//US1284 quarters
			Section_Grade__c [] checksg = [Select Letter_Grade__c, Grade__c, Weighted_Final_Grade__c from Section_Grade__c WHERE Student_Section__c = :testDataSetupUtil_v2.studSectionsList[0].Id AND (RecordTypeID = null OR RecordType.Name = 'Quarter')];
			//system.assertequals('B',checksg[0].letter_grade__c);
		
			Gradebook_Final_GPA_Batch fg = new Gradebook_Final_GPA_Batch();
			fg.query = 'Select Id, Setup__r.Term__c from Student__c where ID = \'' + testDataSetupUtil_v2.studSectionsList[0].Student__c + '\' ';
			fg.isFinal = true;
			fg.showInPortal = false;
			batchprocessid = Database.executeBatch(fg,1);
			
			aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
			    FROM AsyncApexJob WHERE ID =: batchprocessid ];
			system.assertequals('Queued',aaj.Status);
			
		} //end run as    

		test.stoptest();      

		aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
		    FROM AsyncApexJob WHERE ID =: batchprocessid ];
		system.assertequals('Completed',aaj.Status);
		
		
			Final_Grade__c CheckFinalGrade = [
			    Select 
			    Final_GPA_Value__c, 
			    Course_Credits__c, 
			    Final_Grade_Value__c
			    from Final_Grade__c where Student__c = :testDataSetupUtil_v2.studSectionsList[0].Student__c];
			system.assertequals(CheckFinalGrade.Final_Grade_Value__c,85.00);
			system.assertequals(CheckFinalGrade.Final_GPA_Value__c,2.5);
			system.assertequals(CheckFinalGrade.Course_Credits__c,4);
			
			Student_Reporting_Period__c CheckSrpGpa = [
			    Select 
			    GPA__c
			    from Student_Reporting_Period__c where Student__c = :testDataSetupUtil_v2.studSectionsList[0].Student__c and Time__c=:testDataSetupUtil_v2.semester.id];
						system.assertequals(CheckSrpGpa.Gpa__c,2.5);
		 
		 
	} //end test 
} //end class