<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Populate_Original_School</fullName>
        <field>Original_School__c</field>
        <formula>Student__r.School__r.Name</formula>
        <name>Populate Original School</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Original_School_SF_ID</fullName>
        <field>Original_School_Salesforce_Id__c</field>
        <formula>Student__r.School__r.Id</formula>
        <name>Populate Original School SF ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Assessment Populate Student%27s Info</fullName>
        <actions>
            <name>Populate_Original_School</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Populate_Original_School_SF_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Student__c &lt;&gt; null</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
