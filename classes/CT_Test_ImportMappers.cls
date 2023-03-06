@isTest
public class CT_Test_ImportMappers {

    static testMethod void testCreateSchoolMapper() {

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

        Setup__c setup = new Setup__c();
        setup.School__c=acc.id;
        setup.Active__c=true;
        setup.Published__c=true;
        setup.Year__c=timeone.id;
        insert setup;
        
        Staff__c staff = new Staff__c();
        staff.First_Name_Staff__c='dora';
        staff.Staff_Last_Name__c='kara';
        staff.Organization__c =acc.id;
        staff.Reference_Id__c='dsell_Tiffani Test School';
        insert staff;
        Section__c sec = new Section__c();
        sec.Name='test school section ELA/Literacy';
        sec.School__c=acc.id;
        sec.Available_Grade_Levels__c='5';
        sec.Reference_Id__c='test school section ELA/Literacy'+acc.Name;
        sec.RecordTypeId=Schema.SObjectType.Section__c.getRecordTypeInfosByName().get('Published').getRecordTypeId();
        sec.Period__c='ELA/Literacy';
        sec.Active__c=true;
        sec.Reporting_Period__c=timeone.id;
        sec.Time__c=timeone.id;
        insert sec;
        
        Student__c student = new Student__c();
        student.Student_First_Name__c='peter';
        student.Student_Last_Name__c='pet';
        student.School__c=acc.id;
        student.Grade__c='5';
        student.Date_of_Birth__c=system.today();
        //student.Individual__c=con.id;
        student.Active__c=true;
        student.School_Year__c=timeone.id;
        student.Actual_graduation_date__c=System.today();
        student.Setup__c=setup.id;
        student.Entry_Date__c=system.today();
        student.Local_Student_ID__c='082402M901';
        student.Reference_Id__c='CY-642952_Courtney Test School_2022-2023';
        student.Student_Id__c='7345637465';
        insert student;

        HoldingObj__c hold = new HoldingObj__c();
        hold.School_Dbn__c ='38475394857';
        hold.School_Dbn__c ='Tiffani Test School';
        hold.Admission_Date__c=System.today();
        hold.Disability_Flag__c='N';
        hold.DOB__c=System.today();
        hold.Class_Id__c='8457483458';
        hold.ELL__c='true';
        hold.Ethnic_Cde__c='Asian';
        hold.Lep_Flag__c='R';
        Hold.Sex__c='Male';
        hold.Student_Id__c='374536845';
        hold.Email__c='peter23@gmail.com';
        hold.Phone__c='8475974579';
        hold.Address__c='new colony';
        hold.City__c='Us';
        hold.State__c='United';
        hold.zip__c='8475934';
        hold.Staff_Id__c=staff.id;
        insert hold;
       

        Scheduled_Section__c schedule = new Scheduled_Section__c();
        schedule.Name='new schedule';
        schedule.Account__c=acc.id;
        schedule.Schedule_Group_Section__c=sec.id;
        schedule.Staff__c=staff.id;
        insert schedule;

    	CT_ImportMappers.SchoolMapper mapper = CT_ImportMappers.createSchoolMapper();
        mapper.generate(hold);
        CT_ImportMappers.StudentMapper mapper2 = CT_ImportMappers.createStudentContactMapper();
        mapper2.generate(hold);
        CT_ImportMappers.SectionMapper mapper3 = CT_ImportMappers.createSectionMapper();
        mapper3.generate(hold,timeone);
        mapper3.generateForStudent(hold,timeone);
        //mapper3.generate(schedule,true);
        CT_ImportMappers.StaffMapper mapper4 = CT_ImportMappers.createStaffMapper();
        mapper4.generate(hold);
        CT_ImportMappers.StaffSectionMapper mapper5 = CT_ImportMappers.createStaffSectionMapper();
        mapper5.generate(hold);
        CT_ImportMappers.StaffSchoolMapper mapper6 = CT_ImportMappers.createStaffSchoolMapper();
        mapper6.generate(hold);
        CT_ImportMappers.StudentSchoolGradeMapper mapper7 = CT_ImportMappers.createStudentSchoolGradeMapper();
        mapper7.generate(hold,true);
        mapper7.generate(student,schedule);
    	//system.assertNotEquals(null, mapper);
    }
    /*
    static testMethod void testCreateStudentContactMapper() {
    	CT_ImportMappers.StudentMapper mapper = CT_ImportMappers.createStudentContactMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStudentSchoolGradeMapper() {
    	CT_ImportMappers.StudentSchoolGradeMapper mapper = CT_ImportMappers.createStudentSchoolGradeMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateSectionMapper() {
    	CT_ImportMappers.SectionMapper mapper = CT_ImportMappers.createSectionMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStaffMapper() {
    	CT_ImportMappers.StaffMapper mapper = CT_ImportMappers.createStaffMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStaffSectionMapper() {
    	CT_ImportMappers.StaffSectionMapper mapper = CT_ImportMappers.createStaffSectionMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStaffSchoolMapper() {
    	CT_ImportMappers.StaffSchoolMapper mapper = CT_ImportMappers.createStaffSchoolMapper();
      
    	system.assertNotEquals(null, mapper);
    }
    */
    
    
}