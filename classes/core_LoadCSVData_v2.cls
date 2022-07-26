global class core_LoadCSVData_v2 {
	public core_SetupWrapper cSetup							{get;set;}
	public String selectedTemplate							{get;set;}
	public String selectedTemplateFieldSet					{get;set;}
	public Schema.SObjectType selectedTemplateObject 		{get;set;}
	public List<SelectOption> templateList					{get;set;}
	private Map<String, Schema.SObjectType> globalDescribe 	{get;set;}
	public String csvStringHeader 							{get;set;}
	public Boolean bManagedPackage							{get;set;}
	public String redirectType								{get;set;}

	public core_LoadCSVData_v2() {
		//else {
			templateList = new List<SelectOption>();
			redirectType = '';
			bManagedPackage = Schema.SobjectType.Setup__c.getName().replace('__c', '').contains('__');
			if (System.currentPageReference().getParameters().containsKey('setupid')){
				ID setupId = System.currentPageReference().getParameters().get('setupid');
				cSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'load');
			}
			else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'CSV Loader is not associated to a setup.'));
			}
			buildFieldSetMap();
			if(templateList.size() > 0) {
				if(System.currentPageReference().getParameters().containsKey('type')) {
					redirectType = System.currentPageReference().getParameters().get('type');
				}
				if(String.isNotBlank(redirectType) && redirectType != 'Scheduler') {
					//determine how to populate selectedTemplate based on the redirectType
					selectedTemplate = selectListContains(redirectType);
				}
				else {
					selectedTemplate = templateList[0].getValue();
				}
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
		//}

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
			for(Integer len = 0; len < f.size(); len++) {
				if(f[len].getRequired()) {
					s+='*REQ* ';
				}

				if(f.size()-1 == len) {
					s += f[len].getLabel();
				}
				else {
					s += f[len].getLabel() + ',';
				}
			}	
				
		}

		csvStringHeader = s;
		PageReference pr = new PageReference('/apex/core_LoadCSVData_dlTemplate');
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
					//system.debug('*~*~* fsm.fieldPath: ' + fsm.getFieldPath());
					//system.debug('*~*~* header.size: ' + header.size());
					String tHeader = header[index];
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
				throw new Error_Handling.schoolForceException('The number of columns is less than the number of fields in the fieldset.');		
			}
			if(String.isNotBlank(errorHeader)) {
				b = false;
				throw new Error_Handling.schoolForceException(errorHeader);
			}
			if(lookupLimitCounter > 10) {
				b = false;
				throw new Error_Handling.schoolForceException('This template exceeds 10 references to data in SchoolForce. Modify the template with 10 or less references. ');
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
			//Column -> Name values -> List<ID> (if there are more than 1 ID)
			Map<String, Map<String, List<ID>>> columnToValueToIDMap = new Map<String, Map<String, List<ID>>>();
			Map<String, String> lookupNameToObjectName = new Map<String, String>();
			Map<String, String> fieldPathToLabel = new Map<String, String>();
			Integer row = 0;

			Set<String> grades = new Set<String>();

			Map<String, List<Boolean>> sectionToAttendanceCB = new Map<String, List<Boolean>>();

			Map<String, Set<String>> fieldToPicklist = new map<String, Set<String>>();

			//scheduled_section__c case...
			Set<ID> sectionIDs = new  Set<ID>();
			Set<ID> reportingPeriodIDs = new Set<ID>();
			Map<List<ID>, ID> srpKeyMap = new Map<List<ID>, ID>();
			Map<ID, ID> sectionToCourse = new Map<ID, ID>();

			core_SetupWrapper currentSetup;
			if(String.isNotBlank(setupId)) {
				currentSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'load');
				if(sObjectResult.getName() == 'SchoolForce__HoldingObj__c' || sObjectResult.getName() == 'HoldingObj__c'){
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

			Boolean bClassID = false;

			for(List<String> record : csvData) {
				//create a resultWrapper per row.  Innocent until proven guilty
				resultWrapper result = new ResultWrapper(true, '');
				result.row = row;
				SObject token = targetType.newSObject();
				List<Schema.FieldSetMember> f = getFields(sObjectResult, fieldSetName);				
				try {
					if(f.size() <= record.size()) {
						for(Integer column = 0; column < f.size(); column++) {
							Schema.DisplayType fsmType = f[column].getType();
							String fsmFieldPath = f[column].getFieldPath();
							Boolean fsmRequired = f[column].getRequired();
							String fsmLabel = f[column].getLabel();
							//system.debug('*~*~* fsmType: ' + fsmType);
							//system.debug('*~*~* fsmFieldPath: ' + fsmFieldPath);
							//system.debug('*~*~* fsmRequired: ' + fsmRequired);
							//system.debug('*~*~* fsmLabel: ' + fsmLabel);
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
										String packagePath = fsmFieldPath;
										if(isManagedPackage) {
											packagePath = packagePath.replace('SchoolForce__', '');
										}
										Schema.DescribeFieldResult dfr = sObjectResult.fields.getMap().get(packagePath).getDescribe();
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
										String packagePath = fsmFieldPath;
										if(isManagedPackage) {
											packagePath = packagePath.replace('SchoolForce__', '');
										}
										//when encouontered the first time, build the map
										if(!fieldToPicklist.containsKey(packagePath)) {
											Schema.DescribeFieldResult dfr = sObjectResult.fields.getMap().get(packagePath).getDescribe();
											Set<String> tSet = new Set<String>();
											for(Schema.PicklistEntry ple : dfr.getPicklistValues()) {
												tSet.add(ple.getValue());
											}
											fieldToPicklist.put(packagePath, tSet);			
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
										String notInPicklist = '';
										for(Integer i = 0; i < parseRecord.size(); i++) {
											String p = parseRecord[i].trim();
											if(!fieldToPicklist.get(packagePath).contains(p)) {
												bContainsAll = false;
												if(i == parseRecord.size() - 1) {
													notInPicklist += p;
												}
												else {
													notInPicklist += p + ', ';
												}
											}
										}
										if(bContainsAll) {
											token.put(fsmFieldPath, record[column]);
										}
										else {
											result.isSuccess = false;
											result.errorMessage += notInPicklist + ' is not in the ' + fsmLabel + ' picklist(s). ';
										}	
									}
									else if(fsmType == Schema.DisplayType.Percent) {
										token.put(fsmFieldPath, Double.valueOf(record[column]));
									}
									else if(fsmType == Schema.DisplayType.Phone) {
										token.put(fsmFieldPath, record[column]);
									}
									else if(fsmType == Schema.DisplayType.Picklist) {
										String packagePath = fsmFieldPath;
										if(isManagedPackage) {
											packagePath = packagePath.replace('SchoolForce__', '');
										}
										//when encouontered the first time, build the map
										if(!fieldToPicklist.containsKey(packagePath)) {
											Schema.DescribeFieldResult dfr = sObjectResult.fields.getMap().get(packagePath).getDescribe();
											Set<String> tSet = new Set<String>();
											for(Schema.PicklistEntry ple : dfr.getPicklistValues()) {
												tSet.add(ple.getValue());
											}
											fieldToPicklist.put(packagePath, tSet);			
										}
										//after creating entry check
										if(fieldToPicklist.get(packagePath).contains(record[column])) {
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
								if(isManagedPackage){
									if(sObjectResult.getName() == 'SchoolForce__HoldingObj__c') {
										if(fsmFieldPath == 'SchoolForce__Class_Id__c') {
											bClassID = true;
										}
										if(fsmFieldPath == 'SchoolForce__Class_Id__c' && String.isNotBlank(record[column])) {
											if(!sectionToAttendanceCB.containsKey(record[column])) {
												sectionToAttendanceCB.put(record[column], new List<Boolean>());
											}
										}
										if(fsmFieldPath == 'SchoolForce__Grade_Level__c' && String.isNotBlank(record[column])) {
											if(!grades.contains(record[column])) {
												result.isSuccess = false;
												result.errorMessage += record[column] + ' is not a valid grade level for ' + currentSetup.school.School_Full_Name__c + ' for school year ' + currentSetup.setup.Year__r.Name__c + '. ';
											}
										}
										if(fsmFieldPath == 'SchoolForce__Type__c' && record[column]!='Student' && record[column]!='Staff'){
											result.isSuccess = false;
											result.errorMessage += 'The Type '+record[column]+' is not valid';
										}
										//check date in school year
										if(fsmFieldPath == 'SchoolForce__Admission_Date__c' && String.isNotBlank(record[column])){
											Date entryDate = (Date)token.get('SchoolForce__Admission_Date__c');
											if( !(entryDate>=currentSetup.setup.Year__r.Date_Start_Date__c && entryDate<=currentSetup.setup.Year__r.End_Date__c) ){
												result.isSuccess = false;
												result.errorMessage += record[column] + ' is not a valid Entry Date for school year ' + currentSetup.setup.Year__r.Name__c + '. ';
											}
										}										
									}
									if(sObjectResult.getName() == 'SchoolForce__Scheduled_Section__c') {
										if(fsmFieldPath == 'SchoolForce__Section__c') {
											if(isID(record[column])) {
												sectionIDs.add(record[column]);
											}
											if(!sectionToAttendanceCB.containsKey(record[column])) {
												sectionToAttendanceCB.put(record[column], new List<Boolean>());
											}
										}
										if(fsmFieldPath == 'SchoolForce__Reporting_Period__c') {
											if(isID(record[column])) {
												reportingPeriodIDs.add(record[column]);
											}
										}
									}																		
								}
								else {
									if(sObjectResult.getName() == 'HoldingObj__c') {
										if(fsmFieldPath == 'Class_Id__c') {
											bClassID = true;
										}
										if(fsmFieldPath == 'Class_Id__c' && String.isNotBlank(record[column])) {
											if(!sectionToAttendanceCB.containsKey(record[column])) {
												sectionToAttendanceCB.put(record[column], new List<Boolean>());
											}
										}
										if(fsmFieldPath == 'Grade_Level__c' && String.isNotBlank(record[column])) {
											if(!grades.contains(record[column])) {
												result.isSuccess = false;
												result.errorMessage += record[column] + ' is not a valid grade level for ' + currentSetup.school.School_Full_Name__c + ' for school year ' + currentSetup.setup.Year__r.Name__c + '. ';
											}
										}
										if(fsmFieldPath == 'Type__c' && record[column]!='Student' && record[column]!='Staff'){
											result.isSuccess = false;
											result.errorMessage += 'The Type '+record[column]+' is not valid';
										}
										//check date in school year
										if(fsmFieldPath == 'Admission_Date__c' && String.isNotBlank(record[column])){
											Date entryDate = (Date)token.get('Admission_Date__c');
											if( !(entryDate>=currentSetup.setup.Year__r.Date_Start_Date__c && entryDate<=currentSetup.setup.Year__r.End_Date__c) ){
												result.isSuccess = false;
												result.errorMessage += record[column] + ' is not a valid Entry Date for school year ' + currentSetup.setup.Year__r.Name__c + '. ';
											}
										}										
									}	
									if(sObjectResult.getName() == 'Scheduled_Section__c') {
										if(fsmFieldPath == 'Section__c') {
											if(isID(record[column])) {
												sectionIDs.add(record[column]);
											}
											if(!sectionToAttendanceCB.containsKey(record[column])) {
												sectionToAttendanceCB.put(record[column], new List<Boolean>());
											}
										}
										if(fsmFieldPath == 'Reporting_Period__c') {
											if(isID(record[column])) {
												reportingPeriodIDs.add(record[column]);
											}
										}
									}																	
								}
							}
							else if(fsmRequired && String.isEmpty(record[column])) {	
								result.isSuccess = false;
								result.errorMessage += 'The following required column is blank: ' + fsmLabel + '. ';
							}
							else {
								if(isManagedPackage) {
									if(sObjectResult.getName() == 'SchoolForce__Course__c') {
										if(fsmFieldPath == 'SchoolForce__Subject_Area__c' && String.isEmpty(record[column])) {
											token.put(fsmFieldPath, 'Other');
										}
									}
								}
								else {
									if(sObjectResult.getName() == 'Course__c') {
										if(fsmFieldPath == 'Subject_Area__c' && String.isEmpty(record[column])) {
											token.put(fsmFieldPath, 'Other');
										}
									}									
								}
							}
						}//end of for loop
						//contains the Setup__c field
						try {
							system.debug('*~*~* isManagedPackage: ' + isManagedPackage);
							system.debug('*~*~* sobjectResult.getName: ' + sObjectResult.getName());
							if(isManagedPackage) {
								if(sObjectResult.getName() == 'SchoolForce__Picklist_Value__c') {
									if(String.isNotBlank(setupID)) {
										system.debug('*~*~*: key = schoolforce__setup__c');
										if(sObjectResult.fields.getMap().containsKey('schoolforce__setup__c')) {
											token.put('SchoolForce__Setup__c', setupId);
										}
										else if(sObjectResult.fields.getMap().containsKey('setup__c')) {
											system.debug('*~*~* key = setup__c');
											token.put('SchoolForce__Setup__c', setupId);
										} 
									}
									//populate the order value for 3 specific recordtypes
									if(token.get('RecordTypeId') == 'Attendance') {
										token.put('SchoolForce__Order__c', attendanceIncrement);
										attendanceIncrement++;
									}
									if(token.get('RecordTypeId') == 'Behavior Consequence') {
										token.put('SchoolForce__Order__c', consequenceIncrement);
										consequenceIncrement++;
									}
									if(token.get('RecordTypeId') == 'Homework') {
										token.put('SchoolForce__Order__c', homeworkIncrement);
										homeworkIncrement++;
									}
								}
								if(sObjectResult.getName() == 'SchoolForce__HoldingObj__c') {
									if(String.isNotBlank(setupId)) {
										system.debug('*~*~* keys = schoolforce__school_dbn__c, schoolforce__school_name__c, schoolforce__school_year__c');
										String key1 = 'SchoolForce__School_Dbn__c';
										String key2 = 'SchoolForce__School_Name__c';
										String key3 = 'SchoolForce__School_Year__c';
										if(sObjectResult.fields.getMap().containsKey(key1.toLowerCase())) {
											token.put(key1, currentSetup.school.Reference_Id__c);
										}
										else if(sObjectResult.fields.getMap().containsKey('school_dbn__c')) {
											system.debug('*~*~* key = school_dbn__c');
											token.put(key1, currentSetup.school.Reference_Id__c);
										}
										if(sObjectResult.fields.getMap().containsKey(key2.toLowerCase())) {
											token.put(key2, currentSetup.school.School_Full_Name__c);
										}
										else if(sObjectResult.fields.getMap().containsKey('school_name__c')) {
											system.debug('*~*~* key = school_name__c');
											token.put(key2, currentSetup.school.School_Full_Name__c);
										}
										if(sObjectResult.fields.getMap().containsKey(key3.toLowerCase())) {
											token.put(key3, currentSetup.setup.Year__r.Name__c);
										}
										else if(sObjectResult.fields.getMap().containsKey('school_year__c')) {
											system.debug('*~*~* key = school_year__c');
											token.put(key3, currentSetup.setup.Year__r.Name__c);
										}
									}
								}
								if(sObjectResult.getName() == 'SchoolForce__Section__c') {
									if(String.isNotBlank(setupId)) {
										system.debug('*~*~* keys = schoolforce__time__c, schoolforce__school__c');
										String key1 = 'SchoolForce__Time__c';
										String key2 = 'SchoolForce__School__c';
										if(sObjectResult.fields.getMap().containsKey(key1.toLowerCase())) {
											token.put(key1, currentSetup.setup.Year__c);
										}
										else if(sObjectResult.fields.getMap().containsKey('time__c')) {
											system.debug('*~*~* key = time__c');
											token.put(key1, currentSetup.setup.Year__c);
										}
										if(sObjectResult.fields.getMap().containsKey(key2.toLowerCase())) {
											token.put(key2, currentSetup.school.Id);
										}
										else if(sObjectResult.fields.getMap().containsKey('school__c')) {
											system.debug('*~*~* key = school__c');
											token.put(key2, currentSetup.school.Id);
										}
									}
								}
								if(sObjectResult.getName() == 'SchoolForce__Course__c') {
									if(String.isNotBlank(setupId)) {
										system.debug('*~*~* key = schoolforce__account__c');
										if(sObjectResult.fields.getMap().containsKey('schoolforce__account__c')) {
											token.put('SchoolForce__Account__c', currentSetup.school.Id);
										}
										else if(sObjectResult.fields.getMap().containsKey('account__c')) {
											system.debug('*~*~* key = account__c');
											token.put('SchoolForce__Account__c', currentSetup.school.Id);
										}
									}
								}								
							}
							else {
								if(sObjectResult.getName() == 'Picklist_Value__c') {
									if(String.isNotBlank(setupID)) {
										if(sObjectResult.fields.getMap().containsKey('setup__c')) {
											token.put('Setup__c', setupId);
										}
										//populate the order value for 3 specific recordtypes
										if(token.get('RecordTypeId') == 'Attendance') {
											token.put('Order__c', attendanceIncrement);
											attendanceIncrement++;
										}
										if(token.get('RecordTypeId') == 'Consequence Type') {
											token.put('Order__c', consequenceIncrement);
											consequenceIncrement++;
										}
										if(token.get('RecordTypeId') == 'Homework') {
											token.put('Order__c', homeworkIncrement);
											homeworkIncrement++;
										}							
									}
								}
								if(sObjectResult.getName() == 'HoldingObj__c') {
									if(String.isNotBlank(setupId)) {
										String key1 = 'School_Dbn__c';
										String key2 = 'School_Name__c';
										String key3 = 'School_Year__c';
										if(sObjectResult.fields.getMap().containsKey(key1.toLowerCase())) {
											token.put(key1, currentSetup.school.Reference_Id__c);
										}
										if(sObjectResult.fields.getMap().containsKey(key2.toLowerCase())) {
											token.put(key2, currentSetup.school.School_Full_Name__c);
										}
										if(sObjectResult.fields.getMap().containsKey(key3.toLowerCase())) {
											token.put(key3, currentSetup.setup.Year__r.Name__c);
										}									
									}
								}
								if(sObjectResult.getName() == 'Section__c') {
									if(String.isNotBlank(setupId)) {
										String key1 = 'Time__c';
										String key2 = 'School__c';
										if(sObjectResult.fields.getMap().containsKey(key1.toLowerCase())) {
											token.put(key1, currentSetup.setup.Year__c);
										}
										if(sObjectResult.fields.getMap().containsKey(key2.toLowerCase())) {
											token.put(key2, currentSetup.school.Id);
										}									
									}
								}
								if(sObjectResult.getName() == 'Course__c') {
									if(String.isNotBlank(setupId) && currentSetup != null) {
										if(sObjectResult.fields.getMap().containsKey('account__c')) {
											token.put('Account__c', currentSetup.school.Id);
										}
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
				}
				catch(Exception e) {
					result.isSuccess = false;
					result.errorMessage += e.getMessage() + '; ';
				}
				if(result.isSuccess) {
					result.token = token;
				}
				results.add(result);
				row++;
			}
			//second round replace lookups with IDs (instead of names of the lookup)
			//system.debug('*~*~* columnToValueToIDMap.size: ' + columnToValueToIDMap.size());
			for(String fieldPath : columnToValueToIDMap.KeySet()) {
				//build string query
				List<String> names = new List<String>();
				names.addAll(columnToValueToIDMap.get(fieldPath).KeySet());
				//system.debug('*~*~*: names: ' + names);
				//system.debug('*~*~* fieldPath: ' + fieldPath);
				String fieldPathObjectName = fieldPath;
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

					if(isManagedPackage) {
						if(sObjectResult.getName() == 'SchoolForce__Scheduled_Section__c') {
							if(fieldPath == 'SchoolForce__Section__c') {
								sectionIDs.add((ID)so.get('id'));
							}
							if(fieldPath == 'SchoolForce__Reporting_Period__c') {
								reportingPeriodIDs.add((ID)so.get('id'));
							}
						}
					}
					else {
						if(sObjectResult.getName() == 'Scheduled_Section__c') {
							if(fieldPath == 'Section__c') {
								sectionIDs.add((ID)so.get('id'));
							}
							if(fieldPath == 'Reporting_Period__c') {
								reportingPeriodIDs.add((ID)so.get('id'));
							}
						}
					}

				}
			}
			//check to add section verification
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

			if(sectionIDs.size() > 0 && reportingPeriodIDs.size() > 0) {
				for(Section_ReportingPeriod__c srp : [SELECT ID, Time__c, Section__c, Section__r.Course__c FROM Section_ReportingPeriod__c WHERE Section__c IN: sectionIDs AND Time__c IN: reportingPeriodIDs]) {
					List<ID> tempList = new List<ID>{srp.Section__c, srp.Time__c};
					srpKeyMap.put(tempList, srp.ID);
					sectionToCourse.put(srp.Section__c, srp.Section__r.Course__c);
				}
			}
			//loop to replace lookup Names with IDs, this is now going through the results list
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
									for(ID i : columnToValueToIDMap.get(field).get(sKey)) {
										if(columnToValueToIDMap.get(field).get(sKey)[pos]  == i) {
											rw.errorMessage += '(' + i + ')';
										}
										else {
											rw.errorMessage += '(' + i + '), ';
										}
									}
									rw.errorMessage += '. ';
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

					if((sObjectResult.getName() == 'HoldingObj__c' || sObjectResult.getName() == 'SchoolForce__HoldingObj__c') && bClassID) {
						String cName = '';
						try {
							if(isManagedPackage) {
								String key = (String)rw.token.get('SchoolForce__Class_Id__c');
								cName = key;
								//catches out of bound error first...
								if(sectionToAttendanceCB.get(key).size() > 0) {
									rw.token.put('SchoolForce__Daily_Attendance__c', sectionToAttendanceCB.get(key)[0]);
									rw.token.put('SchoolForce__Record_Attendance__c', sectionToAttendanceCB.get(key)[1]);									
								}
								else {
									//? Cannot find
									rw.isSuccess = false;
									rw.errorMessage += cName + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';									
								}
							}
							else {
								String key = (String)rw.token.get('Class_Id__c');
								cName = key;
								//catches out of bound error first...
								if(sectionToAttendanceCB.get(key).size() > 0) {
									rw.token.put('Daily_Attendance__c', sectionToAttendanceCB.get(key)[0]);
									rw.token.put('Record_Attendance__c', sectionToAttendanceCB.get(key)[1]);
								}
								else {
									//?  Cannot find
									rw.isSuccess = false;
									rw.errorMessage += cName + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';									
								}
							}
						}
						catch(Exception e) {
							rw.isSuccess = false;
							rw.errorMessage += e.getMessage() + '; ';
							//rw.errorMessage = cName + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';
						}
					}

					if(sObjectResult.getName() == 'Scheduled_Section__c' || sObjectResult.getName() == 'SchoolForce__Scheduled_Section__c') {
						try {
							if(isManagedPackage) {
								ID sectionID = (ID)rw.token.get('SchoolForce__Section__c');

								if(sectionToAttendanceCB.containsKey(sectionID)){
									if(sectionToAttendanceCB.get(sectionId).size() > 0) {
										rw.token.put('SchoolForce__Daily_Attendance__c', sectionToAttendanceCB.get(sectionID)[0]);
										rw.token.put('SchoolForce__Record_Attendance__c', sectionToAttendanceCB.get(sectionID)[1]);										
									}
									else {
										rw.isSuccess = false;
										//rw.errorMessage += sectionID + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';
										rw.errorMessage += 'Section: ' + sectionID + ' is not an existing section. ';
									}
								}
								else {
									rw.isSuccess = false;
									//rw.errorMessage += sectionID + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';
									rw.errorMessage += 'Section: ' + sectionID + ' is not an existing section. ';
								}
								List<ID> keyList = new List<ID>{sectionID, (ID)rw.token.get('SchoolForce__Reporting_Period__c')};
								if(srpKeyMap.containsKey(keyList)) {
									rw.token.put('SchoolForce__Section_ReportingPeriod__c', srpKeyMap.get(keyList));
								}
								else {
									rw.isSuccess = false;
									//rw.errorMessage += 'cannot find srp for this Scheduled Section.  Section: ' + keyList[0] + ' RP: ' + keyList[1];
									rw.errorMessage += 'Cannot find Section/Reporting Period records for Section: ' + keyList[0] + ', Reporting Period: ' + keyList[1] + '. ';
								}
								if(sectionToCourse.containsKey(sectionID)) {
									rw.token.put('SchoolForce__Course__c', sectionToCourse.get(sectionID));
								}
								else {
									rw.isSuccess = false;
									//rw.errorMessage += 'Cannot find course for section: ' + sectionID + '.  The course searched is derived from the section reportingperiod records.  Please verify that there are section reportingperiod records for that reporting period and section.';
									rw.errorMessage += 'There is no course associated to Section: ' + sectionID + '. ';
								}
							}
							else {
								ID sectionID = (ID)rw.token.get('Section__c');

								if(sectionToAttendanceCB.containsKey(sectionID)){
									if(sectionToAttendanceCB.get(sectionId).size() > 0) {
										rw.token.put('Daily_Attendance__c', sectionToAttendanceCB.get(sectionID)[0]);
										rw.token.put('Record_Attendance__c', sectionToAttendanceCB.get(sectionID)[1]);
									}
									else {
										rw.isSuccess = false;
										//rw.errorMessage += sectionID + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';
										rw.errorMessage += 'Section: ' + sectionID + ' is not an existing Section. ';
									}
								}
								else {
									rw.isSuccess = false;
									//rw.errorMessage += sectionID + ' is not an existing section. The section must exist before adding staff/sections or student/sections. Review your school\'s schedule to ensure that the section exists';
									rw.errorMessage += 'Section: ' + sectionID + ' is not an existing Section. ';
								}
								List<ID> keyList = new List<ID>{sectionID, (ID)rw.token.get('Reporting_Period__c')};
								if(srpKeyMap.containsKey(keyList)) {
									rw.token.put('Section_ReportingPeriod__c', srpKeyMap.get(keyList));
								}
								else {
									rw.isSuccess = false;
									//rw.errorMessage += 'cannot find srp for this Scheduled Section.  Section: ' + keyList[0] + ' RP: ' + keyList[1];
									rw.errorMessage += 'Cannot find Section/Reporting Period records for Section: ' + keyList[0] + ', Reporting Period: ' + keyList[1] + '. ';
								}
								if(sectionToCourse.containsKey(sectionID)) {
									rw.token.put('Course__c', sectionToCourse.get(sectionID)); 
								}
								else {
									rw.isSuccess = false;
									//rw.errorMessage += 'Cannot find course for section:  ' + sectionID + '.  The course searched is derived from the section reportingperiod records.  Please verify that there are section reportingperiod records for that reporting period and section.';
									rw.errorMessage += 'There is no course associated to Section: ' + sectionID + '. ';
								}
							}
						}
						catch(Exception e) {
							rw.isSuccess = false;
							rw.errorMessage += e.getMessage() + '; ';
						}
					}
				}
			}
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