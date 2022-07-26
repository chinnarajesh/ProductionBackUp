@isTest
//the indentation on this test indicates which controller is being used
//this is to keep the controllers from stumbling over themselves and the testing becomes easier
private class TestAttendanceDateWizard {

	static testMethod void TestAttendanceDateWizard() {
		AttendanceDateWizardController con = new AttendanceDateWizardController();
		testDataSetupUtil_v2.isAttendance=true;
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);
		integer i=0;
		for (Section__c sect: testDataSetupUtil_v2.sectionsList){
	 		if (!sect.daily_attendance__c){
	  			testDataSetupUtil_v2.getSessions(10,testDataSetupUtil_v2.semester,sect.Id, i);
	  			i++; 
			}else{
				testDataSetupUtil_v2.getSessions(10,testDataSetupUtil_v2.semester,sect.Id,  null);
			}
		}
  
		List <Picklist_Value__c> pvl = testDataSetupUtil_v2.createDefaultAttendanceTypes(testDataSetupUtil_v2.activeSetup);
  		core_SoqlUtils.loggedInUser = null;
  
  		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
				con = new AttendanceDateWizardController();

			Test.startTest();
				attendanceDateWizardController controller1 = new attendanceDateWizardController();

				controller1.cancel();
				controller1.go();
				controller1.searchStudent.student.Student_First_Name__c = '*';
				controller1.searchStudent.student.Student_Last_Name__c = '*';
				controller1.go();
					//system.assertEquals([SELECT count() FROM Student__c Where active__c = true], controller1.studentSearchResults.size());
				controller1.searchStudent.student.Student_First_Name__c = 'aoheroehoarep';
				controller1.go();
				system.assertEquals(0, controller1.studentSearchResults.size());
				controller1.displaySections();
				controller1.searchStudent.student.Student_First_Name__c = testDataSetupUtil_v2.studentsList[0].Student_First_Name__c;
				controller1.searchStudent.student.Student_Last_Name__c = testDataSetupUtil_v2.studentsList[0].Student_Last_Name__c;
				controller1.go();
				system.assertEquals(1, controller1.studentSearchResults.size());
				
				ApexPages.currentPage().getParameters().put('firstName', testDataSetupUtil_v2.studentsList[0].Student_First_Name__c);
				ApexPages.currentPage().getParameters().put('lastName', testDataSetupUtil_v2.studentsList[0].Student_Last_Name__c);
				ApexPages.currentPage().getParameters().put('studID', testDataSetupUtil_v2.studentsList[0].ID);	
				controller1.displaySections();
					//do the range first
				controller1.selectedFunction='Range';
				controller1.endDate.Expiration_Date__c = date.valueOf('2010-01-01');
				controller1.startDate.Expiration_Date__c = date.valueOf('2011-01-01');
					//cause error
				controller1.save();
					//create attendance records for the whole year
				controller1.endDate.Expiration_Date__c = date.valueOf('2012-01-01');
				controller1.startDate.Expiration_Date__c = date.valueOf('2010-01-01');
				
				
				controller1.setStatus = pvl[0].id;
				controller1.selectedSection1 = testDataSetupUtil_v2.sectionsList[0].id;
				controller1.selectedSection2 = testDataSetupUtil_v2.sectionsList[0].id;
				
				controller1.searchDate.Expiration_Date__c = [select session_date__c from session__c where section__c = :controller1.selectedSection1 limit 1].session_date__c;
				controller1.displayAttendance();
				
				controller1.save();
				controller1.searchDate.Expiration_Date__c = [select session_date__c from session__c where section__c = :controller1.selectedSection2 limit 1].session_date__c;
				controller1.selectedFunction='Date';
				controller1.setStatus = pvl[0].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[0].id;
				controller1.save();
				
				
				controller1.setStatus = pvl[5].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[5].id;
				controller1.save();
				controller1.setStatus = pvl[5].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[5].id;
				controller1.attendanceresult.Departure_Time__c = system.now();
				controller1.attendanceresult.Arrival_Time__c = system.now();
				controller1.save();
				controller1.setStatus = pvl[5].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[5].id;
				controller1.attendanceresult.Departure_Time__c = system.now();
				controller1.attendanceresult.Arrival_Time__c = null;
				controller1.save();
				controller1.setStatus = pvl[5].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[5].id;
				controller1.attendanceresult.Departure_Time__c = controller1.asession.End_DateTime__c.addMinutes(15);
				controller1.save();
				controller1.setStatus = pvl[5].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[5].id;
				controller1.attendanceresult.Departure_Time__c = controller1.asession.End_DateTime__c.addMinutes(-15);
				controller1.save();
				
				
				controller1.setStatus = pvl[4].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[4].id;
				controller1.save();
				controller1.setStatus = pvl[4].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[4].id;
				controller1.attendanceresult.Arrival_Time__c = system.now();
				controller1.save();
				controller1.setStatus = pvl[4].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[4].id;
				controller1.attendanceresult.Arrival_Time__c = controller1.asession.End_DateTime__c.addMinutes(15);
				controller1.save();
				controller1.setStatus = pvl[4].id;
				controller1.attendanceresult.Picklist_Value__c	= pvl[4].id;
				controller1.attendanceresult.Arrival_Time__c = controller1.asession.Start_DateTime__c.addMinutes(15);
				controller1.save();
			Test.stopTest();
 		}
	}
}