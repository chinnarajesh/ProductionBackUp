//Most of the code is based off of Section_StandardsListController
public with sharing class Assignment_StandardsListController {
	public Assignment__c assignment			{get;set;}
	public List<standardWrapper> standards	{get;set;}
	public boolean displayList				{get;set;}
	
	public Assignment_StandardsListController(ApexPages.StandardController stdCon){
		assignment = (Assignment__c) stdCon.getRecord();
		displayList = false;
		standards = new List<standardWrapper>();
		
		List<Grade__c> linkingList = [SELECT ID, Standard__c FROM Grade__c WHERE Assignment__c =: assignment.id];
		Set<Id> standardIds = new Set<Id>();
		for(Grade__c g : linkingList){
			if(g.Standard__c != null) {
				standardIds.add(g.Standard__c);
			}
		}
		
		List<Standard__c> standardList = [select id, Name, Subject__c, Long_Text__c,Parent_Standard__c, Strand__c 
											from Standard__c
											where id IN: standardIds];
												
		Set<Id> strandIds = new Set<Id>();
		Map<id, List<Standard__c>> strandStandardMap = new Map<id, List<Standard__c>>();
		for(Standard__c s: standardList){
			if(s.Strand__c != null){
				strandIds.add(s.Strand__c);
			}
			
			if(strandStandardMap.containsKey(s.Strand__c)){
				strandStandardMap.get(s.Strand__c).add(s);
			} else {
				strandStandardMap.put(s.Strand__c, new List<Standard__c>{s});
			}
		}
		
		List<Standard__c> strandList = [select id, Name, Subject__c, Long_Text__c 
										from Standard__c
										where id IN:strandIds];
		
		for(Standard__c s:strandList){
			standards.add(new standardWrapper(s, StrandStandardMap.get(s.id)));
		}
		
		 displayList = (standards.isEmpty())? false:true;
	}

	public class standardWrapper {
		public Standard__c standard					{get;set;}
		public List<Standard__c> childStandards		{get;set;}
		
		public standardWrapper(Standard__c strand, List<Standard__c> standards){
			standard = strand;
			childStandards = standards;
		}
	}
}