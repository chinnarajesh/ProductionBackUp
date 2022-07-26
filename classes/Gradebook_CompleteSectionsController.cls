public class Gradebook_CompleteSectionsController {
	public Gradebook_RunReportCardsController rrcc {get;set;}
	
	public Gradebook_CompleteSectionsController(){
		rrcc  = new Gradebook_RunReportCardsController();
		rrcc.useS3 = false;
		rrcc.gotoDocumentGeneration();
		//clear the as3 messages from run report cards
		for (Gradebook_RunReportCardsWrapper.schoolWrapper schoolWrapper: rrcc.schools){
			schoolWrapper.bTimeFilter=true;
		}
	}
	
	public void markSectionsCompleted(){
		Apexpages.getMessages().clear();
		List <Section_ReportingPeriod__c> srpList = new List <Section_ReportingPeriod__c>();
		for (Gradebook_RunReportCardsWrapper.sectionWrapper sectionWrapper:rrcc.sectionDisplayWrapper){
			if(sectionWrapper.srp != null){
				srpList.add(sectionWrapper.srp);
			}
		}
		rrcc.hideCurrentSections();
		try {
			update srpList;
			Apexpages.addMessage(new apexpages.message(apexpages.severity.Confirm,'Sections updated successfully!' ));
		} catch (exception e){
			Apexpages.addMessage(new apexpages.message(apexpages.severity.Fatal,'Error occurred when updating sections. Please contact your administrator.' ));
		}	
	}

	@isTest static void test_CompleteSections(){
		Test_Gradebook_RunReportCards.setupData();
		List<Section_ReportingPeriod__c> srpList = new List<Section_ReportingPeriod__c>();
		for(Section__c s:TestDataSetupUtil_v2.sectionsList){
			srpList.add(new Section_ReportingPeriod__c(
				Section__c = s.id, 
				Time__c = TestDataSetupUtil_v2.semester.id, 
				ReferenceId__c=s.id+'_'+TestDataSetupUtil_v2.semester.id, //why is it ReferenceId__c on here? *cries*
				RecordTypeID = core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('Published')
			)); 
		}
		insert srpList;

		Test.setCurrentPage(Page.Gradebook_CompleteSections);
		Test.startTest();
			Gradebook_CompleteSectionsController controller = new Gradebook_CompleteSectionsController();
			controller.rrcc.selectedSectionSchool = controller.rrcc.schools[0].setup.id;
			controller.rrcc.schools[0].selectedReportingPeriod = TestDataSetupUtil_v2.semester.id;
			controller.rrcc.showCurrentSections();
			controller.rrcc.sectionDisplayWrapper[0].srp.Completed__c = true;
			controller.markSectionsCompleted();
			system.assertEquals(true, controller.rrcc.schools[0].sections[0].srp.Completed__c);
			system.assertEquals(true, [select Completed__c from Section_ReportingPeriod__c where ID =:controller.rrcc.schools[0].sections[0].srp.id][0].Completed__c);
		Test.stopTest();
	}
}