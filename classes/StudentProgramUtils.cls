public class StudentProgramUtils {

	public static void updateFields(List<Student_Program__c> lstSP){
		for(Student_Program__c sp: lstSP){
			sp.Reference__c = sp.Student__c + '#' + sp.Program1__c;
		}
	}

}