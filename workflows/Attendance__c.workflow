<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Mark_Session_as_Submitted</fullName>
        <field>Attendance_Submitted__c</field>
        <literalValue>1</literalValue>
        <name>Mark Session as Submitted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
        <targetObject>Session__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Internal_Code</fullName>
        <field>Internal_Code__c</field>
        <formula>TEXT(Picklist_Value__r.Internal_Code__c )</formula>
        <name>Set Internal Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Time_Lost_Update</fullName>
        <description>This will update the Time Lost Rollup field with the value of the Instructional Time Lost field.</description>
        <field>Time_Lost_Rollup__c</field>
        <formula>Instructional_Time_Lost__c</formula>
        <name>Time Lost Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Mark Session as Submitted</fullName>
        <actions>
            <name>Mark_Session_as_Submitted</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Session__c.Attendance_Submitted__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Internal Code</fullName>
        <actions>
            <name>Set_Internal_Code</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>NOT(ISBLANK( Picklist_Value__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Time Lost</fullName>
        <actions>
            <name>Time_Lost_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Attendance__c.Instructional_Time_Lost__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>This will take the time lost from the formula field and set it in the Rollup field so that we can do a rollup summary on the student record.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
