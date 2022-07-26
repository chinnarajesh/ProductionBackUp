public with sharing class Student_Utils {
	public static void processBeforeInsert(List <Student__c> newStudents){
		populateBaseFields(newStudents);
	}

	public static void processAfterInsert(Map <Id, Student__c> newMap){
		if(!core_triggerUtils.mealsTrigger && core_triggerUtils.studentTrigger){
			updateContactFromStudent(newMap.values(), null);
			cascadeStudentContactUpdates(newMap,null, true); 

			if (!core_triggerUtils.sectionWizard)
				scheduleGroup_onInsert(newMap);

			manageActivationProcess(newMap, null, true);
		}
	}

	public static void processBeforeUpdate(Map <Id, Student__c> newMap, Map<Id, Student__c> oldMap){
		if(core_triggerUtils.studentTrigger){
			populateReferenceId_OnChange(newMap.values(), oldMap);
			updateGradIndicator(newMap, oldMap);
			manageActivationProcess(newMap, oldMap, false);
		}
	}

	public static void processAfterUpdate(Map <Id, Student__c> newMap, Map<Id, Student__c> oldMap){
		if(!core_triggerUtils.mealsTrigger || core_triggerUtils.studentTrigger){
			updateContactFromStudent(newMap.values(), oldMap);
			//Copy id updates out to the student sections
			cascadeIdUpdatesToStudentSections(newMap, oldMap);
			//Keeps contacts/student fields insynch if anything changed on key fields
			cascadeStudentContactUpdates(newMap,oldMap, false);
			checkDeactivation(newMap, oldMap);
			if (!core_TriggerUtils.sectionWizard){
				//Deletes student/sections for old Schedule Group & adds student section for new
				scheduleGroup_onUpdate(newMap, oldMap);
			}
		}
		updateChangedMealCategories(newMap.values(), oldMap);//Update meal transactions
	}

	public static void processBeforeDelete(Map <Id, Student__c> oldMap){
		deleteRelatedStudentSections(oldMap.values());//On delete remove any student sections.
	}
	/* ************** End of Method Directly Called from Student Trigger ****************/

	/* ************** Start of Student Helper Methods **************** ****************/
	public static void populateBaseFields(List <Student__c> studentList){
		Boolean isSetupPopulate = false;
		for(Student__c s: studentList){
			if(s.Setup__c == null){
				isSetupPopulate = true;
			}
		}
		if(isSetupPopulate){
			getStudentSetupMap(studentList);
		}

		for(Student__c s: studentList){
			if(s.Setup__c != null){
				s.School__c = s.Setup_School__c;
				s.School_Year__c = s.Setup_Year__c;				
				if(s.Student_Id__c != null){
					s.Reference_Id__c = s.Student_ID__c+'_'+s.Setup_Year_Name__c.trim()+((s.Setup_School_RT__c == 'Summer_School')?'SS':'');
				} else if(s.Reference_Id__c != null && s.Reference_Id__c.contains('_')){
					s.Student_Id__c = s.Reference_Id__c.split('_',2)[0];
				} else {
					s.addError('Unable to create a student due to a malformed reference ID.');
				}

				if (s.Entry_date__c < s.Setup_Term_Start_Date__c || 
						s.Entry_date__c > s.Setup_Term_End_Date__c){
					s.Entry_date__c.addError('Entry date must be within the term start and end dates');
				}
			}
			//if setup field is required this code won`t needed//needed for dataloader
			String setupKey = ''+s.School__c+s.School_Year__c;
			if(s.Setup__c == null && setupMap.containsKey(setupKey)){
				Setup__c setup = setupMap.get(setupKey);
				s.School__c = setup.School__c;
				s.School_Year__c = setup.Year__c;
				s.Setup__c = setup.ID;
				if(s.Student_Id__c != null){
					s.Reference_Id__c = s.Student_ID__c+'_'+setup.Year__r.Name__c.trim()+((setup.School__r.RecordType.Name == 'Summer School')?'SS':'');
				} else if(s.Reference_Id__c != null && s.Reference_Id__c.contains('_')){
					s.Student_Id__c = s.Reference_Id__c.split('_',2)[0];
				} else {
					s.addError('Unable to create a student due to a malformed reference ID.');
				}

				if (s.Entry_date__c < setup.Term__r.Date_start_date__c || 
						s.Entry_date__c > setup.Term__r.End_date__c){
					s.Entry_date__c.addError('Entry date must be within the term start and end dates');
				}
			}

			if (s.name==null && (s.Student_First_Name__c!=null && s.Student_Last_Name__c!=null)){
				s.name = s.Student_First_Name__c.trim()+' '+s.Student_Last_Name__c.trim();
			}
			if(s.Setup__c == null){
				s.addError('The setup the student is assoicated to cannot be found.');
			}
		}
	}

	public static void updateGradIndicator(Map<ID, Student__c> newMap, Map<ID, Student__c> oldMap){
		for(Student__c stud:newMap.values()){
			if(stud.Setup__c!=null && stud.Is_Grade_In_Setup__c==true && 
					stud.Promoted__c==true && 
					(stud.Active__c == false && 
					stud.Archived__c == true && 
					oldMap.get(stud.id).Active__c == true && 
					oldMap.get(stud.id).Archived__c == false)){
				stud.Graduation_Indicator__c=true;
			}
		}
	}

	public static void updateContactFromStudent(List <Student__c> studentList, Map<Id, Student__c> oldMap){
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		for(Student__c s:studentList){
			if(s.Individual__c != null && (oldMap == null || s.Individual__c != oldMap.get(s.Id).Individual__c)){
				if (s.Active__c == true){
					contactMap.put(s.Individual__c, new Contact(Id = s.Individual__c, Student__c = s.Id));
				}				
			}
		}

		if (!contactMap.isEmpty()){			
			Database.upsert(contactMap.values(), false);
		}
	}

	public static void populateReferenceId_OnChange(List <Student__c> studentList, Map <Id, Student__c> oldMap){
		for(Student__c s:studentList){
			if(s.Setup__c == null && oldMap.get(s.id).Setup__c != null){
				s.Setup__c.addError('You cannot remove a setup from a student once set.');
			}
			if(s.School_Year__c == null && oldMap.get(s.id).School_Year__r != null){
				s.Setup__c.addError('You cannot remove the year from a student once set.');
			}
			if(s.Student_ID__c == null){
				s.Student_Id__c = s.Reference_Id__c = s.id;
			}
			if(s.Setup__c != null && s.Setup__c != oldMap.get(s.id).Setup__c){
				s.School__c = s.Setup_School__c;
				s.School_Year__c = s.Setup_Year__c;
			}
			if(s.Setup__c != null && s.Student_Id__c != null){
				s.Reference_Id__c = s.Student_ID__c+'_'+s.Setup_Year_Name__c.trim()+((s.Setup_School_RT__c == 'Summer_School')?'SS':'');
			} else if(s.Student_Id__c != null) {
				s.addError('Unable to update student reference id. The setup the student is assoicated to cannot be found.');
			}
		}
	}

	public static void cascadeIdUpdatesToStudentSections(Map<Id, Student__c> newMap, Map <Id, Student__c> oldMap){
		List <Student__c> studentList = newMap.values();
		Set<Id> studentActivation = new Set<Id>();
		Set<Id> studentIds = new Set<Id>();

		for(Student__c s: studentList){
			//If the id has changed, populate that value over to student section and contact.
			if(s.Student_Id__c != oldMap.get(s.Id).Student_Id__c)
				studentIds.add(s.id);
		}
	
		//process SS ref Id updates
		if(!studentIds.isEmpty()){
			List<Student_Section__c> updatedSections = new List<Student_Section__c>();

			for(Student_Section__c ss: [select id, Name, reference_Id__c, Student__c from Student_Section__c where Student__c IN :studentIds]){
				//rebuild the student part of the student section id
				if(ss.Reference_ID__c == null || !ss.Reference_ID__c.contains('_')) {
					Trigger.newMap.get(ss.Student__c).addError('Unable to update a student section due to a malformed reference ID.');
				} else {
					string refId = ss.Reference_Id__c.split('_', 2)[1];
					refId = newMap.get(ss.Student__c).Student_Id__c + '_' + refId;
					if(ss.Reference_Id__c != refId){
						ss.Reference_Id__c = refID;
						updatedSections.add(ss);
					}
				}
			}

			if(!updatedSections.isEmpty())
				update updatedSections;
		}
	}

	public static void checkDeactivation(Map<ID,Student__c> newMap, Map<ID,Student__c> oldMap){
		Set<ID> deactivatedIDs = new Set<ID>();
		for(Student__c stud: newMap.values()){
			if(oldMap.get(stud.id).Active__c && !stud.Active__c){
				deactivatedIDs.add(stud.id);
			}
		}
		if(!deactivatedIDs.isEmpty()){
			core_triggerUtils.deactivateStudentSections(deactivatedIDs,true);
		}
	}
	
	public static void deleteRelatedStudentSections(List <Student__c> deletedStudentList){
		Set<ID> studentsToDelete = new Set<ID>();
		for(Student__c s:deletedStudentList){
			studentsToDelete.add(s.id);
		}

		List<Student_Section__c> toDelete = [select id from Student_Section__c where Student__c in :studentsToDelete];
		if(toDelete != null && !toDelete.isEmpty()){
			delete toDelete;
		}
	}

	public static Map<String, Setup__c> setupMap;
	public static Map<ID, Setup__c> studentSetupMap;

	public static void getStudentSetupMap(Map <Id, Student__c> studentMap){
		getStudentSetupMap(studentMap.values());
	}

	public static void getStudentSetupMap(List<Student__c> studentList){
		boolean reloadSetupData = false;

		if(setupMap == null){
			setupMap = new Map<String, Setup__c>();
			studentSetupMap = new Map<ID, Setup__c>();
		}
		Set<ID> schoolIDs = new Set<ID>();
		Set<ID> yearIDs = new Set<ID>();

		for (Student__c student: studentList){
			if (student.Setup__c!=null){
				if(!setupMap.containsKey(student.Setup__c)){
					reloadSetupData = true;
					setupMap.put(student.Setup__c, null);
				}
			} else if(student.School__c != null && student.School_Year__c != null){
				String key = ''+student.School__c+student.School_Year__c;
				if(!setupMap.containsKey(key)){
					reloadSetupData = true;
					schoolIDs.add(student.School__c);
					yearIds.add(student.School_Year__c);
				}
				
			}
		}

		if(reloadSetupData){
			
			system.debug(setupMap.keySet());
			system.debug(schoolIds);
			system.debug(yearIds);
			for (Setup__c s: [select ID,Term__r.End_Date__c,Term__r.Date_start_date__c,Cascade_daily_attendance__c,Grade_Span__c, School__c, Year__c, Year__r.Name__c,
								School__r.RecordType.Name
								from Setup__c where id in:setupMap.keySet()
								OR (School__c IN: schoolIds and Year__c IN: yearIDs)]){
				setupMap.put(s.id, s);
				setupMap.put(''+s.School__c+s.Year__c, s);
			}

			for (Student__c student: studentList){
				studentSetupMap.put(student.ID, setupMap.get(student.Setup__c));
			}
		}
	}

	public static void updateChangedMealCategories(List <Student__c> studentList, Map<Id, Student__c> oldMap){
		Map <Id, Student__c> changedMealsStudentMap = new Map <Id, Student__c>();
		for(Student__c s : studentList){
			if (s.Meals_Category__c != oldMap.get(s.id).Meals_Category__c) {
				changedMealsStudentMap.put(s.id, s);
			}
		}
		if(!changedMealsStudentMap.isEmpty()){
			Meals_ProcessTransactions.rollupStats(changedMealsStudentMap);
		}
	}

	public static void cascadeStudentContactUpdates(Map<Id, Student__c> newMap, Map <Id, Student__c> oldMap, boolean isInsert){
		Map<ID, Contact> contactMap = new Map<Id, Contact>();
		for(Student__c s: newMap.values()){
			if (s.individual__c != null){
				contactMap.put(s.individual__c, new Contact(Id = s.individual__c));
			}
		}

		if(!contactMap.isEmpty()){
			for(Student__c s: newMap.values()){
				if(s.Individual__c!=null && s.Student_Id__c!=s.Individual_Reference_Id__c){
					if(!trigger.isInsert){
						if(s.Student_Id__c != oldMap.get(s.Id).Student_Id__c)
						contactMap.get(s.Individual__c).Reference_Id__c = s.Student_Id__c;
					} else{
						contactMap.get(s.Individual__c).Reference_Id__c = s.Student_Id__c;
					}
				}
				Student__c oldStudent = new Student__c();
				if(!isInsert){
					oldStudent = oldmap.get(s.id);
				}
				if(isInsert ||
						(oldStudent.X504_Plan__c != s.X504_Plan__c ||
							oldStudent.Ward__c != s.Ward__c ||
							oldStudent.Student_Last_Name__c != s.Student_Last_Name__c ||
							oldStudent.Student_First_Name__c != s.Student_First_Name__c ||
							oldStudent.Video_Authorized__c != s.Video_Authorized__c ||
							oldStudent.Transportation_Authorized__c != s.Transportation_Authorized__c ||
							oldStudent.Title_1_Status__c != s.Title_1_Status__c ||
							oldStudent.Student_Picture__c != s.Student_Picture__c ||
							oldStudent.State__c != s.State__c ||
							oldStudent.Residence_After_Exiting_School__c != s.Residence_After_Exiting_School__c ||
							oldStudent.Race_PowerSchool_Import__c != s.Race_PowerSchool_Import__c ||
							oldStudent.Previous_School_2__c != s.Previous_School_2__c ||
							oldStudent.Previous_School_2_Type__c != s.Previous_School_2_Type__c ||
							oldStudent.Previous_School_1__c != s.Previous_School_1__c ||
							oldStudent.Previous_School_1_Type__c != s.Previous_School_1_Type__c ||
							oldStudent.Photograph_Authorized__c != s.Photograph_Authorized__c ||
							oldStudent.Permission_for_Directory__c != s.Permission_for_Directory__c ||
							oldStudent.Official_Exit_Type__c != s.Official_Exit_Type__c ||
							oldStudent.Nickname__c != s.Nickname__c ||
							oldStudent.Migrant__c != s.Migrant__c ||
							oldStudent.Lep_Flag__c != s.Lep_Flag__c ||
							oldStudent.Holding_Source__c != s.Holding_Source__c ||
							oldStudent.Home_Language__c != s.Home_Language__c ||
							oldStudent.Gender__c != s.Gender__c ||
							oldStudent.Immigrant__c != s.Immigrant__c ||
							oldStudent.Immigrant_Program_Participant__c != s.Immigrant_Program_Participant__c ||
							oldStudent.Exit_Status__c != s.Exit_Status__c ||
							oldStudent.Exit_Date__c != s.Exit_Date__c ||
							oldStudent.Exit_Comments__c != s.Exit_Comments__c ||
							oldStudent.Ethnicity__c != s.Ethnicity__c ||
							oldStudent.Entry_Type__c != s.Entry_Type__c ||
							oldStudent.Entry_Date__c != s.Entry_Date__c ||
							oldStudent.Emergency_Contact_2_Name__c != s.Emergency_Contact_2_Name__c ||
							oldStudent.Emergency_Contact_1_Work_Phone__c != s.Emergency_Contact_1_Work_Phone__c ||
							oldStudent.Emergency_Contact_1_Name__c != s.Emergency_Contact_1_Name__c ||
							oldStudent.Email__c != s.Email__c ||
							oldStudent.Econtact_2_Relationship_to_Student__c != s.Econtact_2_Relationship_to_Student__c ||
							oldStudent.EContact_2_Work_Phone__c != s.EContact_2_Work_Phone__c ||
							oldStudent.EContact_2_Home_Phone__c != s.EContact_2_Home_Phone__c ||
							oldStudent.EContact_2_Cell_Phone__c != s.EContact_2_Cell_Phone__c ||
							oldStudent.EContact_1_Home_Phone__c != s.EContact_1_Home_Phone__c ||
							oldStudent.EContact_1_Cell_Phone__c != s.EContact_1_Cell_Phone__c ||
							oldStudent.EC_1_Relationship_to_Student__c != s.EC_1_Relationship_to_Student__c ||
							oldStudent.District_of_Columbia_C_Student_ID__c != s.District_of_Columbia_C_Student_ID__c ||
							oldStudent.Disability_Flag__c != s.Disability_Flag__c ||
							oldStudent.Detailed_Exit_Reason__c != s.Detailed_Exit_Reason__c ||
							oldStudent.Date_of_Birth__c != s.Date_of_Birth__c ||
							oldStudent.Currently_evaluated_for_special_ed__c != s.Currently_evaluated_for_special_ed__c ||
							oldStudent.Comments__c != s.Comments__c ||
							oldStudent.Admission_Status__c != s.Admission_Status__c ||
							oldStudent.Admission_Code__c != s.Admission_Code__c ||
							oldStudent.Birth_Place_State__c != s.Birth_Place_State__c ||
							oldStudent.Birth_Place_City__c != s.Birth_Place_City__c ||
							oldStudent.City__c != s.City__c ||
							oldStudent.Country_of_Origin__c != s.Country_of_Origin__c ||
							oldStudent.Zip_Code__c != s.Zip_Code__c ||
							oldStudent.Address__c != s.Address__c) && s.Active__c && s.Individual__c != null){
					Contact c = contactMap.get(s.Individual__c);
					if(s.X504_Plan__c!=null)
					c.X504_Plan__c = s.X504_Plan__c;
					if (s.Student_Last_Name__c != null)
					c.LastName = s.Student_Last_Name__c;
					if (s.Student_First_Name__c != null)
					c.FirstName = s.Student_First_Name__c;
					if(s.Ward__c!=null)
					c.Ward__c = s.Ward__c;
					if(s.Video_Authorized__c!=null)
					c.Video_Authorized__c = s.Video_Authorized__c;
					if(s.Transportation_Authorized__c!=null)
					c.Transportation_Authorized__c = s.Transportation_Authorized__c;
					if(s.Title_1_Status__c!=null)
					c.Title_1_Status__c = s.Title_1_Status__c;
					if(s.Student_Picture__c!=null)
					c.Student_Picture__c = s.Student_Picture__c;
					if(s.State__c!=null)
					c.MailingState = s.State__c;
					if(s.Residence_After_Exiting_School__c!=null)
					c.Residence_After_Exiting_School__c = s.Residence_After_Exiting_School__c;
					if(s.Race_PowerSchool_Import__c!=null)
					c.Race_PowerSchool_Import__c = s.Race_PowerSchool_Import__c;
					if(s.Race__c!=null)
					c.Race__c = s.Race__c;
					if(s.Previous_School_2__c!=null)
					c.Previous_School_2__c = s.Previous_School_2__c;
					if(s.Previous_School_2_Type__c!=null)
					c.Previous_School_2_Type__c = s.Previous_School_2_Type__c;
					if(s.Previous_School_1__c!=null)
					c.Previous_School_1__c = s.Previous_School_1__c;
					if(s.Previous_School_1_Type__c!=null)
					c.Previous_School_1_Type__c = s.Previous_School_1_Type__c;
					if(s.Photograph_Authorized__c!=null)
					c.Photograph_Authorized__c = s.Photograph_Authorized__c;
					if(s.Permission_for_Directory__c!=null)
					c.Permission_for_Directory__c = s.Permission_for_Directory__c;
					if(s.Official_Exit_Type__c!=null)
					c.Official_Exit_Type__c = s.Official_Exit_Type__c;
					if(s.Nickname__c!=null)
					c.Nickname__c = s.Nickname__c;
					if(s.Mobile_Phone__c!=null)
					c.MobilePhone = s.Mobile_Phone__c;
					if(s.Migrant__c!=null)
					c.Migrant__c = s.Migrant__c;
					if(s.Lep_Flag__c!=null)
					c.Lep_Flag__c = s.Lep_Flag__c;
					if(s.Holding_Source__c!=null)
					c.Holding_Source__c = s.Holding_Source__c;
					if(s.Home_Language__c!=null)
					c.Home_Language__c = s.Home_Language__c;
					if(s.Gender__c!=null)
					c.Gender__c = s.Gender__c;
					if(s.Immigrant__c !=null)
					c.Immigrant__c = s.Immigrant__c;
					if(s.Immigrant_Program_Participant__c!=null)
					c.Immigrant_Program_Participant__c = s.Immigrant_Program_Participant__c;
					if(s.Exit_Status__c!=null)
					c.Exit_Status__c = s.Exit_Status__c;
					if(s.Exit_Date__c!=null)
					c.Exit_Date__c = (Date)s.Exit_Date__c;
					if(s.Exit_Comments__c!=null)
					c.Exit_Comments__c = s.Exit_Comments__c;
					if(s.Ethnicity__c!=null)
					c.Ethnicity__c = s.Ethnicity__c;
					if(s.Entry_Type__c!=null)
					c.Entry_Type__c = s.Entry_Type__c;
					if(s.Entry_Date__c!=null)
					c.Entry_Date__c = s.Entry_Date__c;
					if(s.Emergency_Contact_2_Name__c!=null)
					c.Emergency_Contact_2_Name__c = s.Emergency_Contact_2_Name__c;
					if(s.Emergency_Contact_1_Work_Phone__c!=null)
					c.Emergency_Contact_1_Work_Phone__c = s.Emergency_Contact_1_Work_Phone__c;
					if(s.Emergency_Contact_1_Name__c!=null)
					c.Emergency_Contact_1_Name__c = s.Emergency_Contact_1_Name__c;
					if(s.Email__c!=null)
					c.Email = s.Email__c;
					if(s.Econtact_2_Relationship_to_Student__c!=null)
					c.Econtact_2_Relationship_to_Student__c = s.Econtact_2_Relationship_to_Student__c;
					if(s.EContact_2_Work_Phone__c!=null)
					c.EContact_2_Work_Phone__c = s.EContact_2_Work_Phone__c;
					if(s.EContact_2_Home_Phone__c!=null)
					c.EContact_2_Home_Phone__c = s.EContact_2_Home_Phone__c;
					if(s.EContact_2_Cell_Phone__c!=null)
					c.EContact_2_Cell_Phone__c = s.EContact_2_Cell_Phone__c;
					if(s.EContact_1_Home_Phone__c!=null)
					c.EContact_1_Home_Phone__c = s.EContact_1_Home_Phone__c;
					if(s.EContact_1_Cell_Phone__c!=null)
					c.EContact_1_Cell_Phone__c = s.EContact_1_Cell_Phone__c;
					if(s.EC_1_Relationship_to_Student__c!=null)
					c.EC_1_Relationship_to_Student__c = s.EC_1_Relationship_to_Student__c;
					if(s.District_of_Columbia_C_Student_ID__c!=null)
					c.District_of_Columbia_C_Student_ID__c = s.District_of_Columbia_C_Student_ID__c;
					if(s.Disability_Flag__c!=null)
					c.Disability_Flag__c = s.Disability_Flag__c;
					if(s.Detailed_Exit_Reason__c!=null)
					c.Detailed_Exit_Reason__c = s.Detailed_Exit_Reason__c;
					if(s.Date_of_Birth__c!=null)
					c.Date_of_Birth__c = c.Birthdate = s.Date_of_Birth__c;
					if(s.Currently_evaluated_for_special_ed__c!=null)
					c.Currently_evaluated_for_special_ed__c = s.Currently_evaluated_for_special_ed__c;
					if(s.Country_of_Origin__c!=null)
					c.Country_of_Origin__c = s.Country_of_Origin__c;
					if(s.Comments__c!=null)
					c.Comments__c = s.Comments__c;
					if(s.Admission_Status__c!=null)
					c.Admission_Status__c = s.Admission_Status__c;
					if(s.Admission_Code__c!=null)
					c.Admission_Code__c = s.Admission_Code__c;
					if(s.Birth_Place_State__c!=null)
					c.Birth_Place_State__c = s.Birth_Place_State__c;
					if(s.Birth_Place_City__c!=null)
					c.Birth_Place_City__c = s.Birth_Place_City__c;
					if(s.City__c!=null)
					c.MailingCity = s.City__c;
					if(s.State__c!=null)
					c.MailingState = s.State__c;
					if(s.Zip_Code__c!=null)
					c.MailingPostalCode = s.Zip_Code__c;
					if(s.Address__c!=null)
					c.MailingStreet = s.Address__c;

					contactMap.put(c.id, c);
				}//end update conditional if
			}//end for

			core_triggerUtils.contactTrigger = false;
			Database.update(contactMap.values(), false);
			core_triggerUtils.contactTrigger = true;
		}//end empty contactMap
	}

	public static void scheduleGroup_onInsert(Map <Id, Student__c> newMap){
		List <Student_Section__c> ssList = new List <Student_Section__c>();
		for (Student__c s: newMap.values()){
			if (s.primary_schedule_group__c !=null){
				Student_Section__c newSs = new Student_Section__c(
						Active__c=true,
						Student__c=s.id, 
						Section__c=s.primary_schedule_group__c,
						Enrollment_Start_Date__c=s.Exit_Date__c,
						reference_id__c = CT_Student_Section_Utils.generateStudentSectionReference(s)
					);
				ssList.add(newSs);
			}
		}
		if (!ssList.isEmpty()){
			upsert ssList;
		}
	}

	public static void scheduleGroup_onUpdate(Map <Id, Student__c> newMap, Map <Id, Student__c> oldMap){
		List<Student_Section__c>	ssList = new List<Student_Section__c>();
		for (Student__c s: newMap.values()){
			if (newMap.get(s.id).primary_schedule_group__c != oldMap.get(s.id).primary_schedule_group__c){
				if (s.primary_schedule_group__c!=null && s.Primary_Schedule_Group_RT__c=='Schedule_Group'){
					Student_Section__c newSs = new Student_Section__c(Student__c=s.id, Section__c=s.primary_schedule_group__c);
					newSs.Enrollment_Start_Date__c=s.Exit_Date__c;
					newSs.active__c=true;
					newSs.reference_id__c = CT_Student_Section_Utils.generateStudentSectionReference(s);
					system.debug('newSs~~~~'+newSs);
					ssList.add(newSs);
				}
				if (oldMap.get(s.id).primary_schedule_group__c!=null && oldMap.get(s.id).Primary_Schedule_Group_RT__c=='Schedule_Group'){
					Student_Section__c oldSs = new Student_Section__c(Student__c=s.id, Section__c=oldMap.get(s.id).primary_schedule_group__c);
					oldSs.Enrollment_End_Date__c=s.Exit_Date__c;
					oldSs.active__c=false;
					oldSs.reference_id__c = CT_Student_Section_Utils.generateStudentSectionReference(oldMap.get(s.id));
					system.debug('oldSs~~~~'+oldSs);
					ssList.add(oldSs);
				}
			}
		}

		if (!ssList.isEmpty()){
			upsert ssList reference_id__c;
		}
	}

	public static void manageActivationProcess(Map <Id, Student__c> newMap, Map <Id, Student__c> oldMap, boolean isNew){
		List <Enrollment_Tracking__c> enrollmentTrackingList = new List <Enrollment_Tracking__c>();
		for(Student__c s: newMap.values()){
			if(s.Archived__c){
				s.Active__c = false;
			}
			if (s.Setup__c != null && s.Setup_Term__c != null){
				if (isNew){
					if (s.Entry_date__c ==null){
						enrollmentTrackingList.add(processEnrollmentRecords(s, s.Setup_Term_Start_Date__c));
					} else {
						enrollmentTrackingList.add(processEnrollmentRecords(s, s.Entry_date__c));
					}
				} else {
					if (s.Active__c && !oldMap.get(s.Id).Active__c){
						if(s.Primary_Schedule_Group__c!=null)
							s.Primary_Schedule_Group__c = null; //if school is group based, erase this student's group relationship
						if (s.Entry_date__c ==null){
							s.Entry_date__c.addError ('Entry Date cannot be blank');
						}else if (s.Entry_date__c < s.Setup_Term_Start_Date__c || s.Entry_date__c > s.Setup_Term_End_Date__c){
							s.Entry_date__c.addError ('Entry Date must be within the term start and end dates');
						} else {
							enrollmentTrackingList.add(processEnrollmentRecords(s, null));
							s.Exit_date__c = null;
						}
					} else if (!s.Active__c && oldMap.get(s.id).Active__c){
						if (s.Exit_date__c ==null){
							s.Exit_date__c.addError ('Exit Date cannot be blank');
						} else if (s.Exit_date__c < s.Setup_Term_Start_Date__c || s.Exit_date__c > s.Setup_Term_End_Date__c){
							s.Exit_date__c.addError ('Exit Date must be within the term start and end dates');
						} else {
							enrollmentTrackingList.add(processEnrollmentRecords(s, null));
						}
					}
				}
			}
		}
		if (!enrollmentTrackingList.isEmpty()){
			upsert enrollmentTrackingList reference_Id__c;
		}
	}

	public static Enrollment_Tracking__c processEnrollmentRecords(Student__c student, Date firstStartDate){
		Boolean bLogTrackingRecord =true;
		Enrollment_Tracking__c et = new Enrollment_Tracking__c(Student__c=student.id, Current_Record__c = true);
		if (student.entry_date__c==null&&student.active__c){
			et.start_date__c = firstStartDate;
			et.active__c=true;
			//enrollment tracking default
		} else if (student.active__c&&student.entry_date__c!=null){
			//enrollment tracking with entry date__c
			et.start_date__c = student.entry_date__c;
			et.active__c=true;
		} else if (!student.active__c&&student.exit_date__c!=null){
			//enrollment tracking with exit date populated
			et.start_date__c = student.exit_date__c;
			et.active__c=false;
			et.exit_reason__c = student.exit_reason__c;
		} else {
			//enrollment tracking inactive default
			et.active__c=false;
			et.start_date__c = firstStartDate;
			et.exit_reason__c = student.exit_reason__c;
		}
		et.reference_id__c = student.id+'-'+et.start_date__c.format();

		return et;
	}

	public static Map <Id, List <Enrollment_Tracking__c>> getStudentEnrollmentMap(Set <Id> StudentIds){
		Map <ID, List <Enrollment_Tracking__c>> etMap = new Map <ID, List <Enrollment_Tracking__c>>();
		for (Enrollment_Tracking__c et: [select Active__c, Student__c, id, start_date__c, end_date__c from Enrollment_Tracking__c where Student__c in: StudentIds]){
			if (etMap.get(et.Student__c)==null){
				etMap.put(et.Student__c, new List <Enrollment_Tracking__c>{et});
			} else{
				etMap.get(et.Student__c).add(et);
			}
		}
		return etMap;
	}

	public static boolean checkEnrollmentTracking( List <Enrollment_Tracking__c> etList, Date dateToCheck){
		for (Enrollment_Tracking__c et: etList){
			if(et.Start_Date__c <= dateToCheck && et.Active__c){
				if(et.End_Date__c == null || (et.End_Date__c != null && et.End_Date__c > dateToCheck)){
					return true;
				}
			}
		}
		return false;
	}
}