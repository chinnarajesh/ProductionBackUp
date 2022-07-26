public with sharing class StaffTH {
	public static void processBeforeInsert(List<Staff__c> triggerNew){
		Set<Id> schoolId = new Set<Id>();
		for(Staff__c s : triggerNew){	
			if (s.Organization__c==null)
				s.Organization__c.addError('Organization must be populated.');
			else	
				schoolId.add(s.Organization__c);
		}
		
		Map<Id, Setup__c> setupMap = core_SoqlUtils.getActiveSetups(schoolId);
		Map<Id, Account> schoolMap = new Map<Id, Account>([select id, Name, RecordType.Name from Account where id IN: schoolID]);
		for(Staff__c staff : triggerNew){
			if(staff.Organization__c != null){
				if(setupMap.containsKey(staff.Organization__c)){
					staff.Reference_Id__c = staff.ID__c + '_' + setupMap.get(staff.Organization__c).School__r.Name;
				} else if(schoolMap.get(staff.Organization__c).RecordType.Name != 'School' && schoolMap.get(staff.Organization__c).RecordType.Name != 'Summer School'){
						staff.Reference_Id__c = staff.ID__c + '_' + schoolMap.get(staff.Organization__c).Name;
				} else {
					staff.Organization__c.addError('There are no active setups for the selected school. Please setup your school before creating staff.');
				}
			}
			if (staff.name==null&&(staff.First_Name_Staff__c!=null && staff.Staff_Last_Name__c!=null)){
				staff.name = staff.First_Name_Staff__c+' '+ staff.Staff_Last_Name__c;
			}
		}
	}
	
	public static void processAfterInsert(List<Staff__c> triggerNew){
		//ProcessHelper(triggerNew);
	}
	
	//When a staff record is updated - roll updates to contact record
	public static void processAfterUpdate(Map<ID,Staff__c> newMap, Map<ID,Staff__c> oldMap){
		//ProcessHelper(newMap.values());
		checkDeactivation(newMap, oldMap);
	}
	
	//public static void processHelper(List<Staff__c> triggerNew){
	//	Set<Id> conSet = new Set<Id>();
	//	for(Staff__c s1 : triggerNew){
	//		conSet.add(s1.Individual__c);
	//	}
		
	//	Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id, Email, LastName, FirstName, MailingCity, MailingState, MailingStreet, 
	//		MailingPostalCode FROM Contact WHERE Id IN: conSet]);
	//	List<Contact> conList = new List<Contact>();
	//	for(Staff__c s2 : triggerNew){
	//		if (conMap.get(s2.Individual__c)!=null){
	//			Contact con = conMap.get(s2.Individual__c);
	//			if(s2.Email__c != con.Email && s2.Email__c != null){
	//				con.Email = s2.Email__c;
	//			}
	//			if (s2.First_Name_Staff__c != con.FirstName && s2.First_Name_Staff__c!= null){
	//				con.FirstName = s2.First_Name_Staff__c;
	//			}
	//			if (s2.Staff_Last_Name__c != con.LastName && s2.Staff_Last_Name__c != null){
	//				con.LastName = s2.Staff_Last_Name__c;
	//			}
	//			if(s2.Address_1__c != con.MailingStreet && s2.Address_1__c != null){
	//				con.MailingStreet = s2.Address_1__c;
	//			}
	//			if(s2.City__c != con.MailingCity && s2.City__c != null){
	//				con.MailingCity = s2.City__c;
	//			}
	//			if(s2.State__c != con.MailingState && s2.State__c != null){
	//				con.MailingState = s2.State__c;
	//			}
	//			if(s2.Zip_Code__c != con.MailingPostalCode && s2.Zip_Code__c != null){
	//				con.MailingPostalCode = s2.Zip_Code__c;
	//			}
	//			conMap.put(con.id, con);
	//		}
	//	}
		
	//	update conMap.values();
	//}
	
	public static void checkDeactivation(Map<ID,Staff__c> newMap, Map<ID,Staff__c> oldMap){
		Set<ID> deactivatedIDs = new Set<ID>();
		for(Staff__c s: newMap.values()){
			if(oldMap.get(s.id).Active__c && !s.Active__c) deactivatedIDs.add(s.id);
		}
		if(!deactivatedIDs.isEmpty()){
			core_triggerUtils.deactivateStaffSections(deactivatedIDs,true);
		}
	}
	
	public static void processBeforeDelete(List <Staff__c> staffToDelete){
		Set <Id> staffIds = new Set<Id>();
		for (Staff__c s: staffToDelete){
			staffIds.add(s.id);
		}
		List <Staff_Section__c> ssList= new List <Staff_Section__c> ();
		for (Staff_Section__c ss: [select id from Staff_Section__c where staff__c in :staffIds]){
			ssList.add(ss);
		}
		List <Scheduled_Section__c> schedSectionList= new List <Scheduled_Section__c> ();
		for (Scheduled_Section__c ss: [select id from Scheduled_Section__c where staff__c in :staffIds]){
			schedSectionList.add(ss);
		}
		if (!ssList.isEmpty()) delete ssList;
		if (!schedSectionList.isEmpty()) delete schedSectionList;
	}

	public static final String NONE = 'None';
	public static final String SEPARATORPROGRAM = ' & ';
	public static void populateSections(List<Staff__c> staffs, Map<Id, Staff__c> oldMap){
		List<Staff__c> processStaff = new List<Staff__c>();
		Map<String, Set<String>> mapStafftoPrograms = new Map<String, Set<String>>();
		Map<Id, Map<String, Account_Program__c>> mapSchoolToAPs = new Map<Id, Map<String, Account_Program__c>>();
		//populate staff to process
		for(Staff__c staff: staffs){
			mapStafftoPrograms.put(staff.Id, new Set<String>());
			List<String> lstSelProgrms = String.isNotBlank(staff.CreateSections__c)? staff.CreateSections__c.split(';'): new List<String>();
			if(!lstSelProgrms.isEmpty() && (oldMap==null || (oldMap!=null && 
					(staff.CreateSections__c!=oldMap.get(staff.Id).CreateSections__c)))){
				String oldCreateSections = oldMap!=null? oldMap.get(staff.Id).CreateSections__c: '';
				for(String selProgram: lstSelProgrms){
					String selectedProgram = selProgram.removeStart(' ').removeEnd(' ');
					if(oldMap==null || (oldMap!=null && (String.isBlank(oldCreateSections) || 
							(String.isNotBlank(oldCreateSections) && !oldCreateSections.contains(selectedProgram))))){
						mapStafftoPrograms.get(staff.Id).add(selectedProgram);
					}
				}
				if(!mapStafftoPrograms.get(staff.Id).isEmpty()){
					processStaff.add(staff);
					mapSchoolToAPs.put(staff.Organization__c, new Map<String, Account_Program__c>());
				}
			}
		}

		if(!processStaff.isEmpty()){
			//get section record type
			Id sectionRTId = CT_core_SoqlUtils.getRecordTypeIdBySobject('Section__c','Intervention Section');

			//get configuration for section
			List<StaffSectionsCreation__mdt> sscmdt = [SELECT Id, Program_Name__c, In_After_School__c, Start_Date__c, End_Date__c, 
							Section_Frequency__c, Target_Dosage__c, Notes__c FROM StaffSectionsCreation__mdt];			
			Set<String> programNames = new Set<String>();
			for(StaffSectionsCreation__mdt mdt: sscmdt){
				programNames.add(mdt.Program_Name__c);
			}

			//get programs for sections
			List<Account_Program__c> accountPrograms = [SELECT Id, School__c, Program__c, 
				Current_Year_ID__c, Current_Year_ID__r.Date_Start_Date__c, Current_Year_ID__r.End_Date__c, 
				Program__r.Id, Program__r.Name, Program__r.Program_Description__c, Program__r.Indicator_Area__r.Name, 
				Program__r.Indicator_Area__c, Program__r.Recommended_Weekly_Frequency__c, 
				Program__r.Recommended_Time_per_Session__c, Program__r.Overall_Target_Dosage__c   
				FROM Account_Program__c WHERE Active__c = true AND School__c IN :mapSchoolToAPs.keySet() 
					AND Program__r.Name IN :programNames ORDER BY Program__r.Name];			
			for(Account_Program__c ap: accountPrograms){
				mapSchoolToAPs.get(ap.School__c).put(ap.Program__r.Name, ap);
			}

			//populate sections
			List<Section__c> processSections = new List<Section__c>();
			for(Staff__c staff: processStaff){
				Set<String> staffPrograms = mapStafftoPrograms.get(staff.Id);
				for(StaffSectionsCreation__mdt mdt: sscmdt){
					String selectedProgramKey = mdt.Program_Name__c + (mdt.In_After_School__c!=NONE? SEPARATORPROGRAM + mdt.In_After_School__c: '');
					Date initDate = Date.today().month()<6? Date.today().addYears(-1): Date.today();
					Integer diffYears = initDate.year() - mdt.Start_Date__c.year();
					if(staffPrograms.contains(selectedProgramKey) &&
							mapSchoolToAPs.get(staff.Organization__c).containsKey(mdt.Program_Name__c)){
						Account_Program__c selAP = mapSchoolToAPs.get(staff.Organization__c).get(mdt.Program_Name__c);
						processSections.add(new Section__c(
							Name = mdt.Program_Name__c +' '+ mdt.In_After_School__c +' '+ staff.Staff_Last_Name__c, 
							School__c = staff.Organization__c,//activeSchoolID,
							Program__c = selAP.Program__c,//current program id
							Time__c = selAP.Current_Year_ID__c,//CYUtil.getSchoolYearID(staff.Organization__c),
							RecordTypeId = sectionRTId,
							Start_Date__c = mdt.Start_Date__c==null? selAP.Current_Year_ID__r.Date_Start_Date__c: mdt.Start_Date__c.addYears(diffYears),
							End_Date__c = mdt.End_Date__c==null? selAP.Current_Year_ID__r.End_Date__c: mdt.End_Date__c.addYears(diffYears),
							Intervention_Primary_Staff__c = staff.Id,
							In_After_School__c = mdt.In_After_School__c!=NONE? mdt.In_After_School__c: null,
							Notes__c = mdt.Notes__c,
							Section_Frequency__c = mdt.Section_Frequency__c,//Monday; Tuesday; Wednesday; Thursday; Friday
							Target_Dosage_Section_Goal__c = mdt.Target_Dosage__c == null? selAP.Program__r.Overall_Target_Dosage__c: mdt.Target_Dosage__c,
							Account_Program__c = selAP.Id,//current Account Program
							Active__c = true
						));

					}
				}
			}

			//insert new sections
			if(!processSections.isEmpty()){
				insert processSections;
			}
		}
	}

}