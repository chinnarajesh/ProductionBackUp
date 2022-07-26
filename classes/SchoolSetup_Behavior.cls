public with sharing class SchoolSetup_Behavior {	
	public core_SetupWrapper cSetup					{get;set;}
	public List<Picklist_Value__c> behaviorTypes	{get;set;}
	public List<Picklist_Value__c> consequences		{get;set;}
	public String selectedValue						{get;set;}
	public Picklist_Value__c editHolder				{get;set;}
	public boolean isEdit							{get;set;}
	public boolean isManaged						{get;set;}
	public EOY_Progress__c stateTracker				{get;set;}
	public List<SelectOption> behaviorCats			{get;set;}

	/* INTERNAL VARS */
	private Set<ID> behaviorIDs = new Set<ID>();
	private Set<ID> consequenceIDs = new Set<ID>();
	private ID behaviorTypeRTID;
	private ID consequenceRTID;
	private ID setupID;

	public SchoolSetup_Behavior() {
		behaviorTypeRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Behavior_Type');
		consequenceRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Behavior_Consequence');

		setupID = ApexPages.currentPage().getParameters().get('setupId');
		if(setupID != null){
			cSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),null);
			loadValues();
			isEdit = false;
			isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
			stateTracker = SetupWizard_Utils.getEOYProgressRecord(cSetup.setup);
		} else {
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
	}

	/*
		Checks the valididity of the behavior setup and marks the behavior setup as finalized.
	*/
	public void finalize(){
		if(behaviorTypes.isEmpty()){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You must have one behavior type in order to finalize your behavior setup.');
		}
		if(consequences.isEmpty()){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You must have one consequence in order to finalize your behavior setup.');
		}

		if(ApexPages.hasMessages(apexpages.severity.ERROR)){
			return;
		} else {
			stateTracker.Behavior_Wizard_Started__c = true;
			stateTracker.Behavior_Wizard_Completed__c = true;
			upsert stateTracker;
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Your behavior setup has been finalized. You may return here to make changes as needed.');
		}
	}

	/*
		Deletes the picklist value selected on the page.
	*/
	public void deleteValue(){
		Picklist_Value__c toDelete = getValue(true);

		if(toDelete != null){
			try{
				List<Behavior_Incident__c> incidents;
				List<Consequence__c> cons;
				if(toDelete.RecordTypeID == behaviorTypeRTID){
					incidents = [select id from Behavior_Incident__c where Selected_Behavior_Incident_Type__c=:toDelete.id limit 1];
				} else {
					cons = [select id from Consequence__c where Picklist_Value__c =: toDelete.id limit 1];
				}
				if((toDelete.RecordTypeID == behaviorTypeRTID && incidents.isEmpty()) || (toDelete.RecordTypeID != behaviorTypeRTID && cons.isEmpty())){
					delete toDelete;
				} else {
					SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are behavior records filed against this value. Please update these records before deleting.');
					addValue(toDelete);
				}
			} catch (System.DMLException e){
				addValue(toDelete);
			}
		} 
	}

	/*
		Loads the picklist value selected on the page into editHolder.
	*/
	public void editValue(){
		editHolder = getValue(false);

		if(editHolder != null){
			selectedValue = (editHolder.RecordTypeID == behaviorTypeRTID)?'behavior':'consequences';
			editHolder.Type__c = (editHolder.RecordTypeID == behaviorTypeRTID)?'Behavior Type':'Behavior Consequence';
			isEdit = true;
		}
	}

	/*
		Sets editHolder to a new picklist value for population by the user.
	*/
	public void newValue(){
		editHolder = new Picklist_Value__c(Setup__c = setupID);
		editHolder.RecordTypeID = (selectedValue == 'behavior')?behaviorTypeRTID:consequenceRTID;
		editHolder.Type__c = (editHolder.RecordTypeID == behaviorTypeRTID)?'Behavior Type':'Behavior Consequence';
		isEdit = true;
	}
	
	/*
		Saves both new values and edited values
	*/
	public void saveValue(){
		isEdit = false;
		boolean isNew = editHolder.id == null;
		upsert editHolder;
		if(isNew)
			addValue(editHolder);

		stateTracker.Behavior_Wizard_Started__c = true;
		upsert stateTracker;
		editHolder = null;
	}
	
	/*
		Cancels a edit/new. Basically used to turn off the modal.
	*/
	public void cancelEdit(){
		isEdit = false;
	}

	/*
		Saves the setup options changed by the user.
	*/
	public void saveOptions(){
		try{
			update cSetup.setup;
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Changes saved successfully.');
		} catch(System.DMLException e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occured while trying to save your changes.');
		}
	}
	
	/*
		Moves the user to the School setup home page
	*/
	public PageReference prev(){
		PageReference p = Page.SchoolSetup_Home;
		p.getParameters().put('setupId',setupID);
		return p;
	}

	/*
		Loads all existing picklist values for this setup for display. It also initializes the csvLoader.
	*/
	private void loadValues(){
		behaviorTypes = Behavior_SoqlUtils.getPlValuesListByRecordType(behaviorTypeRTID,setupID);
		consequences = Behavior_SoqlUtils.getPlValuesListByRecordType(consequenceRTID,setupID);

		behaviorCats = new List<SelectOption>();
		Schema.DescribeFieldResult fieldResult = Picklist_Value__c.Behavior_Category__c.getDescribe();
        
		for( Schema.PicklistEntry f : fieldResult.getPicklistValues()){
			behaviorCats.add(new SelectOption(f.getLabel(), f.getValue()));
		}


		behaviorIds.addAll(new Map<ID, Picklist_Value__c>(behaviorTypes).keySet());
		consequenceIDs.addAll(new Map<ID, Picklist_Value__c>(consequences).keySet());
	}

	/*
		Searches through the lists of picklist values to find the value the user was interested in. Pulls the record id from selectedValue

		@param remove Should the value be removed from the list or not?
	*/
	private Picklist_Value__c getValue(boolean remove){
		if(behaviorIDs.contains(selectedValue)){
			for(Integer i=0;i<behaviorTypes.size();i++){
				if(behaviorTypes[i].id == selectedValue){
					if(remove) behaviorIDs.remove(selectedValue);
					return (remove)?behaviorTypes.remove(i):behaviorTypes[i];
				}
			}
		} else {
			for(Integer i=0;i<consequences.size();i++){
				if(consequences[i].id == selectedValue){
					if(remove) consequenceIDs.remove(selectedValue);
					return (remove)?consequences.remove(i):consequences[i];
				}
			}
		}
		return null;
	}

	/*
		Adds a new picklist value into the correct list for it's type.

		@param pv The picklist value to be added.
	*/
	private void addValue(Picklist_Value__c pv){
		if(pv.RecordTypeID == behaviorTypeRTID){
			behaviorTypes.add(pv);
			behaviorIDs.add(pv.id);
		} else {
			consequences.add(pv);
			consequenceIDs.add(pv.id);
		}
	}
}