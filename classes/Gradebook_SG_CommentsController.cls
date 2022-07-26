global with sharing class Gradebook_SG_CommentsController {

	public Gradebook_SG_CommentsController(GradebookController controller) {}
	
	@RemoteAction
	global static String updateComments_SG(Map<Id, String> sgCommentsMap, Map<Id, String> sgAltCommentsMap){
		try{
			List<Section_Grade__c> sGrades = new List<Section_Grade__c>();
			//US1284 quarters
			sGrades = [Select s.Alternate_Lang_Comments__c, s.Comments_Next_Steps__c, Do_Not_Show_in_PGV__c from Section_Grade__c s where (Id in :sgCommentsMap.keyset() OR Id in :sgAltCommentsMap.keyset()) AND (RecordTypeID = null OR RecordType.Name = 'Quarter')];
			for(Section_Grade__c sg : sGrades){
				if(sgCommentsMap.keyset().contains(sg.Id))
				sg.Comments_Next_Steps__c = sgCommentsMap.get(sg.Id);
				if(sgAltCommentsMap.keyset().contains(sg.Id))
				sg.Alternate_Lang_Comments__c = sgAltCommentsMap.get(sg.Id);
			}
			if(sGrades.size()>0){
				update sGrades;
				
				sgCommentsMap.clear();
				sgAltCommentsMap.clear();
			}
			return 'success';
		}
		catch(Exception e){
			return 'failure';
		}
	}
	
	@RemoteAction
	global static String updateComments_SG2(Map<Id, String> sgCommentsMap, Map<Id, String> sgAltCommentsMap, Map<ID, String> sgDoNotShow){
		try{
			List<Section_Grade__c> sGrades = new List<Section_Grade__c>();
			//US1284 quarters
			sGrades = [Select s.Alternate_Lang_Comments__c, s.Comments_Next_Steps__c, Do_Not_Show_in_PGV__c from Section_Grade__c s where (Id in :sgCommentsMap.keyset() OR Id in :sgAltCommentsMap.keyset() OR ID in :sgDoNotShow.keySet()) AND (RecordTypeID = null OR RecordType.Name = 'Quarter')];
			for(Section_Grade__c sg : sGrades){
				if(sgCommentsMap.keyset().contains(sg.Id))
				sg.Comments_Next_Steps__c = sgCommentsMap.get(sg.Id);
				if(sgAltCommentsMap.keyset().contains(sg.Id))
				sg.Alternate_Lang_Comments__c = sgAltCommentsMap.get(sg.Id);
				system.debug('sgDoNotShow: ' + sgDoNotShow.get(sg.ID));
				if(sgDoNotShow.get(sg.Id) == 'true') {
					sg.Do_Not_Show_in_PGV__c = true;
				}
				if(sgDoNotShow.get(sg.Id) == 'false') {
					sg.Do_Not_Show_in_PGV__c = false;
				}
			}
			if(sGrades.size()>0){
				update sGrades;
				
				sgCommentsMap.clear();
				sgAltCommentsMap.clear();
				sgDoNotShow.clear();
			}
			return 'success';
		}catch(Exception e){
			return 'failure';
		}
	}	
}