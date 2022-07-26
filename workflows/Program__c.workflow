<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Program_Approval_Needed</fullName>
        <description>Send Program Approval Needed</description>
        <protected>false</protected>
        <recipients>
            <recipient>Program_Approval_Team</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>City_Year_Email_Templates/New_Program_Approval_Needed</template>
    </alerts>
    <alerts>
        <fullName>Send_Program_Approved_Email</fullName>
        <description>Send Program Approved Email</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <recipient>Program_Approval_Team</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>City_Year_Email_Templates/Program_Approved</template>
    </alerts>
    <alerts>
        <fullName>Send_Program_Submitted_for_Approval_Email</fullName>
        <description>Send Program Submitted for Approval Email</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>City_Year_Email_Templates/Program_Submitted</template>
    </alerts>
    <fieldUpdates>
        <fullName>Change_Owner</fullName>
        <field>OwnerId</field>
        <lookupValue>HQ_Approval_Team</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Change Owner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Change_Status_to_Rejected</fullName>
        <field>Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Change Status to Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Approved</fullName>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Set Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Approved</fullName>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Update Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Pending</fullName>
        <field>Status__c</field>
        <literalValue>Pending</literalValue>
        <name>Update Status to Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Set Status to Approved</fullName>
        <actions>
            <name>Set_Status_to_Approved</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Workflow sets all newly created programs to have a status of &quot;Approved&quot;.  This workflow can be deactivated if an approval process is preferred.</description>
        <formula>ISPICKVAL( Status__c , &quot;&quot;)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
