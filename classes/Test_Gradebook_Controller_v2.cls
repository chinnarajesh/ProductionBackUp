@isTest 
public class Test_Gradebook_Controller_v2 {
	public static Assignment__c assignment;
	public static Picklist_Value__c standardScale;
	
	public static void setupData() {
		TestDataSetupUtil_v2.isGradebook = true;
		testDataSetupUtil_v2.setUPCoreData(2);
		TestDataSetupUtil_v2.activeSetUp.Standards_ONLY_Gradebook__c=true;
		update TestDataSetupUtil_v2.activeSetUp;
		testDataSetupUtil_v2.setUPStaffData(2);
		testDataSetupUtil_v2.setUPStudentData(2);
		testDataSetupUtil_v2.createScalesNormalizations();
		standardScale = [select id, RecordTypeID from Picklist_Value__c where RecordType.DeveloperName='Grade_Scale' and Name='Standard' limit 1];
		
		standardScale.Category__c = 'Points';
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
		
		//testing only staff 1 and it's section
		testDataSetupUtil_v2.sectionsList[1].Record_Attendance__c = true;
		update testDataSetupUtil_v2.sectionsList[1];
        
	}
	
	public static void createAssignment() {
		Assignment_Lib__c al    = new Assignment_Lib__c();
		al.Picklist_Value__c = [select picklist_value__c from Default_Assignment_Weighting__c where course__c = :testDataSetupUtil_v2.sectionsList[1].course__c limit 1].picklist_value__c;
		insert al;
        picklist_value__c pick =new picklist_value__c();
        pick.Name='Standard';
        pick.RecordTypeId=Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Grade Scale').getRecordTypeId();
        insert pick;
		Assignment__c a = new Assignment__c(Time__c=testDataSetupUtil_v2.semester.id, section__c=testDataSetupUtil_v2.sectionsList[1].id, name='test2');		
		a.Assignment_Library__r = al;
		a.Assignment_Library__c = al.id;		
		//a.picklist_value__c = [select id from Picklist_value__c where  RecordType.DeveloperName = 'Grade_Scale'  AND Name ='Standard' limit 1 ].id;
		a.Picklist_Value__c=pick.id;
        a.Standard_Scale__c = a.Picklist_Value__c;
		a.Due_Date__c = testDataSetupUtil_v2.semester.Date_Start_Date__c;
		a.Name_in_Gradebook__c = 'Test2';
		a.Weighting_Value__c=1;
		insert a;
		assignment = a;
		
		Grade__c localGrade = new Grade__c (
			Student_Section__c = testDataSetupUtil_v2.studSectionsList[2].ID,
			Student__c = testDataSetupUtil_v2.studSectionsList[2].Student__c,
			Assignment__c = assignment.ID,
            Entered_Grade__c='B',
			Standards_Only_Grading__c = true,
			Include_In_Standard_Grade__c = true,
			Course__c = testDataSetupUtil_v2.sectionsList[1].course__c,
			Exclude_From_Section_Grade__c = !assignment.Include_In_Final_Grade__c,
			Time__c = assignment.Time__c,
			Standard_Times_Assignment__c = assignment.Weighting_Value__c,
			Assignment_Weighting__c = assignment.Weighting_Value__c
			);
		system.debug('*~*~* localGrade: ' + localGrade);
		insert localGrade;
       system.debug('##Assignment'+localGrade.Assignment__c);
	}
    
	static testMethod void initializeGB_v2() {
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			createAssignment();
			test.startTest();
			Gradebook_Controller_v2 gController = new Gradebook_Controller_v2();
			List<Enrollment_Tracking__c> anyET = [SELECT ID, active__c, current_record__c, end_Date__c, start_date__c, Student__c, Student_Section__c FROM Enrollment_Tracking__c];
			List<Staff_Section__c> anySS = [SELECT ID FROM Staff_Section__c WHERE Staff__c =: testDataSetupUtil_v2.teachersList[1].ID];
			system.assertEquals(true, anySS.size() > 0, 'there are no staff_section__c...');
			system.assertEquals(true, anyET.size() > 0, 'there are no enrollment tracking...');
			system.assertEquals(true, gController.loadedSchoolSection.studentOptions.size() > 0, 'no student options');
			system.assertEquals(true, gController.loadedSchoolSection.displaystudentWrapperKeys.size() > 0, 'loadedSchoolSection is empty: students ');						
			test.stopTest();	
		}
	}
	
	static testMethod void initializeGB_commonCalls() {
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			createAssignment();
			test.startTest();
			Gradebook_Controller_v2 gController = new Gradebook_Controller_v2();
			
			//base section ordering
			gController.resetSaveOrder();
			gController.saveSectionOrder();
			
			//common school/year combo call
			gController.getSchoolandYear();
			
			//redirects
			gController.newAssignmentPage();
			gController.xls();
			test.stopTest();	
		}
	}	
	
	static testMethod void testCommentMethods() {
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			createAssignment();
			test.startTest();
			Gradebook_Controller_v2 gController = new Gradebook_Controller_v2();
           
			Test.setCurrentPageReference(new PageReference('Page.Gradebook_v2'));
			String studentKey = gController.loadedSchoolSection.displayStudentWrapperKeys[0];
			system.debug('studentkey'+studentKey);
			//grade Comment
			String commentKey = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).assignmentDisplayWrapperList[0].gradeList[0].stringFilter;
			system.debug('##commentKey'+commentKey.split('_',2));
            
            List<string> newList = new List<string>(commentKey.split('_'));
            system.debug('##newList'+newList.remove(1));
            
            String commentListKey;
            integer count=0;
            for(string key:newList){
                system.debug('$$key'+key);
                if(count==1){
                  commentListKey+='_null';  
                }
                commentListKey+='_'+key;
                count++;
            }
            system.debug('##after'+commentListKey);
            commentListKey=commentListKey.removeStart('null_');
            system.debug('##nullremove'+commentListKey);
            system.debug('##commentKeys'+commentKey);
            Grade__c currentGrade = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).assignmentDisplayWrapperList[0].gradeList[0].mainGrade;
			system.debug('$$currentGrade'+currentGrade);
            System.currentPageReference().getParameters().put('commentGradeKey', commentKey);
			gController.getGradeComment();
            
			gController.commentGrade.Comment__c = 'Good job!';
			gController.submitGradeComment();
			
			//section Grade Comment
			string studentSSKey = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).stringFilter;
			System.currentPageReference().getParameters().put('sgCommentGradeKey', studentSSKey);
			gController.getSGComment();
			gController.sgCommentGrades.Comments_Next_Steps__c = 'Progress is good';
			//studentSection + reportingPeriod
			gController.sgCommentGrades.Key__c = String.valueOf(currentGrade.Student_Section__c)+ String.valueOf(currentGrade.Time__c);
			gController.submitSGComment();
			
			//get all Section Grade
			gController.getAllSGComment();
			Map<ID, String> testSGCommentEntry = new Map<ID, String>();
			testSGCommentEntry.put(gController.sgCommentGrades.ID, 'changing the text');
			Gradebook_Controller_v2.submitAllSGComment(testSGCommentEntry, testSGCommentEntry);
			/**/
           
			String gradeKey = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).assignmentDisplayWrapperList[0].gradeList[0].stringFilter;
            
            gradeKey=gradeKey.remove('_null');
            
            system.debug('endremove'+gradeKey);
            system.debug('studentKey'+studentKey);
			Map<String, String> testGradeEntry = new Map<String, String>();
			testGradeEntry.put(gradeKey, '90');
            system.debug('testGradeEntry'+testGradeEntry);
			Gradebook_Controller_v2.commitDML(testGradeEntry, true, true);
            Gradebook_Controller_v2.validate(testGradeEntry, false, false);
            Gradebook_Controller_v2.commitDML(testGradeEntry, true, false);
            Staff_Section__c section=[select id,name,Order__c from Staff_Section__c limit 1];
            Gradebook_Controller_v2.orderWrapper wrap = new Gradebook_Controller_v2.orderWrapper(section);
            wrap.order=string.valueOf(section.Order__c);
            wrap.staffSection=section;
            gController.saveSectionOrder();
            gController.buildOrderWrapper();
            List<Attendance__c> attendentList =[select id,name from Attendance__c limit 1];
              
            section__c section1 =[select id,name from section__c Limit 1];
            gController.sID=section1.id;
            Assignment__c ass=[select id,name from Assignment__c LIMIT 1];
            gController.assignmentID=ass.id;
            gController.getSection();
            String gradeKey2 = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).assignmentDisplayWrapperList[0].gradeList[0].stringFilter;

            Map<String, String> testGradeEntry2 = new Map<String, String>();
            testGradeEntry.put(gradeKey2, '90');
            Gradebook_Controller_v2.commitDML(testGradeEntry, false, false);
            Grade__c grad =[select id,name from Grade__c LIMIT 1];
            gController.fauxCommentGrade=grad;
            Gradebook_Wrapper_v2.standardWrapper wrapp = new Gradebook_Wrapper_v2.standardWrapper();
           // wrapp.standardID='328745845';
            wrapp.standardName='juturi';
           // wrapp.strandID='8573856';
            wrapp.strandName='rajesh';
            wrapp.longText='new text area';
            Gradebook_Wrapper_v2.standardDisplayWrapper newwrap= new Gradebook_Wrapper_v2.standardDisplayWrapper();
			test.stopTest();	
		}
	}
	
	static testMethod void commitGrades() {
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			createAssignment();
			test.startTest();
			Gradebook_Controller_v2 gController = new Gradebook_Controller_v2();
            Test.setCurrentPageReference(new PageReference('Page.Gradebook_v2'));
            
            system.debug('teststudentKey');
			String studentKey = gController.loadedSchoolSection.displayStudentWrapperKeys[0];
			String gradeKey = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).assignmentDisplayWrapperList[0].gradeList[0].stringFilter;
			system.debug('~~studentKey'+studentKey);
            system.debug('gradeKey'+gradeKey);
			Map<String, String> testGradeEntry = new Map<String, String>();
			testGradeEntry.put(gradeKey, '90');
            system.debug('testGradeEntry'+testGradeEntry);
			Gradebook_Controller_v2.commitDML(testGradeEntry, false, false);
            Gradebook_Controller_v2.validate(testGradeEntry, false, false);
            gController.getAllSGComment();
            gController.saveSectionOrder();
            Gradebook_Wrapper_v2.standardWrapper wrapp = new Gradebook_Wrapper_v2.standardWrapper();
            
			test.stopTest();	
		}
	}
	static testMethod void newcommitGrades() {
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			createAssignment();
			test.startTest();
			Gradebook_Controller_v2 gController = new Gradebook_Controller_v2();
            Test.setCurrentPageReference(new PageReference('Page.Gradebook_v2'));
            
            system.debug('teststudentKey');
			String studentKey = gController.loadedSchoolSection.displayStudentWrapperKeys[0];
			String gradeKey = gController.loadedSchoolSection.studentGradeWrapperMap.get(studentKey).assignmentDisplayWrapperList[0].gradeList[0].stringFilter;
			system.debug('~~studentKey'+studentKey);
            system.debug('gradeKey'+gradeKey);
			Map<String, String> testGradeEntry = new Map<String, String>();
			testGradeEntry.put(gradeKey, '90');
            system.debug('testGradeEntry'+testGradeEntry);
			Gradebook_Controller_v2.commitDML(testGradeEntry, true, false);
            Gradebook_Controller_v2.validate(testGradeEntry, false, false);
            
			test.stopTest();	
		}
	}
   
	static testMethod void quickCreateAssignment() {
		setupData();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			createAssignment();
			test.startTest();
			Gradebook_Controller_v2 gController = new Gradebook_Controller_v2();
			
			gController.openQCA();
	
			gController.gQCA.initializeQuickCreateAssignment();
			gController.gQCA.assignmentWrapper.assignmentName = 'quick Test';
			gController.gQCA.populateGradebookName();
			gController.gQCA.dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
			gController.gQCA.assignmentWrapper.assignmentType = gController.gQCA.assignmentTypeOptions[0].getValue();
			gController.gQCA.searchFeature.SOSLsearch = 'Test';
			gController.gQCA.searchFeature.SOSlsearchMethod();
			gController.gQCA.assignmentWrapper.attachAssignment = true;	
			
			gController.submitAssignment();
			//Gradebook_Wrapper_v2.standardWrapper wrapp = new Gradebook_Wrapper_v2.standardWrapper();
            //Gradebook_Wrapper_v2.standardDisplayWrapper newwrap= new Gradebook_Wrapper_v2.standardDisplayWrapper();
			test.stopTest();	
		}
	}	
}