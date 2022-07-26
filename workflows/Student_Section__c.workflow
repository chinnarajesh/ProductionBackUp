<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Student_Section_populate_ID</fullName>
        <field>Original_School_Salesforce_ID__c</field>
        <formula>Student__r.School__r.Id</formula>
        <name>Student/Section populate ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Student_Section_populate_school</fullName>
        <field>Original_School__c</field>
        <formula>Student__r.School__r.Name</formula>
        <name>Student/Section populate school</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>mark_inactive</fullName>
        <field>Active__c</field>
        <literalValue>0</literalValue>
        <name>mark inactive</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>remove_end_date</fullName>
        <field>Enrollment_End_Date__c</field>
        <name>remove end date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>remove_reason</fullName>
        <field>Section_Exit_Reason__c</field>
        <name>remove reason</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Active no end date or exit reason</fullName>
        <actions>
            <name>remove_end_date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>remove_reason</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Student_Section__c.Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Student%2FSection populate Student info</fullName>
        <actions>
            <name>Student_Section_populate_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Student_Section_populate_school</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Student__c &lt;&gt; null</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>student section inactive enroll end date</fullName>
        <actions>
            <name>mark_inactive</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( NOT(ISBLANK(  Enrollment_End_Date__c )))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
