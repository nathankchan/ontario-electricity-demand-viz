#!/bin/sh

source update.sh

RUNDIR=$(pwd)
PLOTDIR=$(echo $(pwd)"/plots")
[[ ! -d "$PLOTDIR" ]] && mkdir "$PLOTDIR"

for DATAFILE in $(ls data)
do
  Rscript script.R "$(echo $RUNDIR'/data/'$DATAFILE)"
done

Rscript compare.R 2002 2>/dev/null
Rscript compare.R 2006 2>/dev/null
Rscript compare.R 2010 2>/dev/null
Rscript compare.R 2014 2>/dev/null
Rscript compare.R 2018 2>/dev/null

echo "run.sh has finished"
