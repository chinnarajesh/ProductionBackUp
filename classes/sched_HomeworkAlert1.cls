global class sched_HomeworkAlert1 implements Schedulable{
    global void execute(SchedulableContext sc) {
        Homework_PGNotification pgn1 = new Homework_PGNotification('Homework Alerts');
        pgn1.query = Homework_SoqlUtils.HWAlertQuery1;
        ID batchprocessid = Database.executeBatch(pgn1,1);
    }
}