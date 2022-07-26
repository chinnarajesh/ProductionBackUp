/* Overwrites salesforce default UI */
body .bPageBlock,
body #bodyCell .bResource .secondaryPalette,
body .secondaryPalette.bPageBlock,
body .overlayDialog .secondaryPalette.bPageBlock,
body .individualPalette .secondaryPalette.bPageBlock,
body .bodyDiv .genericTable, body .generic	,
body .bodyDiv .bSubBlock, body .bComponentBlock .bPageBlock,
body .bMyDashboard .bPageBlock, body.rlHoverFrame .bPageBlock,
body.subjectSelectionPopup div.choicesBox,
body.lookupTab .secondaryPalette.bPageBlock,
body.popupTab .secondaryPalette.bPageBlock,
body.UserTagStatsPage .secondaryPalette.bPageBlock{
	border:none !important;
}

.bPageBlock{
	background:#fff !important;
	border:none;
}

.bEditBlock .pbHeader > table,
.apexp .bPageBlock.apexDefaultPageBlock .pbHeader > table,
#ep.bLayoutBlock .pbHeader > table{
	border-bottom:none;
}

.section_content{
	padding:15px;
	border:1px solid #ccc;
	border-radius:7px;
	margin:3px 0 52px 0;
}

.top_content_section{
	margin-bottom:15px;
}
.section_content label{
	color:#666; font-weight:normal;
}

.wrapper{
	width:1010px;
	margin:0 auto;
}
/* Buttons */
input.red_btn{
	border-radius:5px !important;
	font-family: 'Varela', sans-serif !important;
	color:#fff !important;
	font-weight:normal !important;
	text-transform:uppercase !important;
	padding:10px !important;
	border:none;
	margin-right:10px !important;
	/* Older browsers (degrades)*/
	background: #cc2800 !important;
	/* FF3.6+ */
	background: -moz-linear-gradient(top,  #cc2800 16%, #7f0e00 100%) !important;
	/* Chrome,Safari4+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(16%,#cc2800), color-stop(100%,#7f0e00)) !important;
	/* Chrome10+,Safari5.1+ */
	background: -webkit-linear-gradient(top,  #cc2800 16%,#7f0e00 100%) !important;
	/* Opera 11.10+ */
	background: -o-linear-gradient(top,  #cc2800 16%,#7f0e00 100%) !important;
	/* IE10+ */
	background: -ms-linear-gradient(top,  #cc2800 16%,#7f0e00 100%) !important;
	/* W3C Compliant*/
	background: linear-gradient(top,  #cc2800 16%,#7f0e00 100%) !important;
	/* IE6-9 */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#cc2800', endColorstr='#7f0e00',GradientType=0 ) !important;
}
input.red_btn:hover{
	background:#7F0E00 !important;
}

input.blue_btn{
	background:#B5E3F2 !important;
	border-radius:5px !important; font-family: 'Varela', sans-serif !important;
	color:#000 !important; font-weight:normal !important;
	text-transform:uppercase !important;
	padding:5px 20px 5px 20px !important;
	border:none !important;
	margin-right:10px !important;
}
input.blue_btn:hover{
	background:#B5E3F2 !important;
	background-position:right 4px !important;
}
/* Why is this not in the gradebook css?*/
div .gradebook input.blue_btn{
	float:right; margin-top:15px;
}

input.basic_black_btn{
	cursor:pointer;
	font-weight:normal;
	padding:10px;
	border-radius:5px ;
	border:none;
	text-transform:uppercase;
	color:#fff;
	/* Old browsers */
	background: #4c4c4c;
	/* FF3.6+ */
	background: -moz-linear-gradient(top,  #4c4c4c 0%, #474747 29%, #2c2c2c 52%, #000000 64%, #1c1c1c 93%, #131313 100%) !important;
	/* Chrome,Safari4+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#4c4c4c), color-stop(29%,#474747), color-stop(52%,#2c2c2c), color-stop(64%,#000000), color-stop(93%,#1c1c1c), color-stop(100%,#131313)) !important;
	/* Chrome10+,Safari5.1+ */
	background: -webkit-linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* Opera 11.10+ */
	background: -o-linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* IE10+ */
	background: -ms-linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* W3C Compliant*/
	background: linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* IE6-9 */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#4c4c4c', endColorstr='#131313',GradientType=0 ) !important;
}

input.black_btn{
	cursor:pointer;
	margin-left:5px;
	margin-bottom:25px;
	font-weight:normal;
	float:right !important;
	padding:10px 10px !important;
	border-radius:5px !important;
	border:none !important;
	text-transform:uppercase !important;
	color:#fff !important;
	/* Old browsers */
	background: #4c4c4c !important;
	/* FF3.6+ */
	background: -moz-linear-gradient(top,  #4c4c4c 0%, #474747 29%, #2c2c2c 52%, #000000 64%, #1c1c1c 93%, #131313 100%) !important;
	/* Chrome,Safari4+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#4c4c4c), color-stop(29%,#474747), color-stop(52%,#2c2c2c), color-stop(64%,#000000), color-stop(93%,#1c1c1c), color-stop(100%,#131313)) !important;
	/* Chrome10+,Safari5.1+ */
	background: -webkit-linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* Opera 11.10+ */
	background: -o-linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* IE10+ */
	background: -ms-linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* W3C Compliant*/
	background: linear-gradient(top,  #4c4c4c 0%,#474747 29%,#2c2c2c 52%,#000000 64%,#1c1c1c 93%,#131313 100%) !important;
	/* IE6-9 */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#4c4c4c', endColorstr='#131313',GradientType=0 ) !important;
}
input.black_btn:hover{
	background:#000 !important;
}

input.drk_blue_btn{
	margin:15px 15px 0 0 !important;
	padding:6px 10px !important;
	color: white !important;
	/* Old browsers */
	background: #59afcc !important;
	/* FF3.6+ */
	background: -moz-linear-gradient(top,  #59afcc 21%, #0180ab 85%) !important;
	/* Chrome,Safari4+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(21%,#59afcc), color-stop(85%,#0180ab)) !important;
	/* Chrome10+,Safari5.1+ */
	background: -webkit-linear-gradient(top,  #59afcc 21%,#0180ab 85%) !important;
	/* Opera 11.10+ */
	background: -o-linear-gradient(top,  #59afcc 21%,#0180ab 85%) !important;
	/* IE10+ */
	background: -ms-linear-gradient(top,  #59afcc 21%,#0180ab 85%) !important;
	/* W3C Compliant*/
	background: linear-gradient(top,  #59afcc 21%,#0180ab 85%) !important;
	/* IE6-9 */
	filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#59afcc', endColorstr='#0180ab',GradientType=0) !important;
 }
 input.drk_blue_btn:hover{
	background:#0180AB !important;
 }

/* General UI */
.clear_fix{
	clear:both;
}
div.gradebook h3{
	font-weight:bold;
	font-size:14px;
	color:#333;
	font-family:"Segoe UI", Segoe, Tahoma, Geneva, sans-serif;
	margin:55px 0 0 15px;
	display:block;
	width:500px;
	float:left;
}
.filter_form{
	padding:15px;
	border:1px solid #D9D9D9;
	border-radius:5px;
	clear:both;
}
.filter_form .form_fields{
	float:left;
	width:755px;
}
.filter_form .form_fields div{
	float:left;
	margin:0 25px 0 0;
	color:#333;
	font-size:12px;
	font-family:"Segoe UI", Segoe, Tahoma, Geneva, sans-serif;
	font-weight:bold;
}
.filter_form .form_fields div.bottom_form_element{
	margin-top:15px;
}
.filter_form .form_fields div select{
	width:130px;
}
span.dateFormat{
	display:none;
}
.filter_form .Submit_btn_wrapper{
	float:left;
	width:173px;
	border-left:1px solid #ccc;
	height:64px;
	padding:25px 0 25px 35px;
}
.gradebook_results_wrapper{
	float:left;
}
.gradebook_results_wrapper #mainDiv{
	width:800px;
	overflow-x:scroll;
	border-top-right-radius: 7px;
	border-bottom-right-radius:7px;
	border:1px solid #ccc;
}
.gradebook_results_wrapper #leftDiv{
	float:left;
	clear:left;
	position:static;
	border-top-left-radius:7px;
	border-bottom-left-radius:7px;
}
#leftDiv #leftTable{
	border:none;
}
.table_top p{
	width:450px;
	float:right;
	text-align:right;
	margin:55px 5px 0 0;
}
.table_top p a{
	color:#999;
	cursor:pointer;
	text-decoration:none;
}
.table_top p a:hover{
	text-decoration:underline;
}
.comment_model{
	border-radius:5px;
	border:5px solid #666 !important;
	-moz-box-shadow: 5px 5px rgba(0,0,0,0.5);
	-webkit-box-shadow: 5px 5px rgba(0,0,0,0.5);
	box-shadow: 5px 5px rgba(0,0,0,0.5);
}

/*Gradebook landing page */
th.headCol{
	color:#666;
	font-weight:normal;
	padding:0 10px;
	border-right:3px solid #fff;
}
th.headCol a{
	color:#333;
	font-weight:bold;
}
a{
	text-decoration:none;
}
td.headCol input{
	border:1px solid #999;
	text-align:center; color:#666;
}
tr.odd{
	background:#FAFAFA;
}
#group .mainTable td{
	border:none;
}
.leftTable th{
	background:#099BCC;
	color:#fff;
	padding-left:10px;
	border-right:3px solid #fff;
}
#group .leftTable td{
	border-right:3px solid #fff;
}
#group .leftTable td.studCol{
	border-right:none;
	padding-left:10px;
	font-size:12px;
	color:#333;
	font-weight:bold;
}
#group .leftTable td.grade{
	text-align:center; font-weight:bold;
}
#group .leftTable td.failing{
	color:#A10505; background:none;
}
#group .leftTable td.passing{
	color:#999A35; background:none;
}

/*Create Groups */
h2{
	color:#333;
	margin:0 0 3px 8px;
	font-size:12px;
	text-transform:uppercase !important;
}
.datahighlight{
	background-color: gold !important;
}
.datahighlight2{
	background-color: cyan !important;
}
.datahighlight3{
	background-color: orange !important;
}
.odd{
	background-color: #F0F0F6;
}
.even{
	background-color: white;
}
h3{
	color:#333;
	margin:0 0 3px 17px;
	font-size:12px;
	text-transform:uppercase !important;
}

/* assignments */
.bPageBlock{
	background:#fff !important;
	border:none;
}
.bEditBlock .pbHeader > table,
.apexp .bPageBlock.apexDefaultPageBlock .pbHeader > table,
#ep.bLayoutBlock .pbHeader > table{
	border-bottom:none;
}

table.list{
	margin-top:45px;
	border-top-left-radius:7px;
	border-top-right-radius:7px;
	width:750px;
}
table.list th.headerRow{
	background:#B5E3F2 !important;
	color:#000 !important;
	font-weight:normal;
}
table.list td{
	color:#666 !important;
	padding:11px;
}
body .pbBody table.list tr th,
body .pbBody table.list tr td{
	border:1px solid #999;
}
label{
	margin:0 15px 5px 0;
}
.detailList table.list{
	margin:0 0 45px 0;
}
.Custom92Tab .tertiaryPalette,
.individualPalette .Custom92Block .tertiaryPalette,
.layoutEdit .individualPalette .Custom92Block .tertiaryPalette{
	background:none;
}
.dataTables_wrapper{
	margin-bottom:15px;
}
.dataTables_filter{
	border:0px solid #67b2ce !important;
}
.ui-widget-header{
	border:1px solid #67b2ce !important;
}
.detailList tr th{
	border-color:#67b2ce !important;
}
.apexp .bPageBlock .detailList{
	margin-bottom:0 !important;
}
.pbBody{
	padding-top:25px !important;
}
.dataTables_paginate.fg-buttonset.ui-buttonset.fg-buttonset-multi.ui-buttonset-multi.paging_two_button{
	width:50px;
	float:right;
}
.dataTables_info{
	width:500px;
	 margin-left:5px;
	 float:left;
}
.ui-toolbar{
	padding:5px;
	background:#B5E3F2;
	color:#333;
}
.ui-widget-header{
	background:#B5E3F2 !important;
	padding:5px;
}
.ui-widget-header .dataTables_length{
	width:250px;
	float:right;
	text-align:right;
}
.ui-widget-header .dataTables_filter{
	float:left;
	width:250px;
}
.tablesorter th{
	padding:3px;
	background:#B5E3F2;
	border:1px solid #67b2ce;
}
.tablesorter tbody tr td{
	padding:5px 3px;
	color:#333;
}

/* historical Data */
#historicalData h3{
	display:block;
	margin-top:10px;
}
#historicalData .sidebarModule{
	float:left;
}
#historicalData .main-content{
	float:left;
	padding-left:25px;
}
#historicalData table{
	border:none;
	padding:0;
}

#historicalData table th{
	border:none;
}

#historicalData table td{
	padding:5px;
	border:none;
}

#historicalData table td.subth{
	font-weight:bold;
	border-bottom:1px solid #666;
}

#historicalData .main-content .tableWrapper table{
	margin-top:45px;
	border-top-left-radius:7px;
	border-top-right-radius:7px;
	width:100%;
}
#historicalData .main-content .tableWrapper table th{
	background:#B5E3F2 !important;
	color:#000 !important;
	font-weight:bold !important;
	border:none; border-spacing:0;
	font-weight:normal;
}
#historicalData .main-content .tableWrapper table td{
	color:#666 !important;
	padding:11px;
	background:transparent;
	border-bottom:1px solid #ccc;
}
#historicalData .main-content .tableWrapper table tr th, body .pbBody table.list tr td{
	border:1px solid #67B2CE;
}
#historicalData .main-content .tableWrapper table{
	margin:0 0 45px 0;
}
#historicalData .main-content .tableWrapper table tr.highlight{
	background:#ffffcc;
}
#historicalData .main-content .tableWrapper table tr:last-child{
	border:none;
}
#historicalData .tableWrapper{
	border-radius:7px;
	border:1px solid #67B2CE;
	overflow:hidden;
	margin-bottom:50px;
}

div.generic table{
	width:100%;
	vertical-align:top;
	border:1px solid #D4DADC;
	border-radius:7px;
}

div.generic table th{
	background-color:#75BEE9;
	border-right:1px solid #99D2F4;
	white-space: nowrap;
	font-size:12px;
	font-weight:bold;
	padding:3px 3px;
}
div.generic table td{
	padding:3px 3px;
	text-align:center;
	vertical-align:middle;
}
div.generic table td table td{
	padding:3px 3px;
	text-align:center;
	vertical-align:middle;
}
.no-bottom-margin{
	margin-bottom:0px!important;
}