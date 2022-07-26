public class Gradebook_ManageStandardWeights {

	public static void isafterupdate(Map<Id, Standard_Weight_Config__c> newamap, Map<Id, Standard_Weight_Config__c> oldamap ) {
		Map<String, Double> standardWeightMap = new Map<String, Double>();
		Set<ID> sectionsToProcess = new Set<ID>();
		Set<ID> standardsToProcess = new Set<ID>();
		for (Standard_Weight_Config__c s: newamap.values() ) {
			system.debug('IN THE LOOP: ' + s);
		//check if standard weight was changed, if so update grade records
			if (newamap.get(s.Id).Default_Weighting__c <> oldamap.get(s.Id).Default_Weighting__c ) {
			//need to update Grade Records
				sectionsToProcess.add(s.Section__c);
				standardsToProcess.add(s.Standard__c);
				standardWeightMap.put(string.valueOf(s.Section__c)+string.valueOf(s.Standard__c), s.Default_Weighting__c);
			}
		}
	
		
		
		
		
		List<Grade__c> gradestoupdate = [Select Id, 
												Standard_Weighting__c,
												Standard__c,
												Student_Section__r.Section__c from Grade__c 
												where Student_Section__r.Section__c in : sectionsToProcess 
												AND Standard__c in : standardsToProcess
												AND Standard_Gradebook_Grade__c = null];
												
		for (Grade__c g: gradestoupdate ) {
			g.Standard_Weighting__c = standardWeightMap.get(String.valueOf(g.Student_Section__r.Section__c)+String.valueOf(g.Standard__c));
		}
		try{
			update gradestoupdate;
		}
		catch (Exception Ex) {
			system.debug(Ex);
		}
	} //end after update
	static testMethod Void test_core_GradeScaleCatalogController(){
    	
    			TestDataSetupUtil_v2.isGradebook=true;
		TestDataSetupUtil_v2.setUPCoreData(3);
		TestDataSetupUtil_v2.setUpStaffData(5);
		TestDataSetupUtil_v2.setUpStudentData(5);
		TestDataSetupUtil_v2.setUpStandards();
		List<Standard__c> standard = [SELECT id,Name FROM Standard__c WHERE Course__c=:TestDataSetupUtil_v2.coursesList[0].id];
		

    	system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
    		

    		Standard_Weight_Config__c swc = new Standard_Weight_Config__c(Default_Weighting__c = 1, Section__c = testdatasetuputil_v2.sectionsList[1].id, Standard__c = standard[0].id);
    		insert swc;
    		system.assert(swc.id!=null);

    		
    				Assignment__c a1 = new Assignment__c(Time__c=TestDataSetupUtil_v2.semester.id, Name='Test Assignment', Section__c=		TestDataSetupUtil_v2.sectionsList[1].id);
		insert a1;
		
		Student__c student = testDataSetupUtil_v2.studentsList[0];
		Grade__c g1 = new Grade__c(Time__c=TestDataSetupUtil_v2.semester.id,Assignment__c=a1.id, Course__c=		TestDataSetupUtil_v2.coursesList[0].id, Standard__c=standard[0].id, Student_Section__c=TestDataSetupUtil_v2.studSectionsList[1].id, Student__c=student.Id);

			g1.standard__c = standard[0].id;
    		g1.Student_Section__c = testdatasetuputil_v2.studSectionsList[1].id;
    		insert g1;
    		swc.default_weighting__c = 2;
    		update swc;
    		
    		
    		
    	}
	}
}