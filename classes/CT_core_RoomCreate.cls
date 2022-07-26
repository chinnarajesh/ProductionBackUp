public with sharing  class CT_core_RoomCreate {
	   
	public cRoom 				initRoom 		{get;set;}
	public CT_core_SetupWrapper	cSetup 			{get;set;}
	public List<string> 		errorMessage;
	public Id 					schoolId;
	public Set <String> 		existingRoomSet;
	public List<Room__c>	 	currentRooms	{get;set;}
	public string				setupId 		{get;set;}
	public integer				iMaxRooms 		{get;set;} //US609
	public boolean				bEdit 				{get;set;}// Shows/Hides the Individual room  entry section
	public boolean				bRange				{get;set;}// Shows/Hides the Range entry section
	public string 				selectedRoomId	{get;set;} //
	
	
	public CT_core_RoomCreate(){
		try{
			if (System.currentPageReference().getParameters().containsKey('setupid')) setupId = System.currentPageReference().getParameters().get('setupid');
			if (setupId!=null){
				cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'room');
				initRoom = new cRoom(cSetup.school);
				bEdit = false; 
				bRange = false; 
				reQueryRooms();
				if(CT_SetupWizard_Utils.checkRooms(cSetup.setup)){
					CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'At least one room must be created before moving on to the next step.');
				}
			}
			iMaxRooms = 100;
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred during initialization.'));
		}  
	}
	
	public void editRoom(){
		initRoom.room = [Select id, Name, Reference_Id__c, Number__c, Usable__c, Size__c, School__c, Schedulable__c, Description__c, Room_type__c, Has_a_lab__c 
							From Room__c r
							Where id =:selectedRoomId];
		bEdit = true;
	}
	
	public void newRoom(){
		initRoom = new cRoom(cSetup.school);
		bEdit = true;
	}
	
	public void saveRoom(){
		errorMessage =new List <String>();
		if(validateRoom(initRoom.room)){
			upsert initRoom.room;
			bEdit = false;
		}
		showErrorMessages();
	}
	
	public void cancelRoom(){
		bEdit = false;
	}
	
	public void showRange(){
		bRange = true;
	}
	
	public void cancelRange(){
		bRange = false;
	}
	
	public void reQueryRooms(){
		currentRooms = new List <Room__c>();
		existingRoomSet = new Set <String>();
		
		for (Room__c r : [Select r.Reference_Id__c, r.Number__c, r.Usable__c, r.SystemModstamp, r.Size__c, r.School__c, r.Schedulable__c, r.Name, r.LastModifiedDate, r.LastModifiedById, r.LastActivityDate, r.IsDeleted, r.Id, r.Description__c, r.CreatedDate, r.CreatedById, r.Room_type__c, r.Has_a_lab__c 
							From Room__c r
							Where school__c =:cSetup.school.id] ){
			currentRooms.add(r);
			existingRoomSet.add(r.Name.toLowerCase());
		}
	}
	
	public void createRooms(){
		try{
			errorMessage =new List <String>();
			List <Room__c> insRoomRange = new List <Room__c>();
			if (initRoom.startNumber< initRoom.endNumber){
				if((initRoom.endNumber-initRoom.startNumber)<iMaxRooms){
					for (Integer i=initRoom.startNumber; i<= initRoom.endNumber;i += initRoom.increment){
						Room__c newRoom = initRoom.room.clone();
						newRoom.number__c = i;
						newRoom.name=string.valueOf(i);
						if (initRoom.prefix!=null&&initRoom.prefix!='') newRoom.name=initRoom.prefix+newRoom.name;
						if (initRoom.suffix!=null&&initRoom.suffix!='') newRoom.name=newRoom.name+initRoom.suffix;
						newRoom.Schedulable__c = initRoom.room.Schedulable__c;
						if(newRoom.Name == null){
							newRoom.Name = String.valueOf(newRoom.Name);
						}
						validateRoom(newRoom);
						insRoomRange.add( newroom );
					}
					if (errorMessage.isEmpty()){
						try {
							upsert insRoomRange Reference_Id__c;
							reQueryRooms();
							ApexPages.addMessage(new apexpages.message(apexpages.severity.confirm, insRoomRange.size()+' rooms created.'));
							bRange = false;
						}
						catch (exception e){
							errorMessage.add(e.getMessage());
						}
					}
				}
				else{
					errorMessage.add('Please create less than ' + iMaxRooms + ' rooms at one time.'); //If # is greater than max allowed throw an error US 609
				}
			}
			else {
				errorMessage.add('End room number cannot be less than start room number.  Please change end room number to be greater than '+initRoom.startNumber+'.'); 
			}
			showErrorMessages();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An unexpected error occurred while creating rooms.'));
			//Global_Error__c ge = Error_Handling.handleError('School, '+cSetup.school.id, 'Core (Room Config)', 'error creating rooms', e);
		//	insert ge;
			bRange = true;
		}   
	}
	
	public boolean validateRoom(Room__c room){
		boolean bNeedsValidate = true;
		if(room.Reference_Id__c!=null){
			String oldName = room.Reference_Id__c.split('-')[1];
			if(oldName==room.Name) bNeedsValidate = false;
		}
		if(bNeedsValidate){
			if (existingRoomSet.contains(room.Name.toLowerCase())){
				errorMessage.add('Room '+room.name+' aleady exists in this school. Please change either the prefix, suffix, or range of numbers to create additional rooms.');
				return false;
			}
			else room.reference_Id__c = cSetup.school.name+'-'+room.name;
		}
		return true;
	}
	
	public void showErrorMessages() {
		try{
			if (!errorMessage.isEmpty()){
				for (String s: errorMessage){
					ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, s));
				}
			}
			else reQueryRooms();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while reloading the page'));
			Global_Error__c ge = CT_Error_Handling.handleError('School, '+cSetup.school.id, 'Core (Room Config)', 'error during initialization', e);
			insert ge;
		}
	}
	
	public PageReference prev(){
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.COURSE_CATALOG,false,cSetup.setup);
	}
	
	public PageReference next(){
		if(!CT_SetupWizard_Utils.checkRooms(cSetup.setup)) return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.STAFF,true,cSetup.setup);
		else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'At least one room must be created before moving on to the next step.');
			return null;
		}
	}
		
	public class cRoom {
		public integer startNumber {get;set;}
		public integer endNumber {get;set;}
		public integer increment {get;set;}
		public string	prefix		{get;set;}
		public string	suffix		{get;set;}
		public Room__c room	{get;set;}
		
		
		public cRoom(Account school){
			startNumber = 101;
			endNumber 	=150;
			increment = 1;
			room = new Room__c(school__c= school.id);
		}
	}
	
	static testMethod void test_core_RoomCreate(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		PageReference pr = new PageReference('/apex/CT_core_RoomCreate?setupId='+testDataSetupUtil_v2.activeSetUp.id);
		test.setCurrentPage(pr);
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			CT_core_RoomCreate crc = new CT_core_RoomCreate();
			crc.newRoom();
			crc.initRoom.room.Number__c = 1239;
			//build breaker: forced validation of using name as the key. So all rooms must have a name.
			crc.initRoom.room.Name = 'testRoom';
			crc.initRoom.room.Schedulable__c = true;
			crc.saveRoom(); //creates 1 rooms, but there are already 5 with testDataSetup
			system.assertEquals(6, crc.currentRooms.size()); 
			crc.newRoom();
			crc.cancelRoom();
			crc.showRange();
			crc.cancelRange();
			crc.showRange();
			crc.createRooms();//will create 50 rooms
				system.assertEquals(56, crc.currentRooms.size());
				//crc.next();
				crc.prev();
		}
	}

}