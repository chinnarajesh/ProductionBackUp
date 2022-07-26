public with sharing class Section_StandardsListController {
	public Section__c section				{get;set;}
	public List<standardWrapper> standards	{get;set;}
	public boolean displayList				{get;set;}
	
	public Section_StandardsListController(ApexPages.StandardController stdCon){
		section = (Section__c) stdCon.getRecord();
		displayList = false;
		standards = new List<standardWrapper>();
		
		List<Section_Standard__c> linkingList = [select id, Standard__c
												from Section_Standard__c 
												where Section__c =: section.id];
		Set<Id> standardIds = new Set<Id>();
		for(Section_Standard__c s: linkingList){
			standardIds.add(s.Standard__c);
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