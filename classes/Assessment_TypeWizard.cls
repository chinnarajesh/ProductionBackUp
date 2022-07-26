public with sharing class Assessment_TypeWizard {
	public Picklist_Value__c assessmentType			{get;set;}
	public List<fieldWrapper> assessmentFieldSet	{get;set;}
	private Map<String, String> assessmentAPIMap;
	private boolean isManagedPackage;
	
	public Assessment_TypeWizard(){
		string recordTypeID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
		isManagedPackage = Schema.SObjectType.Assesment__c.getName().replace('__c', '').contains('__');
		buildAssessmentFieldSet();
		
		string assessmentID = ApexPages.currentPage().getParameters().get('ID');
		if(assessmentID != null){
			assessmentType = Assessment_SoqlUtils.getTypesById(new Set<ID>{assessmentID})[0];
			Set<String> fieldSet = new Set<String>(stringUtils.splitAndTrim(assessmentType.fieldset__c, ','));
			for(fieldWrapper f: assessmentFieldSet){
				f.selected = fieldSet.contains(f.apiName);
			}
		} else {
			assessmentType = new Picklist_Value__c(RecordTypeId = recordTypeId);
		}
	}
	
	public PageReference save(){
		string fieldList = '';
		for(fieldWrapper f: assessmentFieldSet){
			if(f.selected){
				fieldList += (fieldList == '')?'':', ';
				fieldList += f.apiName;
			}
		}
		assessmentType.FieldSet__c = fieldList;
		
		try{
			upsert assessmentType;
			PageReference p = new PageReference('/'+Schema.SObjectType.Picklist_Value__c.getKeyPrefix()+'/o');
			p.setRedirect(true);
			return p;
		} catch (Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Save failed. Please try again.'));
			return null;
		}
	}
	
	public PageReference cancel(){
		PageReference p = new PageReference('/'+Schema.SObjectType.Picklist_Value__c.getKeyPrefix()+'/o');
		p.setRedirect(true);
		return p;
	}
	
	private void buildAssessmentFieldSet(){
		assessmentFieldSet = new List<fieldWrapper>();
		assessmentAPIMap = new Map<String, String>();
		
		//Set of fields to exclude always from assessment types
		Set<String> excludeSet = new Set<String>{'Student__c', 'Student_Id__c', 'Type__c', 'Contact__c'
												,'Date__c', 'External_Id__c', 'Time__c', 'Year_Over_Year__c'
												,'Show_On_Report_Card__c', 'Show_On_Transcript__c'};
		
		//Get field info for Assesment__c object			
		Map<String, Schema.SObjectField> describe = Schema.SObjectType.Assesment__c.fields.getMap();
		
		for(Schema.Sobjectfield s: describe.values()){
			string fieldName = String.valueOf(s);
			fieldName = (isManagedPackage)?fieldName.replace('SchoolForce__', ''):fieldName;

			if(fieldName.contains('__c') && !excludeSet.contains(fieldName)){
				string label = s.getDescribe().getLabel();
				assessmentFieldSet.add(new fieldWrapper(label, fieldName));
				assessmentAPIMap.put(fieldName, label);
			}
		}
		
		//sort
		assessmentFieldSet = sortList(assessmentFieldSet);
	}
	
	private List<fieldWrapper> sortList(List<fieldWrapper> orig){
		if(orig.size() <= 1){
			return orig;
		}
		List<fieldWrapper> left = new List<fieldWrapper>();
		List<fieldWrapper> right = new List<fieldWrapper>();
		List<fieldWrapper> result = new List<fieldWrapper>();
		integer mid = orig.size()/2;

		for(integer i=0;i<mid;i++) {
			left.add(orig[i]);
		}
		for(integer i=mid;i<orig.size();i++) {
			right.add(orig[i]);
		}

		left = sortList(left);
		right = sortList(right);
		result = mergeSort(left, right);
		return result;
	}

	private List<fieldWrapper> mergeSort(List<fieldWrapper> left, List<fieldWrapper> right){
		List<fieldWrapper> result = new List<fieldWrapper>();
		while(left.size() > 0 || right.size() > 0){
			if(left.size() > 0 && right.size() > 0){
				if(left[0].labelName < right[0].labelName){
					result.add(left.remove(0));
				} else {
					result.add(right.remove(0));
				}
			} else if(left.size() > 0) {
				result.add(left.remove(0));
			} else if(right.size() > 0) {
				result.add(right.remove(0));
			}
		}
		return result;
	}
	
	/* Wrapper Class */
	public class fieldWrapper{
		public string apiName	{get;set;}
		public string labelName	{get;set;}
		public boolean selected	{get;set;}
		
		private fieldWrapper(string label, string api){
			selected = false;
			apiName = api;
			labelName = label;
		}
	}
	
}