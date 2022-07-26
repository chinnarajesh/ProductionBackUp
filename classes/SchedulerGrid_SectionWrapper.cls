public with sharing class SchedulerGrid_SectionWrapper {


    public string sTextColor {get;set;}
    public string sDisplay {get;set;}
    public Room__c room {get;set;}
    public Staff__c staff {get;set;}
    public Period__c    period {get;set;}
    public List <Scheduled_Section__c> ssList {get;set;}
    public string RoomId {get;set;}
    public string StaffId {get;set;}
    public string courseId {get;set;}
    public string sectId {get;set;}
    public string sectRpId {get;set;}
    public boolean hasError {get;set;}
    public SchedulerGrid_SectionWrapper (List <Scheduled_Section__c> tempSsList, Period__c p){
        this.sslist = tempSsList;
     //   Scheduled_Section__c schedSec = tempSsList[0];
       // this.staff = schedSec.staff__r;
       // this.room = schedSec.room__r;
       // if (schedSec.room__c!=null) this.roomId =this.room.id;
        //this.staffId = schedSec.Staff__c;
       // this.courseId = schedSec.course__c;
       // this.sectId = schedSec.section__c;
       // this.sectRpId = schedSec.Section_ReportingPeriod__c;
        //if (schedSec.section__r.color__c==null){
           //     this.sTextColor = '';
       // }
       // else      {
          //      if (schedSec.section__r.color__c.contains('#')==false) this.sTextColor = '#000000';
             //   else  this.sTextColor = core_coloringUtils.getTextColor(schedSec.section__r.color__c);
        //}
        this.period=p;
    }
    public SchedulerGrid_SectionWrapper(sObject s, Period__c p, Time_Element__c rp, boolean bRoomView){
        this.ssList = new List <Scheduled_Section__c>{};
        if (!bRoomView)             {
                this.staff = (Staff__c)s;
       //         this.ssList[0].staff__c = s.id;
        }
                  else                        {
                                this.room = (Room__c)s;
                                this.roomId = s.id;
                     //           this.ssList[0].room__c = s.id;
                  }
        this.period = p;
        this.sDisplay = 'none;';
   //     this.staffId = ssList[0].Staff__c;
    }
    public SchedulerGrid_SectionWrapper(Staff__c s, Period__c p, Time_Element__c rp){
        this.staff = s;
         this.ssList = new List <Scheduled_Section__c>{};

        this.period = p;
        this.sDisplay = 'none;';
   //     this.staffId = ssList[0].Staff__c;
    }
    public SchedulerGrid_SectionWrapper(Room__c r, Period__c p, Time_Element__c rp){
        this.room = r;
          this.ssList = new List <Scheduled_Section__c>{};

        this.period = p;
        this.sDisplay = 'none;';
        this.roomId = r.id;
    }
    
   
    
    


}