<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_Behavior_Incident_Owner</fullName>
        <description>Notify Behavior Incident Owner</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Schoolforce/Notify_Incident_Owner</template>
    </alerts>
    <alerts>
        <fullName>Request_Information_from_3rd_Party</fullName>
        <description>Request Information from Adult 2</description>
        <protected>false</protected>
        <recipients>
            <field>Other_Adult_Involved_2_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Schoolforce/Request_for_Add_Info_For_Behavior_Incident</template>
    </alerts>
    <alerts>
        <fullName>Request_Information_from_Adult_on_Duty</fullName>
        <description>Request Information from Adult on Duty</description>
        <protected>false</protected>
        <recipients>
            <field>Adult_On_Duty_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Schoolforce/Request_for_Add_Info_For_Behavior_Incident</template>
    </alerts>
    <alerts>
        <fullName>Request_Information_from_Key_Witness</fullName>
        <description>Request Information from Other Adult 2</description>
        <protected>false</protected>
        <recipients>
            <field>Other_Adult_Involved_1_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Schoolforce/Request_for_Add_Info_For_Behavior_Incident</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Notify_Incident_Owner_To_False</fullName>
        <field>Notify_Incident_Owner__c</field>
        <literalValue>0</literalValue>
        <name>Set Notify Incident Owner To False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Adult_on_Duty_Email</fullName>
        <field>Adult_On_Duty_Email__c</field>
        <formula>Adult_on_Duty__r.Email__c</formula>
        <name>Update Adult on Duty Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Incident_Status</fullName>
        <field>Incident_Status__c</field>
        <literalValue>Awaiting Add&apos;l Info</literalValue>
        <name>Update Incident Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Other_Adult_1</fullName>
        <field>Other_Adult_Involved_1_Email__c</field>
        <formula>Other_Adult_Involved_1__r.Email__c</formula>
        <name>Update Other Adult 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Other_Adult_2</fullName>
        <field>Other_Adult_Involved_2_Email__c</field>
        <formula>Other_Adult_Involved_2__r.Email__c</formula>
        <name>Update Other Adult 2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Notify Adult on Duty</fullName>
        <actions>
            <name>Request_Information_from_Adult_on_Duty</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_Incident_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND( LEN(Adult_On_Duty_Email__c) &gt; 0  , Request_Info_AoD__c == true, NOT(ISPICKVAL( Incident_Status__c , &apos;Closed&apos;)),  NOT(ISPICKVAL( Incident_Status__c , &apos;Draft&apos;)))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Notify Incident Owner</fullName>
        <actions>
            <name>Notify_Behavior_Incident_Owner</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Set_Notify_Incident_Owner_To_False</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Behavior_Incident__c.Notify_Incident_Owner__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Behavior_Incident__c.Incident_Status__c</field>
            <operation>notEqual</operation>
            <value>Draft</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Notify Other Adult 1</fullName>
        <actions>
            <name>Request_Information_from_Key_Witness</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_Incident_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND( LEN(Other_Adult_Involved_1_Email__c) &gt; 0,   Request_Info_Adult1__c  == True,   NOT(ISPICKVAL( Incident_Status__c , &apos;Closed&apos;)), NOT(ISPICKVAL( Incident_Status__c , &apos;Draft&apos;)) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Notify Other Adult 2</fullName>
        <actions>
            <name>Request_Information_from_3rd_Party</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_Incident_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(   LEN(Other_Adult_Involved_2_Email__c)  &gt; 0,  Request_Info_Adult2__c  == True,  NOT(ISPICKVAL( Incident_Status__c , &apos;Closed&apos;)), NOT(ISPICKVAL( Incident_Status__c , &apos;Draft&apos;)) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Email Fields</fullName>
        <actions>
            <name>Update_Adult_on_Duty_Email</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Other_Adult_1</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Other_Adult_2</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>Consequence_Awaiting_Admin_Decision2</fullName>
        <assignedTo>BehaviorCoordinator</assignedTo>
        <assignedToType>role</assignedToType>
        <description>The consequence for a behavior incident is awaiting admin decision.</description>
        <dueDateOffset>1</dueDateOffset>
        <notifyAssignee>true</notifyAssignee>
        <priority>High</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Consequence Awaiting Admin Decision</subject>
    </tasks>
</Workflow>
