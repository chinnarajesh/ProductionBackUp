global class core_UpdateScripts {

	global static void deploy_Hawaii(){
	}

	global static void update_CustomSettings(){ 
		ProactiveCS_CsvLoader csv = new ProactiveCS_CsvLoader();
		csv.loadProactive(); 
	}

	global static void update_CoreData(){
	}

	static testMethod void testUpdateChicago(){
		//Setup data you need
		update_CustomSettings();
		Data_Load_Log__c log = new Data_Load_Log__c(Status__c='Pending', Class_Name__c='Scheduler_HoldingProcessor');
		insert log;
		update_CoreData();
		//testDataSetupUtil_v2.setupSetupRecord();
		testDataSetupUtil_V2.createDefaultPicklistValues();
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setUpStudentData(5);
		testDataSetupUtil_v2.createDefaultAttendanceTypes(testDataSetupUtil_v2.activeSetup);
		testDataSetupUtil_v2.createHomeworkPicklistValues();
		
		addDefaultAssessmentTypes();
		updateAttendancePicklistValues();
		updateStudents();
		updateBehaviorCons();
		updateSections();
		updateStaffSections();
		deploy_Hawaii();

		
		updateHomeworkInternalCode();
		updateCourses();
	}

	public static void updateAttendancePicklistValues(){
		List <Picklist_Value__c> plValueList = new List <Picklist_Value__c>();
		for (Picklist_Value__c p : 
				[Select p.Year_over_year__c, p.Type__c, p.SystemModstamp, p.Standard_Scale__c, p.Show_On_Transcript__c, p.Show_On_Report_Card__c, p.Short_Description__c, p.Setup__c,
					p.Set_as_Default__c, p.RecordTypeId, p.OwnerId, p.Order__c, p.Number__c, p.Notify_Admin__c, p.Name, p.Long_Description__c, p.Level__c, p.LastModifiedDate,
					p.LastModifiedById, p.Is_Tardy__c, p.Is_Suspension__c, p.Is_Unexcused__c, p.Is_Early_Departure__c, p.IsDeleted, p.Internal_Code__c, p.Incident_Involves_Weapon__c, 
					p.Id, p.Fieldset__c, p.External_Id__c, p.Display_Code__c, p.CreatedDate, p.CreatedById, p.Corresponding_Value__c, p.Consequence_Weight__c, p.Category__c, 
					p.Behavior_Incident_Level__c, p.Behavior_Category__c 
				from Picklist_Value__c p
				where RecordType.DeveloperName='Attendance']){
			if (p.Display_Code__c=='UD'){
				p.category__c='Partial';
				p.is_early_departure__c = true;
				p.is_unexcused__c = true;
			}	
			else if (p.Display_Code__c=='EA'){
				p.category__c='Absent';
				p.is_early_departure__c = false;
				p.is_tardy__c = false;
			}
			else if (p.Display_Code__c=='ED'){
				p.category__c='Partial'; 
				p.is_early_departure__c = true;
				p.is_tardy__c = false;
			}	
			else if (p.Display_Code__c=='ET'){
				p.category__c='Partial';
				p.is_early_departure__c = false;
				p.is_tardy__c = true;
			}	
			else if (p.Display_Code__c=='IS'){
				p.category__c='In School Suspension';
				p.is_suspension__c=true;
				p.is_early_departure__c = false;
				p.is_tardy__c = false;
			}	
			else if (p.Display_Code__c=='OS'){
				p.category__c='Out of School Suspension';
				p.is_suspension__c=true;
				p.is_early_departure__c = false;
				p.is_tardy__c = false;
			}	
			else if (p.Display_Code__c=='P'){
				p.category__c='Present';
				p.set_as_default__c=true;
				p.is_early_departure__c = false;
				p.is_tardy__c = false;
			}	
			else if (p.Display_Code__c=='UT'){
				p.category__c='Partial';
				p.is_tardy__c = true;
				p.is_unexcused__c = true;
				p.is_early_departure__c = false;
			}	
			else if (p.Display_Code__c=='TED'){
				p.category__c='Partial';
				p.is_early_departure__c = true;
				p.is_tardy__c = true;
			}
			else if (p.Display_Code__c=='UA'){
				p.category__c='Absent';
				p.is_unexcused__c = true;
				p.is_early_departure__c = false;
				p.is_tardy__c = false;
			}		
			plValueList.add(p);							
		}
		update plValueList;
	}

	global static void updateStudents(){
	}

	global static void updateStaffSections(){
	}
	
	global static void setSFCustomSettings(){
	}
	
	global static void addDefaultAssessmentTypes(){
		Map<String,ID> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
		string id = rtMap.get('Assessment_Type');
		List<Picklist_Value__c> pvlist = new List<Picklist_Value__c>();
		
		Picklist_Value__c at1 = new Picklist_Value__c(RecordTypeId=id, Name='IGDI', FieldSet__c='Rhyming_Score__c, Letters_Score__c, Vocabulary_Score__c');
		pvlist.add(at1);
		
		Picklist_Value__c at2 = new Picklist_Value__c(RecordTypeId=id, Name='Access', FieldSet__c='Listening_Score__c, Speaking_Score__c, Reading_Score__c, Writing_Score__c, Comprehension_Score__c, Oral_Score__c, Literacy_Score__c, Overall_Score__c');
		pvlist.add(at2);
		
		Picklist_Value__c at3 = new Picklist_Value__c(RecordTypeId=id, Name='SAT-2', FieldSet__c='Subject__c, Scale_Score__c, Percentile__c');
		pvlist.add(at3);
		
		Picklist_Value__c at4 = new Picklist_Value__c(RecordTypeId=id, Name='Scantron', FieldSet__c='Scan_Reading_Scale__c, Scan_Math_Scale__c, Scan_Language_Scale__c, Scan_Reading_SIP__c, Scan_Math_SIP__c, Scan_Language_SIP__c, Scan_Reading_NCE__c , Scan_Math_NCE__c, Scan_Language_NCE__c');
		pvlist.add(at4);
		
		Picklist_Value__c at5 = new Picklist_Value__c(RecordTypeId=id, Name='AP', FieldSet__c='Subject__c, Score__c');
		pvlist.add(at5);
		
		Picklist_Value__c at6 = new Picklist_Value__c(RecordTypeId=id, Name='Slosson', FieldSet__c='Slos_Math_Concepts__c, Slos_Problem_Solving__c, Slos_Computation__c');
		pvlist.add(at6);
		
		Picklist_Value__c at7 = new Picklist_Value__c(RecordTypeId=id, Name='Gates MacGinitie', FieldSet__c='GMcG_Vocab_Level__c, GMcG_Comp_Level__c, GMcG_Overall_GE__c');
		pvlist.add(at7);
		
		Picklist_Value__c at8 = new Picklist_Value__c(RecordTypeId=id, Name='PPVT', FieldSet__c='Overall_Score__c');
		pvlist.add(at8);
		
		Picklist_Value__c at17 = new Picklist_Value__c(RecordTypeId=id, Name='Teaching Strategies Gold', FieldSet__c='TSG_Manages_Feelings__c, TSG_Limits_Expectations__c, TSG_Cares_Own_Needs__c, TSG_Relationships_Adults__c, TSG_Emotional_Cues__c, TSG_Makes_Friends__c, TSG_Needs_Rights__c, TSG_Social_Problems__c, TSG_Traveling_Skills__c, TSG_Balancing_Skills__c, TSG_Motor_Skills__c, TSG_Fingers_Hands__c, TSG_Drawing_Tools__c, TSG_Comp_Language__c, TSG_Follows_Directions__c, TSG_Expanding_Vocab__c, TSG_Speaks_Clearly__c, TSG_Conventional_Grammar__c, TSG_Time_Place__c, TSG_Engages_Conversations__c, TSG_Rules_Language__c, TSG_Attends_Engages__c, TSG_Persists__c, TSG_Solves_Problems__c, TSG_Curiosity_Motivation__c, TSG_Flexible_Thinking__c, TSG_Recognizes_Recalls__c, TSG_Makes_Connections__c, TSG_Classification_Skills__c, TSG_Thinks_Symbolically__c, TSG_Sociodramatic_Play__c, TSG_Notices_Rhyme__c, TSG_Notices_Alliteration__c, TSG_Small_Sounds__c, TSG_Names_Letters__c, TSG_Letter_Sound__c, TSG_Uses_Books__c, TSG_Print_Concepts__c, TSG_Interacts_Books__c, TSG_Emergent_Reading__c, TSG_Retells_Stories__c, TSG_Writes_Name__c, TSG_Conveys_Meaning__c, TSG_Counts__c, TSG_Qualifies__c, TSG_Numerals_Quantities__c, TSG_Spatial_Relationships__c, TSG_Understands_Shapes__c, TSG_Compares_Measures__c, TSG_Pattern_Knowledge__c');
		pvlist.add(at17);
		
		Picklist_Value__c at9 = new Picklist_Value__c(RecordTypeId=id, Name='DC-CAS', FieldSet__c='Reading_Scale_Score__c, Math_Scaled_Score__c, Reading_Proficiency_Level__c,  Math_Proficiency_Level__c, Scan_Reading_NCE__c, Scan_Math_NCE__c, Reading_Growth__c, Math_Growth__c');
		pvlist.add(at9);
		
		Picklist_Value__c at10 = new Picklist_Value__c(RecordTypeId=id, Name='PSAT', FieldSet__c='Selection_Index__c, Selection_Index_Percentile__c, Critical_Reading_Scale_Score__c, Critical_Reading_Percentile__c, Scan_Math_Scale__c, Math_Percentile__c, Writing_Scale_Score__c, Writing_Percentile__c');
		pvlist.add(at10);
		
		Picklist_Value__c at11 = new Picklist_Value__c(RecordTypeId=id, Name='SAT', FieldSet__c='Selection_Index__c, Selection_Index_Percentile__c, Critical_Reading_Scale_Score__c, Critical_Reading_Percentile__c, Scan_Math_Scale__c, Math_Percentile__c, Writing_Scale_Score__c, Writing_Percentile__c');
		pvlist.add(at11);
		
		Picklist_Value__c at12 = new Picklist_Value__c(RecordTypeId=id, Name='ACT', FieldSet__c='Composite_Score__c, English_Scale_Score__c, Scan_Math_Scale__c, Scan_Reading_Scale__c, Science_Scale_Score__c, Writing_Score__c');
		pvlist.add(at12);
		
		Picklist_Value__c at13 = new Picklist_Value__c(RecordTypeId=id, Name='A-NET', FieldSet__c='Reading_Percent_Correct__c, Math_Percent_Correct__c');
		pvlist.add(at13);
		
		Picklist_Value__c at14 = new Picklist_Value__c(RecordTypeId=id, Name='Terra Nova', FieldSet__c='Scan_Reading_NCE__c, Scan_Math_NCE__c, Scan_Reading_Scale__c, Scan_Math_Scale__c, Reading_Grade_Equivalent__c, Math_Grade_Equivalent__c, Reading_Percentile__c, Math_Percentile__c');
		pvlist.add(at14);
		
		Picklist_Value__c at15 = new Picklist_Value__c(RecordTypeId=id, Name='F&P', FieldSet__c='FP_Independent_Level__c, FP_Instructional_Level__c, FP_Accuracy_Percentile__c, Comprehension_Score__c, FP_Fluency_Score__c, FP_BOY_Independent_Level__c');
		pvlist.add(at15);
		
		Picklist_Value__c at16 = new Picklist_Value__c(RecordTypeId=id, Name='DRA', FieldSet__c='DRA_Level__c, DRA_Reading_Engagement__c, DRA_Oral_Reading__c, DRA_Comprehension__c, DRA_WPM__c');
		pvlist.add(at16);
		
		insert pvlist;
	}
	
	global static void updateHomeworkInternalCode(){
		Map<String,ID> rtMap = new Map<String, Id>();
		string id = [SELECT id, Name, DeveloperName , sObjectType
		                                 FROM RecordType 
		                                 WHERE Name='Homework'
		                                 AND IsActive = true].id;
		List<Picklist_Value__c> pvList = [select id, Internal_Code__c, Category__c from Picklist_Value__c where RecordTypeID =: id];

		for(Picklist_Value__c pv: pvList){
			if(pv.Internal_Code__c == 'sf_absent')
				pv.Category__c = 'Absent';
			if(pv.Internal_Code__c == 'sf_missing')
				pv.Category__c = 'Missing';
			if(pv.Internal_Code__c == 'sf_incomplete')
				pv.Category__c = 'Incomplete';
			if(pv.Internal_Code__c == 'sf_absentwdue')
				pv.Category__c = 'Absent';
			if(pv.Internal_Code__c == 'sf_exempt')
				pv.Category__c = 'Exempt';
			if(pv.Internal_Code__c == 'sf_late')
				pv.Category__c = 'Late';
			if(pv.Internal_Code__c == 'sf_complete')
				pv.Category__c = 'Complete';
		}
		
		update pvList;
	}
	
	global static void updateBehaviorCons(){
		core_BaseInfo_v2.initBaseInfo();
		string record = core_BaseInfo_v2.picklistValueRecordTypeMap.get('Behavior_Consequence');
		
		List<Picklist_Value__c> updateList = [select id, Name, Category__c, Is_Suspension__c, Type__c from Picklist_Value__c where  RecordTypeId =: record];
		for(Picklist_Value__c pl:updateList){
			if(pl.Name == 'Suspension (In School)'){
				pl.Category__c = 'In School Suspension';
			}
			if(pl.Name == 'Suspension (Out of School)'){
				pl.Category__c = 'Out of School Suspension';
			}
			pl.Type__c = 'Behavior Consequence';
		}
	}
	
	global static void updateCourses(){
		Id rt = [select id From RecordType where Name='Course'].id;
		List <Course__c> cList = new List <Course__c>();
		for (Course__c c: [select id, Name, recordTypeId from Course__c where recordTypeId=null]){
			c.RecordTypeId = rt;
			if(c.Name.length() > 40){
				c.Name = c.Name.Substring(0,40);
			}
			clist.add(c);
		}
		update clist;
	}
	
	global static void updateSections(){
		Map<Id, Section__c> sectionMap = new Map<Id, Section__c>();
		Set<Id> schoolIds = new Set<Id>();
		Set<Id> yearIds = new Set<Id>();
	    	
	    for(Setup__c s: [SELECT Group_Based__c,Active__c, Year__c,School__c FROM Setup__c WHERE Group_Based__c = false AND Active__c = true]){
	    	schoolIds.add(s.school__c);
	    	yearIds.add(s.Year__c);
	    
	    }	
    	for(Section_ReportingPeriod__c srp: [SELECT Period__c, Time__c,Section__r.Period__c,Section__r.Reporting_Period__c
    										 FROM Section_ReportingPeriod__c WHERE Period__c <> null AND Section__r.School__c in: schoolIds 
    										 AND Section__r.Time__c in:yearIds ]){
    			if(srp.Time__c == srp.Section__r.Reporting_Period__c && srp.Period__c != '' && srp.Period__c != null){
	    			srp.Section__r.Period__c = srp.Period__c;
	    			sectionMap.put(srp.Section__c,srp.Section__r);
	    		}
    	}
    	if(sectionMap.values().size() > 0){
    			update sectionMap.values();
    	}
	}
}