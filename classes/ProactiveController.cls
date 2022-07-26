global with sharing class ProactiveController implements Schedulable {
	
	public Date startDate {get;set;}
	public Date endDate {get;set;}
	public String qryStr {get;set;}
	public String delAttStr {get;set;}
	public String delDemoStr {get;set;}
	public Boolean demographics {get;set;}
	public Boolean attendance {get;set;}
	public Proactive_Demographics__c pDemo {get;set;}
	public Proactive_Attendance__c pAtt {get;set;}
	public List<Setup__c> setupList {get;set;}
	public List<Account> schoolList {get;set;}
	public String schoolId {get;set;}
	public String userStr {get;set;}
	public Integer countDemoRec {get;set;}
	public Integer countAttRec {get;set;}
	
	public ProactiveController(){
		pDemo = new Proactive_Demographics__c();
		pAtt = new Proactive_Attendance__c();
		countDemoRec = 0;
		countAttRec = 0;
		for(List<Proactive_Demographics__c> d : [SELECT Id FROM Proactive_Demographics__c LIMIT 24999]){
			countDemoRec = countDemoRec + d.size();
		}
		
		for(List<Proactive_Attendance__c> a : [SELECT Id FROM Proactive_Attendance__c LIMIT 24999]){
			countAttRec = countAttRec + a.size();
		}
	}
	
	public List<SelectOption> getItems(){
		setupList = [SELECT Id, School__c, Active__c, Name FROM Setup__c WHERE Active__c = true];
		system.debug(setupList);
		Set<String> schoolSet = new Set<String>();
		for(Setup__c setup : setupList){
			schoolSet.add(setup.School__c);
		}
		schoolList = [SELECT Id, Name, School_Full_Name__c FROM Account WHERE Id IN: schoolSet and RecordType.Name='School'];
		system.debug(schoolList);
		List<SelectOption> options = new List<SelectOption>();
		for(Account sl: schoolList){
			options.add(new SelectOption(sl.Id, sl.Name));
		}
		return options;
	}
	
	public PageReference buttonClick(){
		if(pDemo.Entry_Date__c != null && pDemo.Exit_Date__c != null && (demographics || attendance)){
			startDate = pDemo.Entry_Date__c;
			endDate = pDemo.Exit_Date__c;
			userStr = userinfo.getUserId();
			
			if(attendance || demographics){
				qryStr = 'SELECT  Daily__c, Id, Student__r.Student_Last_Name__c, Student__r.Student_First_Name__c, Student__c, Session_Date__c, Attendance_Status_Read_Only__c, Student__r.Legacy_ID__c, Student__r.Student__c, Student__r.Address__c, Student__r.City__c, Student__r.State__c, Student__r.Zip_Code__c, Student__r.Gender__c, Student__r.Ethnicity__c, Student__r.Race__c, Student__r.Date_of_Birth__c, Student__r.Grade__c, Student__r.Entry_Date__c,  Student__r.Title_1_Status__c, Student__r.Special_Ed__c, Student__r.Special_Education_Hours__c, Student__r.Special_Education_Level__c, Student__r.SPED_School__r.Setup__r.School__r.Name, Student__r.ELL__c, Student__r.Immigrant__c, Student__r.School_Year__r.Name__c, Student__r.Entry_Type__c, Student__r.Exit_Date__c, Student__r.Exit_Reason__c, Student__r.DC_Resident__c, Student__r.Original_Graduation_Year__c, Student__r.Staff__c, Student__r.Homeroom__c, Student__r.School__r.Name, Picklist_Value__r.is_Tardy__c, Picklist_Value__r.is_Suspension__c, Picklist_Value__r.is_Unexcused__c, Picklist_Value__r.is_Early_Departure__c, Picklist_Value__r.Category__c  FROM Attendance__c WHERE Session_Date__c >=: startDate AND Session_Date__c <=: endDate AND Student__r.School__c = :schoolId AND Student__r.Legacy_Id__c != null';
				delAttStr = 'SELECT Id FROM Proactive_Attendance__c';
				delDemoStr = 'SELECT Id FROM Proactive_Demographics__c';
			}
			
			try{
				
				ProactiveBatch proactiveBatch = new ProactiveBatch(userStr, qryStr, attendance, demographics, startDate, endDate, schoolId);
        		ID batchprocessid3 = Database.executeBatch(proactiveBatch,200);
        		
        		ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.Confirm,'Batch Process was successfully initialized, This may take several minutes.  You will receive an email with additional instructions upon completion.');
        		ApexPages.addMessage(myMsg1);
        		return null;
			}catch(Exception e){
				
			}
			
		}else{
			ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.Error,'Please check your submission for missing fields and submit again.');
        	ApexPages.addMessage(myMsg1);
		}
		
		return null;
	}
	
	public PageReference DeleteProactive(){
		List<Proactive_Attendance__c> pAttList = new List<Proactive_Attendance__c>();
		List<Proactive_Demographics__c> pDemoList = new List<Proactive_Demographics__c>();
		if(countAttRec > 4999 && countDemoRec > 4999){
			pAttList = [SELECT Id FROM Proactive_Attendance__c LIMIT 5000];
			pDemoList = [SELECT Id FROM Proactive_Demographics__c LIMIT 5000];
		}else if(countAttRec > countDemoRec && countDemoRec < 4999){
			Integer x = 10000;
			x = x - countDemoRec;
			pAttList = [SELECT Id FROM Proactive_Attendance__c LIMIT :x];
			if(countDemoRec > 0){
				pDemoList = [SELECT Id FROM Proactive_Demographics__c LIMIT :countDemoRec];
			}
		}else if(countDemoRec > countAttRec && countAttRec < 4999){
			Integer x = 10000;
			x = x - countAttRec;
			if(countAttRec > 0){
				pAttList = [SELECT Id FROM Proactive_Attendance__c LIMIT :countAttRec];
			}
			pDemoList = [SELECT Id FROM Proactive_Demographics__c LIMIT :x];
		}else if(countAttRec < 4999 && countDemoRec < 4999){
			pAttList = [SELECT Id FROM Proactive_Attendance__c ];
			pDemoList = [SELECT Id FROM Proactive_Demographics__c ];
		}
		if(pDemoList.size() > 0){
			CallDeleteDemo(pDemoList);
		}
		if(pAttList.size() > 0){
			CallDeleteAtt(pAttList);
		}
		
		PageReference ref = new PageReference('/apex/proActiveVF');
		ref.setRedirect(true);
		return ref;
	}
	
	public PageReference CallDeleteAtt(List<Proactive_Attendance__c> proA){
		
		Delete proA;
		countAttRec = [SELECT Count() FROM Proactive_Attendance__c LIMIT 24999];
		
		//PageReference ref = new PageReference('/apex/proActiveVF');
		//ref.setRedirect(true);
		return null;
		
	}
	
	public PageReference CallDeleteDemo(List<Proactive_Demographics__c> proD){
		
		Delete proD;
		countDemoRec = [SELECT Count() FROM Proactive_Demographics__c LIMIT 24999];
		
		//PageReference ref = new PageReference('/apex/proActiveVF');
		//ref.setRedirect(true);
		return null;
		
	}
	
	global void execute(SchedulableContext sc){
		String query1 = 'SELECT Id FROM Proactive_Attendance__c';
		String query2 = 'SELECT Id FROM Proactive_Demographics__c';
		
		ProactiveBatch proB1 = new ProactiveBatch(null,query1,null,null,null,null,null);
        ID batchprocessid1 = Database.executeBatch(proB1,500);
        
        ProactiveBatch proB2 = new ProactiveBatch(null,query2,null,null,null,null,null);
        ID batchprocessid2 = Database.executeBatch(proB2,500);
		
	}
	//Setup the scheduled jobs by entering "ProactiveController.setupSchedule();"
    //in the system log window 
	public static void setupSchedule() {
        //Will run every hour minutes  
        String scha = '0 ';
        String schb = ' 3/12 * * ?';
        Integer[] mins = new Integer[]{0};
        for(Integer min : mins){
            String sch = scha + min + schb;
            System.debug('sch==>' + sch);
            ProactiveController s = new ProactiveController();
            if(!Test.isRunningTest()){
                System.schedule('Proactive ' + min + ' minutes',sch,s);
            }  
        } 
    }

}