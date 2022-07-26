@isTest
private class Test_AssessmentWizard {
	
	private static List<Picklist_Value__c> assessmentTypes = new List<Picklist_Value__c>();
	private static void setupData(){
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(1);
		testDataSetupUtil_v2.setUpStudentData(3);
		boolean isManagedPackage = Schema.SObjectType.Assesment__c.getName().replace('__c', '').contains('__');
		string assessmentTypeRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
		string fieldSet = ((isManagedPackage)?'SchoolForce__':'') + 'Score__c, ';
		fieldSet = fieldSet + ((isManagedPackage)?'SchoolForce__':'') + 'Goal_Met__c';
		
		assessmentTypes.add(new Picklist_Value__c(RecordTypeID = assessmentTypeRTID, Name = 'Test1'
												,FieldSet__c = fieldSet
			));
		assessmentTypes.add(new Picklist_Value__c(RecordTypeID = assessmentTypeRTID, Name = 'LongTest2'
												,FieldSet__c = fieldSet
			));
			
		insert assessmentTypes;
	}
	private static void setupData1(){
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(1);
		testDataSetupUtil_v2.setUpStudentData(3);
		boolean isManagedPackage = Schema.SObjectType.Assesment__c.getName().replace('__c', '').contains('__');
		string assessmentTypeRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
		string fieldSet = ((isManagedPackage)?'SchoolForce__':'') + 'Score__c, ';
		fieldSet = fieldSet + ((isManagedPackage)?'SchoolForce__':'') + 'Goal_Met__c';
		fieldSet = fieldSet + ((isManagedPackage)?'SchoolForce__':'') + ',Date_Administered__c';
		//System.assertEquals('p',fieldSet);
		//fieldSet = fieldSet + 'Date_Administered__c';
		assessmentTypes.add(new Picklist_Value__c(RecordTypeID = assessmentTypeRTID, Name = 'Test1'
												,FieldSet__c = fieldSet
			));
		assessmentTypes.add(new Picklist_Value__c(RecordTypeID = assessmentTypeRTID, Name = 'LongTest2'
												,FieldSet__c = fieldSet
			));
			
		insert assessmentTypes;
	}
	
	private static testmethod void testConstructor(){
		setupdata();
		test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			system.assertEquals(true, controller.mainPage);
			system.assert(controller.yearOptions.size() >= 1);
			system.assertEquals(0, controller.studentList.size());
		test.stopTest();
	}
	
	private static testmethod void testStudentSearch(){
		setupdata();
        test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			controller.searchChange();
			controller.searchType = 'student';
			controller.studentSearchInfo.school = '--None--';
			controller.studentSearchInfo.student.Active__c = true;
            controller.studentSearchInfo.student.Grede_Multiselect__c='5';
			controller.groupSearch();
			system.assertEquals(3, controller.studentSearchResults.size());
			for(AssessmentWizardController.studentWrapper s: controller.studentSearchResults){
				s.selected = true;
			}
            Set<String> ids= new Set<String>(); 
            String str=String.valueOf(controller.studentSearchResults[0].student.Student_Id__c); 
            ids.add(str);
            controller.addStudents(ids);
            system.assertEquals(1, controller.studentList.size());
            system.assertEquals(0, controller.studentSearchResults.size());
           
		test.stopTest();
	}
    private static testmethod void testSectionSearch(){
		setupData();
		
		test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			controller.searchChange();
			controller.searchType = 'section';
			controller.groupSearch();
			system.assertEquals(1, controller.sectionSearchResults.size());
			controller.sectionSearchResults[0].selected = true;	
            controller.addSections();
		test.stopTest();
	}
    private static testmethod void testAssessmentGen(){
		setupdata();

		test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			controller.searchChange();
			controller.searchType = 'student';
			controller.studentSearchInfo.school = '--None--';
			controller.studentSearchInfo.student.Active__c = true;
            controller.studentSearchInfo.student.Grede_Multiselect__c='5';
			controller.groupSearch();
			for(AssessmentWizardController.studentWrapper s: controller.studentSearchResults){
				s.selected = true;
			}
            Set<String> ids= new Set<String>(); 
            String str=String.valueOf(controller.studentSearchResults[0].student.Student_Id__c); 
            ids.add(str);
            controller.addStudents(ids);
			controller.studentList[0].selected = true;
			controller.removestudents();
			//system.assertEquals(2, controller.studentList.size());
			controller.generateAssessments();
			
			//system.assertEquals(2, controller.newAssessments.size());
			
		test.stopTest();
	}
    private static testMethod void testExport(){
		setupdata();

		test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			controller.searchChange();
			controller.searchType = 'student';
			controller.studentSearchInfo.school = '--None--';
			controller.studentSearchInfo.student.Active__c = true;
            controller.studentSearchInfo.student.Grede_Multiselect__c='5';
			controller.groupSearch();
			for(AssessmentWizardController.studentWrapper s: controller.studentSearchResults){
				s.selected = true;
			}
            Set<String> ids= new Set<String>(); 
            String str=String.valueOf(controller.studentSearchResults[0].student.Student_Id__c); 
            ids.add(str);
            str=String.valueOf(controller.studentSearchResults[1].student.Student_Id__c);
            ids.add(str);
            controller.addStudents(ids);	
            controller.generateAssessments();
			controller.selectedType = assessmentTypes[0].id;
			controller.changeAssessmentType();
			controller.saveForExport();
			controller.goHome();
			
		test.stopTest();
	}
    
    private static testMethod void testImport(){
		setupdata1();

			assessmentWizardController controller = new AssessmentWizardController();
			controller.searchChange();
			controller.searchType = 'student';
			controller.studentSearchInfo.school = '--None--';
			controller.studentSearchInfo.student.Active__c = true;
            controller.studentSearchInfo.student.Grede_Multiselect__c='5';
			controller.groupSearch();
			for(AssessmentWizardController.studentWrapper s: controller.studentSearchResults){
				s.selected = true;
			}
			Set<String> ids= new Set<String>(); 
            String str1=String.valueOf(controller.studentSearchResults[0].student.Student_Id__c); 
            ids.add(str1);
            str1=String.valueOf(controller.studentSearchResults[1].student.Student_Id__c);
            ids.add(str1);
            controller.addStudents(ids);
			for(AssessmentWizardController.studentWrapper s: controller.studentList){
				s.selected = true;
			}
			controller.generateAssessments();
			controller.selectedType = assessmentTypes[0].id;
			controller.changeAssessmentType();
			controller.saveForExport();
			List<String> str =new List<String>();
			//transform the data some to boost coverage (<75% without)
			List<string> csvData = controller.csvData.split('\n');
			controller.csvData = '';
			//system.assertEquals(str,csvData);
			List<string> rowData = new List<String>();
			rowData = csvData[2].split(',');
			rowData[3] = 'abc 123';
			rowData[4] = 'TRUE'; 
			rowData[5] = '3/31/2016';
				
			
			csvData[2] = StringUtils.join(rowData, ',', null);
			rowData = csvData[3].split(',');
			rowData[3] = '"abc \n123"';
			rowData[4] = 'FALSE';
            rowData[5] = '3/31/2016';

			csvData[3] = StringUtils.join(rowData, ',', null);
     		/*rowData = csvData[4].split(',');
			rowData[3] = '"""abc123"""';
			rowData[4] = 'TRUE';
             rowData[5] = '3/31/2016';

   			csvData[4] = StringUtils.join(rowData, ',', null);*/
           
			string importData = StringUtils.join(csvData, '\n', null);
			
			csvData.clear();
			rowData.clear();
			
			test.startTest();
				PageReference pref = controller.startImport();
				system.assertEquals(pref.getURL(), Page.Assessment_Import.getURL());
				controller.fileBlob = Blob.valueOf(importData);
			//	system.assertEquals('abc',importData);
				importData = '';
				controller.fileName = 'testData.csv';
				controller.fileContentType = 'text/csv';
				
				controller.processInput();
				controller.saveInput();
			test.stopTest();
	}
    private static testMethod void testExistingExport(){
		setupdata();
		
		Assesment__c testAssessment = new Assesment__c(Student__c= testDataSetupUtil_v2.studentsList[0].id
										,Type__c = assessmentTypes[0].id
										,Goal_Met__c = true
										,Score__c = '5'
										,Date__c = system.today());
										
		insert testAssessment;

		test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			
			//load export screen
			controller.startExistingExport();
			system.assertEquals(true,controller.showExport);
			
			//setup search
			//use an instance of section to hold the data
			controller.startDate = system.today().format();
			controller.endDate = system.today().format();
			controller.gradeHolder.All_Grades__c = '1;2;3;4;5;';
			controller.selectedType = assessmentTypes[0].id;
			controller.studentSearchInfo.school = testDataSetupUtil_v2.school.id;
			controller.searchExisting();
			//export as CSV
			controller.exportExisting();
			controller.saveExisting();
			testAssessment = [select id, Score__c from Assesment__c where id=: testAssessment.id];
			test.stopTest();
	}
    private static testMethod void testFunctionality(){
        setupdata();
            AssessmentWizardController controller = new AssessmentWizardController();
        	test.startTest();
            controller.searchChange();
			controller.searchType = 'section';
			controller.groupSearch();
			system.assertEquals(1, controller.sectionSearchResults.size());
            controller.goToMain();
            controller.changeYear();
            controller.slctdStdId=String.valueOf(testDataSetupUtil_v2.studentsList[0].ID)+','+String.valueOf(testDataSetupUtil_v2.studentsList[1].Id);
            controller.getstdata();
            //controller.exportExisting2();
            controller.dummyRefresh();
            PageReference pr= controller.cancelImport();
        
    }
	 private static testMethod void testExistingExport2(){
		setupdata();
		Student__c st=testDataSetupUtil_v2.studentsList[0];
        st.Active__C=true;
        update st;
        system.assertEquals(st.Active__C,true);
		Assesment__c testAssessment = new Assesment__c(Student__c= st.id
										,Type__c = assessmentTypes[0].id
                                        ,Student_Id__c=st.Student_Id__c
										,Goal_Met__c = true
										,Score__c = '5'
										,Date__c = system.today());
										
		insert testAssessment;
       
        update testAssessment;
        test.startTest();
			AssessmentWizardController controller = new AssessmentWizardController();
			controller.startExistingExport();
			system.assertEquals(true,controller.showExport);
		    controller.selectedType = assessmentTypes[0].id;
			controller.studentSearchInfo.student.Student_Id__c=testAssessment.Student_Id__c;
		    controller.studentSearchInfo.school=testAssessment.student__r.School__r.Name;
            controller.studentSearchInfo.indicatorArea='--None--';
            controller.searchExisting();
            List<Assesment__c> ast=[select Date__c, Student_Name__c, Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c, Student__r.Legacy_Id__c, Score__c, Goal_Met__c From Assesment__c where Student__c != null and Type__c='a0rR000000235AmIAI' and Student__r.Active__c = true AND Student_Id__c = 'SC1230_Stu0' order by Date__c Limit 3000]; 
            System.assertEquals(testAssessment.student__r.Active__C,False);
       		controller.exportExisting();
			controller.saveExisting();
			testAssessment = [select id, Score__c from Assesment__c where id=: testAssessment.id];
			test.stopTest();
}
}