#!/bin/sh

RUNDIR=$(pwd)
DATADIR=$(echo $(pwd)"/data")
[[ ! -d "$DATADIR" ]] && mkdir "$DATADIR"

for YEAR in $(seq 2000 $(date +"%Y"))
do
  FILEURL=$(echo "http://reports.ieso.ca/public/Demand/PUB_Demand_"$YEAR".csv")
  if wget --spider "$FILEURL" 2>/dev/null
  then
    cd "$DATADIR"
    wget -N "$FILEURL"
    cd "$RUNDIR"
  fi
done
