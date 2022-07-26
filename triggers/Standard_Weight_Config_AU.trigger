trigger Standard_Weight_Config_AU on Standard_Weight_Config__c (after update) {
	if (!core_triggerUtils.bTriggersDisabled()){
	  try{
	  Gradebook_ManageStandardWeights.isafterupdate(Trigger.NewMap, Trigger.OldMap); 
	  }
	  catch(Exception e){
		string links = '';
		for(Standard_Weight_Config__c s: trigger.new){
			if(s.id != null){
				if(links==''){
					links = s.name + ',' + s.id;
				}
				else{
					links = links + ';' + s.name + ',' + s.id;
				}
			}
		}
		Global_Error__c ge = Error_Handling.handleError(links, 'Gradebook', 'Standard Weight cascade update failure', e);
		insert ge;
	    }
	}
}