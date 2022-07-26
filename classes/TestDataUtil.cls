public class TestDataUtil{
	public static Map<String,Picklist_Value__c> plvMap;
	public static Time_Element__c year;

	public static Id staticSetupId;
	public static Map<String, Map<String, Id>> rtMapCopy;
	public static Picklist_Value__c YearPickVal;
	public static Picklist_Value__c TermPickVal;
	public static Picklist_Value__c SemPickVal;
	public static Picklist_Value__c PeriodPickVal;
	public static Time_Element__c masterYear;
	public static Time_Element__c term;
	public static Time_Element__c semester;
	public static Time_Element__c semester2;
	public static Time_Element__c period;
	public static string plValueType;
	public static Map <String, Picklist_Value__c> plValueMap;
	public static List <Picklist_Value__c> plValuesList;
	public static Map<Id,Setup__c> activeSetupMap = new Map<Id,Setup__c>();		
	
	public static integer availableSchools;
	public static List<Account> schoolList = new List<Account>();
	public static Map<Id, schoolWrapper> testDataMap = new Map<Id, schoolWrapper>();
	public static List<schoolWrapper> testData = new List<schoolWrapper>();

	/* Start methods from CY TestDataUtil*/
	public static void setupTime(){
		createDefaultTimeValues();
		plvMap = plValueMap;
		Integer yearOffset = 2050 - System.today().year();
		setupTimeElements(yearOffset);
	}

	public static void setupSharingControls(){
		List<SharingControls__c> sc = new List<SharingControls__c>();
		sc.add(new SharingControls__c(Name='CM', Profile_Name__c='Corps Member'));
		sc.add(new SharingControls__c(Name='SA', Profile_Name__c='School Admin'));
		sc.add(new SharingControls__c(Name='Site', Profile_Name__c='Site Admin'));
		insert sc;
	}

	public static Account createSchool(String schoolName){
		ID recordType = [SELECT id FROM RecordType WHERE Name='School' AND sObjectType='Account'].id;
		Account school = new Account(
			RecordTypeId=recordType,
			Name=schoolName,
			Reference_ID__c=schoolName,
			Site__c='Cleveland'
		);
		return school;
	}

	public static User createUser(String username, ID profileId){
		User u = new User(
			alias = username.substring(0,3),
			Email = username+'@testorg.com',
			LastName = username+'LastName',
			FirstName = username+'FirstName',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileID = profileId,
			TimeZoneSidKey = 'America/New_York',
			CompanyName = username+' Company',
			UserName ='FirstName.LastName_' + username + '@testing.com',
			Country = username+'Country',
			IsActive = true,
			EmailEncodingKey = 'UTF-8'
		);
		return u;
	}
	
	public static Contact createContact(String firstName, String lastName, ID userId){
		Contact c = new Contact(
			FirstName=firstName,
			LastName=lastName,
			User__c=userId
		);
		return c;
	}
	
	public static Staff__c createStaff(Contact c, Account a, integer i){
		Staff__c staff = new Staff__c(
			ID__c=c.LastName+i,
			External_Id__c=c.LastName+i,
			Name=c.Name,
			First_Name_Staff__c=c.FirstName,
			Staff_Last_Name__c=c.LastName,
			Reference_Id__c=a.Reference_Id__c+'_'+i,
			Individual__c=c.Id,
			Organization__c=a.Id,
			Active__c=true
		);
		return staff;
	}
	
	public static List<Student__c> createStudents(integer cnt, Account school){
		List<Student__c> students = new List<Student__c>();
		for(Integer i = 0; i < cnt; i++){
			Student__c student = new Student__c(
				Student_Last_Name__c = 'Testor',
				Student_First_Name__c = 'Testie' + i.format(),
				School__c = school.id,
				Gender__c = 'M',
				Ethnicity__c = 'Hispanic / Latino',
				Date_of_Birth__c = Date.today(),
				Active__c = true,
				Setup__c = activeSetupMap.get(school.ID).ID,
				Student_ID__c = String.valueOf(Datetime.now().getTime())+i,
				School_Year__c = year.id,
				Grade__c = '5'
			);
			students.add(student);
		}
		return students;
	}
	
	public static List<Indicator_Area__c> createIndicatorAreas() {
		List<Indicator_Area__c> ias = new List<Indicator_Area__c>();
		ias.add(new Indicator_Area__c(Name = 'Attendance',Indicator_Area_Type__c='Attendance',Active__c=true));
		ias.add(new Indicator_Area__c(Name = 'Behavior',Indicator_Area_Type__c='Behavior',Active__c=true));
		ias.add(new Indicator_Area__c(Name = 'ELA/Literacy',Indicator_Area_Type__c='ELA/Literacy',Active__c=true));
		ias.add(new Indicator_Area__c(Name = 'Math',Indicator_Area_Type__c='Math',Active__c=true));
		return ias;
	}
	public static List<Indicator_Area_Student__c> createIAStudents(List<Student__c> students,Id iaId) {
		List<Indicator_Area_Student__c> iaStuList = new List<Indicator_Area_Student__c>();
		for(Student__c stu :students) {
			Indicator_Area_Student__c iaStu = new Indicator_Area_Student__c(
				Student__c = stu.id,
				Indicator_Area__c = iaId,
				Active__c = true
			);
			iaStuList.add(iaStu);
		}
		return iaStuList;
	}

	public static List<Program__c> createPrograms(Integer cnt, boolean isRequired, Indicator_Area__c ia) {
		List<Program__c> programs = new List<Program__c>();
		for(integer i = 1; i <= cnt; i++){
			programs.add(new Program__c(
				Name = ia.Name+' Program '+i,
				Required_Program__c =isRequired,
				Status__c = 'Approved',
				Indicator_Area__c = ia.Id,
				Active__c = true
			));
		}
		return programs;
	}

	public static Section__c createSection(Account school, Account_Program__c ap, List<Student__c> students, Staff__c pm, Program__c p) {
		return createSections(1, school, ap, new List<List<Student__c>>{students},pm,p)[0];
	}
	
	public static List<Section__c> createSections_WithoutInsert(Integer numberOfSections, Account school, Account_Program__c ap, Staff__c pm, Program__c p){
		List<Section__c> sections = new List<Section__c>();
		for(Integer i=0;i<numberOfSections;i++){
			Section__c section = new Section__c(
				Name = 'Section'+i,
				School__c = school.Id,
				RecordTypeId = getRecordTypesBysObject('Section__c').get('Intervention_Section'),
				Time__c = masterYear.id,
				Start_Date__c = Date.today(),
				End_Date__c = Date.today().addDays(5),
				Intervention_Primary_Staff__c = pm.id,
				In_After_School__c = 'In School',
				Notes__c = 'Notes',
				Section_Frequency__c = 'Monday;Wednesday;Friday',
				Target_Dosage_Section_Goal__c = 500,
				Program__c = p.Id,
				Account_Program__c = ap.Id,
				Active__c = true
			);

			sections.add(section);
		}

		return sections;
	}

	public static List<Student_Section__c> createStudentSections_WithoutInsert(List<Section__c> sections,List<List<Student__c>> students){
		List<Student_Section__c> stuSecList = new List<Student_Section__c>();
		for(Integer i=0;i<sections.size();i++){
			for(Student__c s:students[i]){
				Student_Section__c ss = new Student_Section__c(
					Section__c = sections[i].id,
					Student__c = s.id,
					Enrollment_Start_Date__c = Date.today(),
					Intervention_Enrollment_Start_Date__c =	Date.today(),
					Section_Exit_Reason__c = null,
					Active__c = true
				);
				stuSecList.add(ss);
			}
		}

		return stuSecList;
	}


	/*private static Time_Element__c getTime(String timeType, ID plvId, Id parentId, Date startDate, Date endDate, Boolean repPeriod, Boolean nsy){
		Time_Element__c te = new Time_Element__c(
			Type__c=timeType,
			Picklist_Value__c=plvId,
			Date_Start_Date__c=startDate,
			End_Date__c=endDate,
			Name__c=startDate.format()+'-'+endDate.format(),
			Parent_Time_Element__c=parentId,
			Reporting_Period__c=repPeriod,
			New_School_Year__c=nsy
		);
		return te;
	}*/

	/* End methods from CY TestDataUtil */
	
	public static void setupData(integer cnt) {
		if(cnt > 5) cnt = 5;
		if(cnt < 1) cnt = 1;
		createDefaultTimeValues();
		setupTimeElements(50);
		schoolList = createSchools(cnt);
		setupSetupRecord();
		setupStaff();
		setupStudents();
		testData = testDataMap.values();
		
	}

	public static List<Indicator_Area__c> createIndicatorAreas(Integer cnt) {
		List<Indicator_Area__c> ias = new List<Indicator_Area__c>();
		for(integer i = 1; i <= cnt; i++) {
			ias.add(new Indicator_Area__c(Name = 'IA'+i));
		}
		return ias;
	}

	public static Account_Program__c createAccountProgram(Account a, Program__c p) {
		return new Account_Program__c(Program__c = p.id,Program__r = p,School__c = a.id,Active__c = true);
	}

	public static List<Section__c> createSections(Integer numberOfSections, Account school, Account_Program__c ap, List<List<Student__c>> students, Staff__c pm, Program__c p){
		List<Section__c> sections = new List<Section__c>();
		for(Integer i=0;i<numberOfSections;i++){
			Section__c section = new Section__c(
				Name = 'Section'+i, 
				School__c = school.Id,
				RecordTypeId = getRecordTypesBysObject('Section__c').get('Intervention_Section'),
				Time__c = masterYear.id,
				Start_Date__c = Date.today(),
				End_Date__c = Date.today().addDays(5),
				Intervention_Primary_Staff__c = pm.id,
				In_After_School__c = 'In School',
				Notes__c = 'Notes',
				Section_Frequency__c = 'Monday;Wednesday;Friday',
				Target_Dosage_Section_Goal__c = 500,
				Program__c = p.Id,
				Account_Program__c = ap.Id,
				Active__c = true
			);

			sections.add(section);
		}

		insert sections;

		List<Student_Section__c> stuSecList = new List<Student_Section__c>();
		for(Integer i=0;i<numberOfSections;i++){
			for(Student__c s:students[i]){
				Student_Section__c ss = new Student_Section__c(
					Section__c = sections[i].id,
					Student__c = s.id,
					Enrollment_Start_Date__c = Date.today(),
					Intervention_Enrollment_Start_Date__c =	Date.today(),
					Section_Exit_Reason__c = null,
					Active__c = true
				);
				stuSecList.add(ss);
			}
		}
		
		insert stuSecList;
		return sections;
	}

	public static Intervention_Session__c createInterventionSession(ID sectionId, ID studentSectionID, ID staffID) {
		Intervention_Session__c is = new Intervention_Session__c();
		is.Date__c = system.today();
		is.Section__c = sectionId;
		is.All_avenues__c = 'In-Person Service';
		is.Session_Time_Completed_For__c = staffID;
		return is;
	}
	
	//Creating records
	
	public static List<Account> createSchools(integer schoolCnt) {
	List<Account> schools = new List<Account>();
	system.debug('----------' + getRecordTypesBySobject('Account').get('Individuals'));
	Account Individuals = new Account(Name = 'Individuals'
																	,RecordTypeId = getRecordTypesBySobject('Account').get('Individuals')
																	,Reference_Id__c = 'Individuals');
	insert Individuals;
	for(Integer i = 0;i < schoolCnt; i++){
		Account acc = new Account(Legacy_ID__c = 'school'
															,RecordTypeId = getRecordTypesBySobject('Account').get('School')
															,Name = 'SC123'+i
															,BillingStreet = '2412 New Hampshire Ave. NW'+'-'+i
															,BillingState = 'Washington D.C'+'-'+i
															,BillingPostalCode ='2003'+i
															,BillingCountry ='USA'
															,BillingCity = 'D.C'+'-'+i
															,Attendance_Goal__c = 96
															,Behavior_Goal__c = 25
															,Reference_Id__c = 'SC123'+i);
		schools.add(acc);
	}
	upsert schools Reference_Id__c;
		for(Account s :schools){
			testDataMap.put(s.Id, new schoolWrapper(s));
		}
	return schools;
}
	
	
	private static void setupStaff() {
		integer cnt = 5;
		System.debug('***** schoolList: ' + schoolList);		
		for(Account school :schoolList) {
			schoolWrapper SW = testDataMap.get(school.Id);
			List<User> usrList = new List<User>();
			System.debug('***** school.Name: ' + school.Name);			
			String username = 'Staff'+school.Name;
			System.debug('***** username: ' + username);
			String[] environment = Userinfo.getUserName().split('@');
			Id profileID = [select id from Profile where Name='System Administrator' limit 1].id;
			for(integer i=0;i<cnt;i++){
				User u = new User(
					alias = username.substring(0,3)+i
					,Email = username+i+'@testorg.com'
					,LastName = username+i+'LastName'
					,FirstName = username+i+'FirstName'
					,LanguageLocaleKey = 'en_US'
					,LocaleSidKey = 'en_US'
					,TimeZoneSidKey = 'America/New_York'
					,CompanyName = username+' Company'
					,ProfileID = profileID
					,UserName ='FirstName'+ '.' + 'LastName' + i.format() + '_' + String.valueOf(DateTime.now().getTime()) + '@testing.com'
					,Country = username+i+'Country'
					,IsActive = true
					,EmailEncodingKey = 'UTF-8');
					usrList.add(u);
					System.debug('***** usrList: ' + usrList);
			}
			insert usrList;
			String contactName = userName;
			List<Contact> contList = new List<Contact>();
			for(integer i=0;i<cnt;i++){
				Contact con = new Contact(
					FirstName = contactName
					,LastName = contactName +'lastname'+i);
				if (usrList!=null)
					con.User__c = usrList[i].Id;
					con.User__r = usrList[i];
				contList.add(con);
			}
			insert contList;
			String staffName = contactName;
			List<Staff__c> staffList = new List<Staff__c>();
			
			for(integer i=0;i<cnt;i++)
			{
				
				Staff__c st = new Staff__c(ID__c = 'teststaff'+i
									,External_Id__c = 'teststaff'+i);
				st.First_Name_Staff__c = staffName;
				st.Staff_Last_Name__c = staffName + 'lastName' + i;
				st.Name = staffName +' '+staffName+ 'lastName' + i;
				st.Reference_Id__c = school.Reference_Id__c+'_'+i;
				st.Individual__c = contList[i].Id;
				st.Individual__r = contList[i];
				st.Active__c = true;
				st.Organization__c = school.Id;
				staffList.add(st);
			}
			system.debug(' STAFF to insert: ------- ' + staffList);
			insert staffList;
			system.debug('INSERTED STAFF------- ' + staffList);
			List<staffWrapper> staffWrapList = new List<staffWrapper>();
			for(integer i=0;i<cnt;i++)
			{
				staffWrapper staffMember = new staffWrapper(usrList[i],contList[i],staffList[i]);
				staffWrapList.add(staffMember);
			}
			SW.sysAdmin = staffWrapList[0];
			SW.cmDirect = staffWrapList[1];
			SW.schoolAdmin = staffWrapList[2];
			SW.siteAdmin = staffWrapList[3];
			SW.networkAdmin = staffWrapList[4];
		}
	}
	
	private static void setupStudents() {
		//why is there a DML in a for loop?
		//looks like we typically only setup one school, so this isn't so bad.
		for(Account school :schoolList) {
			List<Student__c> students = new List<Student__c>();
			schoolWrapper SW = testDataMap.get(school.Id);
			String studName = 'Student'+school.Name;
			integer cnt = 10;
			for(integer i=0;i<cnt;i++){
				Student__c stu = new Student__c();
				stu.Student_First_Name__c = studName;
				stu.Student_Last_Name__c = studName + 'lastName'+i;
				stu.Name = stu.Student_First_Name__c + ' ' + stu.Student_Last_Name__c;
				stu.Student_ID__c = school.Reference_Id__c+'_Stu'+i;
				stu.State__c = 'NC';
				stu.Grade__c='5';
				stu.Email__c='test' + i + '@123.com';
				stu.School__c = school.Id;
				stu.Setup__c = activeSetupMap.get(school.Id).Id;
				stu.School_Year__c = masterYear.Id;
				stu.Active__c = true;
				stu.Reference_Id__c = school.Reference_Id__c+'_Stu'+i;
				stu.External_Id__c = 'externID'+i;
				students.add(stu);
			}
	
			upsert students;
			SW.students = students;
		}
	}
	
	public static void setupTimeElements(integer yearsToAdd){
		Integer month = system.today().month();
		Integer yearNumber = system.today().year()+yearsToAdd;
		String yearStart = '08/01/' + String.valueOf(yearNumber);
		String yearEnd = '07/31/' + String.valueOf(yearNumber+1);
		String termStart = yearStart;
		String termEnd  = yearEnd;

		//year
		masterYear = getTimeElements_NoInsert(1,'Master Year',YearPickVal.Id,null, yearStart,yearEnd,false)[0]; //Time Element for the Master Year
		masterYear.Current__c = true;
		insert masterYear;
		year = masterYear;
		system.debug(LoggingLevel.info, 'masterYear ~~~~~~~~~~~~~~'+masterYear);

		//term
		term = getTimeElements_NoInsert(1,'Term',TermPickVal.Id,masterYear.Id, termStart, termEnd,false)[0];
		term.Reporting_Period_Value__c = SemPickVal.id; //Shouldn't we adapt the getTimeElements method for this
		insert term;


		semester = getTimeElements_NoInsert(1,'Semester',SemPickVal.Id,term.Id, term.date_start_date__c.format(), term.date_start_date__c.addDays(60).format() ,true)[0];
		system.debug(LoggingLevel.info, 'semester ~~~~~~~~~~~~~~'+semester);
		semester2 = getTimeElements_NoInsert(1,'Semester2',SemPickVal.Id,term.Id, term.date_start_date__c.addDays(61).format(), term.end_Date__c.addDays(-10).format() ,true)[0];
		system.debug(LoggingLevel.info, 'semester2 ~~~~~~~~~~~~~~'+semester2);

		List<Time_Element__c> timeElements = new List<Time_Element__c>{semester,semester2};
		insert timeElements;
	}

	public static List<Time_Element__c> getTimeElements_NoInsert(Integer cnt,String elementType,Id pickValType,Id parentId, String startDate, String endDate, Boolean repPeriod){
		List<Time_Element__c> timeList = new List<Time_Element__c>();

		for(Integer i = 0;i < cnt; i++){
			Time_Element__c t = new Time_Element__c();
			t.Type__c = elementType;
			t.Picklist_Value__c = pickValType;
			t.End_Date__c = date.parse(endDate);
			t.Date_Start_Date__c = date.parse(startDate);
			t.Name__c = t.Date_Start_Date__c.format()+'-'+t.End_Date__c.format();
			t.Parent_Time_Element__c = parentId;
			t.Reporting_Period__c = repPeriod;
			t.Days_of_Week__c = 'MTWHF';
			timeList.add(t);
		}
		system.debug(LoggingLevel.info, 'New Time Elements~~~ Type: '+elementType+' && Details:  '+timeList);
		return timeList;
	}
	
	public static void createDefaultTimeValues(){
		Map<String, Id > rtMap= getRecordTypesBySobject('Picklist_Value__c');
		List<Picklist_Value__c> defaultTimeVals = new List<Picklist_Value__c>();
		String[] defaultTimeValues = processCSVFile('timeDefaults');
		for (Integer i=0; i<defaultTimeValues.size(); i++){
			Picklist_Value__c temp = new Picklist_Value__c();
			String[] inputvalues = defaultTimeValues[i].split(',');
			temp.Name = inputValues[0];
			temp.Type__c = inputValues[1];
			if (inputValues.size()>2){
				temp.Category__c = inputValues[2];
				temp.Corresponding_Value__c = decimal.valueOf(inputValues[3].trim());
			}
			System.debug('rtmap = ' + rtMap);
			System.debug('temp = ' + temp);
			System.debug('rtMap = ' + rtMap);
			temp.RecordTypeId = rtMap.get('Time');
			defaultTimeVals.add(temp);
		}
		system.debug(defaultTimeVals);
		insert defaultTimeVals;

				// Insert Pick List Values
		List<Picklist_Value__c> pickValuesList = new List<Picklist_Value__c>();
		Map<String, Picklist_Value__c> plvToNameMap = getPlStringValues('Time', null);
		system.debug(plvToNameMap);
		pickValuesList = plvToNameMap.values();
		YearPickVal = plvToNameMap.get('Year');
		TermPickVal = plvToNameMap.get('Term');
		SemPickVal =  plvToNameMap.get('Semester');
		PeriodPickVal =  plvToNameMap.get('Period');
	}
	
	
	private static String[] processCSVFile(String fileName){
       StaticResource sr = [Select  s.Name, s.Id, s.Body From StaticResource s  where name =:fileName];
       blob tempBlob = sr.Body;
       String tempString = tempBlob.toString();
       tempString = tempSTring.replace('"', '');
       String[] stringArray = tempString.split('\n');
       return stringArray;
    }
	private static Map<String,Picklist_Value__c> getPlStringValues(String stype,  String SetupId) {
		if (stype!=plValueType || setupId !=staticSetupId || plValueMap == null){
			staticSetupId = setupId;
			plValueType = stype;
			plValueMap = new Map<String, Picklist_Value__c>();
			for (Picklist_Value__c pv: getPlValuesList(stype, setupId)){
				plValueMap.put(pv.Name,pv);
			}
		}
		return plValueMap;
	}
	private Static List<Picklist_Value__c> getPlValuesList(String stype, String SetupId) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			plValuesList = [SELECT Corresponding_Value__c, Set_as_default__c, Number__c, Standard_Scale__c, Level__c, Category__c
							 	   ,CreatedBy.FirstName, CreatedBy.LastName, Name, Display_Code__c, Short_Description__c
							 	   ,Internal_Code__c, Is_Unexcused__c, Is_Tardy__c, Is_Early_Departure__c, Is_Suspension__c, Notify_Admin__c, Order__c, Id, Type__c
					  		FROM Picklist_Value__c
					  		WHERE RecordType.Name = :stype
					  		AND (Setup__c = :SetupId or Setup__c = null)
					  		order by Order__c];
		} catch (Exception e)
		{
			
		}
		return plValuesList;
	}
	
	public static void setupSetupRecord(){
		List<Setup__c> activeSetUps = [SELECT Course_Catalog__c, Grade_Scale_Catalog__c, School__c, Year__c, Year__r.Name__c, Term__c, Active__c, Group_Based__c, Room_Dependent__c, Grade_Span__c, Points_Reset_Value__c, Points_Reset_Date__c, Points_Frequency__c, Show_Homework_in_Portal__c FROM Setup__c WHERE School__c IN :schoolList AND Year__c =: masterYear.ID];
		System.debug('#### activeSetups: ' + activeSetups);
		for(Setup__c activeSetup :activeSetUps){
			activeSetup.Active__c = true;
			activeSetUp.Term__c = term.id;
			activeSetUp.Year__c = masterYear.id;
			activeSetup.Group_based__c = false;
			activeSetup.Room_Dependent__c = true;
			activeSetup.Grade_Span__c = '1;2;3;4;5;';
			activeSetup.Points_Frequency__c = 'Monthly';
			activeSetup.Points_Reset_Date__c = system.today();
			activeSetup.Points_Reset_Value__c = 100;
			activeSetup.Show_Homework_in_Portal__c = true;
		}
		update activeSetups;
		for(Setup__c setup :activeSetups) {
			activeSetupMap.put(setup.School__c, setup);
		}
	}
	
	private static Map<String, Id> getRecordTypesBySobject(String sObjectName){
        if (rtMapCopy == null){
            rtMapCopy  = new Map<String, Map<String, Id>>();
            for (RecordType rt: [SELECT id, Name, DeveloperName , sObjectType
                                 FROM RecordType 
                                 WHERE Name!=null
                                 AND IsActive = true]){
               string tempSObjectName =  rt.sObjectType;
                if (rt.sObjectType.contains('SchoolForce')){
                	tempSObjectName = rt.sObjectType.replace('','');
                }
                if (rtMapCopy.get(tempSObjectName)==null){
                    Map <String, Id> initMap =new Map<String, Id>();
                    initMap.put(rt.DeveloperName, rt.Id);
                    rtMapCopy.put(tempSObjectName, initMap);
                }
                else {
                    rtMapCopy.get(tempSObjectName).put(rt.DeveloperName, rt.Id);
                }                   
            }
        }
        System.debug('rtMapCopy = ' + rtmapCopy);
        return rtMapCopy.get(sObjectName);
    }
	
	public class schoolWrapper {
		public Account school;
		public staffWrapper sysAdmin;
		public staffWrapper cmDirect;
		public staffWrapper schoolAdmin;
		public staffWrapper siteAdmin;
		public staffWrapper networkAdmin;
		public List<Student__c> students;
		
		public schoolWrapper(Account a) {
			school = a;
		}
	}
	public class staffWrapper {
		public User userRecord;
		public Contact contactRecord;
		public Staff__c staffRecord;
			
		public staffWrapper(User u, Contact c, Staff__c s) {
			userRecord = u;
			contactRecord = c;
			staffRecord = s;
		}
			
	}
}