@isTest
private class Test_IndicatorAreasController {
	private static List<Student__c> students;
	private static Account school;
	private static IndicatorAreasController  iac;

	static void setupData(){
		TestDataUtil.setupTime();
		school = TestDataUtil.createSchool('ApexTest School');
		insert school;
		TestDataUtil.schoolList.add(school);
		TestDataUtil.setupSetupRecord();
		students = TestDataUtil.createStudents(10, school);
		insert students;

		List<Indicator_Area__c> ia = TestDataUtil.createIndicatorAreas();
		insert ia;
	}

	static void initialize(){
		iac = new IndicatorAreasController();
		iac.SchoolFilterParam = school.id;
		iac.changeSchool();
	}


	static testMethod void testConstructor() {
		Test.startTest();
			iac = new IndicatorAreasController();
			system.assert(!iac.hasUnsavedChanges);
			system.assertEquals(0,iac.sites.size());
			system.assertEquals(0,iac.schools.size());
			system.assertEquals(0,iac.areas.size());

			setupData();
			iac = new IndicatorAreasController();
			system.assertEquals(1,iac.sites.size());
			system.assertEquals(1,iac.schools.size());
			system.assertEquals(4,iac.areas.size());
		Test.stopTest();
	}

	static testMethod void testFilterSchools() {
		setupData();
		Test.startTest();
			initialize();
			system.assertEquals(students.size(),iac.studentsFiltered.size());
		Test.stopTest();
	}

	static testMethod void testFilterGrades() {
		setupData();
		for(integer i=0; i<5; i++) students[i].Grade__c = '4';
		update students;

		Test.startTest();
			initialize();

			iac.selectedGrade = '4';
			iac.filterGrades();
			system.assertEquals(5,iac.StudentsFiltered.size());
			iac.selectedGrade = 'all';
			iac.filterGrades();
			system.assertEquals(students.size(),iac.StudentsFiltered.size());
			iac.selectedGrade = '8';
			iac.filterGrades();
			system.assertEquals('There are no students available using your filters. Please check your filters.',ApexPages.getMessages()[0].getSummary());
		Test.stopTest();
	}

	static testMethod void testLoadGradeLevels() {
		setupData();
		for(integer i=0; i<5; i++) students[i].Grade__c = '4';
		update students;

		Test.startTest();
			initialize();

			iac.loadGradeLevels(new Set<String>{'4','5'});
			system.assertEquals(3,iac.gradeLevels.size());
			iac.loadGradeLevels(new Set<String>{'4','5','notagrade'});
			system.assertEquals(3,iac.gradeLevels.size());
		Test.stopTest();
	}

	static testMethod void testSelectStudent() {
		setupData();
		Test.startTest();
			initialize();

			iac.selectStudent();
			system.assertEquals('No students selected.',ApexPages.getMessages()[0].getSummary());

			iac.selectStudentParam = students[0].id;
			iac.selectStudent();
			system.assertEquals(1,iac.selected.size());

			iac.selectStudentParam = students[0].id+';'+students[1].id;
			iac.selectStudent();
			system.assertEquals(2,iac.selected.size());
		Test.stopTest();
	}

	static testMethod void testAddPrep() {
		setupData();
		Test.startTest();
			initialize();

			iac.selectStudentParam='';
			for(Student__c stud: students){
				if(iac.selectStudentParam!='') iac.selectStudentParam+=';';
				iac.selectStudentParam+=stud.id;
			}
			iac.selectStudent();

//			iac.addPrep();
//			String prevName = '';
//			for(IndicatorAreasController.StudentWrapper stud: iac.addTo.values()){
//				if(prevName!='') system.assert(prevName<=stud.student.Student_Last_Name__c);
//				prevName = stud.student.Student_Last_Name__c;
//			}
		Test.stopTest();
	}

	static testMethod void testResetPage() {
		setupData();
		Test.startTest();
			initialize();

			PageReference pr = iac.resetPage();
			system.assert(pr.getURL().contains('IM_Indicator_Areas'));
		Test.stopTest();
	}

	static testMethod void testGetIAList() {
		setupData();
		Test.startTest();
			iac = new IndicatorAreasController();
			List<SelectOption> areas = iac.getIAList();
			system.assertEquals(4,iac.areas.size());
		Test.stopTest();
	}

	static testMethod void testUpdateStudents() {
		setupData();
		Test.startTest();
			initialize();
			iac.selectStudentParam = students[0].id+';'+students[1].id;
			iac.selectStudent();
//			iac.addPrep();

			Indicator_Area__c ia = [SELECT id FROM Indicator_Area__c limit 1];
            List<id> newlist = new List<id>();
            newlist.add(ia.id);
			//verify no IA/S already exist
			system.assertEquals(null,iac.StudentWrapperMap.get(students[0].id).areaIds.get(ia.id));
			system.assertEquals(null,iac.StudentWrapperMap.get(students[1].id).areaIds.get(ia.id));

			iac.activeIAId = newlist;
			iac.updateStudents();
			system.assertNotEquals(null,iac.StudentWrapperMap.get(students[0].id).areaIds.get(ia.id));
			system.assertNotEquals(null,iac.StudentWrapperMap.get(students[1].id).areaIds.get(ia.id));
			system.assert(iac.hasUnsavedChanges);
			//should not be committed to database
			List<Indicator_Area_Student__c> ias = [SELECT id FROM Indicator_Area_Student__c];
			system.assertEquals(0,ias.size());
		Test.stopTest();
	}

	static testMethod void testSaveChanges() {
		setupData();
		Test.startTest();
			initialize();
			iac.selectStudentParam = students[0].id+';'+students[1].id;
			iac.selectStudent();
//			iac.addPrep();

			Indicator_Area__c ia = [SELECT id FROM Indicator_Area__c limit 1];
            List<id> arealist = new List<id>();
            arealist.add(ia.id);
			iac.activeIAId = arealist;
			iac.updateStudents();
			iac.saveChanges();
			//saving commits changes to database, so they should be query-able now
			List<Indicator_Area_Student__c> ias = [SELECT id FROM Indicator_Area_Student__c];
			system.assertEquals(0,ias.size());
		Test.stopTest();
	}
	
}