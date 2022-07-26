@isTest
private class Test_PortalWrapper {
	public static List<Awards__c> awardsList;
	public static List<Section_Grade__c> sectionGradesList;
	public static List<Alert__c> alertsList;
	public static List<Media__c> mediaList;
	public static List<Calendars__c> calendarsList;
	public static List<Assignment_Lib__c> assignLibsList;
	public static List<Assignment__c> assignmentsList;
	public static List<Attachment>  assignLibAttachtsList; 
	public static List<Grade__c> gradesList;
	
    public static void createTestData(){
    	TestDataSetupUtil_v2.isGradebook = true;
    	TestDataSetupUtil_v2.setUPCoreData(5);
        TestDataSetupUtil_v2.setUPStaffData(5);
        TestDataSetupUtil_v2.setUPStudentData(5);
    }
    
    public static void alterTestData(){
    	TestDataSetupUtil_v2.studUsersList = TestDataSetupUtil_v2.getPortalUsers(5, 'Student',TestDataSetupUtil_v2.studContactsList);
    	List<Setup__c> setupToUpdate = new List<Setup__c>();
    	for(Setup__c s : [select id, Term__c from Setup__c where School__c = : TestDataSetupUtil_v2.school.Id AND Active__c = true]){
		        if(s.Id != TestDataSetupUtil_v2.activeSetUp.Id){
		        	s.Active__c = false;
		        	setupToUpdate.add(s);
		        }
    	}
    	
    	update setupToUpdate;
    	awardsList = getAwardsForStudent();
    	assignLibsList = getAssignmentLibrary();
    	assignmentsList = getAssignments();
    	assignLibAttachtsList = getAttachmentsOnAssignLib();
       	
    	sectionGradesList = getSectionGrades();
    	alertsList = getAlerts();
    	mediaList = getMediaLinksForCourse();
    	calendarsList = getCalendarsForSchool();
		gradesList = getGrades();
    }
    
    public static void getAttendance(){
    	TestDataSetupUtil_v2.sessionsList = TestDataSetupUtil_v2.getSessions(2,TestDataSetupUtil_v2.semester,TestDataSetupUtil_v2.sectionsList[0].Id,1);
        List<Picklist_Value__c> attendancePVs = TestDataSetupUtil_v2.createDefaultAttendanceTypes(TestDataSetupUtil_v2.activeSetup);
        List<Attendance__c> attendanceList = new List<Attendance__c>();
        
        //Excused Absence
        attendanceList.add(new Attendance__c(Student__c = TestDataSetupUtil_v2.studentsList[0].id
        									,Session__c = TestDataSetupUtil_v2.sessionsList[0].id
        									,Picklist_Value__c = attendancePVs[1].id));
        //Unexcused Tardy
       	attendanceList.add(new Attendance__c(Student__c = TestDataSetupUtil_v2.studentsList[0].id
       										,Session__c = TestDataSetupUtil_v2.sessionsList[1].id
       										,Picklist_Value__c = attendancePVs[4].id));
       	insert attendanceList;
    }
    
    public static List<Awards__c> getAwardsForStudent(){
    	List<Awards__c> awards = new List<Awards__c>();
    	awards.add(new Awards__c(Reason__c = 'Great participation',Award_Type__c = 'Cup',Award_Type_Detail__c='Bronze',Student__c = TestDataSetupUtil_v2.studentsList[0].Id));
    	awards.add(new Awards__c(Reason__c = 'Great participation',Award_Type__c = 'Cup',Award_Type_Detail__c='Silver',Student__c = TestDataSetupUtil_v2.studentsList[0].Id));
    	awards.add(new Awards__c(Reason__c = 'Great participation',Award_Type__c = 'Cup',Award_Type_Detail__c='Gold',Student__c = TestDataSetupUtil_v2.studentsList[0].Id));
    	insert awards;
    	return awards;
    }
    
    public static List<Section_Grade__c> getSectionGrades(){
    	Section_Grade__c sg = new Section_Grade__c();
    	
    	sg.Grade__c = 90.00;
    	sg.Letter_Grade__c = 'A-';
    	sg.Time__c = TestDataSetupUtil_v2.semester.Id;
    	sg.Student_Section__c = TestDataSetupUtil_v2.studSectionsList[0].id;
    	 
    	insert sg;
    	return new List<Section_Grade__c>{sg};
    }
    
    public static List<Alert__c> getAlerts(){
    	List<Alert__c> alerts = new List<Alert__c>();
    		alerts.add(new Alert__c(Expiration_Date__c = System.today().addDays(5), Message__c = 'Submit assignment!!!',	Student__c = TestDataSetupUtil_v2.studentsList[0].Id));
    	
    	insert alerts;
    	System.debug('----------Alerts -------------------------------'+alerts[0]);
    	return alerts;
    }
    
    public static List<Media__c> getMediaLinksForCourse(){
    	List<Media__c> mediaLinks = new List<Media__c>();
    	
    		mediaLinks.add(new Media__c(Name = 'Class 887-Link7',Source__c = 'http://www.youtube.com/embed/PmU69JSimk0',Type__c='Link',Section__c = TestDataSetupUtil_v2.sectionsList[0].Id));
    	
    	insert mediaLinks;
    	System.debug('----------MediaLinks -------------------------------'+mediaLinks[0]);
    	return mediaLinks; 	
    }
    
    public static List<Calendars__c> getCalendarsForSchool(){
    	List<Calendars__c> calendars = new List<Calendars__c>();
    		calendars.add(new Calendars__c(Name = 'Math Club',Calendar_Id__c = 'bmejjb3ofq4qjlmqtvj7h76n0o@group.calendar.google.com',Color__c = '#0D7813',Organization__c = TestDataSetupUtil_v2.school.Id));
    	
    	insert calendars;
    	System.debug('----------Calendars -------------------------------'+calendars[0]);
    	return calendars;
    }
    
    public static List<Assignment_Lib__c> getAssignmentLibrary(){
    	List<Picklist_Value__c> pickValuesList = new List<Picklist_Value__c>();
		pickValuesList.add(new Picklist_Value__c(Name = 'TestAssignLib'
												 ,Type__c = 'Grade Scale'
												)
							);
									
		insert pickValuesList; 
		
    	List<Assignment_Lib__c> assignLibs = new List<Assignment_Lib__c>();
    		assignLibs.add(new Assignment_Lib__c(Picklist_Value__c = pickValuesList[0].Id,Course__c = TestDataSetupUtil_v2.coursesList[0].Id));
    	
    	insert assignLibs;
    	System.debug('----------assignLibs -------------------------------'+assignLibs[0]);
    	return assignLibs;
    	 
    }
    
    public static List<Assignment__c> getAssignments(){
    	List<Assignment__c> assignments = new List<Assignment__c>();
		assignments.add(new Assignment__c(NAME = 'TestAssignment'
										  ,Due_Date__c = System.today().addDays(5)
										  ,Section__c = TestDataSetupUtil_v2.sectionsList[0].Id
										  ,Description__c = 'Assignment test description'
										  ,Media_Source__c = 'http://www.youtube.com/embed/puydh-ey_2k'
										  ,Media_Name__c = 'Chatter Link'
										  ,Assignment_Library__c = assignLibsList[0].Id
												)
							);
							
		System.debug('----------Assignment Section -------------------------------'+TestDataSetupUtil_v2.sectionsList[0].Id);
    	insert assignments;
    	System.debug('----------assignments -------------------------------'+assignments[0]);
    	return assignments; 
    }
    
    public static void getHomework(){
        List<Picklist_Value__c> hwStatus = testDataSetupUtil_v2.createHomeworkPicklistValues();
        
        HW_Tracker__c h = new HW_Tracker__c(Due_Date__c = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1)
       								,Student__c = testDataSetupUtil_v2.studentsList[0].id
       								,Student_Section__c = testDataSetupUtil_v2.studSectionsList[0].id
       								,Picklist_Value__c = hwStatus[1].id);
       	
       	insert h;
    }
    
    public static List<Attachment> getAttachmentsOnAssignLib(){
    	List<Attachment> assignLibAttachts = new List<Attachment>();
    	Blob fileBlob = Blob.valueOf('');
		assignLibAttachts.add(new Attachment(Name ='test assign lib attachment'
										  ,ParentId = assignLibsList[0].Id
										  ,Body = fileBlob
							)
							);
							
		
    	insert assignLibAttachts;
    	System.debug('----------Attachments on AssignLibrary -------------------------------'+assignLibAttachts[0]);
    	return assignLibAttachts;
    }
    
    
    public static List<Grade__c> getGrades(){
    	List<Grade__c> grades = new List<Grade__c>();
		grades.add(new Grade__c(Student_Section__c = TestDataSetupUtil_v2.studSectionsList[0].Id
								,Assignment__c = assignmentsList[0].Id
								,Time__c = TestDataSetupUtil_v2.semester.Id
								,Course__c = TestDataSetupUtil_v2.coursesList[0].Id
								,Student__c = TestDataSetupUtil_v2.studentsList[0].Id
																
							   )
							);
							
		
    	insert grades;
    	System.debug('----------grades &&&& -------------------------------'+grades[0]);
    	return grades;
    }
    
    
    static testmethod void loadPortal(){
    	createTestData();
    	system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
    		alterTestData();
    		getAttendance();
    	}
        test.startTest();
	        system.assert(TestDataSetupUtil_v2.ActiveSetup.Term__c != null);
	        User u = TestDataSetupUtil_v2.studUsersList[0];
	        System.debug('----------Portal User -------------------------------'+u);
	        
	        system.runAs(u){
		        PageReference testPage = Page.Portal;
		        testPage.getParameters().put('tab', 'Home');
		        Test.setCurrentPage(testPage);
		        
		        PortalController portal = new PortalController();
		        integer cnt = 1;
		    	//Verify current student
		    	for(Integer i = 0 ; i < cnt ;i++){
		    	   System.assertEquals(TestDataSetupUtil_v2.studentsList[i].Id, portal.port.currstudent.Id);
		    	}
		    	 
		   	    //Verify Calendar url
		    	String colorCode = '#0D7813';
		    	String calandarId = EncodingUtil.urlEncode(calendarsList[0].Calendar_Id__c,'UTF-8')+'&color='+ EncodingUtil.urlEncode(colorCode,'UTF-8');
				String calandarUrl = 'https://www.google.com/calendar/embed?src='+calandarId+'&ctz='+[SELECT TimeZoneSidKey FROM User WHERE Id = : u.Id].TimeZoneSidKey;
				//System.assertEquals(calandarUrl,portal.port.calandarUrl);
		    	for(Integer i = 0 ; i < cnt ;i++){
			    	System.assertEquals(TestDataSetupUtil_v2.sectionsList[i].Id,portal.port.sectionList[i].Id);
			    	System.assertEquals(TestDataSetupUtil_v2.studSectionsList[i].Id,portal.port.studentSections[i].Id);
			//    	System.assertEquals(sectionGradesList[i].Id,portal.port.sectionGradeWrapperList[i].secGrade.Id);
			    	System.assertEquals(awardsList[i].Id,portal.port.awardsListFull[i].Id);
			    	System.assertEquals(alertsList[i].Id,portal.port.alertsList[i].Id);
			    	//System.assertEquals(gradesList[i].Id,portal.port.currAssignsPerSection[i].grade.Id);
			    	System.assertEquals(assignLibAttachtsList[i].Id,portal.port.currAssignsPerSection[i].atchmnt.Id);
			    	System.assertEquals(assignLibAttachtsList[i].ParentId,portal.port.currAssignsPerSection[i].atchmnt.ParentId);
		    	}
	        }
        test.stopTest();
    }
  
    static testmethod void refreshMyProgressGrades(){
    	createTestData();
    	system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
    		alterTestData();
    	}
        test.startTest();
        User u = TestDataSetupUtil_v2.studUsersList[0];
        System.debug('----------Portal User -------------------------------'+u);
        system.runAs(u){
	        PageReference testPage = Page.Portal;
	        Test.setCurrentPage(testPage);
	        PortalController portal = new PortalController();
	        ApexPages.currentPage().getParameters().put('progressCourseName', TestDataSetupUtil_v2.coursesList[0].Name);
	        portal.refreshMyProgressCourses();
	        system.assertEquals( 1, portal.port.sectionGradeWrapperList.size());
        }
        test.stopTest();
    }
            
            
     static testmethod void refreshMyAssignmentGrades(){
     	createTestData();
     	system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
    		alterTestData();
    	}
		test.startTest();
            User u = TestDataSetupUtil_v2.studUsersList[0];
            System.debug('----------Portal User -------------------------------'+u);
            system.runAs(u){
	            PageReference testPage = Page.Portal;
	            Test.setCurrentPage(testPage);
	            PortalController portal = new PortalController();
	            ApexPages.currentPage().getParameters().put('tabName', TestDataSetupUtil_v2.coursesList[0].Name);
	            portal.refreshMyAssignmentCourses();
	                          //  system.assertEquals( 1, portal.port.mediaList.size());
            }
		test.stopTest();
     }
            
		static testmethod void refreshMyProgressCourses(){
			createTestData();
			system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
    			alterTestData();
    		}   
                test.startTest();
                
                User u = TestDataSetupUtil_v2.studUsersList[0];
                System.debug('----------Portal User -------------------------------'+u);
                system.runAs(u){
	                PageReference testPage = Page.Portal;
	                Test.setCurrentPage(testPage);
	                PortalController portal = new PortalController();
	                //ApexPages.currentPage().getParameters().put('progressCourseName', TestDataSetupUtil_v2.coursesList[0].Name);
	                portal.refreshMyProgressCourses();
	                                system.assertEquals( 2, portal.port.courses.size());
                }
                test.stopTest();
            }
            
    static testmethod void refreshMyAssignmentCourses(){
    	createTestData();
		system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
			alterTestData();
		}  
        test.startTest();
            User u = TestDataSetupUtil_v2.studUsersList[0];
            System.debug('----------Portal User -------------------------------'+u); 
        	system.runAs(u){
                PageReference testPage = Page.Portal;
                Test.setCurrentPage(testPage);
                PortalController portal = new PortalController();
                //ApexPages.currentPage().getParameters().put('progressCourseName', TestDataSetupUtil_v2.coursesList[0].Name);
                portal.refreshMyAssignmentCourses();
                system.assertEquals( 2, portal.port.courses.size());
        	}
        test.stopTest();
    }
            
	static testmethod void dummyRefresh(){
		createTestData();
		system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
			alterTestData();
		}
		test.startTest();
                User u = TestDataSetupUtil_v2.studUsersList[0];
                System.debug('----------Portal User -------------------------------'+u);
                system.runAs(u){
                PageReference testPage = Page.Portal;
                Test.setCurrentPage(testPage);
                PortalController portal = new PortalController();
                portal.dummyRefresh();
                                system.assertEquals( 2, portal.port.courses.size());
                }
                test.stopTest();
     }
     
     static testMethod void testHomework(){
     	createTestData();
		system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
			alterTestData();
			getHomework();
     	}
     	User u = TestDataSetupUtil_v2.studUsersList[0];
        system.runAs(u){
     		test.startTest();
                PageReference testPage = Page.Portal;
                Test.setCurrentPage(testPage);
                PortalController portal = new PortalController();
                system.assertEquals(1, portal.port.homeworkInfo.size());
                system.assertEquals(100.0, portal.port.homeworkInfo[0].percentMissing);
            test.stopTest();
        }
	}
	
	static testMethod void testStrands(){
		createTestData();
		system.runAs(TestDataSetupUtil_v2.staffUsersList[0]){
			alterTestData();
			getHomework();
     	}
     	User u = TestDataSetupUtil_v2.studUsersList[0];
        system.runAs(u){
     		test.startTest();
                PageReference testPage = Page.Portal;
                Test.setCurrentPage(testPage);
                PortalController portal = new PortalController();
				portal.refreshMyStandards();
            test.stopTest();
        }
		
	}
}