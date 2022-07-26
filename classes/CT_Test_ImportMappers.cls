@isTest
public class CT_Test_ImportMappers {

    static testMethod void testCreateSchoolMapper() {
    	CT_ImportMappers.SchoolMapper mapper = CT_ImportMappers.createSchoolMapper();
    	system.assertNotEquals(null, mapper);
    }
    
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
    
    
}