*REQ*Display Value,*REQ* Category,Display Code,Is Unexcused?,Is Tardy?,Is Early Departure?,Is Suspension?,Short Description,Long Description,Default
Present,Present,P,FALSE,FALSE,FALSE,FALSE,Present,student was in class and on time,TRUE
Tardy,Partial,UT,TRUE,TRUE,FALSE,FALSE,Unexcused tardy,student was late w/o prior permission,FALSE
Excused Tardy,Partial,ET,FALSE,TRUE,FALSE,FALSE,Excused tardy,student was late with prior permission,FALSE
Unexcused Absence,Absent,UA,TRUE,FALSE,FALSE,FALSE,Unexcused absence,student was absent w/o prior permission,FALSE
Excused Absence,Absent,EA,FALSE,FALSE,FALSE,FALSE,Excused absence,student was absent with prior permission,FALSE
Early Departure,Partial,UD,TRUE,FALSE,TRUE,FALSE,Unexcused early departure,student left class early w/o permission,FALSE
Excused Early Departure,Partial,ED,FALSE,FALSE,TRUE,FALSE,Excused early departure,student left class early with permission,FALSE
Tardy/Early Departure,Partial,TED,TRUE,TRUE,TRUE,FALSE,Tardy and early departure,student was late and left class early,FALSE
In-school Suspension,In School Suspension,IS,FALSE,FALSE,FALSE,TRUE,In-school suspension,student was spending the day in ISS,FALSE
Out-of-school Suspension,Out of School Suspension,OS,FALSE,FALSE,FALSE,TRUE,Out-of-school suspension,student was suspended from school,FALSE
