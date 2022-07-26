public with sharing class Points_SoqlUtils { 
	public static List<Picklist_Value__c> getCats(){
		Id pointsCats = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Points_Category');
		return [select id, Grade__c, Setup__c, Setup__r.School__c, Name, Default_Points__c from Picklist_Value__c where RecordTypeId =: pointsCats and (Setup__r.Active__c = true OR Setup__c = null) order by Name DESC];
	}
	public static List<Picklist_Value__c> getCatsBySchool(Id setup,String grade){
		List<Picklist_Value__c> categories = new List<Picklist_Value__c>();
		Id pointsCats = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Points_Category');
			for(Picklist_Value__c c: [select id, Grade__c, Setup__c, Setup__r.School__c, Name, Default_Points__c from Picklist_Value__c where RecordTypeId =: pointsCats and Setup__c=:setup order by Name DESC]){
				 if(c.Grade__c == null)
				 	categories.add(c);
				 else{
				 	Set<String> grades = new Set<String>();
				 	grades.addall(c.Grade__c.split(';'));
				 	if(grades.contains(grade))
				 		categories.add(c);
				 }	
			}
	 	System.debug('categories$$$$$'+categories);
		return categories;
	}
	
	public static List<Points__c> getPointsBySection(Id sectionID, Date selectedDate){
		List<Points__c> points = [select id, Student_Section__c, Student__c, Comments__c, Staff__c
									,Is_Redeem__c, Category__c, Points__c, Student__r.Name, Points_Date__c, Reference_Id__c, Student__r.School__c 
									FROM Points__c 
									WHERE is_Redeem__c = false
									AND Student_Section__r.Section__c =: sectionID
									AND Points_date__c =: selectedDate];
		return points;
	}
	
	public static List<Student_Section__c> getPointsByStudentSection(ID sectionID, Date selectedDate){
		List<Student_Section__c> ssList = [select Student__c, Student__r.Name, Student__r.School__c,
										(SELECT id,Points__c.Student__c, Comments__c, Staff__c, Is_Redeem__c, Category__c,Category__r.Name, Points__c, Points_Date__c, Reference_Id__c, Student__r.School__c
											FROM Points_Transactions__r
											WHERE is_Redeem__c = false
											AND Student_Section__r.Section__c =: sectionID
											AND Points_date__c =: selectedDate
											order by Category__r.Name ASC)
									from Student_Section__c
									where Section__c =: sectionID
									AND Active__c = true
									AND Student__r.Active__c = true
									order by Student__r.Student_Last_Name__c];
		return ssList;
	}
	
	public static List<Points__c> getRedeemPointsBySection(ID sectionID, Date selectedDate){
		List<Points__c> points = [select id, Student_Section__c, Student__c, Comments__c, Staff__c
									,Is_Redeem__c, Category__c, Points__c, Student__r.Name, Student__r.School__c, Reference_Id__c 
									FROM Points__c 
									WHERE is_Redeem__c = true
									AND Student_Section__r.Section__c =: sectionID
									AND Points_date__c =: selectedDate];
		return points;
	}
	
	public static List<Student_Section__c> getRedeemByStudentSection(ID sectionID, Date selectedDate){
		List<Student_Section__c> ssList = [select Student__c, Student__r.Name, Student__r.School__c,
										(SELECT id,Points__c.Student__c,Points__c.Student__r.Name, Comments__c, Staff__c, Is_Redeem__c, Category__c,Category__r.Name, Points__c, Points_Date__c, Reference_Id__c 
											FROM Points_Transactions__r
											WHERE is_Redeem__c = true
											AND Student_Section__r.Section__c =: sectionID
											AND Points_date__c =: selectedDate
											order by Category__r.Name DESC)
									from Student_Section__c
									where Section__c =: sectionID
									AND Active__c = true
									order by Student__r.Student_Last_Name__c];
		return ssList;
	}
	
	public static List<Points__c> getPointsByStudent(ID studentId){
		List<Points__c> points = [select id, Student_Section__c, Student__c, Comments__c, Staff__c
									,Is_Redeem__c, Category__c, Points__c, Student__r.Name, Staff__r.Name
									FROM Points__c 
									WHERE Student__c =: studentId];
		return points;
	}
	
	public static List<Points__c> getStudentLedgerPoints(String studId,Date fromDate,Date toDate){
		List<Points__c> points = [select id, Student_Section__c, Student__c, Comments__c, Staff__c,Staff__r.Name
									,Is_Redeem__c, Category__c, Category__r.Name,Student_Section__r.Section__r.Name,Points__c, Student__r.Name,Points_Date__c 
									FROM Points__c 
									WHERE Student__c =: studId
									AND Points_Date__c > = : fromDate
									AND Points_Date__c < = : toDate
									order by Points_Date__c desc LIMIT 1001];
		return points;
	
	}
	
	public static List<Points__c> getStudentLedgerPoints(String studId, Date fromDate,Date toDate, Integer recordLimit){
		List<Points__c> points = [select id, Student_Section__c, Student__c, Comments__c, Staff__c,Staff__r.Name
									,Is_Redeem__c, Category__c, Category__r.Name,Student_Section__r.Section__r.Name,Points__c, Student__r.Name,Points_Date__c 
									FROM Points__c 
									WHERE Student__c =: studId
									AND Points_Date__c > = : fromDate
									AND Points_Date__c < = : toDate
									order by Points_Date__c desc LIMIT: recordLimit];
		return points;
	
	}
	
	public static Decimal getCurrentBalance(Date startDate,Date endDate,String stuId,Set<String> sections){
		Decimal availableBalance;
		Map<String,Decimal> studentBalanceMap = new Map<String,Decimal>();
		for(AggregateResult ag: [SELECT Student__c s, SUM(Points__c) sm
					                FROM Points__c 
					               	WHERE Student__c =: stuId
									AND Points_Date__c > = : startDate
									AND Points_Date__c < = : endDate
					                GROUP BY Student__c]){
			studentBalanceMap.put((String)ag.get('s'),(Decimal)ag.get('sm'));		                
		}
		System.debug('----------------studentBalanceMap----'+studentBalanceMap);
		System.debug('----------------stuId----'+stuId);	
		//if(studentBalanceMap != null)
			availableBalance = studentBalanceMap.get(stuId);
		System.debug('----------------availableBalance----'+availableBalance);	
		return availableBalance;		
	}
	
	public static Map<String,Decimal> getCurrentBalance(Date startDate,Date endDate,Set<String> studIds){
		
		Map<String,Decimal> studentBalanceMap = new Map<String,Decimal>();
		for(AggregateResult ag: [SELECT Student__c s, SUM(Points__c) sm
					                FROM Points__c 
					               	WHERE Student__c in: studIds
					               	AND Points_Date__c > = : startDate
									AND Points_Date__c < = : endDate
					                GROUP BY Student__c]){
			studentBalanceMap.put((String)ag.get('s'),(Decimal)ag.get('sm'));		                
		}
		
		return studentBalanceMap;		
	}
	public static String getPointsAdminProfile(){
		
		Points_Settings_v2__c ps = Points_Settings_v2__c.getOrgDefaults();
		if(ps.Admin_Profile__c!=null){
			String[] profileNames = ps.Admin_Profile__c.split(',');
			Profile p = [select Id,Name FROM Profile WHERE Name in: profileNames];
			return p.Id;
		}
		else{
			return '';
		}
	
	}
	
	public static List<SelectOption> getSectionOptions(Set<String> secIds, String stuId){
		List<SelectOption> sectionOptions = new List<SelectOption>();
		sectionOptions.add(new SelectOption('--None--','--None--'));
		for(Student_Section__c s: [SELECT Id, Section__c,Student__c,Section__r.Name FROM Student_Section__c WHERE Section__c in: secIds AND Student__c = : stuId order by Section__r.Name]){
			sectionOptions.add(new SelectOption(s.Id,s.Section__r.Name));
		}
		
		return sectionOptions;
	
	}
	
	public static List<Student__c> getPointsByStudentGroup(String selectedSchool, String selectedGrade, Date selectedDate){
		string[] properDate = selectedDate.format().split('/',3);
		if(properDate[0].length()==1) properDate[0] = '0'+properDate[0];
		if(properDate[1].length()==1) properDate[1] = '0'+properDate[1];
		string query = 'select ID, Name, School__c,'+
					'(SELECT id,Student__c, Comments__c, Staff__c, Is_Redeem__c, Category__c,Category__r.Name, Points__c, Points_Date__c,Reference_Id__c  '+
					'FROM Points_Transactions__r '+
					'WHERE Is_Redeem__c = false '+
					'AND Student_Section__c = null '+
					'AND Points_date__c = '+properDate[2]+'-'+properDate[0]+'-'+properDate[1]+
					' order by Category__r.Name ASC) '+
				'from Student__c WHERE Active__c = true';
		query += (selectedGrade != '--None--')?' AND Grade__c=\'' + String.escapeSingleQuotes(selectedGrade) + '\' ':'';
		query += (selectedSchool != '--None--')?' AND School__c = \'' + String.escapeSingleQuotes(selectedSchool) + '\'':'';
		
		query += ' order by Student_Last_Name__c';
		List<Student__c> students = database.query(query);
		
		return students;
	}
	
	public static List<Student__c> getRedeemByStudentGroup(String selectedSchool, String selectedGrade, Date selectedDate){
		string[] properDate = selectedDate.format().split('/',3);
		if(properDate[0].length()==1) properDate[0] = '0'+properDate[0];
		if(properDate[1].length()==1) properDate[1] = '0'+properDate[1];
		string query = 'select ID, Name, School__c,'+
					'(SELECT id, Student__c, Comments__c, Staff__c, Is_Redeem__c, Category__c,Category__r.Name, Points__c, Points_Date__c,Reference_Id__c  '+
					'FROM Points_Transactions__r '+
					'WHERE is_Redeem__c = true '+
					'AND Student_Section__c = null '+
					'AND Points_date__c = '+properDate[2]+'-'+properDate[0]+'-'+properDate[1]+')'+
				' from Student__c WHERE Active__c = true';
		query += (selectedGrade!='--None--')?' AND Grade__c=\'' + String.escapeSingleQuotes(selectedGrade) + '\' ':'';
		query += (selectedSchool != '--None--')?' AND School__c = \'' + String.escapeSingleQuotes(selectedSchool) + '\'':'';
		query += ' order by Student_Last_Name__c';
		List<Student__c> students = database.query(query);
		
		return students;
	}
}