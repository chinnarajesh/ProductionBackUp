@isTest
private class Test_Scheduler_SectionWizard {
	static Scheduler_SectionWizard wizard;
	
	static void setup(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUpStaffData(5);
		TestDataSetupUtil_v2.setUpStudentData(5);
		
		ApexPages.StandardController controller = new ApexPages.StandardController(new Student_Section__c()); 
		System.runAs(TestDataSetupUtil_v2.staffUsersList[0]){	  
		   wizard = new Scheduler_SectionWizard(controller);
		}
	}
	
	static void setup_WithoutStudents(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUpStaffData(5);
		
		ApexPages.StandardController controller = new ApexPages.StandardController(new Student_Section__c()); 
		System.runAs(TestDataSetupUtil_v2.staffUsersList[0]){	  
		   wizard = new Scheduler_SectionWizard(controller);
		}
	}

	static void setup_WithoutStudentSections(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUpStaffData(5);
		TestDataSetupUtil_v2.studContactsList = TestDataSetupUtil_v2.getContacts(5, 'Student' , null);
		TestDataSetupUtil_v2.studentsList = TestDataSetupUtil_v2.getStudents(5, 'Student', TestDataSetupUtil_v2.studContactsList);
		TestDataSetupUtil_v2.studpgList = TestDataSetupUtil_v2.getPGs();

		ApexPages.StandardController controller = new ApexPages.StandardController(new Student_Section__c()); 
		System.runAs(TestDataSetupUtil_v2.staffUsersList[0]){	  
		   wizard = new Scheduler_SectionWizard(controller);
		}
	}	

	static testMethod void testScheduleWrapper() {
		setup();
		
		System.assertEquals(wizard.page1, true);
		System.assertEquals(wizard.page2, false);
		System.assertEquals(wizard.page3, false);
		System.assertEquals(wizard.groupBased, TestDataSetupUtil_v2.activeSetUp.Group_Based__c);

		List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
		List<SelectOption> availSW1 = new List<SelectOption>();
		List<SelectOption> availSW2 = new List<SelectOption>();
		for(Section__c sg: groups) availSW2.add(new SelectOption(sg.id+'',sg.Name));
		for(Section__c s: TestDataSetupUtil_v2.sectionsList) availSW1.add(new SelectOption(s.id+'',s.Name));
		
		Test.startTest();
			Scheduler_SectionWizard.ScheduleWrapper sw0 = new Scheduler_SectionWizard.ScheduleWrapper();
			System.assertEquals(0, sw0.available.size());
			System.assert(!sw0.selected);
			
			Scheduler_SectionWizard.ScheduleWrapper sw1 = new Scheduler_SectionWizard.ScheduleWrapper
				(TestDataSetupUtil_v2.studentsList[0],availSW1);
			Scheduler_SectionWizard.ScheduleWrapper sw2 = new Scheduler_SectionWizard.ScheduleWrapper
				(TestDataSetupUtil_v2.studentsList[1],availSW2);	   
			
			System.assertEquals(sw1.stud, TestDataSetupUtil_v2.studentsList[0]);
			System.assertEquals(sw2.stud, TestDataSetupUtil_v2.studentsList[1]);
			for(integer i=0; i<sw1.available.size();i++){
				System.assertEquals(sw1.available[i].getLabel(),availSW1[i].getLabel());
				System.assertEquals(sw1.available[i].getValue(),availSW1[i].getValue());
			}
			for(integer i=0; i<sw2.available.size();i++){
				System.assertEquals(sw2.available[i].getLabel(),availSW2[i].getLabel());
				System.assertEquals(sw2.available[i].getValue(),availSW2[i].getValue());
			}
			
			Student__c newStudent = new Student__c();
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			newStudent.Student_First_Name__c = 'test';
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			newStudent.Student_Last_Name__c = 'test';
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			wizard.selectedGrade = '5';
			wizard.newStudent();
			newStudent.Date_of_Birth__c=Date.newInstance(2010,10,10);
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			newStudent.Gender__c = 'M';
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			newStudent.Race_Multi__c = 'White';
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			newStudent.Student_Id__c = '111222333';
			//should throw an error as it stands because newStudent is missing Entry Date
			wizard.studentToAdd.stud = newStudent;
			wizard.newStudent();
			//add entry date, should succeed
			newStudent.Entry_Date__c=testDataSetupUtil_v2.semester.date_start_date__c;
			wizard.studentToAdd.stud = newStudent;
			//fixes for time options
			wizard.studentToAdd.dateOfBirth='10/10/2010';
			wizard.newStudent();
			System.assertEquals(wizard.studentsToProcess.size(),1);
			System.assertEquals(wizard.page1, false);
			System.assertEquals(wizard.page2, true);
			
			//since student is new, they do not belong to any sections
			//because all of the sections in TestDataSetupUtil are for grade 5, all are available to the student
			System.assertEquals(wizard.toRemove.size(), 0);
			System.assertEquals(wizard.toAdd.size(),TestDataSetupUtil_v2.sectionsList.size());   
		Test.stopTest();
	}
	
	static testMethod void testSearchStudents() {
		setup();
		
		Test.startTest();
			//test that no parameters returns all available students
			wizard.results = false;
			wizard.searchStudent = new Student_SearchStudent();
			wizard.searchStudents();
			System.assertEquals(wizard.studResults[0].size(),TestDataSetupUtil_v2.studentsList.size());
			System.assertEquals(wizard.results,true);
			
			//all students have same first name in TestDataSetupUtil_v2s
			wizard.results = false;
			wizard.searchStudent.student.Student_First_Name__c = 'Student';
			wizard.searchStudents();
			System.assertEquals(wizard.studResults[0].size(),TestDataSetupUtil_v2.studentsList.size());
			System.assertEquals(wizard.results,true);
			
			//only one student has this particular last name
			wizard.results = false;
			wizard.searchStudent = new Student_SearchStudent();
			wizard.searchStudent.student.Student_Last_Name__c = 'StudentlastName1';
			wizard.searchStudents();
			System.assertEquals(wizard.studResults[0].size(),1);
			System.assertEquals(wizard.results,true);
			
			//all students have the same grade in TestDataSetupUtil_v2s
			wizard.results = false;
			wizard.searchStudent = new Student_SearchStudent();
			wizard.searchStudent.student.Grade__c = '5';
			wizard.searchStudents();
			System.assertEquals(wizard.studResults[0].size(),TestDataSetupUtil_v2.studentsList.size());
			System.assertEquals(wizard.results,true);
			
			//all students have the same grade in TestDataSetupUtil_v2
			//testing no results found
			wizard.results = false;
			wizard.searchStudent = new Student_SearchStudent();
			wizard.searchStudent.student.Entry_Date__c =testDataSetupUtil_v2.semester.date_start_date__c;
			wizard.searchStudent.student.Date_of_Birth__c = Date.newInstance(2010,10,10);
			wizard.searchStudents();
			System.assertEquals(wizard.studResults.size(),0);
			System.assertEquals(wizard.results,false);
			
			//Tests the cancel() method
			List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
			
			//set all variables to something that method has to change
			//this should never occur in practice
			wizard.page3=true;
			wizard.page2=true;
			wizard.newStuds=true;
			wizard.page1=false;
			for(Student_Section__c ss: TestDataSetupUtil_v2.studSectionsList)
				wizard.toRemove.add(new Scheduler_SectionWizard.ssWrapper(ss));
			for(Section__c sec: sections) wizard.toAdd.add(new Scheduler_SectionWizard.secWrapper(sec));
		   
			
			wizard.cancel();
			
			//assert all changes occurred
			System.assert(wizard.page1);
			System.assert(!wizard.page2);
			System.assert(!wizard.page3);
			System.assert(!wizard.newStuds);
			System.assert(!wizard.results);
			System.assert(wizard.buttons);
			System.assertEquals(wizard.toAdd.size(),0);
			System.assertEquals(wizard.toRemove.size(),0);
		
		Test.stopTest();
	}
	
	 static testMethod void testWithdraw(){
		//Tests the withdraw() method
		setup();
		List<Student__c> students = TestDataSetupUtil_v2.studentsList;
		List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
		
		Test.startTest();
			wizard.withdraw();
			System.assert(ApexPages.hasMessages());
			
			//add some students to process, make sure the exit dates default to today and that the right page is triggered
			
			Scheduler_SectionWizard.ScheduleWrapper sw1 = new Scheduler_SectionWizard.ScheduleWrapper(students[0],null);
			sw1.selected = true;
			Scheduler_SectionWizard.ScheduleWrapper sw2 = new Scheduler_SectionWizard.ScheduleWrapper(students[1],null);
			sw2.selected = true;
			wizard.studResults.add(new List<Scheduler_SectionWizard.ScheduleWrapper>());
			wizard.studResults[0].add(sw2);
			wizard.studResults[0].add(sw1);
			wizard.withdraw();
		    System.assertEquals(wizard.studentsToProcess.get(students[0].id).stud.Exit_Date__c,system.today());
			System.assert(wizard.page3);
			System.assert(!wizard.page1);
			
			//testEnableAddStudent

			
			//setup some initial variables to ensure removal
			wizard.studentsToProcess.put(students[0].id, new Scheduler_SectionWizard.ScheduleWrapper(students[0],null));
			wizard.newStuds = false;
			wizard.oldStuds = true;
			
			
			
			wizard.enableAddStudent();
			System.assertEquals(wizard.studentsToProcess.size(),0);
			System.assert(wizard.newStuds);
			System.assert(!wizard.oldStuds);
			
			//Tests the enableSearch
			wizard.newStuds = true;
			wizard.oldStuds = false;
			
			wizard.enableSearch();
			System.assert(!wizard.newStuds);
			System.assert(wizard.oldStuds);
		Test.stopTest();
	}
	
	static testMethod void testWithdrawStudents(){
		setup();
		
		//variables of convenience for reference
		List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
		Student__c sTest = TestDataSetupUtil_v2.studentsList[0];

		Boolean hasOneStudentSection = false;
		for(Student_Section__c ss:TestDataSetupUtil_v2.studSectionsList){
			hasOneStudentSection = hasOneStudentSection || ss.Student__c == sTest.ID;
		}
		System.assert(hasOneStudentSection,'Expected the selected student to have at least one student section.');


		Test.startTest();
			//test if there's no exit date or exit reason that errors are thrown
			sTest.Exit_Date__c = TestDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
			wizard.studentsToProcess.put(sTest.id,new Scheduler_SectionWizard.ScheduleWrapper(sTest,null));
			wizard.withdrawStudents();
			System.assert(ApexPages.hasMessages());
			System.assert(sTest.active__c);
			
			sTest.Exit_Date__c = TestDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
			wizard.studentsToProcess.clear();
			wizard.studentsToProcess.put(sTest.id,new Scheduler_SectionWizard.ScheduleWrapper(sTest,null));
			wizard.withdrawStudents();
			System.assert(ApexPages.hasMessages());
			System.assert(sTest.active__c);
			
			//should have all necessary information now--everything should run smoothly
			sTest.Exit_Reason__c = 'NI (No Information)';
			sTest.Student_Exit_Reason__c = CT_core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
			wizard.studentsToProcess.clear();
			wizard.studentsToProcess.put(sTest.id,new Scheduler_SectionWizard.ScheduleWrapper(sTest,null));
			wizard.withdrawStudents();
			//no errors
			//student should be inactive now
			System.assert(!sTest.Active__c);
			//oldExamples should be inactive as well
			for(Student_Section__c ss: [SELECT id,Active__c FROM Student_Section__c WHERE Student__c=:sTest.id]) System.assert(!ss.Active__c);
			//should erase the studentsToProcess map
			System.assertEquals(wizard.studentsToProcess.size(),0);
			//should redirect to original page as if refreshed
			System.assert(wizard.page1);
			System.assert(!wizard.page2);
			System.assert(!wizard.page3);
			System.assert(!wizard.results);
			System.assert(!wizard.newStuds);
			System.assert(!wizard.oldStuds);
		
		Test.stopTest();
	}

	static testMethod void testSaveGroupsNewStudent(){
		setup();
		List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
		//groups[0] has 3 sections, groups[1] has 2 sections
		List<Scheduled_Section__c> schsec = TestDataSetupUtil_v2.createScheduledSections(groups);
		List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
		
		Test.startTest();
		
			wizard.groupBased = true;
			wizard.groupsByGrade = wizard.organizeListByGrade(groups);
			
			Student__c newStud = new Student__c(
				Student_First_Name__c='test',
				Student_Last_Name__c='ing',
				Date_of_Birth__c=Date.newInstance(1995,10,10),
				Gender__c='F',
				Race_Multi__c='Asian',
				Entry_Date__c=testDataSetupUtil_v2.semester.date_start_date__c,
				Student_Id__c='444333222111',
				Grade__c='5'
			);
			wizard.studentToAdd.stud = newStud;
			wizard.studentToAdd.chosen = groups[0].id;
			wizard.studentToAdd.dateOfBirth='10/10/1995';
			wizard.selectedGrade = '5';
			wizard.newStudent();
			
			List<Section__c> avail = TestDataSetupUtil_v2.getGroupsFromSelectOptions_Sections(wizard.studentsToProcess.get(newStud.id).available);
			for(Section__c sg: avail) System.assert(sg.All_Grades__c.contains(newStud.Grade__c));
			
			wizard.saveGroups();

			System.assert(!wizard.page1);
			System.assert(wizard.page2);
			System.assert(!wizard.page3);
			System.assert(!wizard.results);
			System.assert(!wizard.newStuds);
			System.assert(!wizard.oldStuds);
			
			System.assertEquals(newStud.Primary_Schedule_Group__c,groups[0].id);
		
		Test.stopTest();
		//make sure all the right student sections were added
		List<Student_Section__c> ss = [SELECT id,Section__c,Active__c FROM Student_Section__c WHERE Student__c=:newStud.id and Section__r.RecordType.DeveloperName!='Schedule_Group'];
		//since student added to group[0], should have 3 student sections\
		System.assertEquals(ss.size(),3);
		//map section IDs to student sections (just need section IDs to assert the right sections were added)
		Map<Id,Student_Section__c> sectionsToSS = new Map<Id,Student_Section__c>();
		for(Student_Section__c s: ss){
			sectionsToSS.put(s.Section__c,s);
			//assert that all of the new student sections are active
			System.assert(s.Active__c);
		}
		//assert that the correct sections were added
		System.assert(sectionsToSS.containsKey(sections[0].id));
		System.assert(sectionsToSS.containsKey(sections[1].id));
		System.assert(sectionsToSS.containsKey(sections[2].id));
		
	}

	static testMethod void testSaveGroups(){
		setup_WithoutStudentSections();

		SchoolForce_Settings__c sfs;
		if (SchoolForce_Settings__c.getOrgDefaults()==null){
			sfs = new SchoolForce_Settings__c(Triggers_Disabled__c=true);
		}
		else sfs=SchoolForce_Settings__c.getOrgDefaults();
		sfs.Triggers_Disabled__c=true;
		upsert sfs;
		
		List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
		sfs.Triggers_Disabled__c=false;
		update sfs;
		List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
		System.debug('\n\n sections => ' + sections + '\n');
		List<Student__c> students = TestDataSetupUtil_v2.studentsList;
		wizard.groupBased = true;
		
		//create SelectOptions
		List<SelectOption> groupOptions = new List<SelectOption>();
		for(Section__c sec: groups) groupOptions.add(new SelectOption(sec.id,sec.Name));
		//create old records for two students (treating them like new students and adding them to a group)
		Scheduler_SectionWizard.ScheduleWrapper sw1 = new Scheduler_SectionWizard.ScheduleWrapper(students[0],groupOptions);
		sw1.chosen = groups[0].id;
		Scheduler_SectionWizard.ScheduleWrapper sw2 = new Scheduler_SectionWizard.ScheduleWrapper(students[1],groupOptions);
		sw2.chosen = groups[1].id;
		wizard.studentsToProcess.put(students[0].id, sw1);
		wizard.studentsToProcess.put(students[1].id, sw2);
		Test.startTest();
			wizard.saveGroups();
			
			System.assertEquals(groups[0].id,sw1.stud.Primary_Schedule_Group__c);
			System.assertEquals(groups[1].id,sw2.stud.Primary_Schedule_Group__c);
			
			//switch the groups
			sw1.chosen = groups[1].id;
			sw1.oldGroup = sw1.stud.Primary_Schedule_Group__c;
			sw1.stud.Exit_Date__c = testDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
			sw2.chosen = groups[0].id;
			sw2.oldGroup = sw2.stud.Primary_Schedule_Group__c;
			sw2.stud.Exit_Date__c = testDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
			wizard.studentsToProcess.put(students[0].id, sw1);
			wizard.studentsToProcess.put(students[1].id, sw2);
			wizard.saveGroups();
		Test.stopTest();

		Student__c stud1 = testDataSetupUtil_v2.studentsList[0];
		Student__c stud2 = testDataSetupUtil_v2.studentsList[1];
		
		List<Student_Section__c> ss1 = [SELECT id,Section__c,Active__c, name FROM Student_Section__c WHERE Student__c=:stud1.id and Section__r.RecordType.DeveloperName!='Schedule_Group'];

		system.debug( ss1);
		//System.assertEquals(5,ss1.size());
		/*for(Student_Section__c ss: ss1){
			if(ss.Section__c==sections[0].id || ss.Section__c==sections[1].id || ss.Section__c==sections[2].id)
				System.assert(!ss.Active__c);
			else if(ss.Section__c==sections[3].id || ss.Section__c==sections[4].id)
				System.assert(ss.Active__c);
			else System.assert(false);
		}*/
	   
		
		//like above but reversed--originally in group[1], now in group[0]
		List<Student_Section__c> ss2 = [SELECT id,Section__c,Active__c FROM Student_Section__c WHERE Student__c=:stud2.id and Section__r.RecordType.DeveloperName!='Schedule_Group'];
		/*for(Student_Section__c ss: ss2){
			if(ss.Section__c==sections[0].id || ss.Section__c==sections[1].id || ss.Section__c==sections[2].id)
				System.assert(ss.Active__c);
			else if(ss.Section__c==sections[3].id || ss.Section__c==sections[4].id)
				System.assert(!ss.Active__c);
			else System.assert(false);
		}*/
		
		
		//assert page change will occur properly
		System.assert(wizard.page1);
		System.assert(!wizard.page2);
		System.assert(!wizard.page3);
		System.assert(!wizard.results);
		System.assert(!wizard.newStuds);
		System.assert(!wizard.oldStuds);
	}

	static testMethod void testSaveSectionsNewStudent(){
		setup_WithoutStudents();
		List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
		
		Student__c newStud = new Student__c(	Student_First_Name__c='test',
												Student_Last_Name__c='ing',
												Date_of_Birth__c=Date.newInstance(1995,10,10),
												Gender__c='F',
												Race_Multi__c='Asian',
												Entry_Date__c=testDataSetupUtil_v2.semester.date_start_date__c,
												Student_Id__c='444333222111',
												Grade__c='5',
												Active__c=true);
		wizard.studentToAdd.stud = newStud;
		wizard.studentToAdd.dateOfBirth='10/10/1995';
		wizard.selectedGrade = '5';
		wizard.newStudent();
		
		Test.startTest();
		
			//since the new student has no old student sections, this list should be empty
			System.assert(wizard.toRemove.isEmpty());
			//the number of new sections available should only include those available to the new student
			System.assertEquals(wizard.toAdd.size(),wizard.studentsToProcess.get(newStud.id).available.size());
			
			//choose some sections to add the new student to
			for(Scheduler_SectionWizard.secWrapper s: wizard.toAdd){
				if(s.sec.id==sections[0].id || s.sec.id==sections[3].id) {
					s.selected = true;
					s.ss.Enrollment_Start_Date__c = Date.today();
				}
			}
			
			//save, and assert that the student is now in those sections
			wizard.saveSections();
			
			//assert page change will occur properly
			System.assert(wizard.page1);
			System.assert(!wizard.page2);
			System.assert(!wizard.page3);
			System.assert(!wizard.results);
			System.assert(!wizard.newStuds);
			System.assert(!wizard.oldStuds);
			System.assert(wizard.studentsToProcess.isEmpty());
			
			List<Student_Section__c> newSS = [SELECT id,Section__c,Active__c FROM Student_Section__c WHERE Student__c=:newStud.id];
			//should only be 2 student sections for this student
			System.assertEquals(newSS.size(),2);
			//assert that the student sections are active
			for(Student_Section__c ss: newSS){
				if(ss.Section__c==sections[0].id) System.assert(ss.Active__c);
				else if(ss.Section__c==sections[3].id) System.assert(ss.Active__c);
				else System.assert(false);
			}
		
		Test.stopTest();
	}

	static testMethod void testSaveSections(){
		setup();
		List<Section__c> sections = TestDataSetupUtil_v2.sectionsList;
		List<Student__c> students = TestDataSetupUtil_v2.studentsList;
		//create SelectOption list
		List<SelectOption> sectionOptions = new List<SelectOption>();
		for(Section__c sec: sections) sectionOptions.add(new SelectOption(sec.id,sec.Name));
		
		//create old records for two students, who should already have student sections
		Scheduler_SectionWizard.ScheduleWrapper sw1 = new Scheduler_SectionWizard.ScheduleWrapper(students[0],sectionOptions);
		sw1.selected = true;
		Scheduler_SectionWizard.ScheduleWrapper sw2 = new Scheduler_SectionWizard.ScheduleWrapper(students[1],sectionOptions);
		sw2.selected = true;
		wizard.studentsToProcess.put(students[0].id, sw1);
		wizard.studentsToProcess.put(students[1].id, sw2);
		
		wizard.transfer();
		
		Test.startTest();
		
		Student_Section__c remove = [SELECT id, Active__c, Reference_ID__c FROM Student_Section__c 
			WHERE Student__c = :students[1].id AND Section__c = :sections[1].id LIMIT 1];
		
		Scheduler_SectionWizard.secWrapper sec = new Scheduler_SectionWizard.secWrapper(sections[3]);
		sec.selected = true;
		wizard.toAdd.add(sec);
		Scheduler_SectionWizard.ssWrapper studsec = new Scheduler_SectionWizard.ssWrapper(remove);
		studsec.selected = true;
		studsec.ss.Enrollment_End_Date__c = testDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
		wizard.toRemove.add(studsec);
		
		wizard.saveSections();
		
		//assert that both students were added to section[3]
		List<Student_Section__c> ss1 = [SELECT id,Section__c,Active__c FROM Student_Section__c WHERE Student__c=:students[0].id];
		for(Student_Section__c ss: ss1){
			if(ss.Section__c==sections[3].id) System.assert(ss.Active__c);
		}
		//only student[1] was removed from a section--make sure it is so
		List<Student_Section__c> ss2 = [SELECT id,Section__c,Active__c FROM Student_Section__c WHERE Student__c=:students[1].id];
		for(Student_Section__c ss: ss2){
			if(ss.Section__c==sections[3].id)
				System.assert(ss.Active__c);
			else if(ss.Section__c==sections[1].id)
				System.assert(!ss.Active__c);
		}
		
		//assert page change will occur properly
		System.assert(wizard.page1);
		System.assert(!wizard.page2);
		System.assert(!wizard.page3);
		System.assert(!wizard.results);
		System.assert(!wizard.newStuds);
		System.assert(!wizard.oldStuds);
		System.assert(wizard.studentsToProcess.isEmpty());
		
		Student__c s1 = new Student__c(Student_First_Name__c='Lucy', Student_Last_Name__c='Giles',Name='Lucy Giles');
		Student__c s2 = new Student__c(Student_First_Name__c='Mark', Student_Last_Name__c='Brown',Name='Mark Brown');
		Student__c s3 = new Student__c(Student_First_Name__c='Henry', Student_Last_Name__c='Williams',Name='Henry Williams');

		//create old records for two students, who should already have student sections
		 sw1 = new Scheduler_SectionWizard.ScheduleWrapper(s1,null);
		 sw2 = new Scheduler_SectionWizard.ScheduleWrapper(s2,null);
		Scheduler_SectionWizard.ScheduleWrapper sw3 = new Scheduler_SectionWizard.ScheduleWrapper(s3,null);
		
		List<Scheduler_SectionWizard.ScheduleWrapper> swList = new List<Scheduler_SectionWizard.ScheduleWrapper>();
		swList.add(sw1);
		swList.add(sw2);
		swList.add(sw3);
		
		
		swList = Scheduler_SectionWizard.sortList(swList);
		//first should be Brown
		System.assertEquals(swList[0],sw2);
		//then Giles
		System.assertEquals(swList[1],sw1);
		//then Williams
		System.assertEquals(swList[2],sw3);
		
		Test.stopTest();
	}

}