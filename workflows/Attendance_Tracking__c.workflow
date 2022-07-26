<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>NotifyAdminAttendanceCumulative</fullName>
        <ccEmails>juturi.rajesh@jaxconsult.com</ccEmails>
        <description>NotifyAdminAttendanceCumulative</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>Schoolforce/NotifyAdminAttendanceCumulative</template>
    </alerts>
    <alerts>
        <fullName>Send_CONS_Alert</fullName>
        <ccEmails>juturi.rajesh@jaxconsult.com</ccEmails>
        <description>Send CONS Alert</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>Schoolforce/NotifyAdminAttendance</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Record_to_Notified</fullName>
        <field>Admin_Notifications_cons__c</field>
        <literalValue>Administration Notified</literalValue>
        <name>Set Record to Notified</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_to_Notified</fullName>
        <field>Admin_Notifications_cons__c</field>
        <literalValue>Administration Notified</literalValue>
        <name>Set to Notified</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_to_Sent</fullName>
        <field>Admin_Notifications_cuml__c</field>
        <literalValue>Administration Notified</literalValue>
        <name>Set to Sent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
