trigger StudentBehavior_BIAIBUAUAD on Student_Behavior__c (before delete, after insert, before insert, before update) { 
	if (!core_triggerUtils.bTriggersDisabled()){
		Map<ID, Behavior_Incident__c> bimap = new Map<ID,Behavior_Incident__c>();
	    Map<ID, Student__c> studentMap = new Map<ID, Student__c>();
	    Set<ID> biSet = new Set<ID>();
	    Set<ID> sbSet = new Set<ID>();
	    Set<ID> studentSet = new Set<ID>();
	    
	    try{
		    if(trigger.isDelete){
		        for(Student_Behavior__c sb : trigger.old){
		            biSet.add(sb.Behavior_Incident__c);
		            sbSet.add(sb.id);
		        }
		    } else {
		        for(Student_Behavior__c sb : trigger.new){
		            biSet.add(sb.Behavior_Incident__c);
		            studentSet.add(sb.Student__c);
		        }
	    	}
	    
		    if(trigger.isDelete){
		        //delete any consequences
		        List<Consequence__c> cons = Behavior_SoqlUtils.getAllConsequences(sbSet);
		        if(!cons.isEmpty()){
		            delete cons;
		        }
		            
		        biMap = new Map<id, Behavior_Incident__c>(Behavior_SoqlUtils.getBehIncById(biSet));
		        List<Student_Behavior__c> sbList = new List<Student_Behavior__c>([select id, Student__r.Name, Behavior_Incident__c from Student_Behavior__c where Behavior_Incident__c IN :biSet]);
		        
		        for(Behavior_Incident__c bi: biMap.values()){
		            bi.Student_Involved_Full_Name__c = '';
		            biMap.put(bi.id, bi);
		        }
		        
		        if(!sbList.isEmpty()){
		            for(Student_Behavior__c sb: sbList){
		                string names = biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c + sb.Student__r.Name + ';';
		                if(names.length()<255)
		                    biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c = names;
		                else
		                    biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c = names.substring(254);
		            }
		            
		            update biMap.values();
		        }
		    }
	    
	    if(Trigger.isAfter && Trigger.isInsert){
	        biMap = new Map<id, Behavior_Incident__c>(Behavior_SoqlUtils.getBehIncById(biSet));
	        studentMap = new Map<id, Student__c>([select id, Name from Student__c where id IN :studentSet]);
	        
	        for(Student_Behavior__c sb: Trigger.new){
	            string names = '';
	            if(biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c == null)
	                biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c = '';
	            else {  
	                names = biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c + '; ';
	            }
	             
	            names += studentMap.get(sb.Student__c).Name;
	            if(names.length()<255)
	                biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c = names;
	            else
	                biMap.get(sb.Behavior_Incident__c).Student_Involved_Full_Name__c = names.substring(254);
	        }
	        update biMap.values();
	    }
	    
	    if(trigger.isBefore && !trigger.isDelete){
	        biMap = new Map<id, Behavior_Incident__c>(Behavior_SoqlUtils.getBehIncById(biSet));
	
	        for(Student_Behavior__c sb : trigger.new){
	            if (bimap.get(sb.Behavior_Incident__c) != null && sb.Incident_Role__c == 'Instigator'){
	                sb.Behavior_Weighting__c = bimap.get(sb.Behavior_Incident__c).Incident_Weighting__c;
	            } else {
	                sb.Behavior_Weighting__c = 0;
	            }
	        }
	    }
	    }
	    catch(Exception e){
	        string links = '';
	        for(Student_Behavior__c s: trigger.new){
	            if(s.id != null){
	                if(links==''){
	                    links = s.name + ',' + s.id;
	                }
	                else{
	                    links = links + ';' + s.name + ',' + s.id;
	                }
	            }
	        }
	        Global_Error__c ge = Error_Handling.handleError(links, 'Behavior', 'Student Behavior trigger failure', e);
	        insert ge;
	    }
	}
}