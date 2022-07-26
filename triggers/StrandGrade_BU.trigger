trigger StrandGrade_BU on Strand_Grade__c (before update) {
	if (!core_triggerUtils.bTriggersDisabled()){
	   if(!core_triggerUtils.b){
	        integer i=0;
	        try{
		        for(Strand_Grade__c sg:trigger.new){
		            if(trigger.old[i].Grade_Override__c!=trigger.new[i].Grade_Override__c){
		                    sg.Grade_Overridden__c = true;
		            }
		            i++;
		        }
	        }
	        catch(Exception e){
		    	string links = '';
				for(Strand_Grade__c s: trigger.new){
					if(s.id != null){
						if(links==''){
							links = s.name + ',' + s.id;
						}
						else{
							links = links + ';' + s.name + ',' + s.id;
						}
					}
				}
				Global_Error__c ge = Error_Handling.handleError(links, 'Gradebook', 'Strand grade override failure', e);
				insert ge;
	    	}
	    }
	}
}