@isTest
public class Test_Gradebook_AssignmentController_v2 {

    public static void createTestData() {
        TestDataSetupUtil_v2.isGradebook = true;
        TestDataSetupUtil_v2.setUPCoreData(3);
        TestDataSetupUtil_v2.setUpStaffData(5);
        TestDataSetupUtil_v2.setUpStudentData(5);      
        
        //missing this
        List<Grade_Scale_Catalog_Scale__c> gscsList = new List<Grade_Scale_Catalog_Scale__c>();
        for(ID gsID:TestDataSetupUtil_v2.scaleMap.values()){
            gscsList.add(new Grade_Scale_Catalog_Scale__c(Picklist_Value__c = gsID, Grade_Scale_Catalog__c = TestDataSetupUtil_v2.activeSetup.Grade_Scale_Catalog__c));
        }
        insert gscsList;
        
        
        Map <String, Id> sectionRtMap = core_SoqlUtils.getRecordTypesBySobject('Section__c');
        //create gradebook groups   
        //create section, staff/section, student/section
        //List<Section__c> sectionToUses = [SELECT ID, Course__c, All_Grades__c, (SELECT Student__c, Section__c FROM Student_Section__r), (SELECT Staff__c, Section__c FROM Staff_Section__r) FROM Section__c WHERE Is_Section__c = true AND Active__c = true];

        Section__c createGroup = new Section__c(
            Section__c = TestDataSetupUtil_v2.sectionsList[0].ID,
            Is_Section__c = false,
            Course__c = TestDataSetupUtil_v2.sectionsList[0].Course__c,
            Active__c = true,
            All_Grades__c = TestDataSetupUtil_v2.sectionsList[0].All_Grades__c,
            Name = 'testGroup0',
            RecordTypeId = sectionRtMap.get('Gradebook_Group'),
            Time__c = testDataSetupUtil_v2.masterYear.ID,
            School__c = testDataSetupUtil_v2.School.ID
        );
        insert createGroup;

        for(Staff_Section__c s:TestDataSetupUtil_v2.staffSectionsList){
            if(s.Section__c == TestDataSetupUtil_v2.sectionsList[0].ID){
                Staff_Section__c createGroupStaff = new Staff_Section__c(
                    Staff__c = s.Staff__c, 
                    Section__c = createGroup.ID, 
                    Is_Active__c = true);
                insert createGroupStaff;
                break;
            }
        }
        
        for(Student_Section__c s:TestDataSetupUtil_v2.studSectionsList){
            if(s.Section__c == TestDataSetupUtil_v2.sectionsList[0].ID){
                Student_Section__c createGroupStudent = new Student_Section__c(
                    Active__c = true, 
                    Student__c = s.Student__c, 
                    Section__c = createGroup.ID);
                insert createGroupStudent;
                break;
            }
        }
    }
    
    static testMethod void testSO_v2_addToGB() {
        createTestData();   
        Test.startTest(); 
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {              
            Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
            newAssignmentController.standardBased = true;
            newAssignmentController.standardOnly = true;
            newAssignmentController.newAssignmentFlow();
            string newsection='section';
            newAssignmentController.rPoints = true;
            newAssignmentController.validateSubmit(newsection);
            newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
            newAssignmentController.doNotAddStandards();
            newAssignmentController.newFlowChoice();
            newAssignmentController.submit();
            
            newAssignmentController.assignmentWrapper.createAssignmentLibrary();
            newAssignmentController.assignmentWrapper.createNewLibraryFromExisting();
            newAssignmentController.assignmentWrapper.assignmentName = 'testing';
            newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();
            newAssignmentController.rPoints=true;
            newAssignmentController.setSelectedAssignmentTypeOptions();
            newAssignmentController.setDefaultAssignmentWeighting();
            newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
            //search for standards
            newAssignmentController.searchFeature.attributeSearch='All';
            newAssignmentController.searchFeature.searchMethod();
            
            //select two standards
            newAssignmentController.searchFeature.searchStandardResults[0].selected = true;
            newAssignmentController.searchFeature.searchStandardResults[1].selected = true;
            newAssignmentController.searchFeature.addMethod();
            
            //remove one standard
            newAssignmentController.searchFeature.selectedStandardsList[0].selected = true;
            newAssignmentController.searchFeature.removeMethod();
            
            //selecting section or course
            newAssignmentController.sectionOrCourseChoice = 'section';
            newAssignmentController.newFlowChoice();
            newAssignmentController.renderPointsField();  //render just to get the call on page
            
            //ensure section assignment details are populated
            newAssignmentController.assignmentWrapper.attachAssignment = false;
            
            //select a section
            newAssignmentController.sections[0].selected = true;
            //select a reportingPeriod
            newAssignmentController.sections[0].reportingPeriod = testDataSetupUtil_v2.semester.ID;
            //select a dueDate
            newAssignmentController.sections[0].dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
            
            //hit submit!
            newAssignmentController.submit();
            newAssignmentController.rNew=true;
            newAssignmentController.rExisting=false;
            newAssignmentController.submitAndNew();
            Id devRecordTypeId = Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Assignment Assessment Type').getRecordTypeId();
            newAssignmentController.assessmentRecordType=devRecordTypeId;
             newAssignmentController.selectedAssignmentTypeOptions.add(null);
        }
        Test.stopTest();
    }
    
    static testMethod void testSO_v2_addToCourse() {
        createTestData();   
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {
            Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
            newAssignmentController.standardBased = true;
            newAssignmentController.standardOnly = false;
            newAssignmentController.newAssignmentFlow();
            newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
           
            newAssignmentController.assignmentWrapper.createAssignmentLibrary();
            newAssignmentController.assignmentWrapper.createNewLibraryFromExisting();
            newAssignmentController.assignmentWrapper.assignmentName = 'testing';
            newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();
            newAssignmentController.rPoints=true;
            newAssignmentController.setSelectedAssignmentTypeOptions();
            newAssignmentController.setDefaultAssignmentWeighting();
            newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
            //search for standards
            newAssignmentController.searchFeature.attributeSearch='All';
            newAssignmentController.searchFeature.searchMethod();
            
            //select two standards
            newAssignmentController.searchFeature.searchStandardResults[0].selected = true;
            newAssignmentController.searchFeature.searchStandardResults[1].selected = true;
            newAssignmentController.searchFeature.addMethod();
            
            //remove one standard
            newAssignmentController.searchFeature.selectedStandardsList[0].selected = true;
            newAssignmentController.searchFeature.removeMethod();
            
            //selecting section or course
            newAssignmentController.sectionOrCourseChoice = 'course';
            newAssignmentController.newFlowChoice();
            newAssignmentController.renderPointsField();  //render just to get the call on page
            
            //ensure section assignment details are populated
            newAssignmentController.assignmentWrapper.attachAssignment = false;

            //hit submit!
            newAssignmentController.submit();
           newAssignmentController.rNew=true;
            newAssignmentController.rExisting=false;
            newAssignmentController.submitAndNew();
           Id devRecordTypeId = Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Assignment Assessment Type').getRecordTypeId();
           newAssignmentController.assessmentRecordType=devRecordTypeId;
           newAssignmentController.selectedAssignmentTypeOptions.add(null);
           newAssignmentController.setGradebookName();
        }
        Test.stopTest();
    }   
    
    static testMethod void testhybrid_v2() {
        createTestData();
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {
            Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
            newAssignmentController.standardBased = true;
            newAssignmentController.standardOnly = false;
            newAssignmentController.newAssignmentFlow();
           newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
             newAssignmentController.assignmentWrapper.createAssignmentLibrary();
            newAssignmentController.assignmentWrapper.createNewLibraryFromExisting();
            newAssignmentController.assignmentWrapper.assignmentName = 'testing';
            
            newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();
            newAssignmentController.rPoints=true;
            newAssignmentController.setSelectedAssignmentTypeOptions();
            newAssignmentController.setDefaultAssignmentWeighting();
            newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
            //search for standards
            newAssignmentController.searchFeature.attributeSearch='All';
            newAssignmentController.searchFeature.searchMethod();
            
            //select two standards
            newAssignmentController.searchFeature.searchStandardResults[0].selected = true;
            newAssignmentController.searchFeature.searchStandardResults[1].selected = true;
            newAssignmentController.searchFeature.addMethod();
            
            //remove one standard
            newAssignmentController.searchFeature.selectedStandardsList[0].selected = true;
            newAssignmentController.searchFeature.removeMethod();
            
            //selecting section or course
            newAssignmentController.sectionOrCourseChoice = 'section';
            newAssignmentController.newFlowChoice();
            newAssignmentController.renderPointsField();  //render just to get the call on page
            
            //ensure section assignment details are populated
            newAssignmentController.assignmentWrapper.gradeScale = newAssignmentController.gradeScaleOptions[0].getValue();
            newAssignmentController.assignmentWrapper.standardGradeScale = newAssignmentController.standardScaleOptions[0].getValue();
            newAssignmentController.assignmentWrapper.attachAssignment = false;
            
            //select a section
            newAssignmentController.sections[0].selected = true;
            //select a reportingPeriod
            newAssignmentController.sections[0].reportingPeriod = testDataSetupUtil_v2.semester.ID;
            //select a dueDate
            newAssignmentController.sections[0].dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
            
            //hit submit! 
            newAssignmentController.rNew=true;
            newAssignmentController.rExisting=false;
            newAssignmentController.submitAndNew();
            Id devRecordTypeId = Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Assignment Assessment Type').getRecordTypeId();
            newAssignmentController.assessmentRecordType=devRecordTypeId;
            newAssignmentController.selectedAssignmentTypeOptions.add(null);
        }   
        Test.stopTest();            
    }
    
    static testMethod void testhybrid_v2_existing() {
        createTestData();
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {      
            Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
            newAssignmentController.standardBased = true;
            newAssignmentController.standardOnly = false;
            newAssignmentController.newAssignmentFlow();
            newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
             newAssignmentController.assignmentWrapper.createAssignmentLibrary();
            newAssignmentController.assignmentWrapper.createNewLibraryFromExisting();
            newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();  
            newAssignmentController.rPoints=true;
            newAssignmentController.setSelectedAssignmentTypeOptions();
            newAssignmentController.assignmentWrapper.assignmentName = 'testing';
            newAssignmentcontroller.assignmentWrapper.gradebookName = 'test';
            newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
            newAssignmentController.assignmentWrapper.assignmentWeighting = 1;          
            newAssignmentController.setDefaultAssignmentWeighting();
            //ensure section assignment details are populated
            newAssignmentController.assignmentWrapper.gradeScale = newAssignmentController.gradeScaleOptions[0].getValue();
            newAssignmentController.assignmentWrapper.standardGradeScale = newAssignmentController.standardScaleOptions[0].getValue();
            newAssignmentController.assignmentWrapper.attachAssignment = false;
            
            //select a section
            newAssignmentController.sections[0].selected = true;
            //select a reportingPeriod
            newAssignmentController.sections[0].reportingPeriod = testDataSetupUtil_v2.semester.ID;
            //select a dueDate
            newAssignmentController.sections[0].dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
            
            //hit submit! want this data
            //Test.startTest();
            //newAssignmentController.Submit();
            
            //instantiate GB, and then run the test
            pageReference setGBAssignmentCreation = new pageReference('/apex/Gradebook_AddAssignments_v2');
            Test.setCurrentPage(setGBAssignmentCreation);
            Gradebook_AssignmentController_v2 exist = new Gradebook_assignmentController_v2();
            
                exist.standardBased = true;
                exist.standardOnly = false;
                exist.existingAssignmentFlow();
                
                //search for assignments
                //exist.assignmentWrapper.courseSearch = exist.courseOptions[0].getLabel();
                exist.assignmentWrapper.courseSearch = 'All';
                exist.assignmentWrapper.assignmentTypeSearch = 'Any';
                exist.assignmentWrapper.searchMethod(); 
                
                //select first assignment, should be the one created before test.start
                //System.assert(exist.assignmentWrapper.searchAssignmentResults.size()==0,'Search failed to return a result. Clear test history and try again.');
//              setGBAssignmentCreation.getParameters().put('assignmentLibraryID', exist.assignmentWrapper.searchAssignmentResults[0].ID);
                exist.selectAssignment();
                
                //doNotUseStandards
                exist.doNotAddStandards();
                        
                //selecting section or course
                exist.sectionOrCourseChoice = 'course';
                exist.newFlowChoice();
                
                //ensure section assignment details are populated
                exist.assignmentWrapper.attachAssignment = false;
    
                //hit submit!
                exist.submit();                             
            Test.stopTest();            
        }   
                
    }       
    
    static testMethod void testTraditional_v2() {   
        createTestData();
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {      
            Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
            newAssignmentController.newAssignmentFlow();
            newAssignmentController.standardBased=true;
            newAssignmentController.standardOnly = true;
            newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
             newAssignmentController.assignmentWrapper.createAssignmentLibrary();
            newAssignmentController.assignmentWrapper.createNewLibraryFromExisting();
            newAssignmentController.assignmentWrapper.assignmentName = 'testing';
            newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();
             newAssignmentController.rPoints=true;
            newAssignmentController.setSelectedAssignmentTypeOptions();
            newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
            
            //selecting section or course
            newAssignmentController.sectionOrCourseChoice = 'section';
            newAssignmentController.newFlowChoice();
            newAssignmentController.renderPointsField();  //render just to get the call on page
            
            //ensure section assignment details are populated
            //select gradescales
            newAssignmentController.assignmentWrapper.gradeScale = newAssignmentController.gradeScaleOptions[0].getValue();
            newAssignmentController.assignmentWrapper.attachAssignment = false;
            
            //select a section
            newAssignmentController.sections[0].selected = true;
            //select a reportingPeriod
            newAssignmentController.sections[0].reportingPeriod = testDataSetupUtil_v2.semester.ID;
            //select a dueDate
            newAssignmentController.sections[0].dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
            
            //hit submit!
            newAssignmentController.Cancel();                       
        }   
        Test.stopTest();                
    }
    
    static testMethod void testTraditional_v2_existingToSection() { 
        createTestData();
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]) {      
            Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
            newAssignmentController.newAssignmentFlow();
            newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();
            newAssignmentController.rPoints=true;
            newAssignmentController.setSelectedAssignmentTypeOptions();
            newAssignmentController.assignmentWrapper.assignmentName = 'testing';
            newAssignmentcontroller.assignmentWrapper.gradebookName = 'test';
            newAssignmentController.standardBased=true;
            newAssignmentController.standardOnly = true;
            newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
             newAssignmentController.assignmentWrapper.createAssignmentLibrary();
            newAssignmentController.assignmentWrapper.createNewLibraryFromExisting();
            newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
            newAssignmentController.assignmentWrapper.assignmentWeighting = 1;
            newAssignmentController.addStandards();
            newAssignmentController.removeStandards();
            newAssignmentController.setDefaultAssignmentWeighting();
            //ensure section assignment details are populated
            //select gradescales
            newAssignmentController.assignmentWrapper.gradeScale = newAssignmentController.gradeScaleOptions[0].getValue();
            newAssignmentController.assignmentWrapper.attachAssignment = false;
            
            //select a section
            newAssignmentController.sections[0].selected = true;
            //select a reportingPeriod
            newAssignmentController.sections[0].reportingPeriod = testDataSetupUtil_v2.semester.ID;
            //select a dueDate
            newAssignmentController.sections[0].dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(1).format();
            
            //hit submit!, want this data
            //Test.startTest();
            newAssignmentController.Submit();
            
                //instantiate GB, then run the test
                pageReference setGBAssignmentCreation = new pageReference('/apex/Gradebook_AddAssignments_v2');
                Test.setCurrentPage(setGBAssignmentCreation);
                Gradebook_AssignmentController_v2 exist = new Gradebook_assignmentController_v2();
            
                exist.standardBased = false;
                exist.standardOnly = false;
                exist.existingAssignmentFlow();
                
                //search for assignments
                //exist.assignmentWrapper.courseSearch = exist.courseOptions[0].getLabel();
                exist.assignmentWrapper.courseSearch = 'All';
                exist.assignmentWrapper.assignmentTypeSearch = 'Any';
                exist.assignmentWrapper.searchMethod(); 
                
                //select first assignment, should be the one created before test.start

                //System.assert(exist.assignmentWrapper.searchAssignmentResults.size()==0);
//              setGBAssignmentCreation.getParameters().put('assignmentLibraryID', exist.assignmentWrapper.searchAssignmentResults[0].ID);
                exist.selectAssignment();
                        
                //selecting section or course
                exist.sectionOrCourseChoice = 'section';
                exist.newFlowChoice();
                
                //ensure section assignment details are populated
                //select gradescales
                exist.assignmentWrapper.gradeScale = newAssignmentController.gradeScaleOptions[0].getValue();
                exist.assignmentWrapper.attachAssignment = false;
                
                //select a section
//              exist.sections[0].selected = true;
//              //select a reportingPeriod
//              exist.sections[0].reportingPeriod = testDataSetupUtil_v2.semester.ID;
//              //select a dueDate
//              exist.sections[0].dueDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.addDays(2).format();
            
                //hit submit!
                exist.submit();             
            Test.stopTest();                        
        }           
    }   
}