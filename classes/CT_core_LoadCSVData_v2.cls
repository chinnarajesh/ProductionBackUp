global without sharing class CT_core_LoadCSVData_v2 {
	public CT_core_SetupWrapper cSetup						{get;set;}
	public String selectedTemplate							{get;set;}
	public String selectedTemplateFieldSet					{get;set;}
	public Schema.SObjectType selectedTemplateObject 		{get;set;}
	public List<SelectOption> templateList					{get;set;}
	private Map<String, Schema.SObjectType> globalDescribe 	{get;set;}
	public String csvStringHeader 							{get;set;}
	public Boolean bManagedPackage							{get;set;}
	public String redirectType								{get;set;}

	public CT_core_LoadCSVData_v2() {
		templateList = new List<SelectOption>();
		redirectType = '';
		bManagedPackage = Schema.SobjectType.Setup__c.getName().replace('__c', '').contains('__');
		Id setupId = System.currentPageReference().getParameters().get('setupid');
		cSetup = new CT_core_SetupWrapper(String.isNotBlank(setupId)? CT_core_SoqlUtils.getSetupById(setupId): new Setup__c(),'load');

		if (String.isBlank(setupId)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'CSV Loader is not associated to a setup.'));
		}
		buildFieldSetMap();
		if(templateList.size() > 0) {
			if(System.currentPageReference().getParameters().containsKey('type')) {
				redirectType = System.currentPageReference().getParameters().get('type');
			}
			//determine how to populate selectedTemplate based on the redirectType
			selectedTemplate = (String.isNotBlank(redirectType) && redirectType != 'Scheduler')? 
					selectListContains(redirectType): templateList[0].getValue();
			if(String.isNotBlank(selectedTemplate)) {
				setSelectedTemplateParameters();
			}
			else if(String.isNotBlank(selectedTemplate) && String.isNotBlank(redirectType)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Cannot determine a template to select based on the redirect type: ' + redirectType));
			}
		}
		else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There are no templates to select from.  Please review your fieldsets on Objects.  Fieldsets must contain \'Template\' in its name for the CSV Data Loader to recognize the fieldset as a template.'));
		}

		if(ApexPages.currentPage().getParameters().containsKey('csv')) {
			String decode =  ApexPages.currentPage().getParameters().get('csv');
			csvStringHeader = EncodingUtil.urlDecode(decode, 'UTF-8');
			system.debug('*~*~* csvStringHeader: ' + csvStringHeader);
		}
		if(ApexPages.currentPage().getParameters().containsKey('selectedTemplate')) {
			selectedTemplate = ApexPages.currentPage().getParameters().get('selectedTemplate');
			if(String.isNotBlank(selectedTemplate)) {
				setSelectedTemplateParameters();
			}
		}		
	}

	public void buildFieldSetMap() {
		List<String> alphaKey = new List<String>();
		Map<String, String> labelToValue = new Map<String, String>();
		globalDescribe = Schema.getGlobalDescribe();
		for(Schema.SObjectType st : globalDescribe.Values()) {
			Schema.DescribeSObjectResult d = st.getDescribe();
			//map of all the FIELDSETS (not the actual fieldMembers per fieldset)
			Map<String, Schema.FieldSet> fsMap = d.fieldSets.getMap();
			for(String fsName : fsMap.KeySet()) {
				//this is not good coding practice, but because of salesforce package limitation and the inability to remove it, must exclude it
				if(fsName.toLowerCase().contains('template') && !(fsName.toLowerCase() == 'schoolforce__schedule_group_template' || fsName.toLowerCase() == 'schedule_group_template')) {
					//build the select option
					String v = d.getName() + ' - ' + fsName;
					String l = fsMap.get(fsName).getLabel();
					alphaKey.add(l);
					labelToValue.put(l, v);
					//templateList.add(new SelectOption(v, l));
				}
			}			
		}
		alphaKey.sort();
		for(String key : alphaKey) {
			if(labelToValue.containsKey(key)) {
				templateList.add(new SelectOption(labelToValue.get(key), key));
			}
		}
	}

	public String selectListContains(String redirectType) {
		String s = '';
		Set<String> parseType = new Set<String>(redirectType.split(' '));
		for(SelectOption so : templateList) {
			Boolean bContains = true;
			for(String word : parseType) {
				if(!so.getLabel().contains(word)) {
					bContains = false;
					break;
				}
			}
			if(bContains) {
				//return the first option
				s = so.getValue();
				break;
			}
		}
		return s;
	}

	public void setSelectedTemplateParameters() {
		List<String> sOptions = splitSelectOptionString(selectedTemplate);
		if (globalDescribe.containsKey(sOptions[0])) {
			selectedTemplateObject = globalDescribe.get(sOptions[0]);
		}
		selectedTemplateFieldSet = sOptions[1];
		system.debug('*~*~* sOptions[0]: ' + sOptions[0]);
		system.debug('*~*~* sOptions[1]: ' + sOptions[1]);
	}

	public List<Schema.FieldSetMember> getFields() {
		try {
			return selectedTemplateObject.getDescribe().fieldSets.getMap().get(selectedTemplateFieldSet).getFields();
		}
		catch(Exception e) {
			throw e;
		}
		return new List<Schema.FieldSetMember>();	
	}

	public PageReference downloadTemplate() {
		String s = '';
		String fileString = '';
		List<String> sOptions  = splitSelectOptionString(selectedTemplate);
		if(bManagedPackage) {
			sOptions[1] = sOptions[1].replace('schoolforce__', '');
		}
		//sOptions[1] = '%' + sOptions[1];
		try {
			List<StaticResource> querySR = [SELECT ID, Name, Body FROM StaticResource WHERE Name LIKE: sOptions[1] LIMIT 1];
			if(querySR.size() > 0) {
				fileString = querySR[0].body.toString();
			}
		}
		catch(Exception e) {
			e.setMessage('Cannot find default template for file: ' + sOptions[1]);
			throw e;
		}
		
		if(String.isNotBlank(fileString)) {
			s = fileString;
		}
		else {
			List<Schema.FieldSetMember> f = getFields();
			List<String> lstFields = new List<String>();
			for(Integer len = 0; len < f.size(); len++) {
				lstFields.add((f[len].getRequired()? '*REQ* ': '') + f[len].getLabel());
			}
			s += String.join(lstFields, ',');
		}

		csvStringHeader = s;
		PageReference pr = new PageReference('/apex/CT_core_LoadCsvData_dlTemplate');
		pr.getParameters().put('csv', EncodingUtil.urlencode(s, 'UTF-8'));
		if(System.currentPageReference().getParameters().containsKey('setupid')) {
			pr.getParameters().put('setupId', cSetup.setup.Id);
		}
		pr.getParameters().put('selectedTemplate', selectedTemplate);
		return pr;
	}

	@RemoteAction
	public static string getSRLink(String selectOptionString, Boolean bManagedPackage) {
		String pageContent = '';
		try {
			List<String> sOptions  = splitSelectOptionString(selectOptionString);
			if(bManagedPackage) {
				sOptions[1] = sOptions[1].replace('schoolforce__', '');
			}
			StaticResource sResource = [SELECT ID, Name, Body FROM StaticResource WHERE Name LIKE: sOptions[1] LIMIT 1];
			boolean isManagedPackage = Schema.SobjectType.Setup__c.getName().replace('__c', '').contains('__');
			String imagesID = String.valueOf(sResource.ID);
			PageReference pr = new PageReference('/' + imagesID);
			if(!Test.isRunningTest()){
				pageContent = pr.getContent().toString();
			}
			else{
				pageContent = '/resource/';
			}
			Integer startPC = pageContent.IndexOf('/resource/');
			pageContent = pageContent.subString(startPC, pageContent.length());
			Integer endPC = (isManagedPackage)?pageContent.indexOf('/SchoolForce__'+sResource.Name):pageContent.indexOf('/'+sResource.Name);
			pageContent = pageContent.subString(0, endPC) + '/';
			pageContent += (isManagedPackage)?'SchoolForce__':'';
			pageContent += sResource.Name;
		}
		catch(Exception e) {
			throw e;
		}
		return pageContent;
	}
	

	@RemoteAction
	public static ParsedDataHandler handleData(ParsedDataHandler inputData){
		//Notes:  Passing in only 100 records at a time for process.
		CSVDataHandler handler = (CSVDataHandler) inputData;
		handler.isManagedPackage = Schema.SobjectType.Setup__c.getName().replace('__c', '').contains('__');
		handler.totalRows = handler.csvData.size();
		handler.results = new List<ResultWrapper>();
		List<String> sOptions = splitSelectOptionString(handler.selectOptionString);
		handler.objectName = sOptions[0];
		handler.fieldSetName = sOptions[1];
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(handler.objectName);
		Schema.DescribeSObjectResult sObjectResult = targetType.getDescribe();
		if(handler.verifyHeader(sObjectResult)) {
			handler.insertData(targetType, sObjectResult);
		}
		return handler;
	}

	public static final String PREFIXMANAGEDPACKAGE = 'SchoolForce__';
	public static final String FLDTYPEHOLDING = 'Type__c';
	public static final String TYPEHOLDSTAFF = 'Staff';
	public static final String TYPEHOLDSTUDENT = 'Student';
	public static final String TYPEHOLDSS = 'StudentSection';
	//Helper Classes
	global class CSVDataHandler implements ParsedDataHandler{
		public List<List<String>> csvData	{get;set;}
		public List<ResultWrapper> results	{get;set;}
		public integer totalRows			{get;set;} //Page needs this as it can't remember or detect the sent rows after the ajax request
		public String selectOptionString	{get;set;}
		public String objectName			{get;set;}
		public String fieldSetName			{get;set;}
		public List<String> header			{get;set;}
		public String setupId 				{get;set;}
		public Boolean isManagedPackage		{get;set;}
		
		//Column -> Name values -> List<ID> (if there are more than 1 ID)
		private transient Map<String, Map<String, List<ID>>> columnToValueToIDMap;
		private	transient Map<String, String> lookupNameToObjectName;
		private	transient Map<String, String> fieldPathToLabel;

		private	transient Map<String, List<Boolean>> sectionToAttendanceCB;
		private	transient Map<String, Student__c> mapStudentExsists;
		private	transient Map<String, sObject> mapDublicates;

		private	transient Map<List<ID>, ID> srpKeyMap;
		private	transient Map<ID, ID> sectionToCourse;

		private	String 	sObjectName;
		private	String  mpPrefix;
		private Boolean bClassID;

		public CSVDataHandler(){
			totalRows = 0;
			isManagedPackage = Schema.SobjectType.Setup__c.getName().replace('__c', '').contains('__');
		}

		public List<List<String>> getData(){
			return csvData;
		}

		public Boolean verifyHeader(Schema.DescribeSObjectResult sObjectResult) {
			Boolean b = true;
			Integer index = 0;
			String errorHeader = '';
			Integer lookupLimitCounter = 0;
			try {
				for(Schema.FieldSetMember fsm : getFields(sObjectResult, fieldSetName)) {
					String tHeader = header[index];
					//System.debug('@@@ fsm: ' + fsm);
					//System.debug('@@@ tHeader: ' + tHeader);

					if(fsm.getRequired()) {
						if(tHeader.startsWith('*REQ* ')) {
							tHeader = header[index].subString(6);
						}
					}
					if(!(fsm.getFieldPath().equals(tHeader) || fsm.getLabel().equals(tHeader))) {
						errorHeader += 'Unexpected column: ' + tHeader + ' - Expected: ' + fsm.getLabel() + '(' + fsm.getFieldPath() + '), ';
						b = false;
					}
					if(fsm.getType() == Schema.DisplayType.Reference && fsm.getFieldPath().toLowerCase() != 'id') {
						lookupLimitCounter++;
					}
					index++;
				}
			}
			catch(Exception e) {
				throw new CT_Error_Handling.schoolForceException('The number of columns is less than the number of fields in the fieldset.');		
			}
			if(String.isNotBlank(errorHeader)) {
				b = false;
				throw new CT_Error_Handling.schoolForceException(errorHeader);
			}
			if(lookupLimitCounter > 10) {
				b = false;
				throw new CT_Error_Handling.schoolForceException('This template exceeds 10 references to data in SchoolForce. Modify the template with 10 or less references. ');
			}
			return b;
		}

		public List<Schema.FieldSetMember> getFields(Schema.DescribeSObjectResult sObjectResult, String fieldSetName) {
			try {
				return sObjectResult.fieldSets.getMap().get(fieldSetName).getFields();
			}
			catch(Exception e) {
				throw e;
			}
			return new List<Schema.FieldSetMember>();	
		}

		public void insertData(Schema.SObjectType targetType, Schema.DescribeSObjectResult sObjectResult) {
			Set<String> TYPESREQUIRED = new Set<String>{TYPEHOLDSTAFF,TYPEHOLDSTUDENT,TYPEHOLDSS};
			columnToValueToIDMap = new Map<String, Map<String, List<ID>>>();
			lookupNameToObjectName = new Map<String, String>();
			fieldPathToLabel = new Map<String, String>();
			Integer row = 0;

			sectionToAttendanceCB = new Map<String, List<Boolean>>();
			mapStudentExsists = new Map<String, Student__c>();
			mapDublicates = new Map<String, sObject>();
			Map<String, Set<String>> fieldToPicklist = new map<String, Set<String>>();
			Set<String> grades = new Set<String>();
			Set<String> setStudentIds = new Set<String>();
			Set<String> setSchoolDbns = new Set<String>();
			Set<String> setYearsIds = new Set<String>();

			//scheduled_section__c case...
			Set<ID> sectionIDs = new  Set<ID>();
			Set<ID> reportingPeriodIDs = new Set<ID>();
			srpKeyMap = new Map<List<ID>, ID>();
			sectionToCourse = new Map<ID, ID>();

			System.debug('@@@ FLDTYPEHOLDING: '+FLDTYPEHOLDING);
			CT_core_SetupWrapper currentSetup;
			sObjectName = sObjectResult.getName();
			sObjectName = isManagedPackage? sObjectName.replace(PREFIXMANAGEDPACKAGE, ''): sObjectName;
			mpPrefix = isManagedPackage? PREFIXMANAGEDPACKAGE: '';
			Map<String, Schema.SObjectField> mapsObjectFields = sObjectResult.fields.getMap();
			if(String.isNotBlank(setupId)) {
				currentSetup = new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'load');
				if(sObjectName == 'HoldingObj__c'){
					if(currentSetup.setup.Grade_Span__c == null){
						for(List<String> record:csvData){
							resultWrapper result = new ResultWrapper(true, '');
							result.isSuccess = false;
							result.row = row;
							result.errorMessage = 'The grade span for '+currentSetup.school.School_Full_Name__c+' has not yet been set. Please set a grade span before loading Holding Objects.';
							row++;
							results.add(result);
						}
						return;
					}
					grades.addAll(currentSetup.setup.Grade_Span__c.split(';'));
				}
			}

			Integer attendanceIncrement = 0;
			Integer consequenceIncrement = 0;
			Integer homeworkIncrement = 0;

			bClassID = false;

			for(List<String> record : csvData) {
				//create a resultWrapper per row.  Innocent until proven guilty
				resultWrapper result = new ResultWrapper(true, '');
				result.row = row;
				SObject token = targetType.newSObject();
				List<Schema.FieldSetMember> f = getFields(sObjectResult, fieldSetName);				
				//try {
					if(f.size() <= record.size()) {
						for(Integer column = 0; column < f.size(); column++) {
							Schema.DisplayType fsmType = f[column].getType();
							String fsmFieldPath = f[column].getFieldPath();
							Boolean fsmRequired = f[column].getRequired();
							String fsmLabel = f[column].getLabel();
							String fsmFieldPathName = (isManagedPackage && String.isNotBlank(fsmFieldPath))? fsmFieldPath.replace(PREFIXMANAGEDPACKAGE, ''): fsmFieldPath;
							//system.debug('*~*~* fsmType: ' + fsmType);
							//system.debug('*~*~* fsmFieldPath: ' + fsmFieldPath);
							//system.debug('*~*~* fsmRequired: ' + fsmRequired);
							//system.debug('*~*~* fsmLabel: ' + fsmLabel);
							//system.debug('*~*~* sobjectResult.getName: ' + sObjectName);
							if(String.isNotEmpty(record[column]) ) {
								record[column] = record[column].trim();
								try {
									if(fsmType == Schema.DisplayType.ID) {
										system.debug('Processing as ID');
										//two cases: record ID vs lookup ID
										if(fsmFieldPath.toLowerCase() == 'id') {
											if(isID(record[column])) {
												token.put(fsmFieldPath, record[column]);
											}
											else {
												result.isSuccess = false;
												result.errorMessage += 'The value in ' + fsmLabel + ' is not a Salesforce ID. A Salesforce ID is required in this column. ';
											}
										}
										else {	
											//two cases: actual ID vs Name value
											//system.debug('*~*~*not an ID field!');
											//system.debug('*~*~* record[column]: ' + record[column]);
											if(isID(record[column])) {
												token.put(fsmFieldPath, record[column]);
											}			
										}
									}
									else if(fsmType == Schema.DisplayType.Reference) {
										system.debug('Processing '+fsmLabel);
										//below logic for building map
										//populate List<ID> later once queried
										Schema.DescribeFieldResult dfr = mapsObjectFields.get(fsmFieldPathName).getDescribe();
										Schema.DescribeSObjectResult dsor = dfr.getReferenceTo()[0].getDescribe();
										lookupNameToObjectName.put(dfr.getName(), dsor.getName());

										if(!columnToValueToIDMap.containsKey(fsmFieldPath)){
											system.debug('Adding '+fsmFieldPath+' to map');
											system.debug('Adding '+record[column]+' to map');
											Map<String, List<ID>> temp = new Map<String, List<ID>>();
											temp.put(record[column], new List<ID>());
											columnToValueToIDMap.put(fsmFieldPath, temp);
										}
										else {
											system.debug('Adding '+record[column]+' to map');
											if(!columnToValueToIDMap.get(fsmFieldPath).containsKey(record[column])) {
												columnToValueToIDMap.get(fsmFieldPath).put(record[column], new List<ID>());
											}
										}
										if(!fieldPathToLabel.containsKey(fsmFieldPath)) {
											fieldPathToLabel.put(fsmFieldPath, fsmLabel);
										}
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.Integer) {
										token.put(fsmFieldPath, Integer.valueOf(record[column]));
									}
									else if(fsmType == Schema.DisplayType.Double) {
										token.put(fsmFieldPath, Double.valueOf(record[column]));
									}
									else if(fsmType == Schema.DisplayType.Boolean) {
										String enteredValue = record[column].toLowerCase();
										Boolean storedValue;
										if(enteredValue == 't' || enteredValue == 'true'){
											storedValue = true;
										} else if(enteredValue == 'f' || enteredValue == 'false'){
											storedValue = false;
										} else {
											result.isSuccess = false;
											result.errorMessage += 'The value in ' + fsmLabel + ' is not a/an ' + fsmType + '. A/an ' + fsmType + ' value is required in this column.';
										}
										token.put(fsmFieldPath, storedValue);
									}
									else if(fsmType == Schema.DisplayType.Date) {
										token.put(fsmFieldPath, Date.parse(record[column]));
									}
									else if(fsmType == Schema.DisplayType.DateTime) {
										token.put(fsmFieldPath, DateTime.parse(record[column]));
									}
									else if(fsmType == Schema.DisplayType.Time) {
										String tDateTime = system.today().format() + ' ' + record[column];
										token.put(fsmFieldPath, DateTime.parse(tDateTime).time());
									}
									else if(fsmType == Schema.DisplayType.Base64) {
										token.put(fsmFieldPath, EncodingUtil.base64Decode(record[column]));
									}
									else if(fsmType == Schema.DisplayType.Combobox) {
										//assume placing the selected value of the comboBox into the field
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.DataCategoryGroupReference) {
										//assume it's the name of the dataCategoryGroupReference name in reference
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.Email) {
										token.put(fsmFieldPath, record[column]);	
									}
									else if(fsmType == Schema.DisplayType.EncryptedString) {
										//just a string but encoded? can't find anything aboutt decoding an encryptedString
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.MultiPicklist) {
										//Technically selection is a string value, so enforce correct multiselection 
										//when encouontered the first time, build the map
										if(!fieldToPicklist.containsKey(fsmFieldPathName)) {
											Schema.DescribeFieldResult dfr = mapsObjectFields.get(fsmFieldPathName).getDescribe();
											Set<String> tSet = new Set<String>();
											for(Schema.PicklistEntry ple : dfr.getPicklistValues()) {
												tSet.add(ple.getValue());
											}
											fieldToPicklist.put(fsmFieldPathName, tSet);			
										}
										//after creating entry, need to parse record[column]: format = 'AAA;BBB'
										List<String> parseRecord = new List<String>(); 
										try {
											parseRecord = record[column].split(';');
										}
										catch(Exception e) {
											result.isSuccess = false;
											result.errorMessage += 'Failed to parse MultiPicklist: ' + record[column] + ' ';
										}
										Boolean bContainsAll = true;
										List<String> lstNotInPicklist = new List<String>();
										for(String pr: parseRecord){
											String p = pr.trim();
											if(!fieldToPicklist.get(fsmFieldPathName).contains(p)) {
												bContainsAll = false;
												lstNotInPicklist.add(p);
											}
										}
										if(bContainsAll) {
											token.put(fsmFieldPath, record[column]);
										}
										else {
											result.isSuccess = false;
											result.errorMessage += String.join(lstNotInPicklist, ', ') + ' is not in the ' + fsmLabel + ' picklist(s). ';
										}	
									}
									else if(fsmType == Schema.DisplayType.Percent) {
										token.put(fsmFieldPath, Double.valueOf(record[column]));
									}
									else if(fsmType == Schema.DisplayType.Phone) {
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.Picklist) {
										//when encouontered the first time, build the map
										if(!fieldToPicklist.containsKey(fsmFieldPathName)) {
											Schema.DescribeFieldResult dfr = mapsObjectFields.get(fsmFieldPathName).getDescribe();
											Set<String> tSet = new Set<String>();
											for(Schema.PicklistEntry ple : dfr.getPicklistValues()) {
												tSet.add(ple.getValue());
											}
											fieldToPicklist.put(fsmFieldPathName, tSet);			
										}
										//after creating entry check
										if(fieldToPicklist.get(fsmFieldPathName).contains(record[column])) {
											token.put(fsmFieldPath, record[column]);
										}
										else {
											result.isSuccess = false;
											result.errorMessage += record[column] + ' is not in the ' + fsmLabel + ' picklist. ';
										}
									}
									else if(fsmType == Schema.DisplayType.String) {
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.TextArea) {
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.Url) {
										token.put(fsmFieldPath, record[column]);
									}
									else {
										//hrm... probably goofed here
										//impossible, unless there are new types that are added in future releases, would have to implement at that point
									}	
								}
								catch(Exception e) {
									result.isSuccess = false;
									result.errorMessage += 'The value in ' + fsmLabel + ' is not a/an ' + fsmType + '. A/an ' + fsmType + ' value is required in this column. ';
								}


								//special case on Course__c for Subject_Area__c
								if(sObjectName == 'HoldingObj__c') {
									if(fsmFieldPathName == 'Class_Id__c') {
										bClassID = true;
									}
									if(fsmFieldPathName == 'Class_Id__c' && String.isNotBlank(record[column])) {
										if(!sectionToAttendanceCB.containsKey(record[column])) {
											sectionToAttendanceCB.put(record[column], new List<Boolean>());
										}
									}
									if(fsmFieldPathName == 'Grade_Level__c' && String.isNotBlank(record[column])) {
										if(!grades.contains(record[column])) {
											result.isSuccess = false;
											result.errorMessage += record[column] + ' is not a valid grade level for ' + currentSetup.school.School_Full_Name__c + ' for school year ' + currentSetup.setup.Year__r.Name__c + '. ';
										}
									}
									System.debug('@@@ TYPESREQUIRED: '+TYPESREQUIRED);
									if(fsmFieldPathName == FLDTYPEHOLDING && !TYPESREQUIRED.contains(record[column])){
										result.isSuccess = false;
										result.errorMessage += 'The Type '+record[column]+' is not valid';
									}
									//check date in school year
									if(fsmFieldPathName == 'Admission_Date__c' && String.isNotBlank(record[column])){
										Date entryDate = (Date)token.get('Admission_Date__c');
										if( !(entryDate>=currentSetup.setup.Year__r.Date_Start_Date__c && entryDate<=currentSetup.setup.Year__r.End_Date__c) ){
											result.isSuccess = false;
											result.errorMessage += record[column] + ' is not a valid Entry Date for school year ' + currentSetup.setup.Year__r.Name__c + '. ';
										}
									}										
								}	
								if(sObjectName == 'Scheduled_Section__c') {
									if(fsmFieldPathName == 'Section__c') {
										if(isID(record[column])) {
											sectionIDs.add(record[column]);
										}
										if(!sectionToAttendanceCB.containsKey(record[column])) {
											sectionToAttendanceCB.put(record[column], new List<Boolean>());
										}
									}
									if(fsmFieldPathName == 'Reporting_Period__c') {
										if(isID(record[column])) {
											reportingPeriodIDs.add(record[column]);
										}
									}
								}


							}
							else if(fsmRequired && String.isEmpty(record[column])) {	
								result.isSuccess = false;
								result.errorMessage += 'The following required column is blank: ' + fsmLabel + '. ';
							}
							else {
								if(sObjectName == 'Course__c') {
									if(fsmFieldPathName == 'Subject_Area__c' && String.isEmpty(record[column])) {
										token.put(fsmFieldPath, 'Other');
									}
								}
							}
						}//end of for loop fields
						

						//contains the Setup__c field
						try {							
							if(sObjectName == 'Picklist_Value__c') {
								if(String.isNotBlank(setupID)) {
									if(mapsObjectFields.containsKey('setup__c')) {
										token.put(mpPrefix+'Setup__c', setupId);
									}
									//populate the order value for 3 specific recordtypes
									if(token.get('RecordTypeId') == 'Attendance') {
										token.put(mpPrefix+'Order__c', attendanceIncrement);
										attendanceIncrement++;
									}
									if(token.get('RecordTypeId') == 'Consequence Type') {
										token.put(mpPrefix+'Order__c', consequenceIncrement);
										consequenceIncrement++;
									}
									if(token.get('RecordTypeId') == 'Homework') {
										token.put(mpPrefix+'Order__c', homeworkIncrement);
										homeworkIncrement++;
									}							
								}
							}
							if(sObjectName == 'HoldingObj__c') {
								if(String.isNotBlank(setupId)) {
									String key1 = 'School_Dbn__c';
									String key2 = 'School_Name__c';
									String key3 = 'School_Year__c';
									if(mapsObjectFields.containsKey(key1.toLowerCase())) {
										token.put(mpPrefix+key1, currentSetup.school.Reference_Id__c);
									}
									if(mapsObjectFields.containsKey(key2.toLowerCase())) {
										token.put(mpPrefix+key2, currentSetup.school.School_Full_Name__c);
									}
									if(mapsObjectFields.containsKey(key3.toLowerCase())) {
										token.put(mpPrefix+key3, currentSetup.setup.Year__r.Name__c);
									}
								}

								//populate students map
								String studentIdKey = (String)token.get(mpPrefix+'Student_Id__c');
								if(String.isNotBlank(studentIdKey)){
									mapStudentExsists.put(studentIdKey, null);
								}

								//fill map for dublicates
								String selType = (String)token.get(FLDTYPEHOLDING);
								if(selType == TYPEHOLDSTUDENT){
									//String keyStu = CT_ImportUtils.createStudentSchoolYearKey((HoldingObj__c)token, currentSetup.setup.School__r.RecordType.Name == 'Summer School');
									//mapDublicates.put(keyStu, token);
									setStudentIds.add((String)token.get('Student_ID__c'));
									setSchoolDbns.add((String)token.get('School_Dbn__c'));
									setYearsIds.add((String)token.get('School_Year__c'));
								}
							}
							if(sObjectName == 'Section__c') {
								if(String.isNotBlank(setupId)) {
									String key1 = 'Time__c';
									String key2 = 'School__c';
									if(mapsObjectFields.containsKey(key1.toLowerCase())) {
										token.put(mpPrefix+key1, currentSetup.setup.Year__c);
									}
									if(mapsObjectFields.containsKey(key2.toLowerCase())) {
										token.put(mpPrefix+key2, currentSetup.school.Id);
									}									
								}
							}
							if(sObjectName == 'Course__c') {
								if(String.isNotBlank(setupId) && currentSetup != null) {
									if(mapsObjectFields.containsKey('account__c')) {
										token.put(mpPrefix+'Account__c', currentSetup.school.Id);
									}
								}
							}
						}
						catch(Exception e) {
							system.debug(e.getMessage()+':'+e.getStackTraceString());
							result.isSuccess = false;
							result.errorMessage += e.getMessage() + '. ';
						}
					}
					else {
						result.isSuccess = false;
						result.errorMessage += 'The number of expected values in this record does not match the number of column headers. ';
					}
				//}
				//catch(Exception e) {
				//	result.isSuccess = false;
				//	result.errorMessage += e.getMessage() + '; ';
				//}
				if(result.isSuccess) {
					result.token = token;
				}
				results.add(result);
				row++;
			}

			//second round replace lookups with IDs (instead of names of the lookup)
			//system.debug('*~*~* columnToValueToIDMap.size: ' + columnToValueToIDMap.size());
			getLookupIds(columnToValueToIDMap, sectionIDs, reportingPeriodIDs);

			//check to add section verification
			getSectionToAttendanceCB(sectionToAttendanceCB, sectionIDs);

			//check to add student verification
			getExistedStudents(mapStudentExsists, currentSetup);

			//search dublicates
			mapDublicates = getDublicates(setStudentIds, setSchoolDbns, setYearsIds, currentSetup);

			//get cources and rps
			getSectionToCourse(sectionIDs, reportingPeriodIDs);

			//loop to replace lookup Names with IDs, this is now going through the results list
			populateLookup2Validate(results, currentSetup);

			//build insertion list and map placement
			Map<Integer, Integer> expectedToActualPosition = new Map<Integer, Integer>();
			List<SObject> insertions = new List<SObject>();
			Integer newPosition = 0;
			for(Integer i = 0; i < results.size(); i++) {
				if(results[i].isSuccess) {
					insertions.add(results[i].token);
					expectedToActualPosition.put(newPosition, i);
					newPosition++;
				}
			}
			List<Database.SaveResult> sResults = Database.insert(insertions, false);
			for(Integer i = 0; i < sResults.size(); i++) {
				if(!sResults[i].isSuccess()) {
					String errorString = '';
					for(Database.Error err : sResults[i].getErrors()) {
						errorString += err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields() + '. ';
					}
					Integer pos = expectedToActualPosition.get(i);
					results[pos].isSuccess = false;
					results[pos].errorMessage += errorString + '; ';
				}
			}
		}

		public void getLookupIds(Map<String, Map<String, List<ID>>> columnToValueToIDMap, Set<ID> sectionIDs, Set<ID> reportingPeriodIDs){
			for(String fieldPath : columnToValueToIDMap.KeySet()) {
				//build string query
				List<String> names = new List<String>();
				names.addAll(columnToValueToIDMap.get(fieldPath).KeySet());
				//system.debug('*~*~*: names: ' + names);
				//system.debug('*~*~* fieldPath: ' + fieldPath);
				String fieldPathObjectName = fieldPath;
				String fsmFieldPathName = (isManagedPackage && String.isNotBlank(fieldPath))? fieldPath.replace(PREFIXMANAGEDPACKAGE, ''): fieldPath;
				if(lookupNameToObjectName.containsKey(fieldPath)) {
					fieldPathObjectName = lookupNameToObjectName.get(fieldPath);
				}
				String queryString = 'SELECT ID, Name FROM ' + fieldPathObjectName  + ' WHERE Name IN: names';
				for(SObject so : Database.query(queryString)) {
					try {
						if(columnToValueToIDMap.get(fieldPath).containsKey((String)so.get('Name'))) {
							columnToValueToIDMap.get(fieldPath).get((String)so.get('Name')).add((ID)so.get('id'));
							//system.debug('*~*~* ID: ' + columnToValueToIDMap.get(fieldPath).get((String)so.get('Name')));
						}
						//if(columnToValueToIDMap.get(fieldPath).containsKey())
					}
					catch(Exception e) {
						throw e;
					}

					if(sObjectName == 'Scheduled_Section__c') {
						if(fsmFieldPathName == 'Section__c') {
							sectionIDs.add((ID)so.get('id'));
						}
						if(fsmFieldPathName == 'Reporting_Period__c') {
							reportingPeriodIDs.add((ID)so.get('id'));
						}
					}
				}
			}
		}

		public void getSectionToAttendanceCB(Map<String, List<Boolean>> sectionToAttendanceCB, Set<ID> sectionIDs){
			if(sectionToAttendanceCB.size() > 0 || sectionIDs.size()>0) {
				for(Section__c section : [SELECT ID, Name, Daily_Attendance__c, Record_Attendance__c FROM Section__c WHERE Name IN: sectionToAttendanceCB.KeySet() OR ID IN: sectionIDs]){
					if(sectionToAttendanceCB.containsKey(section.Name)) {
						sectionToAttendanceCB.get(section.Name).add(section.Daily_Attendance__c);
						sectionToAttendanceCB.get(section.Name).add(section.Record_Attendance__c);
						sectionToAttendanceCB.put(section.ID,new List<Boolean>{section.Daily_Attendance__c,section.Record_Attendance__c});
					}
					if(sectionToAttendanceCB.containsKey(section.ID) || sectionToAttendanceCB.containsKey(String.valueof(section.ID).subString(0,15))){
						sectionToAttendanceCB.remove(String.valueof(section.ID).subString(0,15)); //this fixes 15 to 18 conversion problems
						sectionToAttendanceCB.put(section.ID,new List<Boolean>{section.Daily_Attendance__c,section.Record_Attendance__c});
					}
				}
			}
		}

		public void getExistedStudents(Map<String, Student__c> mapStudentExsists, CT_core_SetupWrapper currentSetup){
			if(!mapStudentExsists.isEmpty()){
				for(Student__c s: [SELECT Id, Student_First_Name__c, Student_Last_Name__c, Student_Id__c FROM Student__c WHERE School__c = :currentSetup.school.Id AND Student_Id__c IN :mapStudentExsists.keySet()]){
					mapStudentExsists.put(s.Student_Id__c, s);
				}
			}
		}

		public Map<String, sObject> getDublicates(Set<String> setStudentIds, Set<String> setSchoolDbns, Set<String> setYearsIds, CT_core_SetupWrapper currentSetup){
			mapDublicates = new Map<String, sObject>();
			if(!setStudentIds.isEmpty() && !setSchoolDbns.isEmpty() && !setYearsIds.isEmpty()){
				for(HoldingObj__c ho: [SELECT Id, Local_Student_ID__c, Student_ID__c, School_Dbn__c, School_Year__c FROM HoldingObj__c 
						WHERE Student_ID__c IN :setStudentIds AND School_Dbn__c IN :setSchoolDbns AND School_Year__c IN :setYearsIds AND Propagated__c=false AND Type__c = :TYPEHOLDSTUDENT]){
					String keyStu = CT_ImportUtils.createStudentSchoolYearKey(ho, currentSetup.setup.School__r.RecordType.Name == 'Summer School');
					mapDublicates.put(keyStu, ho);
				}
			}
			return mapDublicates;
		}

		public void getSectionToCourse(Set<ID> sectionIDs, Set<ID> reportingPeriodIDs){
			if(sectionIDs.size() > 0 && reportingPeriodIDs.size() > 0) {
				for(Section_ReportingPeriod__c srp : [SELECT ID, Time__c, Section__c, Section__r.Course__c FROM Section_ReportingPeriod__c WHERE Section__c IN: sectionIDs AND Time__c IN: reportingPeriodIDs]) {
					List<ID> tempList = new List<ID>{srp.Section__c, srp.Time__c};
					srpKeyMap.put(tempList, srp.ID);
					sectionToCourse.put(srp.Section__c, srp.Section__r.Course__c);
				}
			}
		}

		public void populateLookup2Validate(List<ResultWrapper> results, CT_core_SetupWrapper currentSetup){
			for(ResultWrapper rw : results) {
				if(rw.isSuccess) {
					system.debug('Starting to check results');
					for(String field : columnToValueToIDMap.KeySet()) {
						try {
							String sKey = String.valueOf(rw.token.get(field));
							//system.debug('*~*~* sKey: ' + sKey);
							if(columnToValueToIDMap.get(field).containsKey(sKey)) {
								if(columnToValueToIDMap.get(field).get(sKey).size() > 1) {
									rw.isSuccess = false;
									rw.errorMessage += 'There are multiple records with the same identifying information in the ' + fieldPathToLabel.get(field) + ' column: ';
									Integer pos = columnToValueToIDMap.get(field).get(sKey).size()-1;
									rw.errorMessage += '('+String.join(columnToValueToIDMap.get(field).get(sKey), '), (')+'). ';
								}
								else if(columnToValueToIDMap.get(field).get(sKey).size() == 0){
									if(!isID(sKey)){
										rw.isSuccess = false;
										rw.errorMessage += 'No records in SchoolForce matched the following value entered in the ' + fieldPathToLabel.get(field) + ' column: ' + sKey + '. ';
									} else {
										rw.token.put(field,skey);
									}
								}
								else {
									rw.token.put(field, columnToValueToIDMap.get(field).get(sKey)[0]);
								}
							}
						}
						catch(Exception e) {
							rw.isSuccess = false;
							rw.errorMessage += e.getMessage() + '; ';
						}
					}

					if(sObjectName == 'HoldingObj__c' && bClassID) {
						try {
							String typeHolding = (String)rw.token.get(mpPrefix+FLDTYPEHOLDING);
							String secKey = (String)rw.token.get(mpPrefix+'Class_Id__c');
							//catches out of bound error first...
							if(sectionToAttendanceCB.get(secKey).size() > 0) {
								rw.token.put(mpPrefix+'Daily_Attendance__c', sectionToAttendanceCB.get(secKey)[0]);
								rw.token.put(mpPrefix+'Record_Attendance__c', sectionToAttendanceCB.get(secKey)[1]);
							}
							else {
								//?  Cannot find
								rw.isSuccess = false;
								rw.errorMessage += secKey + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';									
							}
							
							//validation: check if student exsists
							String stuKey = (String)rw.token.get(mpPrefix+'Student_Id__c');
							if(typeHolding == TYPEHOLDSS && String.isNotBlank(stuKey) && mapStudentExsists.get(stuKey)!=null){
								Student__c s = mapStudentExsists.get(stuKey);//check name student if match
								if(s.Student_First_Name__c!=rw.token.get(mpPrefix+'First_Name__c') || s.Student_Last_Name__c!=rw.token.get(mpPrefix+'Last_Name__c')){
									rw.isSuccess = false;
									rw.errorMessage += 'The existing student '+stuKey+' fields are not match (LastName: '+s.Student_Last_Name__c+' and FirstName: '+s.Student_First_Name__c+'). Review your school\'s schedule to ensure that the student exists';
								}
							}else if(typeHolding == TYPEHOLDSS){
								rw.isSuccess = false;
								rw.errorMessage += stuKey + ' is not an existing student. The student must exist before adding student/sections. Review your school\'s schedule to ensure that the student exists';
							}
						}
						catch(Exception e) {
							rw.isSuccess = false;
							rw.errorMessage += e.getMessage() + '; ';
						}
					}

					String selType = (String)rw.token.get(FLDTYPEHOLDING);
					if(sObjectName == 'HoldingObj__c' && !bClassID && selType == TYPEHOLDSTUDENT) {
						try {				
							//validation by dublicates
							String keyStu = CT_ImportUtils.createStudentSchoolYearKey((HoldingObj__c)rw.token, currentSetup.setup.School__r.RecordType.Name == 'Summer School');
							if(!mapDublicates.containsKey(keyStu)){
								mapDublicates.put(keyStu, rw.token);
							}else{
								rw.isSuccess = false;
								rw.errorMessage += 'Duplicate found in '+(String.isNotBlank(mapDublicates.get(keyStu).Id)? '<a href="/'+mapDublicates.get(keyStu).Id+'">Template</a>': 'file')+'. For student '+rw.token.get(mpPrefix+'First_Name__c')+', '+rw.token.get(mpPrefix+'Last_Name__c')+'. Review your csv file to ensure that the record does not exists.';
							}
						}
						catch(Exception e) {
							rw.isSuccess = false;
							rw.errorMessage += e.getMessage() + '; ';
						}							
					}
					if(sObjectName == 'Scheduled_Section__c') {
						try {
							ID sectionID = (ID)rw.token.get(mpPrefix+'Section__c');

							if(sectionToAttendanceCB.containsKey(sectionID) && sectionToAttendanceCB.get(sectionId).size() > 0){
								rw.token.put(mpPrefix+'Daily_Attendance__c', sectionToAttendanceCB.get(sectionID)[0]);
								rw.token.put(mpPrefix+'Record_Attendance__c', sectionToAttendanceCB.get(sectionID)[1]);
							}
							else {
								rw.isSuccess = false;
								//rw.errorMessage += sectionID + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';
								rw.errorMessage += 'Section: ' + sectionID + ' is not an existing Section. ';
							}
							List<ID> keyList = new List<ID>{sectionID, (ID)rw.token.get(mpPrefix+'Reporting_Period__c')};
							if(srpKeyMap.containsKey(keyList)) {
								rw.token.put(mpPrefix+'Section_ReportingPeriod__c', srpKeyMap.get(keyList));
							}
							else {
								rw.isSuccess = false;
								//rw.errorMessage += 'cannot find srp for this Scheduled Section.  Section: ' + keyList[0] + ' RP: ' + keyList[1];
								rw.errorMessage += 'Cannot find Section/Reporting Period records for Section: ' + keyList[0] + ', Reporting Period: ' + keyList[1] + '. ';
							}
							if(sectionToCourse.containsKey(sectionID)) {
								rw.token.put(mpPrefix+'Course__c', sectionToCourse.get(sectionID)); 
							}
							else {
								rw.isSuccess = false;
								//rw.errorMessage += 'Cannot find course for section:  ' + sectionID + '.  The course searched is derived from the section reportingperiod records.  Please verify that there are section reportingperiod records for that reporting period and section.';
								rw.errorMessage += 'There is no course associated to Section: ' + sectionID + '. ';
							}
						}
						catch(Exception e) {
							rw.isSuccess = false;
							rw.errorMessage += e.getMessage() + '; ';
						}
					}
				}
			}
		}

		public Boolean isID(String value) {
			system.debug('Checking for ID '+value);
			ID newID;
			try {
				newID = (ID)value;
				system.debug('IS ID');
				return true;
			}
			catch(Exception e) {
				system.debug('IS NOT ID');
				return false;
			}
		}
	}

	public static List<String> splitSelectOptionString(String selectOptionString) {
		//expected format: 'ObjectLabel - FieldSetLabel'
		List<String> splitter = selectOptionString.split(' - ');
		List<String> returnList = new List<String>();
		try {
			returnList.add(splitter[0].deleteWhiteSpace());
			returnList.add(splitter[1]);
		}
		catch(Exception e) {
			throw e;
		}
		return returnList;
	}	

	public class ResultWrapper{
		Integer row {get;set;}
		Boolean hasID {get;set;}
		SObject token {get;set;}
		Boolean isSuccess {get;set;}
		String errorMessage {get;set;}
		public ResultWrapper(boolean isSuccess, String errorMessage){
			this.isSuccess = isSuccess;
			this.errorMessage = errorMessage;
		}
	}

	public Interface ParsedDataHandler{
		List<Object> getData();
	}
}