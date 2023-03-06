@IsTest
public class StudentEnrollmentTriggerTest {

    private static testMethod void testdatatwo(){
        Account acc = new Account();
        acc.Name='Juturi rajesh';
        acc.Active__c='true';
        acc.Site__c='Jacksonville';
        acc.Reference_Id__c='Courtney Test School';
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        insert acc;
        
        Picklist_Value__c pickvalue = new Picklist_Value__c();
        pickvalue.Name='Final';
        pickvalue.Type__c='Time';
        pickvalue.Category__c='Reporting Period';
        pickvalue.RecordTypeId=Schema.SObjectType.Picklist_Value__c.getRecordTypeInfosByName().get('Time').getRecordTypeId();
        insert pickvalue;
        
        Time_Element__c timeone = new Time_Element__c();
        timeone.Name__c='2022-2023';
        timeone.Reporting_Period__c=true;
        timeone.School__c=acc.id;
        timeone.Date_Start_Date__c=system.today();
        timeone.End_Date__c=system.today();
        timeone.Picklist_Value__c=pickvalue.id;
        insert timeone;
            
        Section__c sec = new Section__c();
        sec.Name='test school section ELA/Literacy';
        sec.School__c=acc.id;
        sec.Available_Grade_Levels__c='5';
        sec.Reference_Id__c='test school section ELA/Literacy'+acc.Name;
        sec.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Unpublished').getRecordTypeId();
        sec.Period__c='ELA/Literacy';
        sec.Active__c=true;
        sec.Reporting_Period__c=timeone.id;
        sec.Time__c=timeone.id;
        insert sec;
        
        Section__c section = new Section__c();
        section.Name='test school section Math';
        section.School__c=acc.id;
        section.Available_Grade_Levels__c='5';
        section.Reference_Id__c='test school section Math'+acc.name;
        section.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Unpublished').getRecordTypeId();
        section.Period__c='Math';
        section.Active__c=true;
        section.Reporting_Period__c=timeone.id;
        section.Time__c=timeone.id;
        insert section;
        
        Section__c section2 = new Section__c();
        section2.Name='test school section Math2';
        section2.School__c=acc.id;
        section2.Available_Grade_Levels__c='5';
        section2.Reference_Id__c='test school section Math2'+acc.name;
        section2.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Schedule Group').getRecordTypeId();
        section2.Period__c='Math';
        section2.Active__c=true;
        section2.Reporting_Period__c=timeone.id;
        section2.Time__c=timeone.id;
        insert section2;

        Contact con = new Contact();
        con.FirstName='peter';
        con.LastName='parkar';
        con.RecordTypeId=Schema.SObjectType.contact.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        con.Date_of_Birth__c=system.today();
        con.Active__c=true;
        insert con;
        
        Setup__c setup = new Setup__c();
        setup.School__c=acc.id;
        setup.Active__c=true;
        setup.Published__c=true;
        setup.Year__c=timeone.id;
        insert setup;
        
        Test.startTest();
        core_triggerUtils.contactTrigger=true;
        Student__c student = new Student__c();
        student.Student_First_Name__c='peter';
        student.Student_Last_Name__c='pet';
        student.School__c=acc.id;
        student.Grade__c='5';
        student.Date_of_Birth__c=system.today();
        student.Individual__c=con.id;
        student.Active__c=true;
        student.School_Year__c=timeone.id;
        student.Actual_graduation_date__c=System.today();
        student.Setup__c=setup.id;
        student.Entry_Date__c=system.today();
        student.Local_Student_ID__c='082402M901';
        //student.Reference_Id__c='CY-642952_Courtney Test School_2022-2023';
        student.Student_Id__c='7345637465';
        student.Title_1_Status__c='Free';
        student.State__c='TN';
        student.Ward__c='1';
        student.Residence_After_Exiting_School__c='	Armed services';
        //student.Primary_Schedule_Group__c=sec.id;
        insert student;
        Map<Id,Student__c> StudentMap = new Map<Id,Student__c>();
        StudentMap.put(student.id,student);
        CT_Student_Utils.processBeforeDelete(StudentMap);
        CT_Student_Utils.getStudentSetupMap(StudentMap);
        List<Student__c> StudentList = new List<Student__c>();
        StudentList.add(student);
        CT_Student_Utils.getStudentSetupMap(StudentList);
        CT_Student_Utils.populateFieldsOnUpdate(StudentList,StudentMap);
        List<Enrollment_Tracking__c> newset = new List<Enrollment_Tracking__c>();
        date dateToCheck=System.today();
        CT_Student_Utils.checkEnrollmentTracking(newset, dateToCheck);
        core_triggerUtils.contactTrigger=false;
        student.Primary_Schedule_Group__c=section2.id;
        update student;
        Map<Id,Student__c> StudentMap2 = new Map<Id,Student__c>();
        StudentMap2.put(student.id,student);
        CT_Student_Utils.scheduleGroup_onUpdate(StudentMap2,StudentMap);
        Test.stopTest();
    }
    
    /*private static testMethod void testdatatwo(){
        Account account =[select id,name from account where Name='Juturi rajesh'];
        Contact contact =[select id,name from Contact where FirstName='peter'];
       
        Test.startTest();
        contact.FirstName='messi';
        update contact;
        Test.stopTest();
      }
    */
}