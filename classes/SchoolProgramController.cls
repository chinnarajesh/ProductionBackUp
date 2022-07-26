/******************************************************************************************************************
*   Copyright ©2012 Acumen Solutions, Inc. All Rights Reserved.  This software and source code is proprietary to Acumen Solutions, Inc. ("Acumen") and is protected by copyright and other intellectual property laws.  
*   This source code may only be used by an authorized licensee of Acumen and may only be used by such licensee in accordance with the terms and conditions of an executed license agreement between such licensee
*   and Acumen (the "License Agreement").  This source code may not be reproduced, published, or disclosed to others except as provided in the License Agreement.  
* 
* Description: Controller for Student to Program page
* Author: Nick Perna
* Date: 7/16/2012
*
*******************************************************************************************************************/
public with sharing class SchoolProgramController {
	

	public Id selectedSchool{get;set;}
	public Boolean hasUnsavedChanges{get;set;}
	
	public List<Account> schools{get; private set;}
	public List<Program__c> requiredPrograms{get; private set;}
	public List<Program__c> optionalPrograms{get; private set;}
	public Program__c newProgram	{get;set;} 
	public List<String> sites{get; set;}
	public List<Indicator_Area__c> areas{get; private set;}
	public String activeIAId {get; public set;}
	public String activeSite {get; public set;}
	public String checkProgramId {get;set;}
	
	public Set<Account_Program__c> changes;
	public Set<Account_Program__c> removals;
	public List<ProgramWrapper> needsReasons{get;set;}
	
	public List<ProgramWrapper> requiredProgramsDisplay{get; private set;}
	public List<ProgramWrapper> optionalProgramsDisplay{get; private set;}
	public List<SchoolWrapper> SchoolsDisplay{get; private set;}
	
	public Map<Id, Boolean> connectionIrremovable{get;set;}
	
	public Map<Id,Map<Id,Account_Program__c>> SchoolToProgramMap;
		
	private Map<Id, Account> schoolMap;
	private Map<Id, SchoolWrapper> SchoolWrapperMap;
	private Map<Id, Program__c> requiredProgramMap;
	private Map<Id, Program__c> optionalProgramMap;
	public boolean valid{get;set;}
	public boolean bProgram	{get;set;}

	
	/*
	* Author:			Nick Perna
	* Name:				SchoolProgramController
	* Access:			Public
	* Description:		Constructor for controller
	* Param:			NONE
	*/
	public SchoolProgramController(){
		changes = new Set<Account_Program__c>();
		removals = new Set<Account_Program__c>();
		needsReasons = new List<ProgramWrapper>();
		
		connectionIrremovable = new Map<Id,Boolean>();
		
		requiredProgramMap = new Map<Id, Program__c>();
		optionalProgramMap = new Map<Id, Program__c>();
		requiredProgramsDisplay = new List<ProgramWrapper>();
		optionalProgramsDisplay = new List<ProgramWrapper>();
		sites = new List<String>();
		areas = new List<Indicator_Area__c>();
		
		SchoolToProgramMap = new Map<Id,Map<Id,Account_Program__c>>(); 
		loadIndicatorArea();
		loadPrograms();
		schools = loadSchools();
		if(schools.size()==0){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'No schools are available for your user.'));
		}
		loadSections();
		hasUnsavedChanges = false;
		bProgram=false;
	}
	
	
	/*
	* Author:			Nick Perna
	* Name:				loadSchools
	* Access:			Public
	* Description:		Load active schools that users can add progams for
	* Param:			NONE
	* Return:			List<Account>		A list of schools
	*/
	public List<Account> loadSchools(){
		RecordType rt = [select id from RecordType where name = 'School' limit 1];
		
		String profileName = [SELECT Name FROM Profile WHERE Id=:UserInfo.getProfileId()].Name;
		List<Account> query = new List<Account>();
		if(SharingControls__c.getInstance('Site')!=null && profileName.contains(SharingControls__c.getInstance('Site').Profile_Name__c)) {
			User u = [Select Site__c FROM User where ID = :Userinfo.getUserId()];
			query = [Select Name, Site__c, 
					(select Program__c, Reason_for_Not_Participating__c, Active__c 
					from Accounts_Programs__r 
					where Program__r.Status__c = 'Approved'
					and Program__r.Active__c = true),
					(select id from Setup__r where Active__c = true)
				from Account 
				WHERE RecordTypeid=:rt.id AND Site__c=:u.Site__c
				ORDER BY Name ASC];
		} else {
			  query = [Select Name, Site__c, 
					(select Program__c, Reason_for_Not_Participating__c, Active__c 
					from Accounts_Programs__r 
					where Program__r.Status__c = 'Approved'
					and Program__r.Active__c = true),
					(select id from Setup__r where Active__c = true)
				from Account 
				where RecordTypeid=:rt.id 
				ORDER BY Name ASC];
		}
		schoolMap = new Map<Id, Account>();
		SchoolsDisplay = new List<SchoolWrapper>();
		schoolWrapperMap = new Map<Id, SchoolWrapper>();
		Set<String> schoolSites = new set<String>();
		for(Account a : query){
			if(a.Setup__r.size()>0){
				SchoolToProgramMap.put(a.id,new Map<Id,Account_Program__c>());
				SchoolWrapper temp = new SchoolWrapper(a.id,a.name,a.Site__c,'Grades Served',a.Accounts_Programs__r);
				SchoolsDisplay.add(temp);
				schoolWrapperMap.put(a.id,temp);
				schoolMap.put(a.id, a);
				schoolSites.add(a.site__c);
			}
		}
		sites.addAll(schoolsites);
		sites.sort();
		return query;
	}
	/*
	* Author:			Nick Perna
	* Name:				LoadSections
	* Access:			Public
	* Description:		Loads already active account/program connections
	* Param:			NONE
	* Return:			Void
	*/
	public void LoadSections(){
		List<Account_Program__c> connections = [select id, Active__c, (select Active__c from Sections__r where Active__c=true limit 1) from Account_Program__c];
		
		for(Account_Program__c connection : connections){
			connectionIrremovable.put(connection.id, connection.Sections__r.size()>0);
		}
	}
	/*
	* Author:			Nick Perna
	* Name:				loadPrograms
	* Access:			Public
	* Description:		Loads required and optional programs that are available
	* Param:			NONE
	* Return:			NONE
	*/
	public void loadPrograms(){
		List<Program__c> query = [Select name, Indicator_Area__r.name, Required_Program__c from Program__c  where Active__c=true and Status__c = 'Approved'];
		requiredPrograms = new List<Program__c>();
		requiredProgramsDisplay = new List<ProgramWrapper>();
		optionalPrograms = new List<Program__c>();
		optionalProgramsDisplay = new List<ProgramWrapper>();
		
		for(Program__c p : query){
			ProgramWrapper prog =new ProgramWrapper(p.id,p.name ,false, 'none', p.Indicator_Area__r.name,  false);
			if(p.Required_Program__c){
				system.debug('~~~~~ required program: '+prog);
				requiredPrograms.add(p);
				requiredProgramsDisplay.add(prog);
				requiredProgramMap.put(p.id, p);
			} else {
				system.debug('~~~~~ optional program: '+prog);
				optionalPrograms.add(p);
				optionalProgramsDisplay.add(prog);
				optionalProgramMap.put(p.id, p);
			}
		}
	}
	/*
	* Author:			Nick Perna
	* Name:				loadIndicatorArea
	* Access:			Public
	* Description:		Loads indicator areas that will be used for the filtering of programs
	* Param:			NONE
	* Return:			Void
	*/
	public void loadIndicatorArea(){
		//US3510
		List<Indicator_Area__c> query = [select name from Indicator_Area__c WHERE Active__c = TRUE order by name asc limit 40000];
		for(Indicator_Area__c i : query){
			areas.add(i);
		}
	}
	
	public List<SelectOption> getAreaOptions(){
		List<SelectOption> ias = new List<SelectOption>();
		for(Indicator_Area__c a: areas)
			ias.add(new SelectOption(a.id,a.Name));
		return ias;
	}
	
	/*
	* Author:			Liz Ellis
	* Name:				createProgram
	* Access:			Public
	* Description:		Allows the user to create a new program
	* Param:			NONE
	* Return:			Void
	*/
	public void createProgram(){
		newProgram = new Program__c(Active__c=true);
		bProgram=true;
	}
	
	/*
	* Author:			Liz Ellis
	* Name:				createProgram
	* Access:			Public
	* Description:		Allows the user to create a new program
	* Param:			NONE
	* Return:			Void
	*/
	public void saveProgram(){
		//TODO: add necessary validations
		insert newProgram;
		loadPrograms();
		schools = loadSchools();
		bProgram=false;
	}
	
	/*
	* Author:			Liz Ellis
	* Name:				createProgram
	* Access:			Public
	* Description:		Allows the user to create a new program
	* Param:			NONE
	* Return:			Void
	*/
	public void cancelProgram(){
		system.debug('~~~~~ cancel program');
		bProgram=false;
	}
	
	/*
	* Author:			Nick Perna
	* Name:				selectSchool
	* Access:			Public
	* Description:		Tells the page what programs the school is already attached to when they are selected
	* Param:			NONE
	* Return:			Void
	*/
	public void selectSchool(){
		for (ProgramWrapper p : requiredProgramsDisplay){
			SchoolWrapper temp = schoolwrappermap.get(selectedSchool);
			if(temp.programs.get(p.id)==null){
				temp.programs.put(p.id, connect(selectedSchool, p, false));
			}
			if(connectionIrremovable.get(temp.programs.get(p.id).id)!=null){
				p.irremovable = connectionIrremovable.get(temp.programs.get(p.id).id);
			}else{
				p.irremovable = false;
			}
				if(temp.programsEnrolled == 0) {
					p.checked = true;
				} else {
					p.checked = temp.programs.get(p.id).Active__c;
				}
		}
		
		for (ProgramWrapper p : optionalProgramsDisplay){
			SchoolWrapper temp = schoolwrappermap.get(selectedSchool);
			if(temp.programs.get(p.id)==null){
				temp.programs.put(p.id, connect(selectedSchool, p, false));
			}
			if(connectionIrremovable.get(temp.programs.get(p.id).id)!=null){
				p.irremovable=connectionIrremovable.get(temp.programs.get(p.id).id);
			}
			else{
				p.irremovable=false;
			}
			p.checked = temp.programs.get(p.id).Active__c;

		}
	}		
	/*
	* Author:			Nick Perna
	* Name:				connect
	* Access:			Public
	* Description:		Connects an program to a school
	* Param:			Id school					ID of the school to attatch program to
	* Param:			ProgramWrapper prog			Program wrapper of selected program
	* Param:			Boolean Required			True means attaching a required program
	* Return:			Account_Program__c			Returns the upserted Account Program
	*/	
	public Account_Program__c connect(Id school, ProgramWrapper prog, Boolean Required){
		Account_Program__c connection = new Account_Program__c();
		connection.Active__c = false;
		connection.School__c = school;
		connection.Program__c = prog.id;
		connection.Name = prog.name;
		connection.Reason_for_Not_Participating__c = '';
		
		return connection;
	}
	/*
	* Author:			Nick Perna
	* Name:				readyExclusionReasons
	* Access:			Public
	* Description:		When updating and not selected all required reason, populate exclusion reasons if they exist
	* Param:			NONE
	* Return:			void
	*/
	public void readyExclusionReasons(){
		if(selectedSchool==null){
			ApexPages.addMessage(new ApexPages.Message(apexpages.severity.error,'No school selected.'));
			return;
		}
		needsReasons = new List<ProgramWrapper>();
		
		SchoolWrapper temp = schoolwrappermap.get(selectedSchool);
		for(ProgramWrapper p : requiredProgramsDisplay){
			if(!p.checked){
					p.exclusionReason = temp.programs.get(p.id).Reason_for_Not_Participating__c;
					needsReasons.add(p);
			}
		}
	}
	
	/*
	* Author:			Nick Perna
	* Name:				validateReasons
	* Access:			Public
	* Description:		Verify that all exclusion reasons are filled for non selected required programs
	* Param:			NONE
	* Return:			void
	*/
	public void validateReasons(){
		valid= true;
		for(ProgramWrapper p : needsReasons){
			if(p.exclusionReason.equals('')) valid= false;
		}
		
		if(!valid){
			ApexPages.addMessage(new ApexPages.Message(apexpages.severity.error,'Please enter reasons for excluding required programs.'));
		}
	}
	
	public void checkIfRemovable(){
		for(ProgramWrapper p: requiredProgramsDisplay){
			if(p.id==checkProgramId && p.irremovable){
				ApexPages.addMessage(new ApexPages.Message(apexpages.severity.error, p.name+' Program has active sections in '+schoolMap.get(selectedSchool).Name+'. Cannot be removed.'));
				p.checked=true;
			}
		}
		for(ProgramWrapper p: optionalProgramsDisplay){
			if(p.id==checkProgramId && p.irremovable){
				ApexPages.addMessage(new ApexPages.Message(apexpages.severity.error, p.name+' Program has active sections in '+schoolMap.get(selectedSchool).Name+'. Cannot be removed.'));
				p.checked=true;
			}
		}
	}
	
	/*
	* Author:			Nick Perna
	* Name:				updateSchool
	* Access:			Public
	* Description:		Updates the connections of the school with selected/deselected accounts
	* Param:			NONE
	* Return:			void
	*/
	public void updateSchool(){
		SchoolWrapper temp = schoolwrappermap.get(selectedSchool);
		for(ProgramWrapper p : requiredProgramsDisplay){
			Account_Program__c connection = temp.programs.get(p.id);
			if(connection.Active__c != p.checked){
				connection.Active__c = !connection.Active__c;
				if(connection.Reason_for_Not_Participating__c != null && connection.Active__c){
					connection.Reason_for_Not_Participating__c = null;
				}
				changes.add(connection);
				
				if(!connection.Active__c){
					temp.programsEnrolled--;
				}
				else{
					temp.programsEnrolled++;
				}
				
			}
			if(!connection.Active__c){
				if(connection.Reason_for_Not_Participating__c != p.exclusionReason) {
					connection.Reason_for_Not_Participating__c = p.exclusionReason;
					changes.add(connection);
				}
			}
		}
		
		for(ProgramWrapper p : optionalProgramsDisplay){
			Account_Program__c connection = temp.programs.get(p.id);
			if(!connection.Active__c && p.checked){
				connection.Active__c = p.checked;
				changes.add(connection);
				temp.programsEnrolled++;
			}
			else if(connection.Active__c  && !p.checked){
				connection.Active__c = p.checked;
				temp.programsEnrolled--;
				changes.add(connection);
			}
		}
		hasUnsavedChanges =true;
	}
	/*
	* Author:			Nick Perna
	* Name:				saveChanges
	* Access:			Public
	* Description:		Saves the account progtrams
	* Param:			NONE
	* Return:			void
	*/
	public void saveChanges(){
		list<Account_Program__c> ChangesList = new List<Account_Program__c>(changes);
		
		upsert changesList;
		changes = new Set<Account_Program__c>();
		
		hasUnsavedChanges = false;
		for(ProgramWrapper p: requiredProgramsDisplay) p.checked=false;
		for(ProgramWrapper p: optionalProgramsDisplay) p.checked=false;
		ApexPages.addMessage(new apexpages.message(apexpages.severity.confirm,'Your changes have been saved.'));
	}
	
	
	/*
	* Author:			Nick Perna
	* Name:				resetPage
	* Access:			Public
	* Description:		Resets the page so you can add more connetions
	* Param:			NONE
	* Return:			PageReference			Pagereference of the current, refreshed page
	*/
	public PageReference resetPage(){
		PageReference returnPage = new PageReference('/apex/IM_AddSchoolsToPrograms');
		returnPage.setRedirect(true);
		return returnPage;
	}
	
	public class SchoolWrapper{
		public Id id{get; private set;}
		public String name{get; private set;}
		public String site{get; private set;}
		public String gradesServed{get; private set;}
		public Integer programsEnrolled{get; private set;}
		public map<Id, Account_Program__c> programs{get; set;}
		public boolean selected;
				
		public SchoolWrapper(Id id, String name, String site, String gradesServed, List<Account_Program__c> programs){
			selected = false;
			this.id = id;
			this.name = name;
			this.site = site;
			this.gradesServed = gradesServed;
			this.programs = new map<Id, Account_Program__c>();
			programsEnrolled =0;
			for (Account_Program__c p : programs){	
				if(p.Active__c){
					++programsEnrolled;
				}			
				this.programs.put(p.Program__c,p);
			}
		}
	}
	
	public class ProgramWrapper{
		public String id{get; private set;}
		public String name{get; private set;}
		public Boolean checked;
		public String exclusionReason{get; set;}
		public String indicatorArea{get;set;}
		public Boolean irremovable{get;set;}
		
		/*
		* Author:			Nick Perna
		* Name:				getChecked
		* Access:			Public
		* Description:		Checks if program is checked
		* Param:			NONE
		* Return:			Boolean			true if checked
		*/
		public Boolean getChecked(){
			return checked;
		}
		/*
		* Author:			Nick Perna
		* Name:				setChecked
		* Access:			Public
		* Description:		Sets the check on the program if it is selected
		* Param:			Boolean checked			True is checked, false not checked
		* Return:			Void
		*/
		public void setChecked(Boolean checked){
			if(!this.checked || !irremovable){
				this.checked = checked;
			}
		}
				
		public ProgramWrapper(String id, String name, Boolean checked, String ExclusionReason, String indicatorArea, Boolean irremovable){
			this.id = id;
			this.name = name;
			this.checked = checked;
			this.exclusionReason = exclusionReason;
			this.indicatorArea=indicatorArea;
			this.irremovable = irremovable;
		}
	}
}