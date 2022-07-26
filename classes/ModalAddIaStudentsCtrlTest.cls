/**
 * Created by YuriyRudenko on 10/1/2020.
 */
@IsTest
public class ModalAddIaStudentsCtrlTest {
    private static final Integer COUNT = 5;

    private static void setupData() {
        testDataSetupUtil_v2.setUPCoreData(COUNT);
        testDataSetupUtil_v2.setUPStaffData(COUNT);
        testDataSetupUtil_v2.setUPStudentData(COUNT);
        testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
    }

    static testMethod void testSaveIAToStudents() {
        setupData();
        Section__c sectionwithRelatedList =
        [SELECT Id, Name, Start_Date__c, Program__c, Intervention_Primary_Staff__c, End_Date__c,
                School__c, Active__c, School__r.Name, Time__r.Name__c, Program__r.Indicator_Area__r.Id,
                Program__r.Indicator_Area__r.Name, RecordTypeID, RecordType.Name, Account_Program__r.Name,
                In_After_School__c,
        (SELECT Active__c, Student__c, Student__r.Id, Student__r.Name,  Student_Name__c, Student_Grade__c,
                Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c,
                Section__c, Dosage_to_Date__c, Intervention_Enrollment_Start_Date__c,
                Enrollment_Start_Date__c, Enrollment_End_Date__c
        FROM Student_Section__r
        ORDER BY Student__r.Student_First_Name__c ASC LIMIT 1000),
        (SELECT Is_Active__c, Staff__r.Name, Intervention_Primary_Staff__c
        FROM Staff_Section__r)
        FROM Section__c
        WHERE Id =:testDataSetupUtil_v2.sectionsList[0].Id];
        List<Student_Section__c> lstSS = sectionwithRelatedList.Student_Section__r;

        ModalAddIaStudentsCtrl controller = new ModalAddIaStudentsCtrl();
        controller.section = sectionwithRelatedList;
        StudentInfoWrapper siw = new StudentInfoWrapper(lstSS[0].Student__r, lstSS[0], new List<Indicator_Area_Student__c>() );
        controller.studentSections = new List<StudentInfoWrapper>{siw};
        controller.studentSections[0].selected = true;
        controller.dtIA = Date.today();
        controller.studentSections[0].areaIDs = new Map<Id, Indicator_Area_Student__c>();
        controller.studentSections[0].student.Entry_Date__c = Date.today() - 7;
		controller.studentSections[0].student.Expiration_Date__c = Date.today() + 7;
        
        Test.startTest();
        controller.saveIAToStudents();
        Test.stopTest();

        List<Indicator_Area_Student__c> lsrIAS = [SELECT Id, IA_Effective_Date__c FROM Indicator_Area_Student__c WHERE Student__c = :lstSS[0].Student__c];
        System.assertEquals(1, lsrIAS.size(), 'Expected all IA students to be created.');
        System.assertEquals(Date.today(), lsrIAS[0].IA_Effective_Date__c, 'Date should be now');
    }

    static testMethod void testStartAddIAToStudents() {
        setupData();
        Section__c sectionwithRelatedList =
        [SELECT Id, Name, Start_Date__c, Program__c, Intervention_Primary_Staff__c, End_Date__c,
                School__c, Active__c, School__r.Name, Time__r.Name__c, Program__r.Indicator_Area__r.Id,
                Program__r.Indicator_Area__r.Name, RecordTypeID, RecordType.Name, Account_Program__r.Name,
                In_After_School__c,
        (SELECT Active__c, Student__c, Student__r.Id, Student__r.Name, Student_Name__c, Student_Grade__c,
                Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c,
                Section__c, Dosage_to_Date__c, Intervention_Enrollment_Start_Date__c,
                Enrollment_Start_Date__c, Enrollment_End_Date__c
        FROM Student_Section__r
        ORDER BY Student__r.Student_First_Name__c ASC LIMIT 1000),
        (SELECT Is_Active__c, Staff__r.Name, Intervention_Primary_Staff__c
        FROM Staff_Section__r)
        FROM Section__c
        WHERE Id =:testDataSetupUtil_v2.sectionsList[0].Id];
        List<Student_Section__c> lstSS = sectionwithRelatedList.Student_Section__r;
        Indicator_Area_Student__c ias = new Indicator_Area_Student__c(
                Indicator_Area__c = sectionwithRelatedList.Program__r.Indicator_Area__r.Id,
                Indicator_Area__r = new Indicator_Area__c(Id = sectionwithRelatedList.Program__r.Indicator_Area__r.Id),
                IA_Effective_Date__c = Date.today(),
                Student__c = lstSS[0].Student__c);

        ModalAddIaStudentsCtrl controller = new ModalAddIaStudentsCtrl();
        controller.section = sectionwithRelatedList;
        StudentInfoWrapper siw = new StudentInfoWrapper(lstSS[0].Student__r, lstSS[0], new List<Indicator_Area_Student__c>{ias});
        controller.studentSections = new List<StudentInfoWrapper>{siw};
        controller.studentSections[0].selected = true;

        Test.startTest();
        controller.startAddIAToStudents();
        Test.stopTest();

        System.assertEquals(1, controller.studentSections.size());
        for(StudentInfoWrapper siwi: controller.studentSections){
            System.assertEquals(Date.today(), siwi.dtIA);
        }
    }
}