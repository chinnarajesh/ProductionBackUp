public with sharing class SchoolSetup_Gradebook {
	public core_SetupWrapper cSetup		{get;set;}
	public EOY_Progress__c stateTracker	{get;set;}
	public String schoolType			{get;set;}
	public String selectedRecord		{get;set;}
	public boolean isManaged			{get;set;}
	public boolean lockKeyFields		{get;set;}

	/* Standards Upload */
	public blob fileBlob			{get;set;}
	public String fileContentType	{get;set;}
	public String fileName			{get;set;}
	public String fileSize			{get;set;}

	public List<Standard__c> standards	{get;set;}
	public String selectedStandard		{get;set;}
	public Standard__c standardToEdit	{get;set;}

	/* Grade Scale Catalog Config */
	public List<Grade_Scale_Catalog__c> availableCatalogs			{get;set;}
	public Map<ID, Grade_Scale_Catalog__c> grade_ScaleCatalogsMap	{get;set;}
	public boolean displayCatalogSelection							{get;set;}
	/* Catalog Config */
	public cCatalogWrapper selectedCatalogWrapper					{get;set;}
	public List<Grade_ScaleWrapper> wrappedGrade_Scales				{get;set;}
	public boolean displayCalcTypeButton							{get;set;}
	/* Scale config */
	public boolean bEditScale									{get;set;}
	public Picklist_Value__c selectedGrade_Scale				{get;set;}
	public Grade_Scale_Catalog__c selectedCatalog				{get;set;}
	private Map<String, normalizationWrapper> matchMap;
	private Map<String, ID> picklistValue;
	public List<Grade_Normalization__c> currentNormalizations	{get;set;}
	public List<normalizationWrapper> rangeNormalizations		{get;set;}
	public Integer normRowsAdded								{get;set;}
	public boolean rowsAddedFinal								{get;set;}
	public List<SelectOption> calculationTypeOptions			{get;set;}
	public Setup__c calculationTypeValues						{get;set;}

	/* ASSIGNMENT TYPES*/
	public List<Picklist_Value__c> assignmentTypes	{get;set;}
	public Picklist_Value__c assignmentTypeToEdit	{get;set;}
	public boolean showCSV							{get;set;}
	public core_LoadCsvData csvLoader				{get;set;}

	private ID assignmentTypeRTID;

	private ID setupID;

	public SchoolSetup_Gradebook() {
		setupID = ApexPages.currentPage().getParameters().get('setupId');
		if(setupID != null){
			cSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),null);
			schoolType = (!cSetup.setup.Standards_Based_Grading__c)?'Traditional':(cSetup.setup.Standards_ONLY_Gradebook__c)?'Standards Only':'Hybrid';
			stateTracker = SetupWizard_Utils.getEOYProgressRecord(cSetup.setup);

			loadStandards();
			returnAvailableCatalogs();
			isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
			if(cSetup.setup.Grade_Scale_Catalog__c != null){
				returnCatalogDetails(cSetup.setup.Grade_Scale_Catalog__c);
				displayCatalogSelection = false;
			} else {
				displayCatalogSelection = true;
			}
			calculationTypeOptions = getCalculationTypeOptions();
			calculationTypeValues = new Setup__c(
				Calculation_Type__c = csetup.setup.Calculation_Type__c,
				Law_of_Decaying_Average_Weight__c = csetup.setup.Law_of_Decaying_Average_Weight__c
			);
			loadAssignentTypes();

			lockKeyFields = false;
			if(!cSetup.setup.Active__c && cSetup.setup.Published__c && cSetup.setup.Data_Activated__c){
				lockKeyFields = true;
				Error_Handling.infoMessage('This setup is from a past year. You can no longer edit some fields on this screen because they affect grade calculations in the past year.');
			}
		} else {
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
	}

	/*
		Saves the setup options changed by the user.
	*/
	public void saveOptions(){
		try{
			if(!stateTracker.Gradebook_Type_Finalized__c){
				cSetup.setup.Standards_Based_Grading__c = schoolType != 'Traditional';
				cSetup.setup.Standards_ONLY_Gradebook__c = schoolType == 'Standards Only';
			}
			if(grade_ScaleCatalogsMap.containsKey(selectedRecord)){
				if(!cSetup.setup.Published__c){
					cSetup.setup.Grade_Scale_Catalog__c = selectedRecord;
					returnCatalogDetails(selectedRecord);
					displayCatalogSelection = false;
				}
				else SetupWizard_Utils.addMessage(apexpages.severity.INFO,'Your grade scale catalog selection has not been saved because this setup has already been published.');
			}
			if(calculationTypeValues.Calculation_Type__c != csetup.setup.Calculation_Type__c && calculationTypeValues.Calculation_Type__c != null){
				csetup.setup.Calculation_Type__c = calculationTypeValues.Calculation_Type__c;
			}
			if(calculationTypeValues.Law_of_Decaying_Average_Weight__c != csetup.setup.Law_of_Decaying_Average_Weight__c && calculationTypeValues.Law_of_Decaying_Average_Weight__c!=null){
				csetup.setup.Law_of_Decaying_Average_Weight__c = calculationTypeValues.Law_of_Decaying_Average_Weight__c;
			}
			update cSetup.setup;
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Changes saved successfully.');
		} catch(System.DMLException e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occured while trying to save your changes.');
		}
	}

	/* 
		Saves any setup changes, and locks the gradebook type options.
	*/
	public void finalizeGradebookType(){
		try{
			saveOptions();
			stateTracker.Gradebook_Type_Finalized__c = true;
			stateTracker.Gradebook_Wizard_Started__c = true;
			upsert stateTracker;
		} catch(System.DMLException e){
			stateTracker.Gradebook_Type_Finalized__c = false;
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occured while trying to finalize your gradebook type.');
		} 
	}

	/*
		Checks the validitiy of the gradebook setup, and the marks the gradebook setup as finalized.
	*/
	public void finalize(){
		if(!stateTracker.Gradebook_Type_Finalized__c){
			//what did they do moneky with the JS to get here before it was time?
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You have not selected your gradebook type. You must finalize this option before finalizing your gradebook setup.');
		}
		if(cSetup.setup.Passing_Grade_Threshold__c == null){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Passing Grade Threshold is a required field.');
		}
		if(cSetup.setup.On_Track_Threshold__c == null){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'On Track Threshold is a required field.');
		}
		if(cSetup.setup.Standard_Grade_Mastery_Threshold__c == null && cSetup.setup.Standards_Based_Grading__c){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Standard Grade Mastery Threshold is a required field.');
		}
		if(cSetup.setup.Strand_Grade_Mastery_Percentage__c == null && cSetup.setup.Standards_Based_Grading__c){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Strand Grade Mastery Percentage is a required field.');
		}
		if(cSetup.setup.Grade_Scale_Catalog__c == null){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You have not selected a grade scale catalog for your setup. You must select a grade scale catalog.');
		} else {
			selectedRecord = cSetup.setup.Grade_Scale_Catalog__c;
			viewCatalog();
			if(selectedCatalogWrapper.catalogElementList.isEmpty()){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The grade scale catalog you selected for this setup does not contain any grade scales. You must add at least one grade scale.');
			} else if(cSetup.setup.Standards_Based_Grading__c){
				boolean isValid = false;
				for(Grade_ScaleWrapper gsw:selectedCatalogWrapper.catalogElementList){
					isvalid = gsw.gscs.Picklist_Value__r.Category__c == 'Standards';
					if(isValid) break;
				}
				if(!isValid){
					SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The grade scale catalog you selected for this setup does not contain a standards based grade scale. You must add at least one standard grade scale.');
				}
			}
		}
		if(assignmentTypes.isEmpty()){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The selected setup does not have any assignment types assoicated with it, and there are no global assignment types. Please add at least one assignment type.');
		}

		if(ApexPages.hasMessages(apexpages.severity.ERROR)){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Your Gradebook module setup cannot be finalized at this time. Please correct any errors listed above and try again.');
			return;
		}

		stateTracker.Gradebook_Wizard_Started__c = true;
		stateTracker.Gradebook_Wizard_Completed__c = true;
		saveOptions();
		upsert stateTracker;
		
		SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Your gradebook setup has been finalized. You may return here to make changes as needed.');
	}

	/*
		Returns the user to the Setup Home Page
	*/
	public PageReference prev(){
		PageReference p = Page.SchoolSetup_Home;
		p.getParameters().put('setupId',setupID);
		return p;
	}

	/*
		Loads standards for display on the page
	*/
	public void loadStandards(){
		/*standards = 
			[select id, Name, Subject__c,Strand__r.Name, Strand__c, Parent_Standard__c, Long_Text__c, Description_Spanish__c,Grade_Level_Text__c,Identifier__c 
			from Standard__c 
			where School__c = null 
			or School__c=: cSetup.setup.School__c 
			order by Name];*/
	}

	/*public void editStandard(){
		for(Standard__c s:standards){
			if(s.ID == selectedStandard){
				standardToEdit = s;
			}
		}
	}

	public void newStandard(){
		standardToEdit = new Standard__c(School__c = cSetup.setup.School__c);
	}

	public void deleteStandard(){
		List<Standard_Grade__c> standardGrades = [select id from Standard_Grade__c where Standard__c=:selectedStandard OR Standard__r.Strand__c=:selectedStandard limit 1];
		if(standardGrades.isEmpty()){
			for(Integer i=0;i<standards.size();i++){
				if(standards[i].id == selectedStandard){
					try{
						delete standards[i];
						standards.remove(i);
					} catch(System.DMLException e){
						SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occured while trying to delete the selected standard.');
					}
				}
			}
		}
	}

	public void saveStandard(){
		try{
			boolean isNew = standardToEdit.id==null;
			upsert standardToEdit;
			if(isNew){
				standards.add(standardToEdit);
				standards.sort();
			}
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'The standard was saved successfully.');
		} catch(System.DMLException e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occured while trying to save the standard.');
		}
	}

	public void bulkLoadStandards(){
		if(fileBlob == null){
			SetupWizard_Utils.addMessage(apexpages.severity.error,'Please select a file to upload.');
			return;
		}
		String fileString = fileBlob.toString();
		fileBlob = null;

		CSVUtils.CSVParser parser = new CSVUtils.CSVParser(fileString, true);
		parser.parse();

		List<Standard__c> parentList = new List<Standard__c>();
		Set<String> identifierSet = new Set<String>();
		Map<String, List<Standard__c>> parentMap = new Map<String, List<Standard__c>>();

		for(List<String> line:parser.parsedData){
			if(identifierSet.contains(line[5])){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Identifiers must be unique.');
				return;
			} else {
				identifierSet.add(line[5]);
			}
			Standard__c standard = new Standard__c(
				Grade_Level_Text__c = line[0],
				Subject__c = line[1],
				Description_Spanish__c = line[2],
				Long_Text__c = line[3],
				Identifier__c = line[5],
				Name = line[5]
			);

			if(line[4] == ''){
				parentList.add(standard);
			} else {
				if(parentMap.containsKey(line[4])){
					parentMap.get(line[4]).add(standard);
				} else {
					parentMap.put(line[4], new List<Standard__c>{standard});
				}
			}
		}

		Boolean failed = checkForExistingIdentifiers(identifierSet);
		if(failed){
			
		}
	}

	private Boolean checkForExistingIdentifiers(Set<String> identifierSet){
		List<Standard__c> dupes = [select id from Standard__c where Identifier__c IN: identifierSet limit 1];

		if(!dupes.isEmpty()){
			for(Standard__c s: dupes){
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The identifier ');
			}
			return true;
		}

		return false;
	}*/

	/* Grade Scale Catalogs */
	/*
		Queries and builds a list of the avaiable grade scale catalogs
	*/
	public void returnAvailableCatalogs(){
		availableCatalogs = new List<Grade_Scale_Catalog__c>();
		grade_ScaleCatalogsMap = new Map<ID, Grade_Scale_Catalog__c>();
		for(Grade_Scale_Catalog__c cat:[SELECT Name, Description__c, LastModifiedDate, CreatedDate, Active__c
										FROM Grade_Scale_Catalog__c
										WHERE Name!=null]){
			grade_ScaleCatalogsMap.put(cat.id, cat);
			availableCatalogs.add(cat);
		}
	}

	/*
		Validates that the selected grade scale catalog was not in use anywhere and then deletes it.
	*/
	public void deleteGSCatalog(){
		try{
			Grade_Scale_Catalog__c toDelete = Grade_ScaleCatalogsMap.get(selectedRecord);
			List<Setup__c> setups = [select id From Setup__c where Grade_Scale_Catalog__c =: toDelete.id];
			if(setups.isEmpty()){
				delete toDelete;
				Grade_ScaleCatalogsMap.remove(selectedRecord);
				availableCatalogs = Grade_ScaleCatalogsMap.values();
			} else {
				SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The selected grade scale catalog is in use by one or more setups. It cannot be deleted at this time.');
			}
		} catch (DMLException e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occurred while attempting to delete the selected catalog.');
		}
	}

	/*
		Sets the page state up for creating a new grade scale catalog.
	*/
	public void newGSCatalog(){
		selectedCatalog = new Grade_Scale_Catalog__c();
	}

	/*
		Pulls the selected grade scale catalog from the catalog map and puts it into the selectedCatalog holder for editing.
	*/
	public void editGSCatalog(){
		selectedCatalog = grade_ScaleCatalogsMap.get(selectedRecord);
	}

	/*
		Saves the catalog currently being edited, and then updates the catalog map and list with it's updated value.
	*/
	public void saveCatalog(){
		try{
			upsert selectedCatalog;
			grade_ScaleCatalogsMap.put(selectedCatalog.id, selectedCatalog);
			availableCatalogs = grade_ScaleCatalogsMap.values();
		} catch(DMLException e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occurred while attempting to save your catalog.');
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Grade Scale Catalog, '+selectedCatalog.id, 'Core (Grade Scale)', 'editing/adding grade scale catalog', e);
			insert ge;
		}
	}

	/*
		Loads a catalog, and it's grade scales for display to the user.
	*/
	public void viewCatalog(){
		displayCatalogSelection = false;
		returnCatalogDetails(selectedRecord);
	}

	/*
		Modifies the page state so users can return from viewing a catalog/ select a different catalog then their default.
	*/
	public void showGSCSelect(){
		if(cSetup.setup.Published__c == false)
			displayCatalogSelection = true;
	}

	/*
		Loads the selected grade scale into a grade scale wrapper for display. 
		It also loads it's grade scales, and decides if the standard calculation type button should display.

		@param catID The id of the catalog you wish to load
	*/
	private void returnCatalogDetails(ID catID){
		try{
			selectedCatalogWrapper = new cCatalogWrapper(Grade_ScaleCatalogsMap.get(catId));
			displayCalcTypeButton = false;
			//if(selectedCatalogWrapper.catalogElementList.size()!=0){
				checkSOhasStandards();
				
				getGradeScales();
			//}
		} catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occurred while retrieving catalog details.');
		}  
	}

	private void checkSOhasStandards(){
		for(Grade_ScaleWrapper w : selectedCatalogWrapper.catalogElementList) {
			//check the picklist
			if(w.Grade_Scale.Category__c=='Standards' || w.gscs.Picklist_Value__r.Category__c == 'Standards' || w.gscs.Picklist_Value__r.Name =='Standard'){
				displayCalcTypeButton = true;
				break;
			}
		}
	}

	/*
		Queries all grade scales and adds any not used by the current catalog to the avaiable list.
	*/
	public void getGradeScales(){
		try{
			wrappedGrade_Scales = new List<Grade_ScaleWrapper>();
	  		if (selectedCatalogWrapper!=null){
		  		for (Picklist_Value__c c: getAvailableGrade_Scales()){
					if (!selectedCatalogWrapper.configuredGrade_ScaleIds.contains(c.id)){
				 		wrappedGrade_Scales.add(new Grade_ScaleWrapper(c));
					}
				}
			 }
		} catch(Exception e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR, 'An error occurred while loading grade scales.');
		}  
	}

	/*
		Loads the selcted grade scale and it's normalizations for editing.
	*/
	public void editGradeScale(){
		loadScale('edit');
		bEditScale = true;
	}

	/*
		Sets up a new grade scale for configuration by the user. This doe not actually save the scale.
	*/
	public void newGradeScale(){
		loadScale('new');
		selectedRecord = 'new';//used by the page to control rendering of name/category fields
		bEditScale = true;
	}

	/*
		Loads the selected grade scale, and clones it in it's entirity (including normalizations). This is presented to the user for updates before being saved.
	*/
	public void cloneGradeScale(){
		loadScale('clone');
		selectedRecord = 'new';
		bEditScale = true;
	}

	/* 
		Saves the grade scale and it's normalizations.
	*/
	public void saveGradeScale(){
		try{
			boolean isNew;
			boolean hasError = saveNormalizations();
			if (hasError){
				return;
			} else if(selectedGrade_Scale!=null){
				if(selectedGrade_Scale.Name == null || selectedGrade_Scale.Name == ''){
					SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You must give the scale a name.');
					return;
				}
				if(selectedGrade_Scale.Category__c == null){
					SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You must select a category.');
					return;
				}
				upsert selectedGrade_Scale;
				
				if (selectedRecord == 'new'){
					Grade_Scale_Catalog_Scale__c gsc = new Grade_Scale_Catalog_Scale__c(Grade_Scale_catalog__c =selectedCatalogWrapper.catalog.id,Picklist_Value__c= selectedGrade_Scale.id);
					insert gsc;
					gsc.Picklist_Value__r=selectedGrade_Scale;
					selectedCatalogWrapper.catalogElementList.add(new Grade_ScaleWrapper(gsc));
				} else {
					for(Grade_ScaleWrapper gsw: selectedCatalogWrapper.catalogElementList){
						if(gsw.gscs.Picklist_Value__c == selectedGrade_Scale.id){
							gsw.gscs.Picklist_Value__r = selectedGrade_Scale;
							break;
						}
					}
				}

				if(selectedRecord != ''){
					for (Grade_Normalization__c gn: currentNormalizations){
						gn.Picklist_Value__c = selectedGrade_Scale.id;
					}
				}
			}
			
			upsert currentNormalizations;
			bEditScale = false;
			checkSOhasStandards();
			ApexPages.addMessage(new apexpages.message(apexpages.severity.CONFIRM, 'The grade scale was updated successfully.'));
		} catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the new grade scale.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Grade Scale Catalog, '+selectedCatalogWrapper.catalog.Id+'; Grade Scale, '+selectedGrade_Scale.id, 'Core (Grade Scale)', 'error adding grade scale', e);
			insert ge;
		}		
	}

	/*
		Used by the page to maintain state, just called to unrender the scale edit modal
	*/
	public void cancelScaleEdit(){
		bEditScale = false;
	}

	/* 
		Removes selected scales from the current grade scale catalog, if they're currently not in use.
	*/
	public void removeScale(){
		List<Grade_ScaleWrapper> toRemove = new List<Grade_ScaleWrapper>();
		Set<ID> selectedScales = new Set<ID>();
		for(Integer i=0;i<selectedCatalogWrapper.catalogElementList.size();i++){
			if(selectedCatalogWrapper.catalogElementList[i].useRecord){
				selectedScales.add(selectedCatalogWrapper.catalogElementList[i].Grade_Scale.id);
				toRemove.add(selectedCatalogWrapper.catalogElementList.remove(i));
				i--; //fixes issue where selecting two scales side by side would only remove one
			}
		}
		try{
			List<Assignment__c> assignments = [select id from Assignment__c where Picklist_Value__c IN: selectedScales and Section__r.School__c =: cSetup.setup.School__c and Section__r.Time__c =: cSetup.setup.Year__c limit 1];
			if(!assignments.isEmpty()){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'One or more of the seclected scales is in use for this year and cannot be removed at this time. Please review your selections.'));
				selectedCatalogWrapper.catalogElementList.addAll(toRemove);
				return;
			}
		} catch(System.QueryException e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the new grade scale.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Grade Scale Catalog, '+selectedCatalogWrapper.catalog.Id+'; Grade Scale, '+selectedGrade_Scale.id, 'Core (Grade Scale)', 'error validating grade scale removal', e);
			insert ge;
			return;
		}
		List<Grade_Scale_Catalog_Scale__c> toDelete = new List<Grade_Scale_Catalog_Scale__c>();
		for(Grade_ScaleWrapper gsw:toRemove){
			if(gsw.gscs.id != null){
				toDelete.add(gsw.gscs);
			}
			gsw.Grade_Scale = gsw.gscs.Picklist_Value__r;
			gsw.gscs = new Grade_Scale_Catalog_Scale__c(Picklist_Value__c = gsw.Grade_Scale.id);
			gsw.useRecord = false;
			wrappedGrade_Scales.add(gsw);
		}
		try{
			delete toDelete;
		} catch(System.DMLException e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while removing grade scales.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Grade Scale Catalog, '+selectedCatalogWrapper.catalog.Id+'; Grade Scale, '+selectedGrade_Scale.id, 'Core (Grade Scale)', 'error removing grade scale', e);
			insert ge;
		}
		checkSOhasStandards();
	}

	/*
		Adds selected grade scales to the current grade scale catalog.
	*/
	public void addScale(){
		List<Grade_Scale_Catalog_Scale__c> toInsert = new List<Grade_Scale_Catalog_Scale__c>();
		for(Integer i=0;i<wrappedGrade_Scales.size();i++){
			if(wrappedGrade_Scales[i].useRecord){
				Grade_ScaleWrapper holder = wrappedGrade_Scales.remove(i);
				i--;
				holder.gscs = new Grade_Scale_Catalog_Scale__c(Grade_Scale_catalog__c = selectedCatalogWrapper.catalog.id, Picklist_Value__r = holder.Grade_Scale, Picklist_Value__c = holder.Grade_Scale.id);
				toInsert.add(holder.gscs);
				holder.useRecord = false;
				selectedCatalogWrapper.catalogElementList.add(holder);
			}
		}
		try{
			insert toInsert;
		} catch(System.DMLException e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while adding grade scales.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Grade Scale Catalog, '+selectedCatalogWrapper.catalog.Id+'; Grade Scale, '+selectedGrade_Scale.id, 'Core (Grade Scale)', 'error inserting new grade scale catalog scale', e);
			insert ge;
		}
		checkSOhasStandards();
	}

	/*
		Removes the selected normalization from the grade scale. It also recalculates all the other normalizations to balance out the normalization ranges.
	*/
	public void removeNormalization(){
		try{
			if (rangeNormalizations[Integer.valueOf(selectedRecord)].GPAID!=null){
				delete [select id from Grade_Normalization__c where id = :rangeNormalizations[Integer.valueOf(selectedRecord)].GPAID];
			}
			rangeNormalizations.remove(Integer.valueOf(selectedRecord));
			for (normalizationWrapper nw: rangeNormalizations){
				if (nw.index>Integer.valueOf(selectedRecord)) nw.index--;
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while removing a normalization.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Grade Scale, '+selectedGrade_Scale.id, 'Core (Grade Scale)', 'error on remove normalization', e);
			insert ge;
		}
	}

	/*
		Adds a new normalization to the bottom of the range for the grade scale currently being edited.
	*/
	public void addNormalization(){
		normRowsAdded++;//keep track of how many rows are added
		normalizationWrapper nw = new normalizationWrapper();
		nw.index = rangeNormalizations.size();
		rangeNormalizations.add(nw);
	}

	public void reloadCalcuationTypes(){
		calculationTypeValues = new Setup__c(
			Calculation_Type__c = csetup.setup.Calculation_Type__c,
			Law_of_Decaying_Average_Weight__c = csetup.setup.Law_of_Decaying_Average_Weight__c
		);
	}

	/*
		Sets up a new assignment type for configuration by the user.
	*/
	public void newAssignmentType(){
		assignmentTypeToEdit = new Picklist_Value__c(RecordTypeId = assignmentTypeRTID, Setup__c=cSetup.setup.id, Type__c='Assignment Type');
	}

	/*
		Loads the selected assignment type for editing by the user.
	*/
	public void editAssignmentType(){
		Map<ID, Picklist_Value__c> finderMap = new Map<ID, Picklist_Value__c>(assignmentTypes);
		assignmentTypeToEdit = finderMap.get(selectedRecord);
	}

	/*
		Checks to see if the selected assignment type is in use, and if not, deletes it.
	*/
	public void deleteAssignmentType(){
		List<Assignment_Lib__c> assignmentLibs = [select id from Assignment_Lib__c where Picklist_Value__c =: selectedRecord];
		if(!assignmentLibs.isEmpty()){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'The selected assignment type is currently in use. It cannot be deleted at this time.'));
			return;
		}

		Map<ID, Picklist_Value__c> finderMap = new Map<ID, Picklist_Value__c>(assignmentTypes);
		assignmentTypeToEdit = finderMap.remove(selectedRecord);

		try{
			delete assignmentTypeToEdit;
		} catch(System.DMLException e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while deleting the selected assignment type.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Gradbook Setup Wizard: Assignment Types, '+selectedRecord, 'Core (Gradebook School Setup)', 'error on Assignment Type delete', e);
			insert ge;
		}
		assignmentTypes = finderMap.values();
		assignmentTypes.sort();
	}

	/*
		Saves the assignment type currently being edited.
	*/
	public void saveAssignmentType(){
		Map<ID, Picklist_Value__c> finderMap = new Map<ID, Picklist_Value__c>(assignmentTypes);

		try{
			upsert assignmentTypeToEdit;
		} catch(System.DMLException e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving your assignment type.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Gradbook Setup Wizard: Assignment Types, '+assignmentTypeToEdit.id, 'Core (Gradebook School Setup)', 'error on Assignment Type save', e);
			insert ge;
		}

		finderMap.put(assignmentTypeToEdit.id, assignmentTypeToEdit);
		assignmentTypes = finderMap.values();
		assignmentTypes.sort();
		ApexPages.addMessage(new apexpages.message(apexpages.severity.CONFIRM, 'Your changes were saved successfully.'));
	}

	/*public void showCSV(){
		if(csvLoader == null){
			csvLoader = new core_LoadCsvData();
			csvLoader.bNeedsType=false;
			csvLoader.selectedLoadType = 'Assignment Types';
		}
		showCSV = true;
	}

	public void hideCSV(){
		showCSV = false;
	}*/

	/*
		Pulls each normalization out of the wrapper, converts it into the form stored in the system, and saves them.
	*/
	private Boolean saveNormalizations(){  	
  		List<Grade_Normalization__c> finalReUp = new List<Grade_Normalization__c>();		   
		boolean maxBool = true; //first is highest value
		for(normalizationWrapper nw : rangeNormalizations){
			if (nw.startVal==null||nw.GPA == null ||nw.representation==null){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Please ensure that all values have Starting Value, Grade Representation, and GP Value populated'));
				return true;
			} else  if (nw.startVal.format().length()==0||nw.GPA.format().length()==0 ||nw.representation.length()==0){
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Please ensure that all values have Starting Value, Grade Representation, and GP Value populated'));
				return true;
			} else {
				nw.gn.GP_Value__c = nw.GPA;
				nw.gn.Transformed_Grade__c = nw.representation;
				nw.gn.Grade_Value__c = nw.startVal;
				nw.gn.isFinal__c = selectedRecord == '';
				finalReUp.add(nw.gn);
		   	}	  	
		}
		currentNormalizations = finalReUp;
		return false;
	}

	/*
		Called by the constructor, it pulls the values of the calculation picklist types and then creates a list of select options or them.
	*/
	private List<SelectOption> getCalculationTypeOptions() {
		List<selectOption> options = new List<selectOption>();
		Schema.DescribeFieldResult fieldResult = Setup__c.Calculation_Type__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		
		for(Schema.PicklistEntry f : ple) {
			options.add(new selectOption(f.getLabel(), f.getValue()));
		}
		return options;
	}

	/*
		Handles all grade scale loading operations. This method creates new grade scales, load existing ones, and clones them as needed.
		@param selectedFunction Controls the opteration beformed by the method.
	*/
	private void loadScale(String selectedFunction){
		try{
			selectedGrade_Scale = null;
			matchMap				= new Map<String, normalizationWrapper>();
			picklistValue			= new Map<String, ID>();
		 	currentNormalizations 	= new List<Grade_Normalization__c>();
		 	rangeNormalizations		= new List<normalizationWrapper>();
		 	boolean hasNormalizations = false;
		 	normRowsAdded = 0;
			if (selectedFunction=='new'){
				selectedGrade_Scale = new Picklist_Value__c(RecordTypeId=core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Grade_Scale'), Type__c='Grade Scale');
				currentNormalizations = new List <Grade_Normalization__c>();
			} else {
				if (selectedRecord != null && selectedRecord != ''){
				  	try {
				  		selectedGrade_Scale = [select id, category__c, standard_scale__c, name, Type__c from Picklist_Value__c where id=:selectedRecord];
				  	} catch (exception e){
				  		system.debug('selecting final norms');
				  	}
					/*try {
				  		catalogScaleLinker = [select id, picklist_value__c from Grade_Scale_Catalog_Scale__c where id=:selectedScale and grade_scale_catalog__c=:selectedCatalogId];
				  	} catch (exception e){
				  		catalogScaleLinker = new Grade_Scale_Catalog_Scale__c(picklist_value__c=selectedScale, grade_scale_catalog__c=selectedCatalogId);
				  	}*/
				}
				currentNormalizations = [Select isFinal__c, Picklist_Value__c, Picklist_Value__r.Name, Transformed_Grade__c,GP_Value__c,
		 										Name, Id, Grade_Value__c, Picklist_Value__r.RecordTypeId
		 										From Grade_Normalization__c 
		 								where Picklist_Value__c = :selectedRecord	
		 								order by Grade_Value__c DESC, Name Desc];
			}

			if(selectedFunction == 'clone'){
				selectedGrade_Scale = selectedGrade_Scale.clone(false);
				selectedGrade_Scale.Name = 'Copy of ' + selectedGrade_Scale.Name;
				List<Grade_Normalization__c> holder = new List<Grade_Normalization__c>();
				for(Grade_Normalization__c gn:currentNormalizations){
					holder.add(gn.clone(false));
				}
				currentNormalizations = holder;
			}

			hasNormalizations = !currentNormalizations.isEmpty();				

			if(hasNormalizations){
				Grade_Normalization__c prevGn;
				integer k = 0;
				for(Grade_Normalization__c gn : currentNormalizations){
					rangeNormalizations.add(new normalizationWrapper(gn, prevGn, k));
					prevGn = gn;
					k++;
				}
			}		
		 	rowsAddedFinal = false;
		} catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An unexpected error occurred.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+cSetup.setup.id+'; Grade Scale Catalog, '+selectedCatalogWrapper.catalog.id, 'Core (Grade Scale)', 'addNewGrade_Scale', e);
			insert ge;
		}  
	}

	/*
		Called by the constructor it loads all the assignment types for the current setup and that have a null setup.
	*/
	private void loadAssignentTypes(){
		assignmentTypeRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assignment_Type');
		assignmentTypes = [select id, Name from Picklist_Value__c where RecordTypeId=:assignmentTypeRTID and (Setup__c =: cSetup.setup.id OR Setup__c = null) order by Name];
	}

	/*
		Loads grade scales
	*/
	public static List <Picklist_Value__c> getAvailableGrade_Scales(){
		List <Picklist_Value__c> Grade_ScaleList = core_SoqlUtils.getPlValues('Grade Scale', null).values();
		return Grade_ScaleList;
	}
	
	   
	/* get all of the grade scales that are related to the selected grade scale catalog */
	public static  List <Grade_Scale_Catalog_Scale__c> returnGrade_ScaleGrade_ScaleCatalogs(string catalogId){
		List <Grade_Scale_Catalog_Scale__c> ccList = 
				[Select picklist_value__r.category__c, c.Picklist_Value__r.Id, c.Picklist_Value__r.Name
				From Grade_Scale_Catalog_Scale__c c
				where c.Grade_Scale_Catalog__c =:catalogId];
		return ccList;
	}

	/* Wrapper Classes */
	public class cCatalogWrapper {
		public Grade_Scale_Catalog__c catalog				{get;set;}
		public List<Grade_ScaleWrapper> catalogElementList	{get;set;}
		public List <Grade_Scale_Catalog__c> editCatalogs	{get;set;}
		public Set <Id> configuredGrade_ScaleIds			{get;set;}
			public string selectedCatalogId					{get;set;}		

		public cCatalogWrapper (Grade_Scale_Catalog__c parentCatalog ){
			catalogElementList = new List<Grade_ScaleWrapper>();
			configuredGrade_ScaleIds = new Set<Id>();
			
			if(parentCatalog != null){
				this.catalog = parentCatalog;
				for(Grade_Scale_Catalog_Scale__c gscs: returnGrade_ScaleGrade_ScaleCatalogs(parentCatalog.id)){
					catalogElementList.add(new Grade_ScaleWrapper(gscs));
					configuredGrade_ScaleIds.add(gscs.Picklist_Value__c);
				}
			}
		}
	}

	public class Grade_ScaleWrapper{
		public Picklist_Value__c Grade_Scale		{get;set;}
		public Grade_Scale_Catalog_Scale__c Gscs	{get;set;}
		public boolean useRecord					{get;set;}
		
		public Grade_ScaleWrapper(Picklist_Value__c Grade_Scale){
			this.Grade_Scale = Grade_Scale;
			this.gscs = new Grade_Scale_Catalog_Scale__c(Picklist_Value__c=this.Grade_Scale.id);
			useRecord = false;
		}
		public Grade_ScaleWrapper(Grade_Scale_Catalog_Scale__c cat_Scale){
			this.Gscs = cat_Scale;
			this.Grade_Scale = new Picklist_Value__c(ID = this.Gscs.Picklist_Value__c);
			useRecord = false;
		}
	}

	public class normalizationWrapper{ //wrapper so the gpa list and final normalizations can be grouped and shown as a smaller list with ranges
		public decimal startVal				{get;set;} //starting normalized value
		public decimal endVal				{get;set;} //ending normalized value
		public String representation		{get;set;} //what the range translates to in a-f (or whatever the user chooses)
		public decimal GPA					{get;set;} //grade points associated with given grade
		public Id gpaId						{get;set;} //id of the existing grade_normalization object for updating if it exists
		public Grade_Normalization__c gn	{get;set;}
		public Integer index				{get;set;}
		
		public normalizationWrapper(Grade_Normalization__c gn, Grade_Normalization__c prevGn, integer i){ //constructor
			this.index = i;
			this.gn=gn;
			if (prevGn==null){
				startVal =gn.Grade_Value__c;
				endVal = 100;
			} else {
				endVal = prevGn.Grade_Value__c-.01;
				startVal = gn.Grade_Value__c;
			}
			representation = gn.Transformed_Grade__c;	
			gpa = gn.GP_Value__c;
			gpaId = gn.id;
		}

		public normalizationWrapper(){ //constructor
			this.gn = new Grade_Normalization__c();
		}
	}
}