global class Attendance_PGNotification implements Database.Batchable<sObject>,Database.Stateful{
	public String query;
	public String email;
	global Set<Id> uattendance = new Set<Id>();
	global Map<String, Map<String, String>> mNotificationText;

	global Attendance_PGNotification (String alerttype) {
		mNotificationText = core_SoqlUtils.getnotifymap(alerttype);
	}


	global database.querylocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		Set<ID> studs = new Set<ID>();
		for(sObject s : scope){
			Attendance__c uas = (Attendance__c) s;
			studs.add(uas.Student__c);
		}
		String pgQuery = core_SoqlUtils.getMainPGQuery()+' WHERE Student__c IN :studs';
		List<Student_PG__c> pgList = Database.query(pgQuery);
		Map<ID, List<Student_PG__c>> studIdToPG = new Map<ID, List<Student_PG__c>>();
		for(Student_PG__c pg: pgList){
			if(studIdToPG.containsKey(pg.Student__c)) studIdToPG.get(pg.Student__c).add(pg);
			else studIdToPG.put(pg.Student__c, new List<Student_PG__c>{pg});
		}

		for(sObject s : scope) {
    		Attendance__c uas = (Attendance__c ) s;
			//Query for Parents of Student who was absent. 
			if(studIdToPG.containsKey(uas.Student__c)){
   				for (Student_PG__c pgc: studIdToPG.get(uas.Student__c)) {
	        		if ((pgc.Parent_Guardian_c__r.Notify_via_Email__c == true && pgc.Parent_Guardian_c__r.Email != null) 
        				||
        				(pgc.Parent_Guardian_c__r.Notify_via_SMS__c == true && pgc.Parent_Guardian_c__r.Email_to_SMS_Address__c != null)) 
        				//only execute if parent requested notification
                	{
                		NotificationUtils.sendnotification sn;
	               		if (mNotificationText.containsKey(pgc.Parent_Guardian_c__r.Preferred_Language__c + pgc.Student__r.School__c))
                			sn = new NotificationUtils.sendnotification(pgc, mNotificationText.get(pgc.Parent_Guardian_c__r.Preferred_Language__c + pgc.Student__r.School__c));
                		else {sn = new NotificationUtils.sendnotification(pgc, mNotificationText.get('English' + pgc.Student__r.School__c));}
                		//And only set first alert true if they are notified by this process
                		uattendance.add(uas.Id);
                	}
        		}
			}
		}
	}// end execute   

	global void finish(Database.BatchableContext BC){
		List<Attendance__c> uupdateattendance = new List<Attendance__c> ();
		for (Id a : uattendance) {
			uupdateattendance.add(New Attendance__c (Id = a, Date_Time_of_Parental_Notification__c = system.now() ));
		}
		System.debug('\n\n uupdateattendance => ' + uupdateattendance + '\n');
		try {Database.update(uupdateattendance, false); }
		catch (Exception Ex) {
			System.debug(ex.getMessage());
		}
	} // end finish

}