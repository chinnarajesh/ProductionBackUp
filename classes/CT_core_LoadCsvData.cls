public with sharing class CT_core_LoadCsvData {
	
	public string 					setupId				{get;set;}	
	public CT_core_SetupWrapper		cSetup				{get;set;}
	public string 					selectedLoadType 	{get;set;}
	public List<SelectOption> 		loadTypeOptionList	{get;set;}
	public List<sObject>			interimValueList	{get;set;}
	public boolean					bNeedsType			{get;set;}
	public boolean					bUseDefault			{get;set;}
	public boolean					bProcessed			{get;set;}
	public boolean					bScheduler			{get;set;}
	public String 					fileContentType 	{get;set;}	
	public String 					fileName			{get;set;}
	public String					fileSize			{get;set;}
	public Blob						fileBlob 			{get;set;}
	public boolean 					importSuccess		{get;set;}
	public Map<String,String>		loadTypeToSRName	{get;set;}
	public Map<String,String>		SRNameToLoadType	{get;set;}
	public Map<String,String>	 	defaultResourceMap 	{get;set;}
	public string 					linkPathDefault 	{get;set;}
	private String fileString;
	private CT_CSVUtils.CSVParser parser;
	
	public CT_core_LoadCsvData(){
		try{
			bScheduler = false;
			bNeedsType = true;
			if(System.currentPageReference()!=null){
				//if a type is passed in (from a different page?), no need for select list
				if(System.currentPageReference().getParameters().containsKey('type')){
					selectedLoadType = System.currentPageReference().getParameters().get('type');
					if(selectedLoadType=='Scheduler') bScheduler = true;
					else bNeedsType = false;
				}
				if (System.currentPageReference().getParameters().containsKey('setupid')){
					setupId = System.currentPageReference().getParameters().get('setupid');
					cSetup = new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'load');
				}
				if(System.currentPageReference().getParameters().containsKey('success')){
					if(System.currentPageReference().getParameters().get('success')=='true'){
						Apexpages.addMessage(new apexpages.message(apexpages.severity.confirm, 'Records added successfully.'));
					}
					else{
						Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'An error occurred while inserting the new records.'));
					}
				}
			}
			
			loadSRMap();
			if(!Test.isRunningTest()){ //testing does not allow calls to getContent() which getSrLink uses
				//load default templates from static resources
				defaultResourceMap = new Map<String, String>();
				for (StaticResource sr: [select id, name from StaticResource]){
					for(String sType: SRNameToLoadType.keySet()){
						if(sr.name.contains(sType)) defaultResourceMap.put(SRNameToLoadType.get(sType), getSrLink(sr, sr.name));
					}
				}
			}
			
			initPage();
		}
		catch(Exception e){
			Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'An error occurred during initialization.'));
		}
	}
	
	public void initPage(){
		bProcessed = false;
		interimValueList = new List<sObject>();
		if(bNeedsType){
			loadSelectList();
			selectedLoadType = loadTypeOptionList[0].getValue();
		}
		changeLink();
	}
	
	public void loadSRMap(){
		loadTypeToSRName = new Map<String,String>();
		if(!bScheduler) loadTypeToSRName.put('Assignment Types','assignmentTypeTemplate');
		loadTypeToSRName.put('Time Options','timeValueTemplate');
		if(!bScheduler) loadTypeToSRName.put('Courses','courseTemplate');
		if(!bScheduler) loadTypeToSRName.put('Attendance Values','attendanceTemplate');
		loadTypeToSRName.put('Schedule Groups', 'groupTemplate');
		if(!bScheduler) loadTypeToSRName.put('Behavior Types','behaviorTypeTemplate');
		if(!bScheduler) loadTypeToSRName.put('Behavior Consequences','behaviorConsequenceTemplate');
		if(!bScheduler) loadTypeToSRName.put('Grade Scales','gradeScaleTemplate');
		loadTypeToSRName.put('Homework Values', 'homeworkTemplate');
		loadTypeToSRName.put('Students', 'studentTemplate');
		loadTypeToSRName.put('Staff', 'staffTemplate');
		loadTypeToSRName.put('Staff/Section', 'staffSectionTemplate');
		if(!bScheduler) loadTypeToSRName.put('Student/Section', 'studentSectionTemplate');
		loadTypeToSRName.put('Proactive', 'ProactiveCustomSettingCSV');
		
		SRNameToLoadType = new Map<String,String>();
		if(!bScheduler) SRNameToLoadType.put('assignmentTypeTemplate','Assignment Types');
		SRNameToLoadType.put('timeValueTemplate','Time Options');
		if(!bScheduler) SRNameToLoadType.put('courseTemplate','Courses');
		if(!bScheduler) SRNameToLoadType.put('attendanceTemplate','Attendance Values');
		SRNameToLoadType.put('groupTemplate','Schedule Groups');
		if(!bScheduler) SRNameToLoadType.put('behaviorTypeTemplate','Behavior Types');
		if(!bScheduler) SRNameToLoadType.put('behaviorConsequenceTemplate','Behavior Consequences');
		if(!bScheduler) SRNameToLoadType.put('gradeScaleTemplate','Grade Scales');
		SRNameToLoadType.put('homeworkTemplate','Homework Values');
		SRNameToLoadType.put('studentTemplate','Students');
		SRNameToLoadType.put('staffTemplate','Staff');
		SRNameToLoadType.put('staffSectionTemplate', 'Staff/Section');
		if(!bScheduler) SRNameToLoadType.put('studentSectionTemplate', 'Student/Section');
		SRNameToLoadType.put('ProactiveCustomSettingCSV', 'Proactive');
	}
	
	public void loadSelectList(){
		List<String> sortList = SRNameToLoadType.values();
		sortList.sort();
		
		loadTypeOptionList = new List <SelectOption>();
		for(String s : sortList) loadTypeOptionList.add(new SelectOption(s,s));
	}
	
	public string getSrLink(StaticResource sr, string sName){
		boolean isManagedPackage = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
		String imagesID = String.valueOf(sr.id);
		PageReference pr = new PageReference('/' + imagesId);
		// Load the HTML of the page so we can parse out the link to the static resource
		String pageContent = pr.getContent().toString();
		
	   	
		// Find the last instance of what we think is the link of the resource
		Integer startPC = pageContent.IndexOf('/resource/');
		// Chop off everything before the link that we care about.
		pageContent = pageContent.subString(startPC, pageContent.length());
		// Find where the link ends by assuming it is in a src="/ourURL/" type
		Integer endPC = (isManagedPackage)?pageContent.indexOf('/SchoolForce__'+sName):pageContent.indexOf('/'+sName);
		// Chop off everything after the link - we should be left with the link only.
		pageContent = pageContent.subString(0, endPC) + '/';
		pageContent += (isManagedPackage)?'SchoolForce__':'';
		pageContent += sName;
		// Put the URL of the resource into the custom setting for easy access
		return pageContent;
	}
	
	public void changeLink(){
		try{
			bProcessed = false;
			bUseDefault = false;
			linkPathDefault = defaultResourceMap.get(selectedLoadType);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.error, 'This load type does not support default loading.  Please ask your administrator if there is a template.'));
			Global_Error__c ge = CT_Error_Handling.handleError('', 'CSV Loader', 'error processing data', e);
			insert ge;
		}
	}
	
	
	public void loadData(){
		
		try{
			if (bUseDefault){
				fileString = [Select Body From StaticResource where name =:loadTypeToSRName.get(selectedLoadType) limit 1].body.toString();
			}else {
				if (fileBlob!=null){
					fileString = fileBlob.toString();
					fileBlob = null;
				} else {
					errorMessage('Please select a file, or select Load Default Template File.');
					return;
				}
			}
			parser = new CT_CSVUtils.CSVParser(fileString, true);
			fileString = '';
			parser.parse();
			if(parser.errormessage!= null && parser.errorMessage != ''){
				errorMessage(parser.errorMessage);
			}
			if(selectedLoadType=='Assignment Types') createAssignmentTypes();
			else if(selectedLoadType=='Time Options') createDefaultTimeOptions();
			else if(selectedLoadType=='Courses') loadCourses();
			else if(selectedLoadType=='Schedule Groups') loadGroups();
			else if(selectedLoadType=='Attendance Values') loadAttendance();
			else if(selectedLoadType=='Behavior Types') loadBehaviorTypes();
			else if(selectedLoadType=='Behavior Consequences') loadBehaviorConsequences();
			else if(selectedLoadType=='Grade Scales') loadGradeScales();
			else if(selectedLoadType=='Homework Values') loadHomeworkValues();
			else if(selectedLoadType=='Students') loadStudents();
			else if(selectedLoadType=='Staff') loadStaff();
			else if(selectedLoadType=='Staff/Section') loadStaffSections();
			else if(selectedLoadType=='Student/Section') loadStudentSections();
			else if(selectedLoadType=='Proactive') loadProactive();
			bProcessed = true;
			system.debug('selected ' + selectedLoadType);
		}
		catch(Exception e){
			Global_Error__c ge = CT_Error_Handling.handleError('', 'CSV Loader', 'error processing data', e);
			insert ge;
		}
	}
	
	public  void createAssignmentTypes(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> defaultAssignmentTypes = new List<Picklist_Value__c>();
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 1, new Set<Integer>{0});
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						Name = line[0],
						RecordTypeId = rtMap.get('Assignment_Type'),
						Type__c = 'Assignment Type'
					);

					if(cSetup!=null) temp.Setup__c = cSetup.setup.id;
					defaultAssignmentTypes.add(temp);
				}
			}
			interimValueList = defaultAssignmentTypes;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing assignment types.');
			throw e;
		}
	 }
	 
	public void createDefaultTimeOptions(){
		try{
			Map<String, Id> rtMap= CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> defaultTimeVals = new List<Picklist_Value__c>();
			for (String[] line:parser.parsedData){ //for each row
				boolean success = checkErrors(line, 2, new Set<Integer>{0});
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						Name = line[0],
						Category__c = line[1],
						Type__c = 'Time',
						RecordTypeId = rtMap.get('Time')
					);
					temp.Corresponding_Value__c=line[1]!=null && line[1]!='' ? decimal.valueOf(integer.ValueOf(line[2].trim())): null;
					defaultTimeVals.add(temp);
				}
			}
			interimValueList = defaultTimeVals;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing time values.');
			throw e;
		}
	}
	
	public  void loadCourses(){
		try{
			List<Course__c> defaultCourses = new List<Course__c>();
			Map <String, Picklist_Value__c> gradeScaleMap = new Map <String, Picklist_Value__c>();
			for (Picklist_Value__c pl: [select id, name from Picklist_Value__c where RecordType.DeveloperName = 'Grade_Scale']){
				gradeScaleMap.put(pl.name.toLowerCase(), pl);
			}
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 15, new Set<Integer>{0,6,11});
			   if(success){	
					Course__c temp = new Course__c(
						NAME = line[0],
						COURSE_NUMBER__C = line[1],
						CREDIT_HOURS__C	= decimal.valueOf(line[2]),
						DAILY_ATTENDANCE__C	= boolean.valueOf(line[3]),
						DEPARTMENT__C	= (line[5] !='')?line[4]:line[1].replace(' ', '-'),
						NUMBER_OF_REPORTING_PERIODS__C	= decimal.valueOf(integer.valueOf(line[5])),
						REFERENCE_ID__C = line[6],
						Has_Final_Grade__c = boolean.valueOf(line[7]),
						Homework_Based__c = boolean.valueOf(line[8]),
						Meets_Every_Day__c = boolean.valueOf(line[9]),
						Required_for_Graduation__c = boolean.valueOf(line[10]),
						Grade_Scale_Lookup__c = line[11]!=null ? (gradeScaleMap.get(line[11].toLowerCase())!=null ? gradeScaleMap.get(line[11].toLowerCase()).id : null) :null,
						Name_Spanish__c = line[12],
						DISPLAY_ORDER__C= decimal.valueOf(defaultCourses.size()+1),
						Subject_Area__c = line[13],
						Include_in_section_snapshot__c = line[14].toLowerCase().contains('t')
					);
					if(cSetup!=null) temp.Account__c = cSetup.school.id;
					defaultCourses.add(temp);
				}
			}
			interimValueList = defaultCourses;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing courses.');
			throw e;
		}
	}
	
	public void loadGroups(){
		try{
			List<Section__c> groups = new List<Section__c>();
			 //US1254; gets the Record Type ID for Schedule Group off Section object
			Id groupRecordTypeId = CT_core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group');

			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 3, new Set<Integer>{0,1});
				if(success){
					
					Section__c temp = new Section__c(
						NAME = line[0],
						All_Grades__c = line[1],
						Description__c = line[2],
						RecordTypeId = groupRecordTypeId
					);  
					if(cSetup!=null){
						temp.Time__c = cSetup.setup.year__c;
						temp.School__c = cSetup.school.id;
					}
					groups.add(temp);
				}
			}
			interimValueList = groups;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing schedule groups.');
			throw e;
		}
	}
	
	public void loadAttendance(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> att = new List<Picklist_Value__c>();
			for(String[] line:parser.parsedData){
				boolean success = checkErrors(line, 9, new Set<Integer>{0,1});
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						name = line[0],
						Category__c = line[1],
						display_code__c = line[2],
						Short_Description__c = line[7],
						Long_Description__c = line[8],
						RecordTypeId = rtMap.get('Attendance'),
						Type__c = 'Attendance',
						Order__c = att.size() + 1
					);

					temp.Is_Unexcused__c = (line[3].contains('t')||line[3].contains('T'));
					temp.Is_Tardy__c = (line[4].contains('t')||line[4].contains('T'));
					temp.Is_Early_Departure__c = (line[5].contains('t')||line[5].contains('T'));
					temp.Is_Suspension__c = (line[6].contains('t')||line[6].contains('T'));
					temp.Set_as_Default__c = (line[9].contains('t')||line[9].contains('T'));
					if(cSetup!=null) temp.SETUP__c = cSetup.setup.id;
					att.add(temp);
				}
			}
			interimValueList = att;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing the attendance values.');
			throw e;
		}
	}
	
	public void loadBehaviorTypes(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> beh = new List<Picklist_Value__c>();
			for(String[] line:parser.parsedData){

				boolean success = checkErrors(line, 5, new Set<Integer>{0,1});
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						name = line[0],
						behavior_category__c = line[1],
						Behavior_Incident_Level__c = line[2],
						Corresponding_Value__c = double.valueOf(line[3]),
						Incident_Involves_Weapon__c = (line[4].contains('t')||line[4].contains('T')),
						Type__c = 'Behavior Type',
						RecordTypeId = rtMap.get('Behavior_Type')
					);
					if(cSetup!=null) temp.SETUP__c = cSetup.setup.id;
					beh.add(temp);
				}
			}
			interimValueList = beh;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing the behavior types.');
			throw e;
		}
	}
	
	public void loadBehaviorConsequences(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> beh = new List<Picklist_Value__c>();
			for(String[] line:parser.parsedData){
				boolean success = checkErrors(line, 7, new Set<Integer>{0});
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						name = line[0],
						Behavior_Incident_Level__c = line[1],
						Corresponding_Value__c = double.valueOf(line[2]),
						Set_As_Default__c = (line[3].contains('t')||line[3].contains('T')),
						Is_Suspension__c = (line[4].contains('t')||line[4].contains('T')),
						Notify_Admin__c = (line[5].contains('t')||line[5].contains('T')),
						Consequence_Weight__c = double.valueOf(line[6]),
						Type__c = 'Behavior Consequence',
						Order__c = beh.size()+1,
						RecordTypeId = rtMap.get('Behavior_Consequence')
					);
					if(cSetup!=null) temp.SETUP__c = cSetup.setup.id;
					beh.add(temp);
				}
			}
			interimValueList = beh;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing the behavior consequences.');
			throw e;
		}
	}
	
	public void loadGradeScales(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> gradeScales = new List<Picklist_Value__c>();
			boolean hasDefault = false;
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 3, new Set<Integer>{0});  
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						Name = line[0],
						Set_As_Default__c = (line[1].contains('t')||line[1].contains('T')),
						Category__c =  line[2],
						RecordTypeId = rtMap.get('Grade_Scale')
					);
					if(!hasDefault && temp.Set_As_Default__c){
						hasDefault = true;
					} else if(hasDefault && temp.Set_As_Default__c) {
						errorMessage('Only one record can be marked as default. Please select only one default value.');
					}
					gradeScales.add(temp);
				}
			}
			interimValueList = gradeScales;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing grade scales.');
			throw e;
		}
	}
	
	public void loadHomeworkValues(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			List<Picklist_Value__c> hw = new List<Picklist_Value__c>();
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 3, new Set<Integer>{0,1});
				if(success){
					Picklist_Value__c temp = new Picklist_Value__c(
						Name = line[0],
						Category__c = line[1],
						Set_As_Default__c = (line[2].contains('t')||line[2].contains('T')),
						Type__c = 'Homework',
						RecordTypeId = rtMap.get('Homework'),
						Order__c = hw.size() +1
					);
					if(cSetup!=null) temp.SETUP__c = cSetup.setup.id;
					hw.add(temp);
				}
			}
			interimValueList = hw;
		}
		catch(Exception e){
			errorMessage('An error occurred while processing homework values.');
			throw e;
		}
	}
	
	 public void loadStudents(){
	 	try{
	 		if(cSetup.school.Reference_Id__c==null || cSetup.school.Reference_Id__c.trim()==''){
	 			errorMessage('The DBN code is a required field. Please confirm that there is a Reference Id on the School Detail page and then reload the file.');
	 			throw new CT_Error_Handling.schoolForceException();
	 		}
			List<HoldingObj__c> holdingObjs = new List<HoldingObj__c>();
			List<String> gradeList;
			if(cSetup.setup.Grade_Span__c != null)
				gradeList = cSetup.setup.Grade_Span__c.split(';');
			else {
				errorMessage('The current setup does not have a grade span set. Please select a grade span for this year before loading students.');
				throw new CT_Error_Handling.schoolForceException();
			}

			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 18, new Set<Integer>{1,2,3,4,5,6});
				if(success){
					Set<String> grades = new Set<String>();
					grades.addAll(gradeList);
					if(grades.contains(line[4])){
						if(line[13]!=''&&line[13]!=null) line[12] = line[12]+', '+line[13];
						HoldingObj__c temp = new HoldingObj__c(
							Network_Code__c = line[0],
							Student_Id__c = line[1],
							First_Name__c = line[2],
							Last_Name__c = line[3],
							Grade_Level__c = line[4],
							Sex__c = line[6],
							Ethnic_Cde__c = line[7],
							Disability_Flag__c = line[8],
							ELL__c = line[9],
							Email__c = line[11],
							Address__c = line[12],
							City__c = line[14],
							State__c = line[15],
							Zip__c = line[16],
							Phone__c = line[17],
							Type__c = 'Student',
							School_Dbn__c = cSetup.school.Reference_Id__c,
							School_Year__c = cSetup.setup.Year__r.Name__c
						);
						temp.DOB__c = date.newInstance(integer.valueOf(line[5].split('/')[2]), integer.valueOf(line[5].split('/')[0]), integer.valueOf(line[5].split('/')[1]));
						if(line[10]!=null&&line[10]!='') temp.Admission_Date__c = date.newInstance(integer.valueOf(line[10].split('/')[2]), integer.valueOf(line[10].split('/')[0]), integer.valueOf(line[10].split('/')[1]));
						holdingObjs.add(temp);
					}
					else{
						errorMessage(line[4]+' is not a valid grade level for '+cSetup.school.School_Full_Name__c+' for school year '+cSetup.setup.Year__r.Name__c+'.  Any rows with this grade level have been omitted.');
					}
				}
			}
			interimValueList = holdingObjs;
	 	}
	 	catch(Exception e){
	 		errorMessage('An error occurred while processing student data.  Please ensure that all required fields are present and that the load is associated with a setup record.');
			throw e;
	 	}
	}
	
	public void loadStaff(){
	 	try{
	 		if(cSetup.school.Reference_Id__c==null || cSetup.school.Reference_Id__c.trim()==''){
	 			errorMessage('The DBN code is a required field. Please confirm that there is a Reference Id on the School Detail page and then reload the file.');
	 			throw new CT_Error_Handling.schoolForceException();
	 		}
			List<HoldingObj__c> holdingObjs = new List<HoldingObj__c>();
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 13, new Set<Integer>{1,2,3,4});
				if(success){
					if(line[7]!=''&&line[7]!=null) line[6] = line[6]+', '+line[7];
					HoldingObj__c temp = new HoldingObj__c(
						Network_Code__c = line[0],
						Staff_Id__c = line[1],
						First_Name__c = line[2],
						Last_Name__c = line[3],
						Email__c = line[4],
						Phone__c = line[5],
						Address__c = line[6],
						City__c = line[8],
						State__c = line[9],
						Zip__c = line[10],
						Sex__c = line[11],
						Age__c = line[12],
						Type__c = 'Staff',
						School_Dbn__c = cSetup.school.Reference_Id__c,
						School_Name__c = cSetup.school.School_Full_Name__c,
						School_Year__c = cSetup.setup.Year__r.Name__c
					);
					holdingObjs.add(temp);
				}
			}
			interimValueList = holdingObjs;
	 	}
	 	catch(Exception e){
	 		errorMessage('An error occurred while processing staff data.  Please ensure that all required fields are present and that the load is associated with a setup record.');
			throw e;
	 	}
	}
	
	public void loadStaffSections(){
	 	try{
	 		if(cSetup.school.Reference_Id__c==null || cSetup.school.Reference_Id__c.trim()==''){
	 			errorMessage('The DBN code is a required field. Please confirm that there is a Reference Id on the School Detail page and then reload the file.');
	 			throw new CT_Error_Handling.schoolForceException();
	 		}
			List<HoldingObj__c> holdingObjs = new List<HoldingObj__c>();
			Set<String> sectionNames = new Set<String>();
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 4, new Set<Integer>{0,1,2,3});
				if(success){
					HoldingObj__c temp = new HoldingObj__c(
						Staff_Id__c = line[0],
						First_Name__c = line[1],
						Last_Name__c = line[2],
						Class_Id__c = line[3],
						Type__c = 'Staff',
						//EE 1/4 DE2768 removing reporting period
						//Reporting_Period_Id__c = cSetup.reportingPeriodList[0].id,
						School_Dbn__c = cSetup.school.Reference_Id__c,
						School_Name__c = cSetup.school.School_Full_Name__c,
						School_Year__c = cSetup.setup.Year__r.Name__c
					);
					holdingObjs.add(temp);
					sectionNames.add(temp.Class_Id__c);
				}
			}
			//DE3575 need to pull attendance data from section so that it isn't overwritten
			Map<String,Section__c> nameToSection = new Map<String,Section__c>();
			for(Section__c sec: [SELECT id, Name, Record_Attendance__c, Daily_Attendance__c FROM Section__c WHERE Name IN :sectionNames])
				nameToSection.put(sec.Name,sec);
			for(HoldingObj__c ho: holdingObjs){
				if(nameToSection.containsKey(ho.Class_Id__c)){
					Section__c section = nameToSection.get(ho.Class_Id__c);
					ho.Record_Attendance__c = section.Record_Attendance__c;
					ho.Daily_Attendance__c = section.Daily_Attendance__c;
				} else {
					errorMessage(ho.Class_Id__c+' is not an existing section.  The section must exist before adding staff/sections.  If this is in error, please review your school\'s schedules to ensure that the section exists.');
				}
			}
			interimValueList = holdingObjs;
	 	}
	 	catch(Exception e){
	 		errorMessage('An error occurred while processing staff/section data.  Please ensure that all required fields are present and that the load is associated with a setup record.');
			throw e;
	 	}
	}
	
	public void loadStudentSections(){
	 	try{
	 		if(cSetup.school.Reference_Id__c==null || cSetup.school.Reference_Id__c.trim()==''){
	 			errorMessage('The DBN code is a required field. Please confirm that there is a Reference Id on the School Detail page and then reload the file.');
	 			throw new CT_Error_Handling.schoolForceException();
	 		}
			List<HoldingObj__c> holdingObjs = new List<HoldingObj__c>();
			for (String[] line:parser.parsedData){
				boolean success = checkErrors(line, 5, new Set<Integer>{0,1,2,3,4});
				if(success){
					HoldingObj__c temp = new HoldingObj__c(
						Student_Id__c = line[0],
						First_Name__c = line[1],
						Last_Name__c = line[2],
						Grade_Level__c = line[3],
						Class_Id__c = line[4],
						Type__c = 'Student',
						//EE 1/4 DE2768 removing reporting period
						//Reporting_Period_Id__c = cSetup.reportingPeriodList[0].id,
						School_Dbn__c = cSetup.school.Reference_Id__c,
						School_Name__c = cSetup.school.School_Full_Name__c,
						School_Year__c = cSetup.setup.Year__r.Name__c
					);
					holdingObjs.add(temp);
				}
			}
			interimValueList = holdingObjs;
	 	}
	 	catch(Exception e){
	 		errorMessage('An error occurred while processing student/section data.  Please ensure that all required fields are present and that the load is associated with a setup record.');
			throw e;
	 	}
	}
	
	public void loadProactive(){
		try{
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Proactive_CS__c');
			List<Proactive_CS__c> proactiveCSLoad = new List<Proactive_CS__c>();

			for (String[] line:parser.parsedData){
					Proactive_CS__c a = new Proactive_CS__c(
						Name = line[0],
						Name_Type__c = line[1],
						Proactive_Attendance_Status__c = line[2],
						Proactive_Attendance_Type__c = line[3],
						Proactive_PG_Relationship__c = line[4],
						Proactive_SPED_School__c = line[5],
						Proactive_Student_Entry__c = line[6],
						Proactive_Student_Exit__c = line[7],
						Proactive_TitleI__c = line[8],
						SF_Attendance_Status__c = line[9],
						SF_Attendance_Type__c = line[10],
						SF_PG_Relationship__c = line[11],
						SF_SPED_School__c = line[12],
						SF_Student_Entry__c = line[13],
						SF_Student_Exit__c = line[14],
						SF_TitleI__c = line[15]
					);
					proactiveCSLoad.add(a);
			}
			
			interimValueList = proactiveCSLoad;
		}catch(Exception e){
	 		errorMessage('An error occurred while processing proactive data.  Please ensure that all required fields are present and that the load is associated with a setup record.');
			throw e;
	 	}
	}
	
	/*
		For every row in the CSV file, validate that adequate data is present.
		1) Make sure the number of columns in this row of the CSV is correct
		2) Make sure all required fields are present
		
		@param line - one row in the CSV file
		@param size - the expected number of columns
		@param requiredVals - the locations of required fields
		@return true if valid data, false otherwise
	*/
	public boolean checkErrors(List<String> line, integer size, Set<Integer> requiredVals){
		if(line.size()<size){
			Apexpages.addMessage(new apexpages.message(apexpages.severity.info, 'CSV file has rows with missing columns. These rows have been omitted. Please check results table to ensure necessary data has processed successfully.'));
			return false;
		}
		
		for(integer i: requiredVals){
			system.debug('required val '+i+' has value '+line[i]);
			if((line[i]==null) || (line[i].trim().length()==0)){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.info, 'CSV file has rows where required information is missing.  These rows have been omitted.  Please check results table to ensure necessary data has processed successfully.'));
				return false;
			}
		}
		return true;
	}

	public void insertList_component(){
		insertList();
	}
	 
	public PageReference insertList(){
		try{
			insert interimValueList;
			String urlLink = '/apex/CT_core_LoadCsvData?success=true';
			if(setupId!=null) urlLink += '&setupId='+setupId;
			if(bScheduler) urlLink += '&type=Scheduler';
			else if(!bNeedsType) urlLink += '&type='+selectedLoadType;
			PageReference p = new PageReference(urlLink);
			bProcessed = false;
			p.setRedirect(true);
			return p;
		}
		catch(Exception e){
			Global_Error__c ge = CT_Error_Handling.handleError('', 'CSV Loader', 'error inserting data', e);
			insert ge;
			errorMessage('An error occurred while inserting the new records.');
			return null;
		}
	 }
	 
	private void errorMessage(string message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
	}	
	/*********************************** UNIT TEST ***********************************/
	static testMethod void testCsvLoader(){
		Test.startTest();
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		CT_core_LoadCsvData loader = new CT_core_LoadCsvData();
		system.assertequals(null, loader.cSetup);
		system.assertequals(false, loader.bProcessed);
		system.assertequals(loader.SRNameToLoadType.size(), loader.loadTypeToSRName.size());
		system.assertequals(loader.loadTypeToSRName.size(), loader.loadTypeOptionList.size());
		system.assertequals(true, loader.bNeedsType);
		
		PageReference pr = new PageReference('/apex/CT_core_LoadCsvData?setupId='+TestDataSetupUtil_v2.activeSetUp.id+'&type=Students');
		test.setCurrentPage(pr);
		loader = new CT_core_LoadCsvData();
		system.assertnotequals(null, loader.cSetup);
		system.assertequals(false, loader.bProcessed);
		system.assertequals(loader.SRNameToLoadType.size(), loader.loadTypeToSRName.size());
		system.assertequals(false, loader.bNeedsType);
		
		pr = new PageReference('/apex/CT_core_LoadCsvData?setupId='+TestDataSetupUtil_v2.activeSetUp.id);
		test.setCurrentPage(pr);
		loader = new CT_core_LoadCsvData();
		system.assertnotequals(null, loader.cSetup);
		system.assertequals(false, loader.bProcessed);
		system.assertequals(loader.SRNameToLoadType.size(), loader.loadTypeToSRName.size());
		system.assertequals(loader.loadTypeToSRName.size(), loader.loadTypeOptionList.size());
		system.assertequals(true, loader.bNeedsType);
		
		loader.selectedLoadType = 'Assignment Types';
		//this will not work because the default resource map was not populated
		//as test methods are not allowed to call getContent()
		loader.changeLink();
		
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Time Options';
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Courses';
		loader.changeLink();
		system.assert(!loader.bProcessed);		
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Course__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Schedule Groups';
		loader.changeLink();
		system.assert(!loader.bProcessed);		
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Section__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Attendance Values';
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Behavior Types';	
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Behavior Consequences';
		loader.changeLink();
		system.assert(!loader.bProcessed);		
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Grade Scales';
		loader.changeLink();
		system.assert(!loader.bProcessed);		
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Homework Values';	
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(Picklist_Value__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Students';	
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(HoldingObj__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Staff';	
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(HoldingObj__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Staff/Section';	
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(HoldingObj__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.selectedLoadType = 'Student/Section';	
		loader.changeLink();
		system.assert(!loader.bProcessed);	
		loader.bUseDefault = true;
		loader.loadData();
		system.assert(loader.bProcessed);
		system.assertEquals(HoldingObj__c.sObjectType, loader.interimValueList.getsObjectType());
		
		loader.insertList();
		system.assertEquals(false, loader.bProcessed);	
		
		Test.stopTest();
	}
}