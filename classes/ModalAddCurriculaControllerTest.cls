/**
 * Created by YuriyRudenko on 9/30/2020.
 */
@IsTest
public with sharing class ModalAddCurriculaControllerTest {
    private static Skill__c skill;
    public static Student_Section__c studentSections;
    private static final Integer COUNT = 5;
    private static final Integer AMOUNT = 30;

    private static void setupData() {
        testDataSetupUtil_v2.setUPCoreData(COUNT);
        testDataSetupUtil_v2.setUPStaffData(COUNT);
        testDataSetupUtil_v2.setUPStudentData(COUNT);
        testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
        testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);
        testDataSetupUtil_v2.setUpCurriculumData(COUNT);


        List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
    }

    static testMethod void testStartAddCurricula() {
        setupData();
        Test.startTest();
        ModalAddCurriculaController controller = new ModalAddCurriculaController();
        controller.section = testDataSetupUtil_v2.sectionsList[0];
        StudentInfoWrapper siw = new StudentInfoWrapper(testDataSetupUtil_v2.studSectionsList[0]);
        controller.studentSections = new List<StudentInfoWrapper>{
                siw
        };
        controller.studentSections[0].selected = true;
        controller.startAddCurricula();
        System.assertEquals(1, controller.curriculumStudents.size(), 'Expected all enrolled students to be loaded.');
        controller.curriculumStudents = new List<Curriculum__c>{
                controller.curriculum
        };

        controller.saveCurricula();
        controller.curriculum.Date_of_Module__c = null;
        controller.saveCurricula();
        controller.curriculum.Date_of_Module__c = Date.today();
        controller.curriculum.Curriculum_Name__c = 'test';
        controller.curriculum.Module_Name__c = '';
        controller.saveCurricula();
        controller.curriculum.Module_Name__c = 'test';
        controller.curriculum.Module_Assignments__c = '';
        controller.saveCurricula();
        controller.curriculum.Module_Assignments__c = 'test';
        controller.saveCurricula();
        controller.curriculumStudents[0].Module_Score__c = 21.1;
        controller.saveCurricula();

        Test.stopTest();
    }


    static testMethod void testStartEditCurricula() {
        setupData();

        Test.startTest();
        ModalAddCurriculaController controller = new ModalAddCurriculaController();
        StudentInfoWrapper siw = new StudentInfoWrapper(testDataSetupUtil_v2.studSectionsList[0]);
        controller.studentSections = new List<StudentInfoWrapper>{
                siw
        };
        controller.curriculumId = testDataSetupUtil_v2.curriculumList[0].Id;
        controller.startEditCurricula();
        System.assertEquals(1, controller.curriculumStudents.size(), 'Expected all enrolled students to be loaded.');
        Test.stopTest();
    }
}