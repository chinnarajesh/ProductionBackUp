@isTest
private class Test_AssessmentTypeWizard {
	
	private static List<Picklist_Value__c> assessmentTypes = new List<Picklist_Value__c>();
	private static void setupData(){
		testDataSetupUtil_v2.setUPCoreData(0);
		testDataSetupUtil_v2.setUpStaffData(0);
		testDataSetupUtil_v2.setUpStudentData(3);
		
		string assessmentTypeRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
		
		assessmentTypes.add(new Picklist_Value__c(RecordTypeID = assessmentTypeRTID
												,FieldSet__c = 'Score__c, Goal_Met__c'
			));
			
		insert assessmentTypes;
	}
	
	private static testmethod void testConstructor(){
		setupdata();
		
		Assessment_TypeWizard wizard = new Assessment_TypeWizard();
		system.assert(wizard.assessmentFieldSet.size() > 0, 'There should be some available assessment fields.');
	}
	
	private static testmethod void testNewAssessment(){
		setupdata();
		
		Assessment_TypeWizard wizard = new Assessment_TypeWizard();
		
		wizard.assessmentType.Name = 'Test';
		wizard.save();
	}
	
	private static testmethod void testExistingAssessment(){
		setupdata();
		
		PageReference pref = Page.Assessment_TypeWizard;
		pref.getParameters().put('ID', assessmentTypes[0].id);
		Test.setCurrentPage(pref);
		Assessment_TypeWizard wizard = new Assessment_TypeWizard();
		
		system.assertEquals(assessmentTypes[0].id, wizard.assessmentType.id);
		wizard.save();
	}
	
	private static testmethod void testCancel(){
		setupdata();
		
		PageReference pref = Page.Assessment_TypeWizard;
		pref.getParameters().put('ID', assessmentTypes[0].id);
		Test.setCurrentPage(pref);
		Assessment_TypeWizard wizard = new Assessment_TypeWizard();
		wizard.cancel();
	}

	private static testmethod void testError(){
		setupdata();
		
		PageReference pref = Page.Assessment_TypeWizard;
		pref.getParameters().put('ID', assessmentTypes[0].id);
		Test.setCurrentPage(pref);
		Assessment_TypeWizard wizard = new Assessment_TypeWizard();
		wizard.assessmentFieldSet = null;
		try{
			wizard.save();
		}
		catch(Exception e){
		}
	}
}