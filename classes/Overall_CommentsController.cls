global with sharing class Overall_CommentsController {
	public static List<scheduleGroupWrapper> displayWrapper	{get;set;}
	private static List<Student__c> studentList;

	public Overall_CommentsController(){
		try{
			ID userID = userInfo.getUserID();
			displayWrapper = new List<scheduleGroupWrapper>();
			Set<ID> sectionSet = new Set<ID>();
			system.debug('Userid ' + userID);
			
			for(Staff_Section__c ss : [Select ID, Section__c 
							from Staff_Section__c 
							where Staff__r.Individual__r.User__r.ID = :userID 
							AND Display_Teacher_On_RC_PR__c = true
							AND Section__r.RecordType.DeveloperName = 'Published']){
				sectionSet.add(ss.Section__c);
			}
			Set<ID> studentSet = new Set<ID>();
			for(Student_Section__c ss : [Select ID, Student__c
							from Student_Section__c 
							where Active__c = true 
							AND Section__c IN :sectionSet]){
				studentSet.add(ss.Student__c);
			}
			
			string currentGroup = '';
			scheduleGroupWrapper singleGroup;
			for(Student__c s:[select id, Name, Home_Language__c, Primary_Schedule_Group__c,
								Alternate_Lang_Comments__c, Comments__c, Primary_Schedule_Group__r.Name
							from Student__c
							where id IN: studentSet
							and Primary_Schedule_Group__c != null
							order by Primary_Schedule_Group__c]){
				if(singleGroup == null || s.Primary_Schedule_Group__c != singleGroup.id){
					if(singleGroup != null){
						displayWrapper.add(singleGroup);
					}
					singleGroup = new scheduleGroupWrapper(s.Primary_Schedule_Group__c, s.Primary_Schedule_Group__r.Name);
				}
				singleGroup.students.add(s);
			}
			displayWrapper.add(singleGroup);
		}catch(Exception e){
            Apexpages.addMessage(new apexpages.message(apexpages.severity.ERROR,'There was an error while loading students. Please try again, or contact your administrator.'));
        }
	}
	
	@RemoteAction
	global static String updateComments(Map<Id, String> oaCommentsMap, Map<Id, String> oaAltCommentsMap){
		try{
			List<Student__c> toUpdate = new List<Student__c>();
			for(Student__c s:[select id, Comments__c, Alternate_Lang_Comments__c from Student__c where (ID IN: oaCommentsMap.keyset() OR ID IN:oaAltCommentsMap.keySet())]){
				if(oaCommentsMap.containskey(s.id)){
					s.Comments__c = oaCommentsMap.get(s.id);
				}
				if(oaAltCommentsMap.containsKey(s.id)){
					s.Alternate_Lang_Comments__c = oaAltCommentsMap.get(s.id);
				}
				toUpdate.add(s);
			}
			update toUpdate;
			return 'success';
		}catch(Exception e){
			return 'failed';
		}
	}
	
	global class scheduleGroupWrapper{
		public string scheduleGroupName 	{get;set;}
		public string id					{get;set;}
		public List<Student__c> students	{get;set;}
		
		public scheduleGroupWrapper(string sgID, string sgName){
			this.id = sgID;
			this.scheduleGroupName = sgName;
			this.students = new List<Student__c>();
		}
	}
	
	static testMethod void testOverallComments(){
		testDataSetupUtil_v2.setUPCoreData(2);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setUpStudentData(5);

		Section__c scheduleGroup = testDataSetupUtil_v2.getSection(core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group'), 'ScheduleGroup', null, testDataSetupUtil_v2.masterYear.id, null);
		insert scheduleGroup;

		for(Student__c s:testDataSetupUtil_v2.studentsList){
			s.Primary_Schedule_Group__c = scheduleGroup.id;
		}
		update testDataSetupUtil_v2.studentsList;
		Test.startTest();
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
		//first make sure that staff sections come back that have the box checked that needs to be
			list<Staff_Section__c> toSet = new List<Staff_Section__c>();
			ID userID = userInfo.getUserID();
			//KCC: 4/7/13: Why is this even here?
			for(Staff_Section__c ss : [Select ID, Section__r.ID from Staff_Section__c where Staff__r.Individual__r.User__r.ID = :userID AND Display_Teacher_On_RC_PR__c = true AND Section__r.RecordType.DeveloperName = 'Published']){
				ss.Display_Teacher_On_RC_PR__c = true;
				toSet.add(ss);
			}
			update toSet;
			Overall_CommentsController occ = new Overall_CommentsController();
		//now we need to make some comments to send to the remoting call
			Student__c ss = [Select Name, Alternate_Lang_Comments__c, Home_Language__c, ID, Comments__c from Student__c where ID = :testDataSetupUtil_v2.studentsList[0].id];
			
			Map<Id, String> oaCommentsMap = new Map<Id, String>();
			oaCommentsMap.put(ss.id, 'This is a comment');
		//we can test both alt and regular in one call
			String result = Overall_CommentsController.updateComments(oaCommentsMap, oaCommentsMap);
		}
		Test.stopTest();
	}
}