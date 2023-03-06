public with sharing class CT_Student_Utils {
	public static void processBeforeInsert(List<Student__c> newStudents){
		System.debug('first condition');
		populateBaseFields(newStudents);
		evaluateExternalStudents(newStudents, null);
	}
	
	public static void processAfterInsert(Map<Id, Student__c> newMap){
		System.debug('second condition');
		if(!core_triggerUtils.mealsTrigger && core_triggerUtils.studentTrigger){
			updateContactFromStudent(newMap.values(), null);
			cascadeStudentContactUpdates(newMap,null, true);

			if (!core_triggerUtils.sectionWizard)
				scheduleGroup_onInsert(newMap);

			manageActivationProcess(newMap, null, true);
		}
	}

	public static void processBeforeUpdate(Map<Id, Student__c> newMap, Map<Id, Student__c> oldMap){
		System.debug('third condition');
		populateFieldsOnUpdate(newMap.values(), oldMap);
		if(core_triggerUtils.studentTrigger){
			populateReferenceId_OnChange(newMap.values(), oldMap);
			updateGradIndicator(newMap, oldMap);
			manageActivationProcess(newMap, oldMap, false);
		}
		checkforgradeoverride(newMap.values(), oldMap);
		evaluateExternalStudents(newMap.values(), getStudentToSchoolMap(newMap.values()));
	}

	public static void processAfterUpdate(Map<Id, Student__c> newMap, Map<Id, Student__c> oldMap){
		System.debug('four condition');
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

	public static void processBeforeDelete(Map<Id, Student__c> oldMap){
		deleteRelatedStudentSections(oldMap.values());//On delete remove any student sections.
	}
	/* ************** End of Method Directly Called from Student Trigger ****************/

	/* ************** Start of Student Helper Methods **************** ****************/
	public static void populateBaseFields(List<Student__c> studentList){
		Boolean isSetupPopulate = false;
		for(Student__c s: studentList){
			System.debug('first conditon data++'+s.Student_ID__c);
			if(s.Setup__c == null){
				isSetupPopulate = true;
			}
		}
		if(isSetupPopulate){
			getStudentSetupMap(studentList);
		}

		for(Student__c s: studentList){
			System.debug('Student_ID__c~~~~'+s.Student_ID__c);
			s.Student_ID__c = String.isNotBlank(s.Local_Student_ID__c)? s.Local_Student_ID__c : s.Student_ID__c;
			System.debug('Student_ID__c!!!'+s.Student_ID__c);
			if(s.Setup__c != null){
				s.School__c = s.Setup_School__c;
				s.School_Year__c = s.Setup_Year__c;
				s.Expiration_Date__c = s.Setup_Year_End_Date__c;
				if(s.Student_ID__c != null){
					s.Reference_Id__c = generateStudentReference(s);
					System.debug('s.Reference_Id__c^^^^'+s.Reference_Id__c);
				} else if(s.Reference_Id__c != null && s.Reference_Id__c.contains('_')){
					s.Student_Id__c = s.Reference_Id__c.split('_',2)[0];
					System.debug('Trigger s.Student_Id__c ***'+s.Student_Id__c);
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
				s.Expiration_Date__c = setup.Year__r.End_Date__c;
				if(s.Student_ID__c != null){
					System.debug('s.Student_ID__c++++'+s.Student_ID__c);
					s.Reference_Id__c = generateStudentReference(s, setup);
				} else if(s.Reference_Id__c != null && s.Reference_Id__c.contains('_')){
					s.Student_Id__c = s.Reference_Id__c.split('_',2)[0];
					System.debug('s.Student_Id__c$$$$'+s.Student_Id__c);
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
			if(String.isNotBlank(s.Holding_Local_ID__c)){
				s.Local_Student_ID__c = String.isBlank(s.Local_Student_ID__c)? s.Holding_Local_ID__c: s.Local_Student_ID__c;
				s.Legacy_Id__c = s.Local_Student_ID__c;
			}
			if(s.isNeedActivate__c){
				s.Active__c = true;
			}
			if(s.Setup__c == null){
				s.addError('The setup the student is assoicated to cannot be found.');
			}
		}
	}

	private static void evaluateExternalStudents(List<Student__c> studentList, Map<Id, Account> studentToSchool){
		for(Student__c student : studentList){
			String legacyKey1 = '';
			String districtExternalId = '';
			if (String.isNotEmpty(student.School__c) & String.isNotEmpty(student.School__r.legacy_key1__c)) {
				legacyKey1 = student.School__r.legacy_key1__c;
			} else {
				if ((studentToSchool != null) && (student.get('Id') != null ) & studentToSchool.containsKey(student.Id)) {
					legacyKey1 = studentToSchool.get(student.Id).legacy_key1__c;
				}
			}
			if (String.isNotEmpty(student.School__c) & String.isNotEmpty(student.School__r.District_School_ID__c)) {
				districtExternalId = student.School__r.District_School_ID__c;
			} else {
				if ((studentToSchool != null) && (student.get('Id') != null ) & studentToSchool.containsKey(student.Id)) {
					districtExternalId = studentToSchool.get(student.Id).District_School_ID__c;
				}
			}
			student = setExternallyEvaluatedValues(student, legacyKey1, districtExternalId);
		}
	}

	private static Map<Id, Account> getStudentToSchoolMap(List<Student__c> students) {
		Map <Id, Account> studentToSchool = new Map<Id, Account>();
		Set<Id> schoolIds = new Set<Id>();
		for(Student__c student : students) {
			schoolIds.add(student.School__c);
		}
		Map<Id, Account> schools = new Map<Id, Account>([SELECT Id, legacy_key1__c, District_School_ID__c FROM Account WHERE Id IN :schoolIds]);
		for(Student__c student : students) {
			studentToSchool.put(student.Id, schools.get(student.School__c));
		}
		return studentToSchool;
	}

	private static Student__c setExternallyEvaluatedValues(Student__c student, String legacyKeyId, String districtExternalId) {
		String localStudentId = student.Local_Student_ID__c;
		if (String.isNotEmpty(localStudentId)) {
			Pattern lettersAndNumbersPattern = Pattern.compile('^[a-zA-Z0-9\\s]*$');
			Matcher lettersAndNumbersPatternMatcher = lettersAndNumbersPattern.matcher(localStudentId);
			Pattern sameCharactersPattern = Pattern.compile('^(.)\\1{1,}$');
			Matcher sameCharactersPatternMatcher = sameCharactersPattern.matcher(localStudentId);
			String error_message = 'Invalid - Local Student ID is not valid, unable to calculate';
			if (!String.isEmpty(localStudentId) && lettersAndNumbersPatternMatcher.matches()) {
				student.External_Evaluation_ID__c = getExternalEvaluationId(localStudentId, legacyKeyId);
				if (!sameCharactersPatternMatcher.matches()) {
					student.CY_YOY_Student_EEID__c = getCYYOYStudentEEId(localStudentId, districtExternalId);
				} else {
					student.CY_YOY_Student_EEID__c = error_message;
				}
			} else {
				student.External_Evaluation_ID__c = error_message;
				student.CY_YOY_Student_EEID__c = error_message;
			}
		}
		return student;
	}

	private static String getExternalEvaluationId(String localStudentId, String legacyKeyId){
		String externalId = localStudentId.right(5);
		if (String.isEmpty(legacyKeyId)) {
			externalId += localStudentId.left(5);
		} else {
			externalId += legacyKeyId + localStudentId.left(5);
		}
		externalId = replaceNumbersToSpecialCharacters(externalId);
		externalId = replaceLettersToNumbers(externalId);
		externalId = replaceSpecialCharactersToNumbers(externalId);
		return externalId;
	}

	private static String replaceNumbersToSpecialCharacters(String numberedString){
		numberedString = numberedString.replace('0', '+');
		numberedString = numberedString.replace('1','!');
		numberedString = numberedString.replace('2','@');
		numberedString = numberedString.replace('3','#');
		numberedString = numberedString.replace('4','$');
		numberedString = numberedString.replace('5','%');
		numberedString = numberedString.replace('6','^');
		numberedString = numberedString.replace('7','&');
		numberedString = numberedString.replace('8','*');
		numberedString = numberedString.replace('9','?');
		return numberedString;
	}

	private static String replaceLettersToNumbers(String str){
		str = str.replace('a', '50');
		str = str.replace('b','51');
		str = str.replace('c','52');
		str = str.replace('d','53');
		str = str.replace('e','54');
		str = str.replace('f','55');
		str = str.replace('g','56');
		str = str.replace('h','57');
		str = str.replace('i','58');
		str = str.replace('j','59');
		str = str.replace('k','60');
		str = str.replace('l','61');
		str = str.replace('m','62');
		str = str.replace('n','63');
		str = str.replace('o','64');
		str = str.replace('p','65');
		str = str.replace('q','66');
		str = str.replace('r','67');
		str = str.replace('s','68');
		str = str.replace('t','69');
		str = str.replace('u','70');
		str = str.replace('v','71');
		str = str.replace('w','72');
		str = str.replace('x','73');
		str = str.replace('y','74');
		str = str.replace('z','75');

		str = str.replace('A', '50');
		str = str.replace('B','51');
		str = str.replace('C','52');
		str = str.replace('D','53');
		str = str.replace('E','54');
		str = str.replace('F','55');
		str = str.replace('G','56');
		str = str.replace('H','57');
		str = str.replace('I','58');
		str = str.replace('J','59');
		str = str.replace('K','60');
		str = str.replace('L','61');
		str = str.replace('M','62');
		str = str.replace('N','63');
		str = str.replace('O','64');
		str = str.replace('P','65');
		str = str.replace('Q','66');
		str = str.replace('R','67');
		str = str.replace('S','68');
		str = str.replace('T','69');
		str = str.replace('U','70');
		str = str.replace('V','71');
		str = str.replace('W','72');
		str = str.replace('X','73');
		str = str.replace('Y','74');
		str = str.replace('Z','75');
		return str;
	}

	private static String replaceSpecialCharactersToNumbers(String str){
		str = str.replace('!','76');
		str = str.replace('@','77');
		str = str.replace('#','78');
		str = str.replace('$','79');
		str = str.replace('%','80');
		str = str.replace('^','81');
		str = str.replace('&','82');
		str = str.replace('*','83');
		str = str.replace('?','84');
		str = str.replace('+','85');
		return str;
	}

	private static String replaceSpecialCharactersToNumbersForCYYOYStudentID(String str){
		str = str.replace('+','71');
		str = str.replace('!','52');
		str = str.replace('@','69');
		str = str.replace('#','49');
		str = str.replace('$','43');
		str = str.replace('%','63');
		str = str.replace('^','41');
		str = str.replace('&','45');
		str = str.replace('*','48');
		str = str.replace('?','61');
		str = str.replace('A','50');
		str = str.replace('a','50');
		str = str.replace('B','51');
		str = str.replace('b','51');
		str = str.replace('C','54');
		str = str.replace('c','54');
		str = str.replace('D','60');
		str = str.replace('d','60');
		str = str.replace('E','62');
		str = str.replace('e','62');

		str = str.replace('F','66');
		str = str.replace('f','66');
		str = str.replace('G','40');
		str = str.replace('g','40');
		str = str.replace('H','68');
		str = str.replace('h','68');
		str = str.replace('I','72');
		str = str.replace('i','72');
		str = str.replace('J','42');
		str = str.replace('j','42');
		str = str.replace('K','59');
		str = str.replace('k','59');
		str = str.replace('L','58');
		str = str.replace('l','58');
		str = str.replace('M','55');
		str = str.replace('m','55');
		str = str.replace('N','53');
		str = str.replace('n','53');
		str = str.replace('O','56');
		str = str.replace('o','56');
		str = str.replace('P','65');
		str = str.replace('p','65');
		str = str.replace('Q','73');
		str = str.replace('q','73');
		str = str.replace('R','47');
		str = str.replace('r','47');
		str = str.replace('S','46');
		str = str.replace('s','46');
		str = str.replace('T','64');
		str = str.replace('t','64');
		str = str.replace('U','57');
		str = str.replace('u','57');
		str = str.replace('V','44');
		str = str.replace('v','44');
		str = str.replace('W','70');
		str = str.replace('w','70');
		str = str.replace('X','67');
		str = str.replace('x','67');
		str = str.replace('Y','74');
		str = str.replace('y','74');
		str = str.replace('Z','75');
		str = str.replace('z','75');
		return str;
	}

	private static String getCYYOYStudentEEId(String localStudentId, String districtSchoolId){
		String studentId;
		String errorMessage;
		if (localStudentId.contains(' ')) {
			errorMessage = 'Invalid - Local Student ID contains spaces';
		}
		if (localStudentId.length() <= 4) {
			errorMessage = 'Invalid - Local Student ID Less Than 5 characters';
		}
		if (localStudentId.toUpperCase().contains('STUD')) {
			errorMessage = 'Invalid - Site does not assign Local Student IDs';
		}
		if (localStudentId.toUpperCase().contains('E+')) {
			errorMessage = 'Invalid - Local Student ID contains scientific notation';
		}
		if (String.isEmpty(errorMessage)) {
			String internalLocalId = localStudentId.leftPad(20, '0');
			if (localStudentId.length() < 10) {
				studentId = String.valueOf(localStudentId.length()).leftPad(2, '0');
			} else {
				if (localStudentId.length() >= 10 && localStudentId.length() < 100) {
					studentId = String.valueOf(localStudentId.length());
				} else {
					studentId = '00';
				}
			}
			studentId += internalLocalId.left(10) + districtSchoolId + internalLocalId.right(10);
			studentId = studentId.replace(' ','');
			studentId = replaceNumbersToSpecialCharacters(studentId);
			studentId = replaceSpecialCharactersToNumbersForCYYOYStudentID(studentId);
			return studentId;
		} else {
			return errorMessage;
		}
	}

	public static void populateFieldsOnUpdate(List<Student__c> lstStudents, Map<Id, Student__c> oldMap){
		for(Student__c student: lstStudents){
			if(student.Expiration_Date__c==null){
				student.Expiration_Date__c = student.Setup_Year_End_Date__c;
			}
		}
	}

	public static String generateStudentReference(Student__c s){
		System.debug('s.Student_ID__c$$$'+s.Student_ID__c+'_'+s.School_Reference_Id__c+'_'+s.Setup_Year_Name__c.trim()+((s.Setup_School_RT__c == 'Summer_School')?'SS':''));
		return s.Student_ID__c+'_'+s.School_Reference_Id__c+'_'+s.Setup_Year_Name__c.trim()+((s.Setup_School_RT__c == 'Summer_School')?'SS':'');
	}

	public static String generateStudentReference(Student__c s, Setup__c setup){
		return s.Student_ID__c+'_'+setup.School__r.Reference_Id__c+'_'+setup.Year__r.Name__c.trim()+((setup.School__r.RecordType.Name == 'Summer School')?'SS':'');
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
			System.debug('studentId++'+s.Student_ID__c);
			System.debug('Id++'+s.Id);
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

	public static void populateReferenceId_OnChange(List<Student__c> studentList, Map <Id, Student__c> oldMap){
		for(Student__c s:studentList){
			if(s.Setup__c == null && oldMap.get(s.id).Setup__c != null){
				s.Setup__c.addError('You cannot remove a setup from a student once set.');
			}
			if(s.School_Year__c == null && oldMap.get(s.id).School_Year__r != null){
				s.Setup__c.addError('You cannot remove the year from a student once set.');
			}
			if(s.Student_ID__c == null && oldMap.get(s.id).Student_ID__c != null){
				//s.Student_Id__c = s.Reference_Id__c = s.id;
				s.Student_Id__c.addError('You cannot remove the Student Id from a student once set.');
			}
			if(s.Setup__c != null && s.Setup__c != oldMap.get(s.id).Setup__c){
				s.School__c = s.Setup_School__c;
				s.School_Year__c = s.Setup_Year__c;
			}
			if(s.Setup__c != null && s.Student_Id__c != null){
				//s.Reference_Id__c = s.Student_ID__c+'_'+s.School_Reference_Id__c+'_'+s.Setup_Year_Name__c.trim()+((s.Setup_School_RT__c == 'Summer_School')?'SS':'');
				s.Reference_Id__c = generateStudentReference(s);
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
			System.debug('Student_ID__c@@@@'+s.Student_ID__c);
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
					System.debug('Student_Id__c&&&'+newMap.get(ss.Student__c).Student_Id__c);
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
		Map<Id, Student__c> mapStudents = new Map<Id, Student__c>();
		for(Student__c s: newMap.values()){
			if(oldMap.get(s.Id).Active__c && !s.Active__c){
				mapStudents.put(s.Id, s);
			}
		}
		if(!mapStudents.isEmpty() && CT_core_TriggerUtils.disabledProceedSS==false){
			CT_core_triggerUtils.populateDeactivateActivateSS(mapStudents, oldMap, CT_core_triggerUtils.SOBJTYPE.STUDENT, CT_core_triggerUtils.SOBJMODE.StudenSection);
		}
	}

	public static void deleteRelatedStudentSections(List<Student__c> deletedStudentList){
		Set<ID> studentsToDelete = new Set<ID>();
		for(Student__c s:deletedStudentList){
			studentsToDelete.add(s.id);
		}

		List<Student_Section__c> toDelete = [select id from Student_Section__c where Student__c in :studentsToDelete];
		if(toDelete != null && !toDelete.isEmpty()){
			InterventionSessionUtils.isSkipValidtion = true;
			delete toDelete;
			InterventionSessionUtils.isSkipValidtion = false;
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
			for (Setup__c s: [SELECT ID,Term__r.End_Date__c,Term__r.Date_start_date__c,Cascade_daily_attendance__c,Grade_Span__c,
					School__c, Year__c, Year__r.Name__c, Year__r.End_Date__c,
					School__r.RecordType.Name, School__r.Reference_Id__c
			FROM Setup__c
			WHERE id in:setupMap.keySet() OR (School__c IN: schoolIds and Year__c IN: yearIDs)]){
				setupMap.put(s.id, s);
				setupMap.put(''+s.School__c+s.Year__c, s);
			}

			for (Student__c student: studentList){
				System.debug('student~~~~'+student.Student_ID__c);
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
				System.debug('s.Individual__c++'+s.Individual__c);
				System.debug('X18_digit_ID__c'+s.X18_digit_ID__c);
				if(s.Individual__c!=null && s.Student_Id__c!=s.Individual_Reference_Id__c){
					if(!trigger.isInsert){
						if(s.Student_Id__c != oldMap.get(s.Id).Student_Id__c)
							contactMap.get(s.Individual__c).Reference_Id__c = s.X18_digit_ID__c;
							System.debug('s.Student_Id__c==='+s.Student_Id__c);
						    System.debug('trigger contact Reference_Id__c==='+contactMap.get(s.Individual__c).Reference_Id__c);
					} else{
						contactMap.get(s.Individual__c).Reference_Id__c = s.X18_digit_ID__c;
						System.debug('s.Student_Id__c****'+s.Student_Id__c);
						System.debug('trigger contact Reference_Id__c **'+contactMap.get(s.Individual__c).Reference_Id__c);
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
						c.Exit_Date__c = (Date) s.Exit_Date__c;
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
						System.debug('c.Date_of_Birth__c++'+c.Date_of_Birth__c);
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
			System.debug('contactMap.values()+++'+contactMap.values());
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
					oldSs.Section_Exit_Reason__c = core_triggerUtils.SECTIONEXITREASONBYSCHEDULER;
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

	public static void manageActivationProcess(Map<Id, Student__c> newMap, Map<Id, Student__c> oldMap, Boolean isNew){
		List<Enrollment_Tracking__c> enrollmentTrackingList = new List<Enrollment_Tracking__c>();
		for(Student__c s: newMap.values()){
			if(s.Archived__c){
				s.Active__c = false;
			}
			if (s.Setup__c == null || s.Setup_Term__c == null){ continue;}
			if (isNew){
				enrollmentTrackingList.add(processEnrollmentRecords(s, s.Entry_date__c==null? s.Setup_Term_Start_Date__c: s.Entry_date__c));
			} else {
				if (s.Active__c && !oldMap.get(s.Id).Active__c){
					if(s.Primary_Schedule_Group__c!=null){
						s.Primary_Schedule_Group__c = null; //if school is group based, erase this student's group relationship
					}
					if (s.Entry_date__c ==null){
						s.Entry_date__c.addError ('Entry Date cannot be blank');
					}else if (s.Entry_date__c < s.Setup_Term_Start_Date__c || s.Entry_date__c > s.Setup_Term_End_Date__c){
						s.Entry_date__c.addError ('Entry Date must be within the term start and end dates');
					} else {
						enrollmentTrackingList.add(processEnrollmentRecords(s, null));
						s.Exit_date__c = null;
						s.Student_Exit_Reason__c = null;
					}
				} else if (!s.Active__c && oldMap.get(s.id).Active__c){
					if (s.Exit_date__c == null){
						s.Exit_date__c.addError ('Exit Date cannot be blank');
					} else if (s.Exit_date__c < s.Setup_Term_Start_Date__c || s.Exit_date__c > s.Setup_Term_End_Date__c){
						s.Exit_date__c.addError ('Exit Date must be within the term start and end dates');
					} else {
						enrollmentTrackingList.add(processEnrollmentRecords(s, null));
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
		et.reference_id__c = student.id+'-'+et.start_date__c.format(CT_core_SoqlUtils.ENROLLMENTTRACKINGREFERENCE);

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

	public static boolean checkEnrollmentTracking(List<Enrollment_Tracking__c> etList, Date dateToCheck){
		for (Enrollment_Tracking__c et: etList){
			if(et.Start_Date__c.date() <= dateToCheck && et.Active__c){
				if(et.End_Date__c == null || (et.End_Date__c != null && et.End_Date__c > dateToCheck)){
					return true;
				}
			}
		}
		return false;
	}

	public static void checkforgradeoverride(List<Student__c> students, Map<Id, Student__c> oldMap) {
		for(Student__c s: students){
			if(s.Final_Grade_Overridden_Count__c != oldMap.get(s.Id).Final_Grade_Overridden_Count__c ||
					s.Final_Section_Grades_Overridden_Count__c != oldMap.get(s.Id).Final_Section_Grades_Overridden_Count__c){
				s.Grades_Overridden__c = (s.Final_Grade_Overridden_Count__c + s.Final_Section_Grades_Overridden_Count__c)>0? true: false;
			}
		}
	}
}