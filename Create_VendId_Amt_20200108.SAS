%let payper=13;
%let schd_date="010620";

*%let schd_date="&schdate";
%let node=prod;
%let srvname=\\doefs1\office;
%let prjname=osapay\&node.;

%include "&srvname.\&prjname.\sas\osapay_LIBNAME.sas";

data ENTITLE2 (KEEP=CO DIST PP ENTITLE)
	negentl (KEEP=CO DIST PP ENTITLE);
	set sapaydt.Y&yr1.&yr2.entitle;
	ARRAY actpayba(*) actpayb01-actpayb20;
	PP=sum(&PAYPER., -4);

	if pp>0 and pp<=20 then
		ENTITLE=actpayba[PP];

	if entitle=. then
		entitle=0;

	if ENTITLE>0 then
		output ENTITLE2;
	else output negentl;
run;

title4 "DISTRICTS WITH NEGATIVE AMOUNT";

proc print n data=negentl;
	where abs(ENTITLE)>0;
	id co dist;
	var ENTITLE;
	sum ENTITLE;
	format entitle comma16.2;
run;

PROC SORT DATA=ENTITLE2;
	BY CO DIST;
run;

****%include "appdev:create_vhead.sas"/source2;
DATA ENTITLE2;
	MERGE ENTITLE2(IN=C) VHEAD;
	BY CO DIST;

	IF C;
	DATE=TODAY();
	DATE1=DATE+2;
	ppx=put(pp,z2.);
run;

title4 "PAYMENT AMOUNT FOR PAY PERIOD &PAYPER. ";

/*
PROC PRINT DATA=ENTITLE2;
BY CO 
NOTSORTED;
PAGEBY CO;
ID CO DIST DISTNAME;
VAR VENDORID 
ENTITLE;
sum ENTITLE;
FORMAT CO Z2. DIST Z4. DATE MMDDYY8. DATE1 MMDDYY8. ENTITLE COMMA19.2;
run;
*/
ods pdf close;

DATA entitle(keep=co dist pp amt_to_pay);
	SET entitle2(DROP=PP);

	****if dist in (0125, 0285, 0605, 0715, 1774, 3103, 4635, 5450);
	amt_to_pay=ENTITLE;
	project=' ';
	length pp $2.;
	pp=ppx;
run;

%let keep=VENDORID DISTNAME amt_to_pay;

DATA entitle(keep=&keep);
	format amt_to_pay comma16.2;
	MERGE entitle(IN=C) VHEAD(IN=V);
	BY CO DIST;

	IF C;
run;

/* to change order of variables use retain statement */
data entitle4;
	retain &keep;
	set entitle(keep=&keep);
run;

proc print n;
	var &keep;
	sum amt_to_pay;
run;

proc export data=entitle4 
	outfile="&srvname.\&prjname.\out\data\Jan08_Pay_test.csv"
	dbms=csv 
	replace;
	/* label delimiter= putnames=yes/no sheet=FY20_pay */
run;

/*
proc print;
id co dist;
var pp amt_to_pay;
sum amt_to_pay;
format amt_to_pay comma16.;
run;
*/

/*
%include "&srvname.\hdrhead\prmsas\read_param.sas"  /source2;
ods pdf
file="&srvname.\&cfs.\OUT\REPORTS\STATE_AID\Y&yr1.&yr2.SAPMTCFS_&payper.__&ccyymmdd._.pdf";

%include "&srvname.\hdrhead\prmsas\create_cfs.sas"/source2;
ods pdf close;
*/