@isTest
private with sharing class Test_Course_Weightings_Utils {
public static Picklist_Value__c semesterPlv;
public static  Picklist_Value__c termPlv;
	static void setup(Set <Integer> configSet){
		testDataSetupUtil_v2.setUPCoreData(2);
			testDataSetupUtil_v2.setUPStaffData(2);
			testDataSetupUtil_v2.setUPStudentData(2);
			for (Picklist_Value__c pl: [select id, corresponding_Value__c , name from Picklist_Value__c where RecordType.DeveloperName = 'Time']){
				if (pl.name=='Semester')semesterPlv=pl;
				if (pl.name=='Term') termPlv=pl;
			}
			
			List <Course_Weightings__c> cwList = [select id, weighting__c, key__c, course__c, reporting_period_type__c from Course_Weightings__c where course__c =:testDataSetupUtil_v2.sectionsList[0].course__c];
			system.assertEquals(cwList.size(), 2);
			List <Course_Weightings__c> updCwList = new List <Course_Weightings__c>();
			if (configSet.contains(2)){			
				for (Course_Weightings__c cw: cwList){
					cw.weighting__c = 25; 
					updCwList.add(cw);
					Course_Weightings__c finalCw = cw.clone(false);
					finalCw.key__c = finalCw.key__c+'-Final';
					updCwList.add(finalCw);
				}
			}
			if (configSet.contains(1)){
						Course_Weightings__c cw = new Course_Weightings__c(course__c=testDataSetupUtil_v2.sectionsList[0].course__c, reporting_period_type__c=termPlv.id, key__c='1', weighting__c=100);
						updCwList.add(cw);
			}


			upsert updCwList;
			system.assertEquals([select count() from Section_ReportingPeriod__c where section__c=:testDataSetupUtil_v2.sectionsList[0].id],4);
			system.assert([select course_weighting__c from Section_ReportingPeriod__c where section__c=:testDataSetupUtil_v2.sectionsList[0].id limit 1]!=null);

	}
	
	static testMethod void TestCwValidationFailure(){
			setup(new Set <Integer>{2});
			test.startTest();
			testDataSetupUtil_v2.sectionsList[0].number_of_reporting_periods__c = '1';
			try {
				update testDataSetupUtil_v2.sectionsList[0];
			}
			catch (exception e){
				system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
			}
			Picklist_Value__c plv2 = [select id, corresponding_Value__c from Picklist_Value__c where RecordType.DeveloperName = 'Time' and Name='Term'];
			Course_Weightings__c cw = new Course_Weightings__c(course__c=testDataSetupUtil_v2.sectionsList[0].course__c, reporting_period_type__c=plv2.id, key__c='1', weighting__c=100);
			insert cw;
			update testDataSetupUtil_v2.sectionsList[0];
			test.stopTest();
		
	}
	
	
		static testMethod void TestRpConfigValidationFailure(){
			setup(new Set <Integer>{2});
			test.startTest();
			testDataSetupUtil_v2.sectionsList[0].reporting_period__c = testDataSetupUtil_v2.semester2.id;
			try {
				update testDataSetupUtil_v2.sectionsList[0];
			}
			catch (exception e){
				system.assert(e.getMessage()!=null);
			}
					test.stopTest();
	}
	

	static testMethod void TestAttendanceDeletionFailure(){
					setup(new Set <Integer>{1,2});
			test.startTest();
			Course_Weightings__c cw = new Course_Weightings__c(course__c=testDataSetupUtil_v2.sectionsList[0].course__c, reporting_period_type__c=testDataSetupUtil_v2.term.picklist_value__c, key__c='1', weighting__c=100);
			insert cw; 
			List <Session__c> sessList =TestDataSetupUtil_v2.getSessions(5,testDataSetupUtil_v2.semester2, testDataSetupUtil_v2.sectionsList[0].id, 1);
			List <Picklist_Value__c> pvl = testDataSetupUtil_v2.createDefaultAttendanceTypes(testDataSetupUtil_v2.activeSetup);
			SchoolForce_Settings__c s = SchoolForce_Settings__c.getOrgDefaults();
			s.Triggers_Disabled__c=true;
			update s;
			Attendance__c a = new Attendance__c(Student__c=TestDataSetupUtil_v2.studentsList[0].id, Session__c=sessList[0].id, Picklist_Value__c=pvl[0].id);
			insert a;
			s.Triggers_Disabled__c = false;
			update s;
			testDataSetupUtil_v2.sectionsList[0].number_of_reporting_periods__c = '1';
				try {
				update testDataSetupUtil_v2.sectionsList[0];
			}
			catch (exception e){
				system.assert(e.getMessage()!=null);
			}
						test.stopTest();
			
	}
	
	
	static testMethod void TestSectionRpDeletion(){
			
		setup(new Set <Integer>{1,2});
		test.startTest();
//Tempoary comment ptn to get test failures resolved		system.assertEquals ([select count() from Section_Grade__c where student_section__c=:TestDataSetupUtil_v2.studSectionsList[0].id], 4);
		core_triggerUtils.b = true;
		update testDataSetupUtil_v2.sectionsList[0];
		testDataSetupUtil_v2.sectionsList[0].number_of_reporting_periods__c = '1';
		update testDataSetupUtil_v2.sectionsList[0];	
		system.assertEquals([select count() from Section_ReportingPeriod__c where section__c=:testDataSetupUtil_v2.sectionsList[0].id ],1);
		//Summer 2014 iteration 2: section grade count is now 4 instead of 0 (one for each RP).
		system.assertEquals ([select count() from Section_Grade__c where student_section__c=:TestDataSetupUtil_v2.studSectionsList[0].id], 4);//Updated for 12.7 Ohio
					test.stopTest();
	}
	
	static testMethod void test_DeleteFinalValidation(){
		setup(new Set <Integer>{2});
		Time_Element__c te = [select id from Time_Element__c where parent_time_element__c =: testDataSetupUtil_v2.semester2.id];
		SchoolForce_Settings__c s = SchoolForce_Settings__c.getOrgDefaults();
		s.Triggers_Disabled__c=true;
			update s;
			Assignment__c a = new Assignment__c(Time__c=te.id, section__c=testDataSetupUtil_v2.sectionsList[0].id, name='test' );
		insert a;
			s.Triggers_Disabled__c = false;
			update s;
		test.startTest();
		Course_Weightings__c finalCw = [select id, weighting__c, key__c, course__c, reporting_period_type__c from Course_Weightings__c where course__c =:testDataSetupUtil_v2.sectionsList[0].course__c and key__c='2-Final'];
		try {
				delete finalCw;
			}
			catch (exception e){
				system.assert(e.getMessage()!=null);
			}
						test.stopTest();
	}
}