/**
 * Created by TarasTorubka on 04.11.2020.
 */
global class CT_UpdateSObjects implements Database.Batchable<sObject> {

    String query;

    global CT_UpdateSObjects(String soqlQuery) {
        this.query = soqlQuery;
    }

    public static void usingSObjectAPIName(String sObjectAPIName) {
        usingSObjectAPIName(sObjectAPIName, 200);
    }

    public static void usingSObjectAPIName(String sObjectAPIName, Integer batchSize) {
        if (String.isEmpty(sObjectAPIName)) {
            return;
        }
        String queryString = 'SELECT Id FROM ' + sObjectAPIName;
        usingSOQL(queryString, batchSize);
    }

    public static void usingSOQL(String queryString) {
        usingSOQL(queryString, 200);
    }

    public static void usingSOQL(String queryString, Integer batchSize) {
        if (String.isEmpty(queryString)) {
            return;
        }
        if (batchSize < 1 || batchSize > 200) {
            return;
        }
        queryString = String.escapeSingleQuotes(queryString);
        //TODO Validate query string before run batch
        Id batchId = Database.executeBatch(new CT_UpdateSObjects(queryString), batchSize);
    }

    webService static String runBatch(String query, Integer scope) {
        System.debug('@@@ query: '+query);
        System.debug('@@@ scope: '+scope);
        Id batchId = Database.executeBatch(new CT_UpdateSObjects(query), scope);
        return 'OK';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
    }
}