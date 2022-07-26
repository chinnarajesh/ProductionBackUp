@isTest
private class Charts_Test {

	static testMethod void testIt() {
		testDataSetupUtil_v2.isGradebook=true;
		testDataSetupUtil_v2.setUPCoreData(2);//Increased the count to 2 to fix the "List out of bounds" Exception in TestDataSetupUtil_V2 line no. 939
		testDataSetupUtil_v2.setUPStaffData(4);
		testDataSetupUtil_v2.setUPStudentData(4);
		Standard__c s = new Standard__c();
		 s.Identifier__c='ABC';
		 s.Name = 'ABC';
		 Insert(s);
		 Standard__c s2 = new Standard__c();
		 s.Identifier__c='ABCD';
		 s.Name = 'ABCD';
		 Insert(s2);
		 Test.startTest();
		 Charts c = new Charts();
		 c.loadFilters();   //cover non-staff specific filter loads
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			 c.loadFilters();
			 c.selectedTeacherIDs = new List<String>();
			 c.selectedSchool = new List<Id>();
			 c.selectedStudents = new List<Charts.StudentWrapper>();
			 
			 c.dummyStandard.Identifier__c = 'ABC*';
			 c.standardCourseSearch = 'ABC*';
			 c.standardStrandSearch = 'ABC*';
			 c.standardSubjectSearch = 'ABC*';
			 c.standardParentStandardSearch = 'ABC*';
			 c.searchStandards();
			 
			 c.dummyStandard.Identifier__c = 'ABC';
			 c.standardCourseSearch = 'ABC';
			 c.standardStrandSearch = 'ABC';
			 c.standardSubjectSearch = 'ABC';
			 c.standardParentStandardSearch = 'ABC';
			 c.searchStandards();
			 
			c.SelectStudents();
			 c.selectedSchool.addAll(c.schoolToSectionOptionsMap.keyset());
			 c.reRenderSections();
			 c.selectedTeacherIDs.addAll(c.teacherToSectionOptionsMap.keyset());
			 c.reRenderSections();
			 c.selectedTeacherIDs.clear();
			 c.reRenderSections();
			 c.dummyStudent.Ethnicity__c = 'White';
			 c.dummyStudent.Race__c = 'Generic';
			 c.dummyStudent.ELL__c = true;
			 c.dummyStudent.IEP__c = true;
			 c.dummyStudent.Title_1_Status__c = 'Title 1';
			 
			 c.getStudents();
		 }
		 Test.stopTest();
	}
	
	static testMethod void testIt2(){
		testDataSetupUtil_v2.isGradebook=true;
		testDataSetupUtil_v2.setUPCoreData(2);//Increased the count to 2 to fix the "List out of bounds" Exception in TestDataSetupUtil_V2 line no. 939
		testDataSetupUtil_v2.setUPStaffData(4);
		testDataSetupUtil_v2.setUPStudentData(4);
		Standard__c s = new Standard__c();
		 s.Identifier__c='ABC';
		 s.Name = 'ABC';
		insert s;
		Standard__c s2 = new Standard__c();
		 s.Identifier__c='ABCD';
		 s.Name = 'ABCD';
		insert s2;
		Test.startTest();
		Charts c = new Charts();
		c.loadFilters();   //cover non-staff specific filter loads
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			 c.dummyStandard.Identifier__c = null;
			 c.standardCourseSearch  = null;
			 c.standardStrandSearch  = null;
			 c.standardSubjectSearch  = null;
			 c.standardParentStandardSearch  = null;
			 c.searchStandards();
			for(Charts.standardWrapper st : c.WrappedStandardS){
				st.selected = true;
			 }
			 c.selectStandards();
			c.dummyStudent = new Student__c();
			 c.getStudents();
			 list<Standard_Grade__c> sgToInsert = new List<Standard_Grade__c>();
			 string tempstudid = '';
			 for(charts.studentWrapper stud : c.wrappedStudents){
				for(charts.standardWrapper sw : c.selectedStandards){
					Standard_Grade__c sg = new Standard_Grade__c();
					sg.Student__c = stud.student.id;
					sg.Standard__c = sw.standard.id;
					sgToInsert.add(sg);
				}
				stud.selected = true;
				tempstudid = stud.student.id;
			 }
			 insert sgToinsert;
			 standard__c tempstd;
			 c.infomap = new map<id, standard__c>();
			 for(charts.standardWrapper sw : c.selectedStandards){
				tempstd = sw.standard;
				tempstd.long_text__c = 'test';
				c.infomap.put(tempstd.id, tempstd);  
			 }
			 ApexPages.currentpage().getparameters().put('removedStandards', tempstd.id);
			 ApexPages.currentpage().getparameters().put('removedStudents', tempstudid);
			 c.SelectStudents();
			 c.generateReports2();
			 c.removeSelectedStandards();
			 c.removeSelectedStudents();
		}
		Test.stopTest();
	}

}