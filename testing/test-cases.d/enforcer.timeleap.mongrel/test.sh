#!/usr/bin/env bash

# Change this line to return 1 even on success if you want to leave
# the output files around for inspection
KEEP_LOG_ON_SUCCESS=0
WRITE_GOLD=0
RANGE=`seq 1 200`

if [ -n "$HAVE_MYSQL" ]; then
        ods_setup_conf conf.xml conf-mysql.xml
fi &&

ods_reset_env &&
rm -rf base && mkdir base &&

ods_start_enforcer &&

log_this 01_zone_add 'ods-enforcer zone add --zone zone0a' &&
log_this 01_zone_add 'ods-enforcer zone add --zone zone0b' &&
log_this 01_zone_add 'ods-enforcer zone add --zone zone1 -p csk' &&
log_this 01_zone_add 'ods-enforcer zone add --zone zone2a -p notshared' &&
log_this 01_zone_add 'ods-enforcer zone add --zone zone2b -p notshared' &&
log_this 01_zone_add 'ods-enforcer zone add --zone zone3 -p dual' &&

for n in $RANGE
do
	ods-enforcer key list -v -p | cut -d ";" -f 1-6,8|sed -r "s/[0-9-]{10} [0-9:]{8}/date time/" > base/$n.verbose &&
	ods-enforcer key list -d -p | cut -d ";" -f 1-8 > base/$n.debug &&
	log_this 02_timeleap 'ods-enforcer time leap --attach' 
done &&

if [ $WRITE_GOLD -eq 1 ]
then
	rm -rf gold
	cp -r base gold
fi &&

for n in $RANGE
do
	diff base/$n.verbose gold/$n.verbose &&
	diff base/$n.debug gold/$n.debug
done &&

ods_stop_enforcer &&
echo "**** OK" &&
return $KEEP_LOG_ON_SUCCESS

echo  "**** FAILED"
ods_kill
return 1
