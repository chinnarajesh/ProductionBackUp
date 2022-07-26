*REQ* Display Value,*REQ* Category,Display Code,Is Unexcused,Is Tardy,Is Early Departure,Is Suspension,Short Description,Long Description,Set as Default,*REQ* Type,*REQ* Record Type ID
Present,Present,P,FALSE,FALSE,FALSE,FALSE,Present,Student was in class and on time.,TRUE,Attendance,Attendance
Tardy,Partial,UT,TRUE,TRUE,FALSE,FALSE,Unexcused tardy,Student was late w/o prior permission.,FALSE,Attendance,Attendance
Excused Tardy,Partial,ET,FALSE,TRUE,FALSE,FALSE,Excused tardy,Student was late with prior permission.,FALSE,Attendance,Attendance
Unexcused Absence,Absent,UA,TRUE,FALSE,FALSE,FALSE,Unexcused absence,Student was absent w/o prior permission.,FALSE,Attendance,Attendance
Excused Absence,Absent,EA,FALSE,FALSE,FALSE,FALSE,Excused absence,Student was absent with prior permission.,FALSE,Attendance,Attendance
Early Departure,Partial,UD,TRUE,FALSE,TRUE,FALSE,Unexcused early departure,Student left class early w/o permission.,FALSE,Attendance,Attendance
Excused Early Departure,Partial,ED,FALSE,FALSE,TRUE,FALSE,Excused early departure,Student left class early with permission.,FALSE,Attendance,Attendance
Tardy/Early Departure,Partial,TED,TRUE,TRUE,TRUE,FALSE,Tardy and early departure,Student was late and left class early.,FALSE,Attendance,Attendance
In-school Suspension,In School Suspension,IS,FALSE,FALSE,FALSE,TRUE,In-school suspension,Student was spending the day in ISS.,FALSE,Attendance,Attendance
Out-of-school Suspension,Out of School Suspension,OS,FALSE,FALSE,FALSE,TRUE,Out-of-school suspension,Student was suspended from school.,FALSE,Attendance,Attendance
