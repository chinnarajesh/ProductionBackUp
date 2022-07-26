@isTest
public class Test_AttendanceWizard_v2 {

  static void setupData() {
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
  }

	static testMethod void adwStudent() {
    setupData();

		system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
			Test.startTest();
			AttendanceWizard_v2 awController = new AttendanceWizard_v2();
			awController.attendanceDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.format();
			awController.RetrieveResults();
			if(awController.stSearch.sCriteria.studResults.size() > 0) {
			   ApexPages.currentPage().getParameters().put('studentID', awController.stSearch.sCriteria.studResults[0].ID);
			   awController.stSearch.getEnrolledAttendance();

			   awController.stSearch.submitAttendance();

				  if(awController.stSearch.swAttendance.size() > 0) {
					   awController.stSearch.swAttendance[0].at.Picklist_Value__c = awController.stSearch.pvList[0].ID;
					   awController.stSearch.submitAttendance();              
				  }
			}

			Test.stopTest();
		}
  }

  static testMethod void adwStudent1() {
    setupData();

    system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
      Test.startTest();
      AttendanceWizard_v2 awController = new AttendanceWizard_v2();
      awController.attendanceDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.format();
      awController.RetrieveResults();
      if(awController.stSearch.sCriteria.studResults.size() > 0) {
         ApexPages.currentPage().getParameters().put('studentID', awController.stSearch.sCriteria.studResults[0].ID);
         awController.stSearch.getEnrolledAttendance();

         awController.stSearch.submitAttendance();

          if(awController.stSearch.swAttendance.size() > 0) {
             dateTime dt = System.Now();
             awController.stSearch.swAttendance[0].at.Arrival_Time_Text__c = dt.format('hh:mm a');     
             awController.stSearch.swAttendance[0].at.Departure_Time_Text__c = dt.format('hh:mm a');  

             awController.stSearch.swAttendance[0].at.Picklist_Value__c = awController.stSearch.pvList[0].ID;
             awController.stSearch.submitAttendance();
             awController.stSearch.swAttendance[0].at.Picklist_Value__c = awController.stSearch.pvList[1].ID;
             awController.stSearch.submitAttendance();
             awController.stSearch.swAttendance[0].at.Picklist_Value__c = awController.stSearch.pvList[2].ID;
             awController.stSearch.submitAttendance();              
             awController.stSearch.swAttendance[0].at.Picklist_Value__c = awController.stSearch.pvList[3].ID;
             awController.stSearch.submitAttendance();                
          }
      }

      Test.stopTest();
    }
  }  

  static testMethod void adwSection() {
    setupData();

    system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
      Test.startTest();

      AttendanceWizard_v2 awController = new AttendanceWizard_v2();
      awController.attendanceDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.format();

      awController.bMode = 'Section';
      awController.loadInitialSearch();
      awController.RetrieveResults();
      if(awController.snSearch.sessionResults.size() > 0) {
        ApexPages.currentPage().getParameters().put('sessionID', awController.snSearch.sessionResults[0]);
        awController.snSearch.setup = testDataSetupUtil_v2.activeSetup;
        awController.snSearch.getEnrolledAttendance();

        awController.stSearch.submitAttendance();

       if(awController.snSearch.swAttendance.size() > 0) {
            awController.snSearch.swAttendance[0].at.Picklist_Value__c = awController.snSearch.pvList[2].ID;
            awController.snSearch.swAttendance[0].at.Comments__c = 'testing';
            awController.snSearch.submitAttendance();          
        }

        awController.getAfterSubmissionSuccess();
      }

      Test.stopTest();
    }
  }

  static testMethod void adwSection2() {
    setupData();

    system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
      Test.startTest();

      AttendanceWizard_v2 awController = new AttendanceWizard_v2();
      awController.attendanceDate = testDataSetupUtil_v2.semester.Date_Start_Date__c.format();

      awController.bMode = 'Section';
      awController.loadInitialSearch();
      awController.snSearch.sessionTime = '10:00 AM';
      awController.snSearch.staffMembers = 'Admin';
      awController.RetrieveResults();
      if(awController.snSearch.sessionResults.size() > 0) {
        ApexPages.currentPage().getParameters().put('sessionID', awController.snSearch.sessionResults[0]);
        awController.snSearch.setup = testDataSetupUtil_v2.activeSetup;
        awController.snSearch.getEnrolledAttendance();

        awController.stSearch.submitAttendance();

       if(awController.snSearch.swAttendance.size() > 0) {
            awController.snSearch.swAttendance[0].at.Picklist_Value__c = awController.snSearch.pvList[2].ID;
            awController.snSearch.swAttendance[0].at.Comments__c = 'testing';
            awController.snSearch.submitAttendance();          
        }

        awController.getAfterSubmissionSuccess();
      }

      Test.stopTest();
    }
  }  
}