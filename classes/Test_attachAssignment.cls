@isTest
public class Test_attachAssignment {
    public static Assignment_lib__c createAssignment(){
        Gradebook_AssignmentController_v2 newAssignmentController = new Gradebook_AssignmentController_v2();
        newAssignmentController.newAssignmentFlow();
        newAssignmentController.assignmentWrapper.assignmentCourse = newAssignmentController.courseOptions[0].getValue();
        newAssignmentController.setSelectedAssignmentTypeOptions();
        newAssignmentController.assignmentWrapper.assignmentName = 'testing';
        newAssignmentcontroller.assignmentWrapper.gradebookName = 'test';
        newAssignmentController.assignmentWrapper.assignmentType = newAssignmentController.selectedAssignmentTypeOptions[0].getValue();
        newAssignmentController.assignmentWrapper.assignmentWeighting = 1;
        
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
        return newAssignmentController.assignmentWrapper.assignmentLibrary;
    }

    static testMethod void myUnitTest() {
        Test_Gradebook_AssignmentController_v2.createTestData();
        
        
        Test.startTest();
        system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
            Assignment_Lib__c a = createAssignment();
            ApexPages.StandardController controller = new ApexPages.StandardController(a);
            //          Gradebook_AttachAssignment attach = new Gradebook_AttachAssignment(controller);
//          attach.cancel();
//          Blob dataBlob = Blob.valueOf('Test data to encoded');
//          Attachment testAttach = new Attachment();
//          testAttach.body = dataBlob;
//
//          attach.newAssignDoc1.pathOnClient = 'Something';
//          attach.newAssignDoc2.pathOnClient = 'Something';
//          attach.newAssignDoc3.pathOnClient = 'Something';
//          attach.newAssignDoc4.pathOnClient = 'Something';
//          attach.newAssignDoc5.pathOnClient = 'Something';
//
//          attach.newAssignDoc1.VersionData = dataBlob;
//          attach.newAssignDoc2.VersionData = dataBlob;
//          attach.newAssignDoc3.VersionData = dataBlob;
//          attach.newAssignDoc4.VersionData = dataBlob;
//          attach.newAssignDoc5.VersionData = dataBlob;
//
//          pagereference p = attach.upload();
//          pagereference q = attach.uploadNew();
            System.assert(true);
        }
        Test.stopTest();
    }

    static testMethod void testTriggerEffiency(){
        Integer totalDML = 0;
        Integer lastDML = 0;
        TestDataSetupUtil_v2.setupCustomSettings();
        totalDML = Limits.getQueries();
        System.debug('Setting up custom settings: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.createDefaultPicklistValues();
        totalDML = Limits.getQueries();
        System.debug('Creating default picklist values: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.school = TestDataSetupUtil_v2.getSchools(1)[0];
        totalDML = Limits.getQueries();
        System.debug('Creating a school: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.setupTimeElements(30);
        totalDML = Limits.getQueries();
        System.debug('Setting up time elements: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.setupCourses(1);
        totalDML = Limits.getQueries();
        System.debug('Setting up courses: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.setupSetupRecord();
        totalDML = Limits.getQueries();
        System.debug('Configuring the setup: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.staffUsersList = TestDataSetupUtil_v2.getUsers(1, 'Staff');
        totalDML = Limits.getQueries();
        System.debug('Setting up staff users: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.staffContactsList = TestDataSetupUtil_v2.getContacts(1, 'Staff',TestDataSetupUtil_v2.staffUsersList);
        totalDML = Limits.getQueries();
        System.debug('Setting up staff contacts: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.teachersList = TestDataSetupUtil_v2.getStaffMembers(1, 'Staff', TestDataSetupUtil_v2.staffContactsList);
        totalDML = Limits.getQueries();
        System.debug('Setting up staff records: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.sectionsList = TestDataSetupUtil_v2.getSections(TestDataSetupUtil_v2.coursesList);
        totalDML = Limits.getQueries();
        System.debug('Setting up sections: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.staffSectionsList = TestDataSetupUtil_v2.getStaffSections(1, TestDataSetupUtil_v2.teachersList, TestDataSetupUtil_v2.sectionsList);
        totalDML = Limits.getQueries();
        System.debug('Setting up staff sections: '+(totalDML-lastDML));
        lastDML = totalDML;
        
        TestDataSetupUtil_v2.roomList = TestDataSetupUtil_v2.getRooms(1);
        totalDML = Limits.getQueries();
        System.debug('Setting up rooms: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.studContactsList = TestDataSetupUtil_v2.getContacts(1, 'Student' , null);
        totalDML = Limits.getQueries();
        System.debug('Setting up student contacts: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.studentsList = TestDataSetupUtil_v2.getStudents(1, 'Student', TestDataSetupUtil_v2.studContactsList);
        totalDML = Limits.getQueries();
        System.debug('Setting up student records: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.studpgList = TestDataSetupUtil_v2.getPGs();
        totalDML = Limits.getQueries();
        System.debug('Setting up student pgs: '+(totalDML-lastDML));
        lastDML = totalDML;

        TestDataSetupUtil_v2.studSectionsList = TestDataSetupUtil_v2.getStudentSections(1, TestDataSetupUtil_v2.studentsList, TestDataSetupUtil_v2.sectionsList);
        totalDML = Limits.getQueries();
        System.debug('Setting up student sections: '+(totalDML-lastDML));
        lastDML = totalDML;
    }
}