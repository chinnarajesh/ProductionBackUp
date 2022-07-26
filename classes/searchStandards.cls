public with sharing class searchStandards {

	//search parameters as of now
	public String identifierSearch {get; set;}
	public String courseSearch {get; set;}
	public String strandSearch {get; set;}
	public String parentStandardSearch {get; set;}
	public String subjectSearch {get; set;}
	public String attributeSearch {get; set;}
	//public Boolean cityWideInstructionalExpectationSearch {get; set;}  //removed as requested in Anchorage
	public String SOSLsearch {get; set;}
	
	//DE3467: only for SOSL
	private Boolean isManagedPackage {get; set;}

	//stored results
	public List<standardWrapper> searchStandardResults {get; set;}
	public List<standardWrapper> selectedStandardsList {get; set;}
	Set<ID> selectedStandardsSet {get; set;}
	
	//result states
	public Boolean noResults {get; set;}
	public Boolean over500 {get; set;}
	public Boolean showStandards {get; set;}
	public Boolean noneSelected {get; set;}

	//strictly for aiding in visualforce pages
	public class standardWrapper {
		public Boolean selected {get; set;}
		public Boolean includeStandardGrade {get; set;}
		//will try to incorporate with editAssignStandards Later
		public Boolean doNotTouch {get; set;}
		public Standard__c standard {get; set;}
		
		public standardWrapper(Standard__c s) {
			selected = false;
			includeStandardGrade = true;
			doNotTouch = false;
			standard = s;
		}
	}
	
	public searchStandards() {
		noResults = true;
		over500 = false;
		showStandards = false;
		noneSelected = true;
		searchStandardResults = new List<standardWrapper>();
		selectedStandardsList = new List<standardWrapper>();
		selectedStandardsSet = new Set<ID>();
		
		//DE3467
		isManagedPackage = Schema.SObjectType.Assesment__c.getName().replace('__c', '').contains('__');
	}
	
	//used in the old assignment creation process
	public void searchMethod() {
		String searchQuery = 'SELECT Name, Citywide_Instructional_Expectation__c, Level__c, Long_Text__c, Attribute__c, Identifier__c, Id, Parent_Standard__c, Strand__c, Strand__r.Name, Subject__c, Standard_Subject__r.Name, Course__c, Course__r.Name FROM Standard__c ';
		String whereClause = 'WHERE ID != NULL ';
		String idWild = '';
		
		//Summer 2014 Release: make traditional assignment standard search similar to quick create standard search
		List<standardWrapper> temp = new List<standardWrapper>();
		for(standardWrapper sWrapper : searchStandardResults) {
			if(sWrapper.selected) {
				standardWrapper clone = new standardWrapper(sWrapper.standard);
				clone.selected = true;
				clone.includeStandardGrade = sWrapper.includeStandardGrade;
				temp.add(clone);
				selectedStandardsSet.add(sWrapper.standard.ID);
			} else {
				selectedStandardsSet.remove(sWrapper.standard.ID);
			}
		}
		searchStandardResults.clear();
		searchStandardResults.addAll(temp);		
		
		//Summer 2014 iteration 3: reminder that identifier is replaced with the Name field.
		if(String.isNotEmpty(identifierSearch)) {
			if(identifierSearch.contains('*')) {
				idWild = identifierSearch.replace('*', '');
			}
			else {
				idWild = identifierSearch;
			}
			whereClause += 'AND Name LIKE \'%' + String.escapeSingleQuotes(idWild) + '%\' ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		
		if(String.isNotEmpty(courseSearch)) {
			if(courseSearch.contains('*')) {
				courseSearch = courseSearch.replace('*', '');
			}
			whereClause += 'AND Course__r.Name LIKE \'%' + String.escapeSingleQuotes(courseSearch) + '%\' ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		
		if(String.isNotEmpty(strandSearch)) {
			if(strandSearch.contains('*')) {
				strandSearch = strandSearch.replace('*', '');
			}
			whereClause += 'AND Strand__r.Name LIKE \'%' + String.escapeSingleQuotes(strandSearch) + '%\' ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		
		if(String.isNotEmpty(subjectSearch)) {
			if(subjectSearch.contains('*')) {
				subjectSearch = subjectSearch.replace('*', '');
			}
			whereClause += 'AND (Subject__c LIKE \'%' + String.escapeSingleQuotes(subjectSearch) + '%\' OR Standard_Subject__r.Name LIKE\'%' + String.escapeSingleQuotes(subjectSearch) + '%\' ) ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		
		if(!attributeSearch.equalsIgnoreCase('All')) {
			whereClause += 'AND Attribute__c = \'' + String.escapeSingleQuotes(attributeSearch)+'\' ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		
		if(String.isNotEmpty(parentStandardSearch)) {
			if(parentStandardSearch.contains('*')) {
				parentStandardSearch = parentStandardSearch.replace('*', '');
			}
			//used to be Identifier__c, but it should be Name
			whereClause += 'AND Parent_Standard__r.Name LIKE \'%' + String.escapeSingleQuotes(parentStandardSearch) + '%\' ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		
		/*
		if(cityWideInstructionalExpectationSearch) {
			whereClause += 'AND Citywide_Instructional_Expectation__c = true ';
			system.debug('*~*~* WHERE: ' + whereClause);
		}
		*/
		
		system.debug('*~*~* final WHERE: ' + whereClause);
		string query = searchQuery + whereClause + 'AND Strand__c != NULL AND ID NOT IN: selectedStandardsSet ORDER BY Level__c DESC, Name LIMIT 500';
		
		//process the query
		try {
			for(Standard__c standard : Database.query(query)) {
				searchStandardResults.add(new standardWrapper(standard));
			}
			if(searchStandardResults.size() > 0) {
				noResults = false;
			}
			else {
				noResults = true;
			}
			if(searchStandardResults.size() == 500) {
				over500 = true;
			}
			else {
				over500 = false;
			}
		}
		catch(Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Failed standard query search! ' + e.getMessage()));
		}
	}
	
	//deprecated
	public void addMethod() {
		noneSelected = true;
		for(standardWrapper s : searchStandardResults) {
			if(s.selected) {
				//create new instance of the record, passed by reference
				standardWrapper temp =new standardWrapper(s.standard);
				temp.selected = false;
				temp.includeStandardGrade = s.includeStandardGrade; 
				selectedStandardsList.add(temp);
				selectedStandardsSet.add(temp.standard.ID);
				noneSelected = false;
			}
		}
		
		if(selectedStandardsList.size() > 0) {
			showStandards = true;
		}
		else {
			showStandards = false;
		}
	}
	
	//deprecated
	public void removeMethod() {
		List<standardWrapper> temp = new List<standardWrapper>();
		Set<ID> tempID = new Set<ID>();
		for(standardWrapper s : selectedStandardsList) {
			if(!s.selected) {
				temp.add(s);
				tempID.add(s.standard.ID);
			}	
		}
		selectedStandardsList = temp;
		selectedStandardsSet = tempID;
		
		if(selectedStandardsList.size() == 0) {
			showStandards = false;
		}
	}
	
	//updated 2/11/2014
	public void addStandards(List<Standard__c> standards) {
		for(Standard__c standard : standards) {
			//create new instance of the record, passed by reference
			standardWrapper temp =new standardWrapper(standard);
			temp.selected = true;
			temp.includeStandardGrade = true; 
			searchStandardResults.add(temp);
			noneSelected = false;
		}		
	}
	
	public void removeStandards() {
		selectedStandardsList.clear();
		selectedStandardsSet.clear();
		noneSelected = true;
		showStandards = false;
	}
	
	public List<Standard__c> getSelectedStandards() {
		List<Standard__c> returnList = new List<Standard__c>();
		for(standardWrapper sWrapper : searchStandardResults) {
			if(sWrapper.selected){
				returnList.add(sWrapper.standard);
			}
		}
		return returnList;
	}
	
	public Map<ID, Boolean> getStandardToInclude() {
		Map<ID, Boolean> returnMap = new Map<ID, Boolean>();
		for(standardWrapper sWrapper : searchStandardResults) {
			if(sWrapper.selected) {
				returnMap.put(sWrapper.standard.ID, sWrapper.includeStandardGrade);
			}
		}
		return returnMap;
	}
	
	//SOSL version
	public void SOSLsearchMethod() {
		List<standardWrapper> temp = new List<standardWrapper>();
		for(standardWrapper sWrapper : searchStandardResults) {
			if(sWrapper.selected) {
				standardWrapper clone = new standardWrapper(sWrapper.standard);
				clone.selected = true;
				clone.includeStandardGrade = sWrapper.includeStandardGrade;
				temp.add(clone);
				selectedStandardsSet.add(sWrapper.standard.ID);
			}
			else {
				selectedStandardsSet.remove(sWrapper.standard.ID);
			}
		}
		searchStandardResults.clear();
		searchStandardResults.addAll(temp);
		if(String.isNotEmpty(SOSLsearch) && SOSLsearch.length() > 1) {
			//DE3467
			String SchoolForce = '';
			if(isManagedPackage) {
				SchoolForce = 'SchoolForce__';
			}
			String query = 'FIND \'"' + String.escapeSingleQuotes(SOSLSearch) + '*"?\' IN ALL FIELDS RETURNING ' + SchoolForce + 'Standard__c(ID, Name, Level__c, Long_Text__c, Attribute__c, Identifier__c, Parent_Standard__c, Strand__c, Strand__r.Name, Subject__c, Standard_Subject__r.Name, Course__c, Course__r.Name WHERE Strand__c != NULL AND ID != NULL AND ID NOT IN: selectedStandardsSet)';
			List<List<SObject>> searchList = search.query(query);
			try {
				for(Standard__c standard : (List<Standard__c>)searchList[0]) {
					searchStandardResults.add(new standardWrapper(standard));
				}
				if(searchStandardResults.size() > 0) {
					noResults = false;
				}
				else {
					noResults = true;
				}
				if(searchStandardResults.size() == 500) {
					over500 = true;
				}
				else {
					over500 = false;
				}
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Failed standard query search! ' + e.getMessage()));
			}
		}
		else {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must enter at least 2 characters.'));
		}
	}
	
	public List<Standard__c> getSOSLSelectedStandards() {
		List<Standard__c> returnList = new List<Standard__c>();
		for(standardWrapper sWrapper : searchStandardResults) {
			if(sWrapper.selected) {
				returnList.add(sWrapper.standard);
			}
		}
		return returnList;		
	}
	
	public Map<ID, Boolean> getSOSLStandardToInclude() {
		Map<ID, Boolean> returnMap = new Map<ID, Boolean>();
		for(standardWrapper sWrapper : searchStandardResults) {
			if(sWrapper.selected) {
				returnMap.put(sWrapper.standard.ID, sWrapper.includeStandardGrade);
			}	
		}
		return returnMap;		
	}
}