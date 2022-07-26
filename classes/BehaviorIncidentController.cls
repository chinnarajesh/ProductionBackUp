public without sharing class BehaviorIncidentController {
	/* LOCAL DATA STORE */
	public Behavior_Incident__c incident			{get; set;} //copy of the behavior incident information
	public List <cStudentWrapper> stuWrapperList	{get; set;} //holding container for student information

	/* PAGE STATE */
	public string selBehType			{get; set;} //used to maintain the selected behavior type on the page
	public boolean bfatalError			{get; set;} //controlls page displays when error on controller load
	public boolean displayActionsTaken	{get; set;} //controlls display checkboxes for actions taken panel
	public boolean hasWeapon			{get; set;} //controlls display of weapon selection panel
	public boolean canUserNotify		{get; set;} //controlls display of notification save button
	public boolean displayStudentTable	{get; set;} //controlls displaying of student table
	public boolean bHasBeenSavedAsDraft	{get; set;} //controlls displaying of the draft save button
	public string studentInvolvedId		{get; set;} //passes student ids back to the controller
	public string activeConsequence		{get; set;} //passes consequence ids back to the controller

	/* TYPE/CATEGORY CONTAINERS */
	public List <SelectOption> behaviorCategoryValues				{get; set;} //maintains a list of the available behavior cateory values
	public List<SelectOption> behaviorTypeValues					{get; set;} //maintains a list of the available behavior type values
	public Map <String, Picklist_Value__c> behaviorIncidentTypeMap  {get; set;} //a map of id to the picklist_value objects that make behavior types
	public List <SelectOption> recordTypeOption						{get; set;} //a list of available incident types
	private Map<String, Id> 								behRTMap; //A map of incident type name to its record type id
	private Map<String, Id> 								picklistRTMap; //A map of picklist record types
	private Map<String, Map<String, List<SelectOption>>> 	picklistMap; //a map of incident types to behavior categories to behavior types

	/* CONESQUENCE CONTAINTERS */
	public List<Picklist_Value__c> consequencesValues	{get; set;} //a list of all available consequence values

	private Map<Id, Map<String, List<Picklist_Value__c>>>	masterConsequenceMap; //map of setups to behavior consequences
	private Map<Id, Map<String, List<SelectOption>>>		masterConsequenceSelect; //map of setups to consequence selectoptions
	private Set<Id> 										notifyAdminSet; //a set of the consequences that have admin notifications
	private Map<Id, Picklist_Value__c> 						consequencePLMap;
	/* SEARCH OBJECTS */
	public Student__c searchInfo			{get;set;} //the student limiters used in the search
	public boolean showResults				{get;set;} //should the results be shown?
	public boolean showSearch				{get;set;} //should the search table be shown?
	public List<searchWrapper> results		{get;set;} //wrapper for displaying results
	public List<searchWrapper> addList		{get;set;} //wrapper for students to be added to the incident
	public List<selectOption> schoolList	{get;set;} //list of schools to search over

	/* PRIVATE INTERNALS */
	private List<Student_Behavior__c> 			deletedStudents; //A maintained list of deleted students
	private List<Consequence__c> 				deletedConsequences; //A maintained list of deleted conseqences
	private core_BaseInfo_v2.cSchool_BaseInfo 	baseObj; //school core info object
	private integer 							totalStudents = 0; //Maintains a counter so unique ids can be generated.
	private Set<Id> studentsAdded;
	private id firstStudent;
	private id firstStudentSetup;
	private string defaultSchool;

	public BehaviorIncidentController(ApexPages.StandardController stdcon){
		try{
			core_BaseInfo_v2.initBaseInfo(null, false, false, true);
			baseObj = core_BaseInfo_v2.baseInfoObj;
		}catch(Exception e){
			errorMessage('User: ' + userInfo.getFirstName() + ' ' + userInfo.getLastName() + ' is not associated with a staff record.');
		}

		core_BaseInfo_v2.showErrorMessages();

		if (ApexPages.hasMessages()) {
			bfatalError=true;
		} else {
			incident			= (Behavior_Incident__c) stdcon.getRecord();
			defaultSchool = (core_BaseInfo_v2.staffList.isEmpty())?'':core_BaseInfo_v2.staffList[0].Organization__c;
			hasWeapon			= false;
			showSearch			= false;
			showResults			= false;
			selBehType 			= '';
			activeConsequence 	= '';
			studentInvolvedId	= '';
			bHasBeenSavedAsDraft = false;
			stuWrapperList = new List<cStudentWrapper>();
			deletedStudents = new List<Student_Behavior__c>();
			deletedConsequences = new List<Consequence__c>();
			behaviorIncidentTypeMap = new Map <String, Picklist_Value__c>();
			behaviorTypeValues = new List<Selectoption>();
			schoolList = new List<SelectOption>();
			notifyAdminSet = new Set<Id>();
			results = new List<searchWrapper>();
			searchInfo = new Student__c(School__c=defaultSchool);
			masterConsequenceMap = new Map<Id, Map<String, List<Picklist_Value__c>>>();
			masterConsequenceSelect = new Map<Id, Map<String, List<SelectOption>>>();
			consequencePLMap = new Map<Id, Picklist_Value__c>();
			recordTypeOption = new List<SelectOption>();
			consequencesValues = new List<Picklist_Value__c>();
			studentsAdded = new Set<Id>();
			firstStudent = null;
			firstStudentSetup = null;

			//Used to keep track of the incident record type
			behRTMap = core_SoqlUtils.getRecordTypesBySobject('Behavior_Incident__c');
			picklistRTMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
			Map<String,ID> accountRTs = core_SoqlUtils.getRecordTypesBySobject('Account');
			
			for(Account a:[select id, Name from Account where RecordTypeId =: accountRTs.get('School') OR RecordTypeId =: accountRTs.get('Summer_School') order by Name]){
				schoolList.add(new SelectOption(a.id, a.Name));
			}
			for(String recordType: behRTMap.keySet()) {
				recordTypeOption.add(new selectOption(recordType,recordType));
			}
			recordTypeOption = sortList(recordTypeOption);

			//Fixes issues with bad active setups that have this field as null.
			if(baseObj.activeSetup.Behavior_Referal_Details__c != null)
				displayActionsTaken = baseObj.activeSetup.Behavior_Referal_Details__c;
			else
				displayActionsTaken = false;


			if(incident.Id == null) {
				// New Incident
				incident = new Behavior_Incident__c();
				incident.Incident_Type__c = 'Negative';

				addConsequenceSetup(baseObj.activeSetup.id, incident.Incident_Type__c);
				setAdultOnDutytoCurrentUser();

				//Auto add the first student
				String studURLId = System.currentPagereference().getParameters().get('studid');

				if (studURLId != null) {
					displayStudentTable = true;
					addStudent(core_soqlUtils.getStudentById(studURLId)[0]);
				} else {
					displayStudentTable = false;
					showSearch = true;
				}
			} else {
				//existing incident
				incident = Behavior_SoqlUtils.getBehaviorIncident(incident.Id);
				addConsequenceSetup(baseObj.activeSetup.id, incident.Incident_Type__c);

				List<Student_Behavior__c> studentsInvolved = Behavior_SoqlUtils.getStudentsInvolved(incident.Id);
				List<Consequence__c> consequences = new List<Consequence__c>();
				Set<Id> stuInvIds = new Set<Id>();

				//draft saves don't always have students
				if (studentsInvolved.size() > 0) {
					for (Student_Behavior__c sbc: studentsInvolved) {
						stuInvIds.add(sbc.Id);
						if(sbc.student__r.Archived__c){
							bfatalError = true;
							infoMessage('The incident you have selected is for a past year. You are unable to edit this record. Please use the details page to review the incident.');
						}
					}

					consequences = Behavior_SoqlUtils.getAllConsequences(stuInvIds);

					//Seed stuWrapperList
					addStudents(studentsInvolved, consequences);
				}

				displayStudentTable = !stuWrapperList.isEmpty();
			}
			//should the notify button be displayed?
			canUserNotify = verifyUserCanNotify();

			//fill behavior picklists required for the page
			changeIncidentType();
			addConsequenceSetup(baseObj.activeSetup.id, incident.Incident_Type__c);

			//If an existing incident fill in the behavior type too
			if(incident.id != null)
				fillBehaviorType();
		}
	}

	/*ACTION METHODS */
	/* Return the user to the behavior tab.
		This is used by the save methods. */
	public pageReference escapeToBehaviorTab(){
		String biKeyPref = Schema.SObjectType.Behavior_Incident__c.getKeyPrefix();
		PageReference p = new PageReference('/'+biKeyPref+'/o');
		p.setRedirect(true);
		return p;
	}

	/* Called when the incident type is changed on the page.
		Reloads the picklists for cat and type so they reflect the incident type. */
	public void changeIncidentType(){
		behaviorCategoryValues = new List<SelectOption>();
		behaviorTypeValues = new List<SelectOption>();

		//build the catagory values
		if (firstStudentSetup != null && picklistMap.containsKey(incident.Incident_Type__c)) {
			for(String s: picklistMap.get(incident.Incident_Type__c).keyset()) {
				behaviorCategoryValues.add(new SelectOption(s, s));
			}
			behaviorCategoryValues = sortList(behaviorCategoryValues);
		}

		behaviorTypeValues.add(new SelectOption('--Please Select Category--', '--Please Select Category--'));

		if(firstStudentSetup == null){
			behaviorCategoryValues.add(new SelectOption('--Please Add Student--', '--Please Add Student--'));
		} else if(behaviorCategoryValues.isEmpty()){
			behaviorCategoryValues.add(new SelectOption('--Please Select--', '--Please Select--'));
		} else {
			behaviorCategoryValues.add(0, new SelectOption('--Please Select--', '--Please Select--'));
		}

		//update consequences on students
		if(stuWrapperList.size() > 0){
			for(cStudentWrapper swrap: stuWrapperList){
				if(swrap.student.Setup__c == null){
					swrap.consequenceOptions = masterConsequenceSelect.get(baseObj.activeSetup.id).get(incident.Incident_Type__c);
				} else if(masterConsequenceSelect.containsKey(swrap.student.Setup__c)){
					swrap.consequenceOptions = masterConsequenceSelect.get(swrap.student.Setup__c).get(incident.Incident_Type__c);
				} else {
					errorMessage('Unable to update student consequences.');
					return;
				}
			}
		}

		if(behaviorCategoryValues.size() == 1 && firstStudentSetup != null && incident.Incident_Type__c != 'Quick_Hit'){
			errorMessage('Error: There are no available Behavior Categories for the Incident Type you selected.');
		}
	}

	/* Remove a student from the incident */
	public void deleteStudent() {
		try {
			cStudentWrapper studentToDel = findAndRemoveStudentWrapperById(studentInvolvedId);
			studentsAdded.remove(studentToDel.student.id);
			if(studentToDel.sb.id != null)
				deletedStudents.add(studentToDel.sb);

			if(stuWrapperList.isEmpty()){
				displayStudentTable = false;
				firstStudentSetup = null;
				firstStudent = null;
				incident.Selected_Behavior_Incident_Type__c = null;
				incident.Selected_Behavior_Category__c = null;
				selBehType = '';
				changeIncidentType();
			} else if(studentToDel.student.id == firstStudent){
				boolean shiftSetup = (stuWrapperList[0].student.Setup__c != studentToDel.student.Setup__c)? true:false;
				firstStudent = stuWrapperList[0].student.id;
				firstStudentSetup = stuWrapperList[0].student.Setup__c;
				if(shiftSetup){
					if(behaviorIncidentTypeMap.containsKey(incident.Selected_Behavior_Incident_Type__c)
							&& behaviorIncidentTypeMap.get(incident.Selected_Behavior_Incident_Type__c).Setup__c != null)
						incident.Selected_Behavior_Incident_Type__c = null;

					preFillDropDowns();
					changeIncidentType();
					fillBehaviorType();
				}
			}
		} catch (Exception e) {
			globalErrorMessage('', 'Error while attempting to remove student.', e, true);
		}
	}

	/* Add a consquence to a student */
	public void addConsequence() {
		try {
			for(cStudentWrapper swrap: stuWrapperList) {
				if (studentInvolvedId == swrap.id){
					Picklist_Value__c defaultConsequence = consequencePLMap.get(swrap.consequenceOptions[0].getValue());
					swrap.addCon(new Consequence__c(Picklist_Value__c = defaultConsequence.id, Time_Lost__c = defaultConsequence.Corresponding_Value__c, Student_Consequence__c = swrap.student.id), defaultConsequence.Notify_Admin__c);
				}
			}
		} catch (Exception e) {
			globalErrorMessage('', 'Error while adding consequence.', e, true);
		}
	}

	/* When the type of consequence changes, save the new value
		and update the suspension information */
	public void storeCon() {
		try {
			string selectedCon = ApexPages.currentPage().getParameters().get('selectedCon');
			Picklist_Value__c selectedValue = consequencePLMap.get(selectedCon);
			integer location = findStudentWrapperPosition(studentInvolvedId);
			integer conLocation = 0;
			boolean found = false;
			for(cConsequenceWrapper con: stuWrapperList[location].conList) {
				if(con.id == activeConsequence) {
					found = true;
				} else {
					if (con.con.Picklist_Value__c == selectedValue.id){
						errorMessage('The student already has that conseqeuence.');
						return;
					}
					if(!found){
						conLocation++;
					}
				}
			}

			Picklist_Value__c oldValue = consequencePLMap.get(stuWrapperList[location].conList[conLocation].con.Picklist_Value__c);
			if(selectedValue.Is_Suspension__c && !oldValue.Is_Suspension__c && stuWrapperList[location].hasSuspension){
				errorMessage('Only one suspension consequence per student is allowed.');
				return;
			}

			//keep the hasSuspension field up to date
			if(oldValue.Is_Suspension__c == null || oldValue.Is_Suspension__c){
				stuWrapperList[location].hasSuspension = false;
				stuWrapperList[location].suspension = new Consequence__c();
			}
			if(selectedValue.Is_Suspension__c != null && selectedValue.Is_Suspension__c){
				stuWrapperList[location].hasSuspension = true;
				stuWrapperList[location].suspension = stuWrapperList[location].conList[conLocation].con;
			}

			//keep the notify field up to date
			if(oldValue.Notify_Admin__c == null || oldValue.Notify_Admin__c){
				stuWrapperList[location].notify = false;
			}
			if(selectedValue.Notify_Admin__c != null && selectedValue.Notify_Admin__c){
				stuWrapperList[location].notify = true;
			}

			//store the new value
			stuWrapperList[location].conList[conLocation].con.Picklist_Value__c = selectedValue.id;
			stuWrapperList[location].conList[conLocation].conWeight = selectedValue.Consequence_Weight__c;
		} catch (Exception e){
			globalErrorMessage('', 'Error while updating consequence selection.', e, true);
		}
	}

	/* Remove a consequence from a student. */
	public void removeCon() {
		try {
			integer location = findStudentWrapperPosition(studentInvolvedId);
			integer counter = 0;

			for(cConsequenceWrapper con: stuWrapperList[location].conList){
				if(con.id == activeConsequence) {
					//If the consequence is in the db, we need to delete it on save
					if(con.con.id != null){
						deletedConsequences.add(con.con);
					}
					//update suspension information
					if(consequencePLMap.get(con.con.Picklist_Value__c).Is_Suspension__c){
						stuWrapperList[location].hasSuspension = false;
					}
					break;
				} else {
					counter++;
				}
			}
			stuWrapperList[location].conList.remove(counter);
		} catch (Exception e) {
			globalErrorMessage('', 'Error while removing conseqence.', e, true);
		}
	}

	public void searchStudents(){
		try{
			List<Student__c> studentResults = Behavior_SoqlUtils.searchStudents(searchInfo, baseobj.school.Id);
			showResults = (studentResults.size()>0) ? true:false;
			if(!showResults){
				errorMessage('Search returned 0 results.');
			}

			//Keep already selected students
			List<searchWrapper> tempList = new List<searchWrapper>();
			if(results.size()>0){
				for(searchWrapper swrap: results){
					if(swrap.selected){
						tempList.add(swrap);
					}
				}
			}
			results.clear();
			results.addAll(tempList);

			for(Student__c stud:studentResults){
				results.add(new searchWrapper(stud));
			}
		} catch (Exception e){
			globalErrorMessage('', 'Error when searching for students. Please check inputs.',e,true);
		}
	}

	public void searchAdd(){
		boolean foundStudent = false;
		for(searchWrapper s:results){
			if(s.selected){
				addStudent(s.student);
				foundStudent = true;
			}
		}
		if(!foundStudent){
			errorMessage('Error: Please select a student.');
			return;
		}

		displayStudentTable = true;
		endSearch();
	}

	public void startSearch(){
		results.clear();
		searchInfo = new Student__c(School__c = defaultSchool);
		showSearch = true;
	}

	public void endSearch(){
		showSearch = false;
		showResults = false;
	}

	/* Called from the page when the Behavior Category is updated.
		This pulls data from the picklistMap which was built on load.
		It handles several states, as well as filtering cats without types. */
	public void fillBehaviorType() {
		behaviorTypeValues = new List<SelectOption>();
		selBehType = '';
		string emptyType = '--Please Select--';
		string emptyCat = '--Please Select Category--';

		//fixes a null error when the user would change the category back to please select
		if(incident.Selected_Behavior_Category__c != emptyType){
			try{
				//Adds the values, but only if there are values for the selected combination of type and category
				if(picklistMap.containsKey(incident.Incident_Type__c) && picklistMap.get(incident.Incident_Type__c).containsKey(incident.Selected_Behavior_Category__c))
					behaviorTypeValues.addAll(picklistMap.get(incident.Incident_Type__c).get(incident.Selected_Behavior_Category__c));
				else if(incident.Incident_Type__c != 'Quick_Hit')
					errorMessage('Error: For the Behavior Category you selected, there are no Behavior Types available.');
			} catch (Exception e){
				errorMessage('The behavior types in your org have been modified and no longer valid for the combination of values chosen for this incident. Therefore the saved behavior type cannot be loaded.');
				incident.Selected_Behavior_Incident_Type__c = null;
			}

			behaviorTypeValues = sortList(behaviorTypeValues);

			//If there is only one option, make that the selected value.
			if (behaviorTypeValues.size() > 1)
				behaviorTypeValues.add(0, new SelectOption(emptyType, emptyType));
			else if(behaviorTypeValues.isEmpty()){
				behaviorTypeValues.add(new SelectOption(emptyType, emptyType));
			}
		} else {
			//If the user sets the cat back to null, set this to wait on the cat.
			behaviorTypeValues.add(new SelectOption(emptyType, emptyCat));
		}
	}

	/* Decides if the weapon type panel should be shown on the page */
	public void displayWeaponType(){
		try {
			hasWeapon = (behaviorIncidentTypeMap.containsKey(selBehType))? behaviorIncidentTypeMap.get(selBehType).Incident_Involves_Weapon__c:false;
			if(!hasWeapon)
				incident.Weapon_Type__c = null;

			incident.Selected_Behavior_Incident_Type__c = (selBehType.contains('-'))?null:selBehType;
		} catch (Exception e){
			globalErrorMessage('', 'Error in weapon dipslay.', e, true);
		}
	}

	/* SAVE FUNCTIONS */
	/* Marks a incident as saved as a draft, but otherwise performs a full save */
	public pageReference saveDraft() {
		bHasBeenSavedAsDraft = true;
		return saveIncident();
	}

	/* The save and notify button on the page.
		It performs a full save, but it also triggers the notify workflows. */
	public pageReference notifyIncidentOwner() {
		incident.Notify_Incident_Owner__c = canUSerNotify;
		return saveIncident();
	}

	/* Saves all the incident data */
	public pageReference saveIncident() {
		try {
			//Stops the page from saving if there are no students. Allows draft saving without students.
			if(!bHasBeenSavedAsDraft && stuWrapperList.isEmpty())
				return errorMessage('You must add at least one student to save this incident. Please search for a student below and add them to the incident.');
			
			//check a type was selected. It's looking at the ID not the string on the page, so we can check for -
			if(incident.Incident_Type__c != 'Quick_Hit' && (incident.Selected_Behavior_Incident_Type__c == null || String.valueOf(incident.Selected_Behavior_Incident_Type__c).contains('-'))){
				return errorMessage('You must select a behavior category and behavior type. Please select a type and save again.');
			}

			//This stops the save if there are errors other then those generated by the controller.
			if (apexPages.hasMessages()) {
				system.debug('ERROR: Save failed due to detected page messages.');
				return null;
			}
			
			//update Notification information
			updateNotificationInfo();
			//Calculate the status
			setStatus();

			//success keeps track of errors and stops the save if a DML occurs.
			boolean success = true;
			if (incident.Other__c == false)
				incident.Other_Notes__c = '';

			incident.RecordTypeId = behRTMap.get(incident.Incident_Type__c.replace(' ', '_'));

			//Fill out email forms for information requests.
			populateIncidentEmailFields();
			//update Notification information
			updateNotificationInfo();
			//process attendance
			preProcessStudents();

			//Start saving
			//Incident first, we need it's id.
			success = upsertIncident(new List<Behavior_Incident__c>{incident});
			if(!success)
				return errorMessage('Failed to save incident. Please check your entries and try again.');

			//Save student behavior and consequences
			List<Student_Behavior__c> studentsInvolved = new List<Student_Behavior__c>();
			List<Consequence__c> consequences = new List<Consequence__c>();
			for(cStudentWrapper swrap: stuWrapperList){
				//This field shouldn't be written to unless it's null but sometimes it does anyway.
				if(swrap.sb.Behavior_Incident__c == null){
					try{
						swrap.sb.Behavior_Incident__c = incident.id;
					} catch(exception e) {
						return errorMessage('Attempt to relate students to incident failed. Please try to save again. If this problem persists, contact your system administrator.');
					}
				}
				studentsInvolved.add(swrap.sb);
			}

			//save the students.
			success = upsertStudentsInvolved(studentsInvolved);
			if(!success){
				return errorMessage('Failed to save students. Please check your entries and try again.');
			}

			for(cStudentWrapper swrap: stuWrapperList){
				//check to see if the student has consequences (FUTURE: Could be optimized?)
				if(!swrap.conList.isEmpty()) {
					ID sbID;
					if(swrap.sb.id != null){
						sbId = swrap.sb.id;
					} else {
						for(Student_Behavior__c sb: studentsInvolved) {
							if(sb.Student__c == swrap.sb.Student__c){
								sbId = sb.id;
								break;
							}
						}
					}

					boolean hasFinalCon = false;
					for(cConsequenceWrapper cwrap: swrap.conList){
						//used for reports, so it needs to be copied over (should be moved to Consequence trigger)
						cwrap.con.Consequence__c = consequencePLMap.get(cwrap.con.Picklist_Value__c).Name;

						//set the student to the consquence
						if(cwrap.con.Student_Consequence__c == null)
							cwrap.con.Student_Consequence__c = swrap.sb.Student__c;

						//link the consequence to the student behavior
						if(cwrap.con.Student__c == null){
							cwrap.con.Student__c = sbId;
						}

						if(cwrap.con.Time_Lost__c == null){
							Error_Handling.errorMessage('You must enter time lost for consequences.');
							return null;
						}

						//Copy suspesion information from to the right consequence
						if (consequencePLMap.get(cwrap.con.Picklist_Value__c).Is_Suspension__c) {
							if(swrap.suspension.Days_Suspended__c == null ||
								swrap.suspension.Date_of_Re_entry__c == null ||
								swrap.suspension.Re_entry_Mtg_Time__c == null ||
								swrap.suspension.Re_entry_Mtg_Date__c == null) {
								  return errorMessage('Please enter suspension information for a suspension consequence.');
							} else {
								cwrap.con.Days_Suspended__c		= swrap.suspension.Days_Suspended__c;
								cwrap.con.Date_of_Re_entry__c	= swrap.suspension.Date_of_Re_entry__c;
								cwrap.con.Re_entry_Notes__c		= swrap.suspension.Re_entry_Notes__c;
								cwrap.con.Re_entry_Mtg_Time__c	= swrap.suspension.Re_entry_Mtg_Time__c;
								cwrap.con.Re_entry_Mtg_Date__c	= swrap.suspension.Re_entry_Mtg_Date__c;
								
								if(swrap.suspension.Show_Suspension_In_Attendance__c && (
										swrap.suspension.Suspension_Start_Date__c == null ||
										swrap.suspension.Suspension_End_Date__c == null)){
									return errorMessage('You must enter a start and end date to record suspesions in Attendance.');
								} else if(swrap.suspension.Show_Suspension_In_Attendance__c){
									cwrap.con.Show_Suspension_In_Attendance__c = swrap.suspension.Show_Suspension_In_Attendance__c;
									cwrap.con.Suspension_Start_Date__c = swrap.suspension.Suspension_Start_Date__c;
									cwrap.con.Suspension_End_Date__c = swrap.suspension.Suspension_End_Date__c;
								}
							}
						}

						if(cwrap.con.Final_Consequence__c && !hasFinalCon){
							hasFinalCon = true;
						} else if(cwrap.con.Final_Consequence__c){
							return errorMessage('You may select only one final consequence per student.');
						}

						consequences.add(cwrap.con);
					}
				}
			}

			//Save the consequences
			success = upsertConsequences(consequences);
			if(!success)
				return errorMessage('Failed to save consequences. Please check your entries and try again.');

			//Now that everything has been saved, delete anything that was deleted during edit
			if (!deletedStudents.isEmpty()) {
				success = deleteStudentsInvolved(deletedStudents);
				if(!success) {
					return errorMessage('Failed to save student changes. Please check your entries and try again.');
				}
			}
			if(!deletedConsequences.isEmpty()) {
				success = deleteConsequences(deletedConsequences);
				if(!success) {
					return errorMessage('Failed to save consequence changes. Please check your entries and try again.');
				}
			}

			//return the user to the details page for the incident.
			PageReference p = new PageReference('/apex/BehaviorIncidentDetail?id=' + incident.Id);
			p.setRedirect(true);
			return p;
		} catch (Exception e) {
			globalErrorMessage('', 'Unhandeled exception while saving.', e, true);
			return null;
		}
	}

	/* DML OPERATIONS */
	/* Saves the incident to the database*/
	//You only need to save one, but SF security frowns on non-List dml ops.
	private boolean upsertIncident(List<Behavior_Incident__c> incident) {
		try {
			upsert Incident;
			return true;
		} catch (System.DMLException ex) {
			globalErrorMessage('', 'DML exception on incident upsert', ex, false);
			return false;
		}
	}

	/* Saves the students to the database */
	private boolean upsertStudentsInvolved(List<Student_Behavior__c> studentsInvolved) {
		try {
			upsert studentsInvolved;
			return true;
		} catch (System.DMLException ex) {
			globalErrorMessage('', 'DML exception on student upsert', ex, false);
			return false;
		}
	}

	/* Saves the consequences to the database */
	private boolean upsertConsequences(List<Consequence__c> consequences) {
		try {
			upsert consequences;
			return true;
		} catch (System.DMLException ex) {
			globalErrorMessage('', 'DML exception on consequence upsert', ex, false);
			return false;
		}
	}

	/* Deletes students from the database */
	private boolean deleteStudentsInvolved(List<Student_Behavior__c> studentsInvolved) {
		try{
			delete studentsInvolved;
			return true;
		} catch (System.DMLException ex) {
			globalErrorMessage('', 'DML exception on student delete', ex, false);
			return false;
		}
	}

	/* Deletes consequences from the database */
	private boolean deleteConsequences(List<Consequence__c> consequences) {
		try{
			delete consequences;
			return true;
		} catch (System.DMLException ex) {
			globalErrorMessage('', 'DML exception on consequence delete', ex, false);
			return false;
		}
	}

	/* HELPER METHODS */
	/* Simplifies error messages. This returns null because
		ths save method requires many null returns */
	private PageReference errorMessage(string message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
		return null;
	}
	
	private void infoMessage(string message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,message));
	}

	private void preProcessStudents(){
		Map<ID,Consequence__c> suspensionMap = new Map<ID, Consequence__c>();
		Date firstStartDate, lastEndDate;
		Map<ID, ID> studentSetupMap = new Map<ID, ID>();
		for(cStudentWrapper s:stuWrapperList){
			if(s.hasSuspension){
				//mark the incident as permant if there is a suspension
				incident.Preserve__c = true;
				//setup for attendance creation for suspensions
				if(s.suspension.Show_Suspension_In_Attendance__c){
					studentSEtupMap.put(s.student.id, s.student.Setup__c);
					suspensionMap.put(s.Student.ID, s.suspension);
					if(firstStartDate == null || s.suspension.Suspension_Start_Date__c < firstStartDate)
						firstStartDate = s.suspension.Suspension_Start_Date__c;
					if(lastEndDate == null || s.suspension.Suspension_End_Date__c > lastEndDate)
						lastEndDate = s.suspension.Suspension_End_Date__c;
				}
			}
		}
		if(!suspensionMap.isEmpty()){
			List<Student_Section__c> ssList = [select Section__c, Student__c from Student_Section__c 
												where Student__c IN: suspensionMap.keySet()
												AND Active__c = true
												and Section__r.RecordType.DeveloperName = 'Published'];
			Set<ID> sectionIDs = new Set<ID>();
			for(Student_Section__c s:ssList){
				sectionIDs.add(s.Section__c);
			}
			Map<ID, Session__c> sessionMap = new Map<ID, Session__c>([select id, Session_Date__c, End_DateTime__c, Section__c
											from Session__c
											where Session_Date__c >= :firstStartDate 
											and Session_Date__c <= :lastEndDate
											and Section__c IN: SectionIDs]);
			
			Map<ID, Set<ID>> studentSessionMap = new Map<ID,Set<ID>>();
			for(Student_Section__c student: ssList){
				if(!studentSessionMap.containsKey(student.Student__c))
					studentSessionMap.put(student.Student__c, new Set<ID>());
				for(Session__c s:sessionMap.values()){
					if(student.Section__c == s.Section__c)
						studentSessionMap.get(student.Student__c).add(s.id);
				}
			}
			
			List<Attendance__c> existingAttendance = [select id, Student__c, Session__c, External_Id__c
														from Attendance__c
														where Student__c IN: suspensionMap.keySet()
														and Session__c IN: sessionMap.keySet()];
			
			Set<String> existingRefIDs = new Set<String>();										
			for(Attendance__c a:existingAttendance){
				existingRefIDs.add(a.External_Id__c);
			}
			string attendancePV = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance');

			Map<String,ID> picklistValueMap = new Map<String, ID>();
			Picklist_Value__c OSS, ISS;
			for(Picklist_Value__c pv:[select id, Category__c, Setup__c from Picklist_Value__c where RecordTypeID =: attendancePV]){
				if(pv.Category__c == 'Out of School Suspension')
					picklistValueMap.put(pv.Setup__c+'OSS',pv.id);
				if(pv.Category__c == 'In School Suspension')
					picklistValueMap.put(pv.Setup__c+'ISS',pv.id);
			}
			
			List<Attendance__c> toCreate = new List<Attendance__c>();
			for(ID student: studentSessionMap.keySet()){
				Consequence__c con = suspensionMap.get(student);
				for(ID s:studentSessionMap.get(student)){
					PickList_Value__c consequenceValue = consequencePLMap.get(con.Picklist_Value__c);
					if(consequenceValue.Category__c != null){
						Session__c session = sessionMap.get(s);
						//does the session fall in the range?
						String refID = (string)student+(string)s+'';
						if(session.Session_Date__c >= con.Suspension_Start_Date__c && session.Session_Date__c <= con.Suspension_End_Date__c && !existingRefIDs.contains(refID)){
							//did it already end?
							if((session.End_DateTime__c > system.now() && session.Session_Date__c == system.today())||session.Session_Date__c > system.today()){
								String attValue;
								if(consequenceValue.Category__c == 'Out of School Suspension' && picklistValueMap.containsKey(studentSetupMap.get(student)+'OSS')){
									attValue = picklistValueMap.get(studentSetupMap.get(student)+'OSS');
								} else if(consequenceValue.Category__c == 'In School Suspension'&& picklistValueMap.containsKey(studentSetupMap.get(student)+'ISS')){
									attValue= picklistValueMap.get(studentSetupMap.get(student)+'ISS');
								}else if(consequenceValue.Category__c == 'Out of School Suspension' && picklistValueMap.containsKey('nullOSS')){
									attValue = picklistValueMap.get('nullOSS');
								}else if(consequenceValue.Category__c == 'In School Suspension'&& picklistValueMap.containsKey('nullISS')){
									attValue = picklistValueMap.get('nullISS');
								}else{
									system.debug('Unable to find '+consequenceValue.Category__c+'. No attendance records were created.');
									continue;
								}
								toCreate.add(new Attendance__c(Student__c = student, Session__c = s, Picklist_Value__c = attValue, External_ID__c = refID));
							}
						}
					}
					
				} //end outer for
				insert toCreate;
			}
		}
	}

	private void globalErrorMessage(string links, string info, Exception e, boolean pageError){
		Global_Error__c ge;
		if(incident.id != null){
			ge = Error_Handling.handleError('Incident,' + incident.id + ';' + links, 'Behavior', info, e);
		} else {
			ge = Error_Handling.handleError(links, 'Behavior', info + ' Error on creation', e);
		}
		insert ge;

		if(pageError){
			errorMessage(info);
		}
	}

	/* Gets the current adult on duty and auto fills the field. */
	private void setAdultOnDutytoCurrentUser() {
		try {
			incident.Adult_on_Duty__c = baseObj.staff.id;
		} catch(Exception ex) {
			errorMessage('Unable to locate staff records. Please check your active setup and try again.');
		}
	}

	private void updateNotificationInfo(){
		String userIdentity = identifyUser();

		//don't let them notify themselves
		if (userIdentity == 'Adult_on_Duty')
			incident.Request_Info_AoD__c = false;
		else if (userIdentity == 'Adult1')
			incident.Request_Info_Adult1__c = false;
		else if (userIdentity == 'Adult2')
			incident.Request_Info_Adult2__c = false;
	}

	/* Checks if the user has the ability to notify other users */
	private boolean verifyUserCanNotify() {
		String userIdentity;
		userIdentity = identifyUser();

		if (userIdentity == 'Adult_on_Duty' || userIdentity == 'Adult1' || userIdentity == 'Adult2' && incident.id != null)
			return true;
		//If the user is not assoicated with the incident they can't notify
		return false;
	}

	/* Identifes the current user and the connection to the incident */
	private string identifyUser() {
		User currentUser = core_SoqlUtils.getLoggedInUser();

		if(currentUser.Id == incident.Adult_On_Duty__r.Individual__r.User__r.Id)
			return 'Adult_on_Duty';
		else if(currentUser.Id == incident.Other_Adult_Involved_1__r.Individual__r.User__r.Id)
			return 'Adult1';
		else if(currentUser.Id == incident.Other_Adult_Involved_2__r.Individual__r.User__r.Id)
			return 'Adult2';
		else
			return 'Not Authorized';
	}

	/* Provides data to the form that sends emails. */
	private void populateIncidentEmailFields(){
		//I assume the email on the user record is the most correct, so I use that versus the contact/provided email.
		if(incident.Adult_on_Duty__c != null)
			incident.Adult_on_Duty_Email__c = core_SoqlUtils.getStaffDetails(incident.Adult_on_Duty__c).Staff_Email__c;

		if(incident.Other_Adult_Involved_1__c != null)
			incident.Other_Adult_Involved_1_Email__c = core_SoqlUtils.getStaffDetails(incident.Other_Adult_Involved_1__c).Staff_Email__c;

		if(incident.Other_Adult_Involved_2__c != null)
			incident.Other_Adult_Involved_2_Email__c = core_SoqlUtils.getStaffDetails(incident.Other_Adult_Involved_2__c).Staff_Email__c;

		if(incident.Adult_on_Duty_Email__c == null)
			incident.Adult_On_Duty_Email__c = '';
		if(incident.Other_Adult_Involved_1_Email__c == null)
			incident.Other_Adult_Involved_1_Email__c = '';
		if(incident.Other_Adult_Involved_2_Email__c == null)
			incident.Other_Adult_Involved_2_Email__c = '';
	}

	/* Fills out the picklist map used by the incident type, behavior category, and behavior type */
	private void preFillDropDowns() {
		picklistMap = new Map<String, Map<String, List<SelectOption>>>();

		//Get all Behavior Types for sorting.
		String biTypeRecordId = picklistRTMap.get('Behavior_Type');
		List <Picklist_Value__c> behaviorTypeList = core_SoqlUtils.getPlValuesListByRecordType(biTypeRecordId,firstStudentSetup);

		String[] cats = new String[]{};
		//This does the actual work. It takes all incident types and builds a map
		//of the categorys to the behavior types for it.
		for(String recordType: behRTMap.keySet()) {
			Map<String, List<SelectOption>> catToBehMap = new Map<String, List<SelectOption>>();
			//iterate over set of Behavior types
			for(Picklist_Value__c bt: behaviorTypeList) {
				behaviorIncidentTypeMap.put(bt.Id, bt);
				//split the behavior cats, because its a multi select
				if(bt.Behavior_Incident_Level__c == recordType && bt.Behavior_Category__c != null) {
					cats.clear();
					if(bt.Behavior_Category__c.contains(';'))
						cats = bt.Behavior_Category__c.split(';');
					else
						cats.add(bt.Behavior_Category__c);

					//now add the behavior type to each cat.
					for (String cat: cats) {
						if (catToBehMap.containsKey(cat))
							catToBehMap.get(cat).add(new SelectOption(bt.Id, bt.Name));
						else
							catToBehMap.put(cat, new List<SelectOption>{new SelectOption(bt.Id, bt.Name)});
					}
				}
			}
			//relate each map of cats to a incident type
			if(!catToBehMap.isEmpty()){
				picklistMap.put(recordType, catToBehMap);
			}
		}
	}

	/* Find a student in the student wrapper and remove them */
	private cStudentWrapper findAndRemoveStudentWrapperById(string student){
		integer location = findStudentWrapperPosition(student);
		if(location == -1)
			return null;
		else
			return stuWrapperList.remove(location);
	}

	/* Find a students location in the student wrapper list. */
	private Integer findStudentWrapperPosition(string student){
		if (stuWrapperList==null || stuWrapperList.isEmpty())
			return -1;

		integer i = 0;
		boolean found = false;
		for (cStudentWrapper swrap: stuWrapperList){
			if (swrap.id == student)
				return i;
			else
				i++;
		}

		return -1;
	}

	/* Borrowed from the homework controller Teheheh :) */
	private List<SelectOption> sortList(List<SelectOption> orig){
		if(orig.size() <= 1){
			return orig;
		}
		List<SelectOption> left = new List<SelectOption>();
		List<SelectOption> right = new List<SelectOption>();
		List<SelectOption> result = new List<SelectOption>();
		integer mid = orig.size()/2;

		for(integer i=0;i<mid;i++) {
			left.add(orig[i]);
		}
		for(integer i=mid;i<orig.size();i++) {
			right.add(orig[i]);
		}

		left = sortList(left);
		right = sortList(right);
		result = mergeSort(left, right);
		return result;
	}

	private List<SelectOption> mergeSort(List<SelectOption> left, List<SelectOption> right){
		List<SelectOption> result = new List<SelectOption>();
		while(left.size() > 0 || right.size() > 0){
			if(left.size() > 0 && right.size() > 0){
				if(left[0].getLabel() < right[0].getLabel()){
					result.add(left.remove(0));
				} else {
					result.add(right.remove(0));
				}
			} else if(left.size() > 0) {
				result.add(left.remove(0));
			} else if(right.size() > 0) {
				result.add(right.remove(0));
			}
		}
		return result;
	}

	private void setStatus(){
		string status = '';
		if(bHasBeenSavedAsDraft == true){
			status = 'Draft';
		} else if(incident.Request_Info_AoD__c || incident.Request_Info_Adult1__c || incident.Request_Info_Adult2__c){
			status = 'Awaiting Add\'l Info';
		} else {
			for(cStudentWrapper sw: stuWrapperList){
				if(sw.notify){
					status = 'Awaiting Admin Decision';
					break;
				}
			}
		}

		//If none of the other statuses are needed, close the incident
		if(status == ''){
			status = 'Closed';
		}
		incident.Incident_Status__c = status;
	}

	private void addStudent(Student__c student){
		if(studentsAdded.contains(student.id)){
			errorMessage('Student ' + student.Name + ' is already on the incident.');
			return;
		} else {
			studentsAdded.add(student.id);
		}

		List<SelectOption> consequenceOptions = new List<SelectOption>();
		if(student.Setup__c == null){
			consequenceOptions = masterConsequenceSelect.get(baseObj.activeSetup.id).get(incident.Incident_Type__c);
		} else {
			if(masterConsequenceSelect.containsKey(student.Setup__c)){
				consequenceOptions = masterConsequenceSelect.get(student.Setup__c).get(incident.Incident_Type__c);
			} else {
				consequenceOptions = addConsequenceSetup(student.Setup__c, incident.Incident_Type__c);
			}
		}

		if(stuWrapperList.isEmpty()){
			firstStudentSetup = student.Setup__c;
			firstStudent = student.id;
			preFillDropDowns();
			changeIncidentType();
		}

		stuWrapperList.add(new cStudentWrapper(uniqueStudentID(), student, consequenceOptions));
	}

	private void addStudents(List<Student_Behavior__c> studentsInvolved, List<Consequence__c> consequences){
		Set<Id> studentIds = new Set<Id>();
		for (Student_Behavior__c sb: studentsInvolved) {
			if(studentsAdded.contains(sb.Student__c)){
				errorMessage('Student ' + sb.Student__r.Name + ' is already on the incident.');
				return;
			} else {
				studentsAdded.add(sb.Student__c);
				studentIds.add(sb.Student__c);
			}
		}

		Map<Id, Student__c> students = Behavior_SoqlUtils.getStudentsById(studentIds);
		if(stuWrapperList.isEmpty()){
			firstStudentSetup = students.values()[0].Setup__c;
			firstStudent = students.values()[0].id;
			preFillDropDowns();
			changeIncidentType();
		}
		for(Student_Behavior__c sb: studentsInvolved) {
			List<SelectOption> consequenceOptions = new List<SelectOption>();
			if(students.get(sb.Student__c).Setup__c == null){
				consequenceOptions = masterConsequenceSelect.get(baseObj.activeSetup.id).get(incident.Incident_Type__c);
			} else {
				if(masterConsequenceSelect.containsKey(students.get(sb.Student__c).Setup__c)){
					consequenceOptions = masterConsequenceSelect.get(students.get(sb.Student__c).Setup__c).get(incident.Incident_Type__c);
				} else {
					consequenceOptions = addConsequenceSetup(students.get(sb.Student__c).Setup__c, incident.Incident_Type__c);
				}
			}

			List<Consequence__c> stuCon = new List<Consequence__c>();
			boolean adminNotification = false;
			for (Consequence__c cn: consequences) {
				if (cn.Student__c == sb.Id){
					stuCon.add(cn);
					if(consequencePLMap.containsKey(cn.Picklist_Value__c) && consequencePLMap.get(cn.Picklist_Value__c).Notify_Admin__c){
						adminNotification = true;
					}
				}
			}
			stuWrapperList.add(new cStudentWrapper(uniqueStudentID(), sb, stuCon,consequenceOptions, students.get(sb.Student__c),adminNotification));
		}
	}

	/* Adds consequences for the provided setup. It does not check to see if they have been loaded already. */
	private List<SelectOption> addConsequenceSetup(Id setupId, string incidentType){
		String bcTypeRecordId = picklistRTMap.get('Behavior_Consequence');

		//This gets all possible behavior incident levels (avoids hard coding values)
		//Allows the addtion of behavior incident levels without updating the code
		Schema.DescribeFieldResult fieldResult = Picklist_Value__c.Behavior_Incident_Level__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		List<SelectOption> consequenceOption = new List<SelectOption>();
		Map<String, List<PickList_Value__c>> consequencesMap = new Map<String, List<PickList_Value__c>>();
		Map<String, List<SelectOption>> selectOptionMap = new Map<String, List<SelectOption>>();

		for(Picklist_Value__c pl: Behavior_SoqlUtils.getPlValuesListByRecordType(bcTypeRecordId, setupId)){
			consequencesValues.add(pl);
			consequencePlMap.put(pl.id, pl);

			//Fallback for bad data, if picklist incident fields are not filled out, add it for everything.
			if(pl.Behavior_Incident_Level__c == null || pl.Behavior_Incident_Level__c == ''){
				for(Schema.PicklistEntry s: ple){
					if (consequencesMap.containsKey(s.value)){
						consequencesMap.get(s.value).add(pl);
						selectOptionMap.get(s.value).add(new SelectOption(pl.id, pl.Name));
					}else{
						consequencesMap.put(s.value, new List<Picklist_Value__c>{pl});
						selectOptionMap.put(s.value, new List<SelectOption>{new SelectOption(pl.id, pl.Name)});
					}
				}
			} else if(consequencesMap.containsKey(pl.Behavior_Incident_Level__c)) {
				consequencesMap.get(pl.Behavior_Incident_Level__c).add(pl);
				selectOptionMap.get(pl.Behavior_Incident_Level__c).add(new SelectOption(pl.id, pl.Name));
			} else {
				consequencesMap.put(pl.Behavior_Incident_Level__c, new List<Picklist_Value__c>{pl});
				selectOptionMap.put(pl.Behavior_Incident_Level__c, new List<SelectOption>{new SelectOption(pl.id, pl.Name)});
			}
		}

		masterConsequenceMap.put(setupId, consequencesMap);
		masterConsequenceSelect.put(setupId, selectOptionMap);
		return selectOptionMap.get(incidentType);
	}

	/* Creates a unique id for the wrapper objects so they can be identified
		on the page without requiring a salesforce id */
	private string uniqueStudentId() {
		totalStudents++;
		return totalStudents.format();
	}

	/*WRAPPER CLASSES */
	/* Student wrapper class */
	public class cStudentWrapper {
		public String id								{get;set;}
		public Student_Behavior__c sb					{get;set;}
		public Student__c student						{get;set;}
		public List<cConsequenceWrapper> conList		{get;set;}
		public Consequence__c suspension				{get;set;}
		public boolean hasSuspension					{get;set;}
		public boolean notify							{get;set;}
		public List<SelectOption> consequenceOptions	{get;set;}
		private Integer totalCons = 0;

		public cStudentWrapper() {
			sb = new Student_Behavior__c();
			student = new Student__c();
			conList = new List<cConsequenceWrapper>();
			suspension = new Consequence__c();
			consequenceOptions = new List<SelectOption>();
			hasSuspension = false;
			notify = false;
		}

		public cStudentWrapper(string identifer, Student__c stu, List<SelectOption> conOps){
			this();
			id = identifer;
			student = stu;
			sb.Student__c = stu.id;
			sb.Contact__c = stu.Individual__c;
			sb.Incident_Role__c = 'Instigator';
			consequenceOptions = conOps;
		}

		public cStudentWrapper(String identifier, Student_Behavior__c studentbehavior, List<Consequence__c> consequenceList, List<SelectOption> conOps, Student__c stu, boolean notifyAdmin) {
			id = identifier;
			student = stu;
			sb = studentbehavior;
			hasSuspension = false;
			suspension = new Consequence__c();
			notify = notifyAdmin;
			consequenceOptions = conOps;

			conlist = new List<cConsequenceWrapper>();
			for(Consequence__c con: consequenceList){
				if(con.is_Suspended__c == 'Yes') {
					suspension = con;
					hasSuspension = true;
				}
				conList.add(new cConsequenceWrapper(uniqueConId(), con));
			}
		}

		public void addCon(Consequence__c defaultCon, boolean notifyAdmin) {
			conList.add(new cConsequenceWrapper(uniqueConId(), defaultCon));
			notify = notifyAdmin;
		}

		public String uniqueConId() {
			totalCons++;
			return totalCons.format();
		}
	}

	/* Consequence wrapper class */
	public class cConsequenceWrapper {
		public String id				{get;set;}
		public Consequence__c con		{get;set;}
		public double conWeight			{get;set;}

		public cConsequenceWrapper(){
			id = '';
			con = new Consequence__c();
		}

		public cConsequenceWrapper(String identifier, Consequence__c consequence){
			id = identifier;
			con = consequence;
		}
	}

	/* Search Wrapper Class */
	public class searchWrapper{
		public Student__c student	{get;set;}
		public boolean	selected	{get;set;}

		public searchWrapper(Student__c stud){
			student = stud;
			selected = false;
		}
	}
}