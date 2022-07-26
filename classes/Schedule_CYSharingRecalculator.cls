public class Schedule_CYSharingRecalculator implements Schedulable {
	
	public boolean useLog = false;
	
	public Schedule_CYSharingRecalculator(){ }
	
	public Schedule_CYSharingRecalculator(boolean bUseLog){
		useLog = bUseLog;
	}
	
	public void execute(SchedulableContext sc){
		//CYSharingRecalculator cysr = new CYSharingRecalculator(useLog);
		//Database.executeBatch(cysr,1);
	}
}