public class Gradebook_ManageAssignments {
//called by trigger on Assignment Object, to process all records
public static void isBeforeInsert(List <Assignment__c> assignmentList){
	for (Assignment__c ass: assignmentList){
		if (!Test.isRunningTest()){
			if (ass.assignment_library__c == null) ass.assignment_library__c.addError ('Assignment Library must be populated;');
			if (ass.Picklist_Value__c ==null) 			ass.Picklist_Value__c.addError ('Grading Scale must be populated');
			if (ass.Section__c ==null) 			ass.Section__c.addError ('Section must be populated');
		}
	}
}
//using a isbeforeupdate method to validate if the new assignment picklist_value__c = 1-100 and 
//if the point_possible__c field is not null, then make that field null before updating
public static void isbeforeupdate(Map<ID, Assignment__c> newamap, Map<ID,Assignment__c> oldamap) {
	Set<ID> pointScaleIDs = new Set<ID>();
	Set<ID> zero100ScaleIDs = new Set<ID>();
	
	Map<ID, Time_Element__c> rpMap = getAllRP();
	
	Set <String> decimalGsCategories = new Set <String>{'0-100','Points'};
	for(Picklist_Value__c pv : [SELECT ID, category__c FROM Picklist_Value__c WHERE RecordType.DeveloperName = 'Grade_Scale' and Category__c in :decimalGsCategories ]) {
		if (pv.category__c=='0-100') zero100ScaleIDs.add(pv.ID);
		else pointScaleIDs.add(pv.Id);
	}
	Map <Id, Boolean> checkScaleChangeMap= new Map <Id, Boolean>();
	Set <Id>						hasGradePlChangeSet = new Set <Id>();
	
	for(Assignment__c a : newamap.values()) {
		
		//DE3597
		if(a.Due_Date__c != oldaMap.get(a.ID).Due_Date__c) {
			if(rpMap.containsKey(a.Time__c)) {
				Time_Element__c te = rpMap.get(a.Time__c);
				if(!(a.Due_Date__c >= te.Date_Start_Date__c && a.Due_Date__c <= te.End_Date__c)) {
					a.Due_Date__c.addError('The Due Date must be a date that is within the reporting period!');
				}
			}
		}
		
		if (a.assignment_library__c != oldaMap.get(a.id).assignment_library__c){
			a.assignment_library__c.addError('Changing the Assignment Library on an assignment is not allowed.  Please delete and recreate the assignment.');
		}
		if (a.Picklist_Value__c != oldaMap.get(a.id).Picklist_Value__c){
			ID gsId = newamap.get(a.ID).Picklist_Value__c;
			if (!zero100ScaleIDs.contains(gsId)&&!pointScaleIDs.contains(gsId)){
				checkScaleChangeMap.put(a.id, true);
			}
			else {
				if(zero100ScaleIDs.contains(newamap.get(a.ID).Picklist_Value__c)) {
					if(newamap.get(a.ID).Possible_Points__c != null) {
						newamap.get(a.ID).Possible_Points__c = null;
					}
				}
				else {
					if (newamap.get(a.ID).Possible_Points__c == null){
						newamap.get(a.ID).Possible_Points__c.addError('You must enter a whole number greater than 0 when changing to a \'Points\' scale');
					}
				}
			}
		}
		
		//Summer 2014 iteration 3: US3304 - check for weightingValue change if GradeScale is of points
		if(a.Weighting_Value__c != oldaMap.get(a.ID).Weighting_Value__c) {
			if(pointScaleIDs.contains(a.Picklist_Value__c)) {
				a.Weighting_Value__c.addError('You cannot change the weighting value of a grade scale category \'Points\' assignment.');
			}
		}
	}
	if (!checkScaleChangeMap.isEmpty()){
		for (Grade__c g: [select id, assignment__c 
										from Grade__c 
										where assignment__c in :checkScaleChangeMap.keySet()
										and	entered_grade__c!=null	]){
			hasGradePlChangeSet.add(g.assignment__c);
		}	
	}
	if (!hasGradePlChangeSet.isEmpty()){
			for(Assignment__c a : newamap.values()) {
					if (a.Picklist_Value__c != oldaMap.get(a.id).Picklist_Value__c){
						if (hasGradePlChangeSet.contains(a.id)){
							a.Picklist_Value__c.addError('Changing the Grading Scale on an assignment with submitted grades is not allowed.  Please clear the grades related to the assignment before changing the scale.');
						}
					}
			}
	}
}

public static void isafterupdate(Map<Id, Assignment__c> newamap, Map<Id, Assignment__c> oldamap ) {
	
	
	Map<Id, Assignment__c> AssignmentstoProcess = new Map<Id, Assignment__c> ();
	Map<Id, Assignment__c> oldAssignmentsToProcess = new Map<Id, Assignment__c> ();
	try{
		for (Assignment__c a: newamap.values() ) {
		//check if assignment weight was changed, if so update grade records
			if(newamap.get(a.Id).Picklist_Value__c <> oldamap.get(a.Id).Picklist_Value__c){
				AssignmentstoProcess.put(a.Id, a);
				oldAssignmentsToProcess.put(a.Id, oldamap.get(a.Id));
			}
			if (newamap.get(a.Id).Weighting_Value__c <> oldamap.get(a.Id).Weighting_Value__c||
				newamap.get(a.Id).Possible_Points__c <> oldamap.get(a.Id).Possible_Points__c||
				newamap.get(a.Id).Time__c <> oldamap.get(a.Id).Time__c||
				newamap.get(a.id).Include_in_Final_Grade__c <> oldamap.get(a.id).Include_in_Final_Grade__c ) {
					oldAssignmentsToProcess.put(a.Id, oldamap.get(a.Id));
					AssignmentstoProcess.put(a.Id, a);
			}
			
		}
		if(AssignmentstoProcess.size()>0){
			core_TriggerUtils.calculationTriggerUpdate(true);  //US2794; actually make sure recalc occurs when changing this flag.  
			updategraderecords(AssignmentstoProcess, oldAssignmentsToProcess);
			core_TriggerUtils.calculationTriggerUpdate(false);  //US2794; actually make sure recalc occurs when changing this flag.  
		}
	}
	catch(Exception e){
		string linkString;
		for(ID key : AssignmentstoProcess.keySet()){
			if(linkString == null){
				linkString = string.valueOf(AssignmentsToProcess.get(key).Name) + ',' + string.valueOf(AssignmentsToProcess.get(key).id);
			}
			else{
				linkString = linkString + ';' + string.valueOf(AssignmentsToProcess.get(key).Name) + ',' + string.valueOf(AssignmentsToProcess.get(key).id);
			}
		}
		Global_Error__c ge = Error_Handling.handleError(linkString, 'Gradebook', 'Manage Assignments trigger: isAfterUpdate', e);
		insert ge;

	}
} //end after update

//@future
public static void updategraderecords (Map<Id, Assignment__c> newamap, Map<ID, Assignment__c> oldamap) {

	List<Grade__c> gradestoupdate = [Select Id, Assignment__c, Assignment__r.Name, Assignment__r.Picklist_Value__r.Name, Possible_Points__c, Time__c, Assignment_Weighting__c, Entered_Grade__c from Grade__c where Student_Section__r.Active__c = true AND Assignment__c in : newamap.keyset()];
	
	for (Grade__c g: gradestoupdate ) {
		if(oldamap.containsKey(g.Assignment__c)){
			g.Assignment_Weighting__c = newamap.get(g.Assignment__c).Weighting_Value__c;
			
			g.Possible_Points__c = newamap.get(g.Assignment__c).Possible_Points__c;
			
			if (g.exclude_From_Section_Grade__c != !newamap.get(g.Assignment__c).Include_in_Final_Grade__c){
				system.debug('changed~~~~'+g);
			}
			g.exclude_From_Section_Grade__c = !newamap.get(g.Assignment__c).Include_in_Final_Grade__c;
			system.debug('g~~~~'+g);
			
			if(g.Standard_Weighting__c==null || g.Standard_Weighting__c==0){
				g.Standard_Times_Assignment__c = g.Assignment_Weighting__c;
			}
			else{
				g.Standard_Times_Assignment__c = g.Standard_Weighting__c*g.Assignment_Weighting__c;
			}
		}
	}
	try{
		system.debug(gradestoupdate);
		update gradestoupdate;
	}catch(Exception e) {
		string linkString;
		set<String> assignments = new Set<String>();
		for(grade__c g: gradestoupdate){
			if(!(assignments.contains(g.Assignment__r.Name))){
				if(linkString==null){
					linkString = g.Assignment__r.Name + ',' + g.id;
				}
				else{
					linkString = linkString + ';' + g.Assignment__r.Name + ',' + g.id;
				}
			}
		}
		Global_Error__c ge = Error_Handling.handleError(linkString, 'Gradebook', 'Manage Assignments trigger: updategraderecords', e);
		insert ge;
		newamap.values()[0].addError('There was a problem processing your request. Please contact your system admin');
		
	}


} //end class

	public static void isBeforeDelete(Map<Id, Assignment__c> oldAMap){
		List<Grade__c> deleteList = new List <Grade__c>();
		Set<ID> assignIDSet = new Set<ID>();
				
		for(Assignment__c a:oldAMap.values()){
			assignIDSet.add(a.Id);
		}
		
		deleteList = [select g.ID, Entered_Grade__c, Assignment__c
						from Grade__c g 
						where Student_Section__r.Active__c = true 
						AND g.assignment__c IN :assignIDSet
						And Student__r.Active__c = true];

		for(Grade__c g:deleteList){
			if(!String.isBlank(g.Entered_Grade__c)){
				oldAMap.get(g.Assignment__c).addError('Assignments with entered grades cannot be deleted. Please remove all entered grades for an assignment before deleting.');
			}
		}

		if(!deleteList.isEmpty()){
			try{
				core_TriggerUtils.gradeDeleteTriggerUpdate(true);
				delete deleteList;
				core_TriggerUtils.gradeDeleteTriggerUpdate(false);
			}
			catch(exception e){
				Global_Error__c ge = Error_Handling.handleError('', 'Gradebook', 'Deletetion of grades failed on assignment delete', e);
				insert ge;
			}
		}
	}
	
	public static void rollDownIncludeFinalGrade(List<Assignment__c> triggerOld, Map<Id, Assignment__c> triggerNewMap)
	{
		Set<Id> changedIncludeIds = new Set<Id>();
		for (Assignment__c curr: triggerOld)
		{
			if (curr.Include_in_Final_Grade__c != triggerNewMap.get(curr.Id).Include_in_Final_Grade__c)
				changedIncludeIds.add(curr.Id);
		}
		
		/* These are not the same flags; US2794; Exclude = dropped grade; include_if final => Should count in final grade; different use cases
		for (Grade__c curr: assignmentGrades)
		{
			curr.Exclude_From_Section_Grade__c = !triggerNewMap.get(curr.Assignment__c).Include_In_Final_Grade__c;
			//curr.Assignment_Weighting__c = 2;
		}*/
		List<Grade__c> assignmentGrades = [SELECT Exclude_From_Section_Grade__c, Assignment_Weighting__c, Assignment__c FROM Grade__c WHERE Assignment__c IN :changedIncludeIds];
		System.debug('assign grades = ' + assignmentGrades);
		core_TriggerUtils.calculationTriggerUpdate(true);  //US2794; actually make sure recalc occurs when changing this flag.  
		update assignmentGrades;
		core_TriggerUtils.calculationTriggerUpdate(false);
	}
	
	public static Map<ID, Time_Element__c> getAllRP() {
		return new Map<ID, Time_Element__c>([SELECT Date_Start_Date__c, End_Date__c FROM Time_Element__C WHERE Picklist_Value__r.Name != 'Year' OR Picklist_Value__r.Name != 'Term']);
	}
}