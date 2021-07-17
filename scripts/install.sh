#!/bin/bash
CHART_NAME="application"

DEPLOYED=$(helm list | awk '{ print $1 }' | grep "^application$" | wc -l)

if [ $DEPLOYED == 1 ]; then
   helm upgrade application ../helm/application
else
   helm install application ../helm/application
fi