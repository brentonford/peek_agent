#!/bin/bash

set -o nounset
set -o errexit
set -x

# activate virtualenv
export PATH=/home/bamboo/pyenvs/py_ut/bin:$PATH

# Define python path
PYTHONPATH="`pwd`/peek_platform/src"
PYTHONPATH="$PYTHONPATH:`pwd`/rapui/src"
PYTHONPATH="$PYTHONPATH:`pwd`/peek_agent/src"
export PYTHONPATH

UT_DIRS="peek_agent"

FILES=`find $UT_DIRS -name "*.py" -exec grep -l unittest.TestCase {} \;`
echo "Running unit tests in files:"
echo $FILES

JUNIT_DIR=.junit
mkdir ${JUNIT_DIR}
OUT=${JUNIT_DIR}/trial.xml

echo "TEST1 ==================================================================="
trial --reporter=subunit ${FILES}

echo "TEST2 ==================================================================="
trial --reporter=subunit ${FILES} | subunit-1to2

echo "TEST3 ==================================================================="
trial --reporter=subunit ${FILES} | subunit-1to2 | subunit2junitxml -o $OUT

echo "Finished"

