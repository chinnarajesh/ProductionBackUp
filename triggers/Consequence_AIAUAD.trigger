trigger Consequence_AIAUAD on Consequence__c (after delete, after insert, after update) {
if (!core_triggerUtils.bTriggersDisabled()){	
	
		try{
			Set<Id> SbIds = new Set<Id>();
			List<Consequence__c> studentsforupdate = new List<Consequence__c> ();
			List<Student_Behavior__c> sbtoupdate = new List<Student_Behavior__c>();   
			if (Trigger.isDelete){
				for (Consequence__c c: Trigger.old) {
					studentsforupdate.add(c);
					SbIds.add(c.Student__c);
				}
			} else if (trigger.isAfter) {
				for (Consequence__c c: Trigger.new) {
					studentsforupdate.add(c);
					SbIds.add(c.Student__c);
				}
			}
		  
			if (sbIds.size()>0){
				Map<Id, Double> timeLostMap = new Map<Id, Double>();
				Map<Id, Double> weightMap = new Map<Id, Double>();
		            
				for(Consequence__c c: studentsforupdate){
					if(c.Time_Lost__c == null){
						c.addError('Time lost for consequences cannot be blank.');
					} else {
						if(timeLostMap.containsKey(c.Student__c)){
							if(c.Days_Suspended__c != null){
		                    	timeLostMap.put(c.Student__c, c.Time_Lost__c*c.Days_Suspended__c + timeLostMap.get(c.Student__c));
							} else {
								timeLostMap.put(c.Student__c, c.Time_Lost__c + timeLostMap.get(c.Student__c));
							}
						} else {
							if(c.Days_Suspended__c != null){
		                   		timeLostMap.put(c.Student__c, c.Time_Lost__c*c.Days_Suspended__c);
							} else {
								timeLostMap.put(c.Student__c, c.Time_Lost__c);
							}
						}
						
						if(weightMap.containsKey(c.Student__c) && c.Final_Consequence__c){
							weightMap.put(c.Student__c, c.Consequence_Weighting__c + weightMap.get(c.Student__c)); //cannot do direct assignemnt for whatever reason
						} else if(c.Final_Consequence__c){
							weightMap.put(c.Student__c, c.Consequence_Weighting__c);
		                }
					}
				}
				List<Student_Behavior__c> sbList = behavior_SoqlUtils.getStudentBehaviorToWeight(SbIds);
				for (Student_Behavior__c sb: sbList){
					if(timeLostMap.containsKey(sb.id))
						sb.Consequence_Time_Lost__c = timeLostMap.get(sb.id);
					if(weightMap.containsKey(sb.id))
						sb.Final_Consequence_Weighting__c = weightMap.get(sb.id);
		                
					sbtoupdate.add(sb);
				}
		        
				if (!sbtoupdate.isEmpty()){
					try {
						update sbtoupdate; 
					} catch (Exception e) {
						Global_Error__c ge = Error_Handling.handleError('', 'Behavior', 'Consequence Trigger: Failed to roll consequence information to student behavior.', e);
						insert ge;
					}
				}
			}
		} catch (Exception e) {
			Global_Error__c ge = Error_Handling.handleError('', 'Behavior', 'Consequence Trigger: Non-dml failure.', e);
			insert ge;
		}
	}
}