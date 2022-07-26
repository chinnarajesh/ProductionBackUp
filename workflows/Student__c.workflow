<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Get_Student_LocalID</fullName>
        <field>Local_Student_ID__c</field>
        <formula>Holding_Source__r.Local_Student_ID__c</formula>
        <name>Get Student LocalID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Internal_Local_ID</fullName>
        <field>Internal_Local_ID__c</field>
        <formula>IF(Len( Local_Student_ID__c )&lt;=4, &quot;Invalid - Local Student ID Less Than 5 characters&quot;,

(IF(CONTAINS(UPPER(Local_Student_ID__c), &quot;STUD&quot;),&quot;Invalid - Site does not assign Local Student IDs&quot;,

(IF(CONTAINS(Local_Student_ID__c, &quot; &quot;), &quot;Invalid - Local Student ID contains spaces&quot;,

(IF(CONTAINS(UPPER(Local_Student_ID__c), &quot;E+&quot;), &quot;Invalid - Local Student ID contains scientific notation&quot;,

LPAD(Local_Student_ID__c,20,&quot;0&quot;))))))))</formula>
        <name>Internal Local ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>LocalIDclone</fullName>
        <field>Legacy_Id__c</field>
        <formula>Local_Student_ID__c</formula>
        <name>LocalIDclone</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Original_School</fullName>
        <field>Original_School__c</field>
        <formula>School__r.Name</formula>
        <name>Populate Original School</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_AutoNumber_to_ID</fullName>
        <field>Student_Id__c</field>
        <formula>Student_ID_Auto_Number__c</formula>
        <name>Set Auto-Number to ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Student_ID</fullName>
        <field>Student_Id__c</field>
        <formula>Id</formula>
        <name>Set Student ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Student_Name</fullName>
        <field>Name</field>
        <formula>Student_First_Name__c + &quot; &quot; + Student_Last_Name__c</formula>
        <name>Set Student Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Reference_ID</fullName>
        <field>Reference_Id__c</field>
        <formula>Student_Id__c + &quot;_&quot; + School_Reference_Id__c + &quot;_&quot; +  School_Year_Name__c</formula>
        <name>Update Reference ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Get Student LocalID</fullName>
        <actions>
            <name>Get_Student_LocalID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Local_Student_ID__c  = Null &amp;&amp; Holding_Source__r.Local_Student_ID__c &lt;&gt; Null</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Internal Local ID</fullName>
        <actions>
            <name>Internal_Local_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR(ISNEW(), ISCHANGED( Local_Student_ID__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Local ID clone to USID</fullName>
        <actions>
            <name>LocalIDclone</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(Local_Student_ID__c) ||  ISNEW()</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Student ID</fullName>
        <actions>
            <name>Set_AutoNumber_to_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Reference_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the student ID to the system-generated number</description>
        <formula>Student_Id__c  &lt;&gt;  Student_ID_Auto_Number__c</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Student Name</fullName>
        <actions>
            <name>Set_Student_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set Name field to be First + Last Name</description>
        <formula>OR (  ISNEW(),  OR ( ISCHANGED( Student_Last_Name__c), ISCHANGED( Student_First_Name__c ) )  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>original school name</fullName>
        <actions>
            <name>Populate_Original_School</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Student__c.School_Name__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
