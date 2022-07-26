public class Homework_ManageHomework {
	public static void updatestats (Map<Id, HW_Tracker__c> newmap) {
		Set<Id> studentIDs = new Set<Id>();
		//we neede the ids of the stupdens we neede to push homework updates to
		for (HW_Tracker__c h: newmap.values()) {
			studentIDs.add(h.Student__c);
		}

		Map<Id, Student__c> studentMap = new Map<Id, Student__c> ();
		for(AggregateResult ar : Homework_SoqlUtils.getHWStatInfo(studentIDs)){
			Student__c std;
			Id sid = (Id)ar.get('s');
			if (studentMap.containskey(sid) ) {
				std = studentMap.get(sid); 
			} else {
				std = new Student__c (Id = sid
									  ,of_Completed_Homework__c = 0 
									  ,of_Late_Homework__c = 0
									  ,of_Missing_Homework__c = 0
									  ,of_Assigned_Homework__c = 0);
			}
			
			String pvc = (String)ar.get('pv'); 
			if (pvc.equals('Complete')){
				std.of_Completed_Homework__c = (Decimal)ar.get('scount');
				std.of_Assigned_Homework__c += (Decimal)ar.get('scount');
			} else if (pvc.equals('Incomplete')){
				std.of_Missing_Homework__c = (Decimal)ar.get('scount');
				std.of_Assigned_Homework__c += (Decimal)ar.get('scount');
			} else if (pvc.equals('Late')){
				std.of_Late_Homework__c = (Decimal)ar.get('scount');
				std.of_Assigned_Homework__c += (Decimal)ar.get('scount');
			} else if (!pvc.equals('Exempt') || !pvc.equals('sf_absent') ) {
				std.of_Assigned_Homework__c += (Decimal)ar.get('scount');
			}
			studentMap.put(sid, std);
		}
		
		update studentMap.values();
	}
}