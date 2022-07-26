@isTest
private class CT_Test_courseCatalogsetup {
	
	public static List<Course__c> courseList;
	public static List<Course_Catalog__c> courseCatalogList;
	
	public static void createTestData(){
        testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
    	
    	courseList = testDataSetupUtil_v2.coursesList;
    	courseCatalogList = getCourseCatalog();
	}
	
   
    
    public static List<Course_Catalog__c> getCourseCatalog(){
    	List<Course_Catalog__c> courseCatalog = new List<Course_Catalog__c>();
    	courseCatalog.add(new Course_Catalog__c(Name = '2009', Course_Catalog_Description__c = 'Course Catalog 2009', Course_Catalog_Status__c = true));
    	courseCatalog.add(new Course_Catalog__c(Name = '2010', Course_Catalog_Description__c = 'Course Catalog 2010', Course_Catalog_Status__c = true));
    	courseCatalog.add(new Course_Catalog__c(Name = '2011', Course_Catalog_Description__c = 'Course Catalog 2011', Course_Catalog_Status__c = true));
    	
    	insert courseCatalog;
    	System.debug('----------Course Catalog List -------------------------------'+courseCatalog);
    	return courseCatalog;
    }    

    public static testmethod void testCourseCatalogController(){
    	createTestData(); 
		test.startTest();
			User u = testDataSetupUtil_v2.staffUsersList[1];
			System.debug('----------Portal User -------------------------------'+u);
                
			system.runAs(u){				
				//throw error
				PageReference pr = Page.CT_core_CourseCatalogSetup;
				pr.getParameters().put('setupid','abc');
				test.setCurrentPage(pr);
				    
				ApexPages.StandardController con2 = new ApexPages.StandardController(testDataSetupUtil_v2.activeSetUp);
				CT_core_CourseCatalogController c2 = new CT_core_CourseCatalogController(con2);
				
				PageReference pr1 = Page.CT_core_CourseCatalogSetup;
				pr1.getParameters().put('setupid',testDataSetupUtil_v2.activeSetup.id);
				test.setCurrentPage(pr1);
				    
				ApexPages.StandardController con1 = new ApexPages.StandardController(testDataSetupUtil_v2.activeSetUp);
				CT_core_CourseCatalogController c1 = new CT_core_CourseCatalogController(con1);
				
				//throw error
				integer countErr = [SELECT count() FROM Global_Error__c];
				c1.selectedCatalogId = 'abc';
				c1.saveSetup();
				system.assertEquals(countErr+1,[SELECT count() FROM Global_Error__c]);
				    
				PageReference pr2 = Page.CT_core_CourseCatalogSetup;
				pr2.getParameters().put('setupid',testDataSetupUtil_v2.activeSetup.id);
				pr2.getParameters().put('ccid',courseCatalogList[0].id);
				test.setCurrentPage(pr2);
				    
				ApexPages.StandardController con = new ApexPages.StandardController(testDataSetupUtil_v2.activeSetUp);
				CT_core_CourseCatalogController c = new CT_core_CourseCatalogController(con);

				system.assertEquals(c.bShowCatalogDetails ,true);

				c.saveSetup();
				
				//throw error
				c.selectedCatalogWrapper = null;
				c.saveCatalogConfig();
				system.assertEquals(countErr+2,[SELECT count() FROM Global_Error__c]);
					
				c.configureNewCatalog();
				system.assertEquals(c.bConfigureCatalog ,true);
				system.assertEquals(c.bShowCatalogDetails ,false);				    
				system.assertEquals(c.bShowCourseDetails ,false);
				    
				c.selectedCatalogWrapper.catalog.Name = 'Test Catalog';
				c.selectedCatalogWrapper.catalog.Course_Catalog_Description__c = 'Test Description';
				c.selectedCatalogWrapper.catalog.Course_Catalog_Status__c =true;
				    
				c.saveCatalogConfig();
				system.assertEquals(c.bConfigureCatalog ,false);
				
				//throw error
				System.currentPageReference().getParameters().put('selectedCatalogId','abc');
				c.editCatalogDetails();
				system.assertEquals(countErr+3,[SELECT count() FROM Global_Error__c]);
				
				System.currentPageReference().getParameters().put('selectedCatalogId',null);  
				c.editCatalogDetails();
				system.assertEquals(c.bShowCatalogDetails ,false);
				system.assertEquals(c.bConfigureCatalog ,true);				    
				system.assertEquals(c.bShowCourseDetails ,false);
				c.selectedCatalogId = courseCatalogList[0].id;

				c.saveCatalogConfig();
				    				    				    
				c.editCatalogDetails();
				c.goBack();
				system.assertEquals(c.bShowCatalogDetails ,false);
				system.assertEquals(c.bConfigureCatalog ,false);
				
				//throw error
				System.currentPageReference().getParameters().put('selectedCatalogId','abc');
				c.removeCatalogDetails();
				system.assertEquals(countErr+4,[SELECT count() FROM Global_Error__c]);
				
				
				//throw error
				c.selectedCatalogId = 'abc';
				c.returnCatalogDetails();
				system.assertEquals(countErr+5,[SELECT count() FROM Global_Error__c]);
				
				System.currentPageReference().getParameters().put('selectedCatalogId',null);
				c.selectedCatalogId = courseCatalogList[1].id;														    
				c.removeCatalogDetails();
				c.returnCatalogDetails();
				
				//throw error
				c.selectedCourse = null;
				c.saveNewCourse();
				system.assertEquals(countErr+6, [SELECT count() FROM Global_Error__c]);
					
				c.addNewCourse();
				system.assertEquals(c.bAddNewCourse ,true);
				system.assertEquals(c.bEditCourse ,false);
				system.assertEquals(c.courseSectionString ,'Create New Course');

				c.selectedCourse.course.Name = 'Test Course';
				c.selectedCourse.course.course_number__c='09802938423';
				c.selectedCourse.course.Has_a_lab__c = true;
				c.selectedCourse.course.Has_Final_Grade__c = false;				    
				c.selectedCourse.course.Department__c = 'Test Course';
				c.selectedCourse.course.Type__c = 'Test Type';
				c.selectedCourse.selectedRpNum = '2';
				
				//throw error
				c.selectedCatalogId = null;
				c.selectedCourse.course.subject_area_lookup__c = testDataSetupUtil_v2.coursesList[0].subject_area_lookup__c;
				c.saveNewCourse();
				system.assertEquals(countErr+7, [SELECT count() FROM Global_Error__c]);
				
				c.selectedCatalogId = courseCatalogList[0].id;
				system.assertEquals(c.bAddNewCourse ,true);
				system.assertEquals(c.bEditCourse ,false);
				c.saveNewCourse();
				c.selectedCatalogId = courseCatalogList[0].id;
				apexpages.currentpage().getParameters().put('selectedCourseId',courseList[0].id);
												    
				c.editCourseDetails();
				system.assertEquals(c.bShowCatalogDetails ,false);
				system.assertEquals(c.bConfigureCatalog ,false);
				system.assertEquals(c.bShowCourseDetails ,true);
				system.assertEquals(c.bAddNewCourse ,false);
				system.assertEquals(c.bEditCourse ,true);
				system.assertEquals(c.courseSectionString ,'Edit Course');
				
				c.selectedCourse.selectedRpNum = '2';
				c.saveNewCourse();
				   
				c.addCourse();
							   
				c.addExistingCourses();
				    
				c.cancelCourse();
				system.assertEquals(c.bAddNewCourse ,false);
				system.assertEquals(c.bShowCatalogDetails ,true);
					
				
			}
		test.stopTest();
    }
    
    public static testMethod void testCourseCat2(){
    	test.startTest();
			createTestData();
			User u = testDataSetupUtil_v2.staffUsersList[1];
			System.debug('----------Portal User -------------------------------'+u);
                
			system.runAs(u){			
				integer countErr = [SELECT count() FROM Global_Error__c];	
				//throw error
				PageReference pr = new PageReference('/apex/CT_core_CourseCatalogSetup?setupid=abc');
				test.setCurrentPage(pr);
				    
				ApexPages.StandardController con2 = new ApexPages.StandardController(testDataSetupUtil_v2.activeSetUp);
				CT_core_CourseCatalogController c2 = new CT_core_CourseCatalogController(con2);
				
				PageReference pr1 = new PageReference('/apex/CT_core_CourseCatalogSetup?setupid='+testDataSetupUtil_v2.activeSetup.id);
				test.setCurrentPage(pr1);
				    
				ApexPages.StandardController con1 = new ApexPages.StandardController(testDataSetupUtil_v2.activeSetUp);
				CT_core_CourseCatalogController c = new CT_core_CourseCatalogController(con1);
				
				apexpages.currentpage().getParameters().put('selectedCourseId',courseList[0].id);
				

				c.editCourseDetails();
				
				//throw error
				c.plMap = null;
				c.initAssignmentWeightings();
				system.assertEquals(countErr+1, [SELECT count() FROM Global_Error__c]);
				c.plMap = new Map<Id, CT_core_CourseCatalogController.assignmentWeightWrapper>();
				

				
				Default_Assignment_Weighting__c daw = new Default_Assignment_Weighting__c(Course__c = c.selectedCourseId, Picklist_Value__c =CT_core_SoqlUtils.getPlStringValues('Assignment Type', testDataSetupUtil_v2.activeSetup.id).values()[0].id, Default_Weighting__c = 1);
				insert daw;
				c.initAssignmentWeightings();
				c.addAssWeightings();
				system.assertEquals(c.bAssWeightings ,true);
				system.assertEquals(c.bAddNewCourse ,false);
				system.assertEquals(c.bConfigureCourse ,true);
				c.saveDefaultAssignmentWeightings();	

				
				c.addWeightings();
				
				c.saveWeightings();
				
				c.addWeightings();
					
				c.cancelWeightings();
				system.assertEquals(c.bConfigureWeightings ,false);
			} 	
    }
}