Version 3
UPDATED 01/07/2019 8:51:40

------------------------------
RUN
------------------------------

This script is intended to run on an R80.+ Check Point Firewall
(Requires jq utility)

install:
  cp o365_dynObj.sh $CPDIR/bin
  chmod 755 $CPDIR/bin/o365_dynObj.sh

Usage:
  o365_dynObj.sh

Check:
  dynamic_objects -l

Schedule:
   cpd_sched_config add o365Update -c $CPDIR/bin/o365_dynObj.sh -e 86400 -r -s

See scheduled status:
   cpd_sched_config print

Remove scheduled task:
   cpd_sched_config delete o365Update

------------------------------
LOGS
------------------------------

A Log of events can be found at $FWDIR/log/o365_dynObj.log. 

------------------------------
Change Log
------------------------------

v3 - 1/07/19  - 3rd build - updated to new MS format - json from "https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7"
v2 - 6/19/18  - 2nd build - Added function to clear object before updating.
v1 - 5/17/18  - 1st version

------------------------------
Author
------------------------------
CB Currier - ccurrier@checkpoint.com
