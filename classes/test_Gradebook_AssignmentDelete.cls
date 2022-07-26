@isTest
private class test_Gradebook_AssignmentDelete {

	public static Assignment__c testAssign;
	public static Grade__c standardGrade;
	public static Grade__c fakeGrade;
	public static Standard__c stand;
	public static Strand_Grade__c strandGrade;
	public static Picklist_Value__c standardScale;

	static void setupData(){
		TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		TestDataSetupUtil_v2.activeSetUp.Standards_ONLY_Gradebook__c=true;
		update TestDataSetupUtil_v2.activeSetUp;
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();
		standardScale = [select id, RecordTypeID from Picklist_Value__c where RecordType.DeveloperName='Grade_Scale' and Name='Standard' limit 1];
		
		standardScale.Category__c = 'Standards';
		update standardScale;
		//Summer 2014: iteration 2;
		//insert some grade normalizations for standardScale, just in case
		List<Grade_Normalization__c> gns = new List<Grade_Normalization__c>();
		gns.add(new Grade_Normalization__c(Picklist_Value__c = standardScale.ID, Transformed_Grade__c = '1.0', Grade_Value__c = 50, GP_Value__c = 1.0));
		gns.add(new Grade_Normalization__c(Picklist_Value__c = standardScale.ID, Transformed_Grade__c = '2.0', Grade_Value__c = 70, GP_Value__c = 2.0));
		gns.add(new Grade_Normalization__c(Picklist_Value__c = standardScale.ID, Transformed_Grade__c = '3.0', Grade_Value__c = 80, GP_Value__c = 3.0));
		gns.add(new Grade_Normalization__c(Picklist_Value__c = standardScale.ID, Transformed_Grade__c = '4.0', Grade_Value__c = 90, GP_Value__c = 4.0));
		insert gns;
		
		for (Course__c c: testDataSetupUtil_v2.coursesList){
			c.grade_scale_lookup__c = standardScale.id;
		}
		update testDataSetupUtil_v2.coursesList;
	} 

	public static void createAssignment(){
		Assignment_Lib__c al    = new Assignment_Lib__c();
		al.Picklist_Value__c = [select picklist_value__c from Default_Assignment_Weighting__c where course__c = :testDataSetupUtil_v2.sectionsList[0].course__c limit 1].picklist_value__c;
		insert al;
		Assignment__c a = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
		a.Assignment_Library__r = al;
		a.Assignment_Library__c = al.id;		
		a.picklist_value__c = [select id from Picklist_value__c where  RecordType.DeveloperName = 'Grade_Scale'  AND Name ='Standard' limit 1 ].id;
		a.Standard_Scale__c = a.Picklist_Value__c;
		a.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		a.Name_in_Gradebook__c = 'Test1';
		a.Weighting_Value__c=1;
		insert a;
		testAssign = a;
		stand=[select id, Name, Long_Text__c from Standard__c where strand__c !=null limit 1];
		strandGrade = createStrandGrade(testDataSetupUtil_v2.semester.id, testDataSetupUtil_v2.studentsList[0].id, testDataSetupUtil_v2.strandStandard.id);
		Standard_Grade__c standGrade = createStandardGrade ( testDataSetupUtil_v2.studentsList[0].id,stand.id);
		createGrade_Standard(a,strandGrade, stand, testDataSetupUtil_v2.studSectionsList[0]);
	}

	public static void createGrade_Standard(Assignment__c a, Strand_Grade__c sg, Standard__c standard,  Student_Section__c ss){
		Grade__c g= new Grade__c(
		Standards_Only_Grading__c = true,
		exclude_From_Section_Grade__c = false,
		Student__c = ss.Student__c,
		Course__c = testDataSetupUtil_v2.coursesList[0].id,
		Time__c = a.Time__c,
		Assignment__c = a.id,
		Student_Section__c = ss.id,
		Assignment_Weighting__c = a.Weighting_Value__c,
		Standard_Times_Assignment__c = a.Weighting_Value__c,
		Valid_grade__c=true
		);
		fakeGrade = g.clone(false);
		//fakeGrade.Strand_Grade__c = sg.Id;
		fakeGrade.Standard__c = standard.Id;
		fakeGrade.Standard_Weighting__c=1;	
		fakeGrade.Include_In_Standard_Grade__c = true;

		fakeGrade.Standard_Times_Assignment__c = fakeGrade.Standard_Weighting__c*a.Weighting_Value__c;
			SchoolForce_Settings__c sf = SchoolForce_Settings__c.getOrgDefaults();
			sf.triggers_disabled__c = true;
			update sf;
			system.debug('fakeGrade~~~'+fakeGrade);
			insert fakeGrade;
			g.Standard_Gradebook_Grade__c=fakeGrade.id;
						sf.triggers_disabled__c = false;
			update sf;
			insert g;
			standardGrade = g;
	}

	public	static Strand_Grade__c createStrandGrade(Id rpId, Id StudentId, Id Strand){
		Strand_Grade__c sg = new Strand_Grade__c();
		sg.Reporting_Period__c=rpId;
		sg.Student__c =studentId;
		sg.Strand__c=strand;
		insert sg;
		return sg;
	}
	public	static Standard_Grade__c createStandardGrade( Id StudentId, Id Standard){
		Standard_Grade__c sg = new Standard_Grade__c();
		//sg.Reporting_Period__c=rpId;
		sg.Student__c =studentId;
		sg.Standard__c=Standard;
		sg.key__c = studentId+''+Standard;
		insert sg;
		return sg;
	}
	public static Section_Standard__c createSectionStandard(Id SectionId, Id Standard){
		Section_Standard__c ss = new Section_Standard__c();
		ss.Standard__c =Standard;
		ss.Section__c=SectionId;
		insert ss;
		return ss;
	}

	
	static testMethod void testAssignmentLibTypeChance(){
				//Check to make sure can't change assignment library assignment Type
		setupData();
		createAssignment();
		test.startTest();
		Assignment_Lib__c al = [select id, picklist_value__c from Assignment_Lib__c where id =:testAssign.Assignment_Library__c];
		al.picklist_value__c = null;
		boolean bError = false;
		try {
			update al;
		}
		catch (exception e){bError = true;}
		system.assert(bError);
		test.stopTest();
	}
	

	static testMethod void testAssignmentDelete(){
		setupData();

		test.startTest();
			createAssignment();
			system.assertNotEquals(0, [select count() from Grade__c where student_section__r.section__c=:testDataSetupUtil_v2.sectionsList[0].id]);//there best be grades son
			delete [select id from Assignment__c where id =:testAssign.Id];	
		test.stopTest();
		system.assertEquals(0, [select count() from Grade__c where student_section__r.section__c=:testDataSetupUtil_v2.sectionsList[0].id]); // i killed ya off bros
	}
	
	
	static testMethod void testStrandGradeDelete(){
		setupData();  
		
		
		test.startTest();
		createAssignment();
		Standard__c strand2 = testDataSetupUtil_v2.strandStandard.clone(false);
		insert strand2;
		Assignment__c testAssign2 = testAssign.clone(false);
		insert testAssign2;
		Strand_Grade__c sg2 = createStrandGrade(testDataSetupUtil_v2.semester.id, testDataSetupUtil_v2.studentsList[0].id, strand2.id);

		delete [select id from Assignment__c where id =:testAssign.Id];	
		test.stopTest();
	}
	
	
	
	static testMethod void testStandardGradeDelete(){
		setupData();  
		
		test.startTest();
		createAssignment();
		Standard__c stand2 = [select id from STandard__c where id !=:fakeGrade.standard__c limit 1];
		
		Assignment__c testAssign2 = testAssign.clone(false);
		insert testAssign2;
		Standard_Grade__c sg2 = createStandardGrade( testDataSetupUtil_v2.studentsList[0].id, stand2.id);
		delete [select id from Assignment__c where id =:testAssign.Id];	
		test.stopTest();
		
	}
	
	static testMethod void testSectionStandardDelete(){
		setupData();  

		test.startTest();
		createAssignment();
		Standard__c stand2 = [select id from Standard__c where id !=:fakeGrade.standard__c limit 1];

		Assignment__c testAssign2 = testAssign.clone(false);
		insert testAssign2;
		Section_Standard__c ss2 = createSectionStandard( testDataSetupUtil_v2.sectionsList[0].id, stand2.id);
	
		delete [select id from Assignment__c where id =:testAssign.Id];	
		test.stopTest();
	}
	
	static testMethod void testSectionGradeDelete(){
		setupData();
		createAssignment();
		system.assertEquals(2, [select count() from Section_Grade__c where student_section__c=:testDataSetupUtil_v2.studSectionsList[0].id ]);
		test.startTest();
		delete [select id from Assignment__c where id =:testAssign.Id];	
		test.stopTest();
		//Summer 2014: iteration 2 - deleting assignments does not necessarily should delete the section grade.  
		//system.assertEquals(0, [select count() from Section_Grade__c where student_section__c=:testDataSetupUtil_v2.studSectionsList[0].id ]);
	}
	
	
		static testMethod void testAssignmentGsChanges(){
		setupData();
		createAssignment();
				SchoolForce_Settings__c sf = SchoolForce_Settings__c.getOrgDefaults();
			sf.triggers_disabled__c = true;
			update sf;
			fakeGrade.Entered_Grade__c = '1';
			update fakeGrade;
			sf.triggers_disabled__c = false;
			update sf;
		test.startTest();
		try {
			testAssign.picklist_Value__c = null;
			update testAssign;
		}
		catch (exception e){
			system.assert(e.getMessage()!=null);
		}
		
		Id newGsId = [select id from Picklist_Value__c where recordType.DeveloperName='Grade_Scale' and name ='Points' limit 1].id;
		testAssign.picklist_Value__c = newGsId;
		testAssign.Possible_Points__c = 10;	
		try {
			update testAssign;
		}
		catch (exception e){
			system.assert(e.getMessage()!=null);
		}
		
			sf.triggers_disabled__c = true;
			update sf;
			fakeGrade.Entered_Grade__c = null;
			update fakeGrade;
			sf.triggers_disabled__c = false;
			update sf;
		
			update testAssign;

		
		test.stopTest();
		system.assertEquals(newGsId, [select picklist_Value__c  from Assignment__c where id=:testAssign.id].picklist_Value__c);
		}

	static testMethod void testGradeRecalc(){
		setupData(); 
		createAssignment();
		test.startTest();
			standardGrade.entered_grade__c = '3.0';
			update standardGrade;

			Assignment_Lib__c al    = new Assignment_Lib__c();
			al.Picklist_Value__c = [select picklist_value__c from Default_Assignment_Weighting__c where course__c = :testDataSetupUtil_v2.sectionsList[0].course__c limit 1].picklist_value__c;
			insert al;
			Assignment__c a = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );		
			a.Assignment_Library__r = al;
			a.Assignment_Library__c = al.id;		
			a.picklist_value__c = [select id from Picklist_value__c where  RecordType.DeveloperName = 'Grade_Scale'  AND Name ='Standard' limit 1 ].id;
			a.Standard_Scale__c = a.picklist_value__c;
			a.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
			a.Name_in_Gradebook__c = 'Test1';
			a.Weighting_Value__c=1;
			insert a; 

			strandGrade = createStrandGrade(testDataSetupUtil_v2.semester.id, testDataSetupUtil_v2.studentsList[0].id, testDataSetupUtil_v2.strandStandard.id);
			Standard_Grade__c standGrade = createStandardGrade ( testDataSetupUtil_v2.studentsList[0].id,standardGrade.Standard__c);
			createGrade_Standard(a,strandGrade, new Standard__c(id=standardGrade.Standard__c), testDataSetupUtil_v2.studSectionsList[0]);
			standardGrade.entered_grade__c = '2.0';

			update standardGrade;

			//need to clear the grade so we can test the assignment delete
			standardGrade.Entered_Grade__c = '';
			update standardGrade;
		test.stopTest();
		system.debug('sg~~'+[select Letter_Grade__c, Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Name from Section_Grade__c where student_section__c=:testDataSetupUtil_v2.studSectionsList[0].id ]);
	}
}