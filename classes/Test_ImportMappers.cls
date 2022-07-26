@isTest
public class Test_ImportMappers {

    static testMethod void testCreateSchoolMapper() {
    	ImportMappers.SchoolMapper mapper = ImportMappers.createSchoolMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStudentContactMapper() {
    	ImportMappers.StudentMapper mapper = ImportMappers.createStudentContactMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStudentSchoolGradeMapper() {
    	ImportMappers.StudentSchoolGradeMapper mapper = ImportMappers.createStudentSchoolGradeMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateSectionMapper() {
    	ImportMappers.SectionMapper mapper = ImportMappers.createSectionMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStaffMapper() {
    	ImportMappers.StaffMapper mapper = ImportMappers.createStaffMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStaffSectionMapper() {
    	ImportMappers.StaffSectionMapper mapper = ImportMappers.createStaffSectionMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    static testMethod void testCreateStaffSchoolMapper() {
    	ImportMappers.StaffSchoolMapper mapper = ImportMappers.createStaffSchoolMapper();
    	system.assertNotEquals(null, mapper);
    }
    
    
}