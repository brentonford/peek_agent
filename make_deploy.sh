#!/bin/bash

set -o nounset
set -o errexit
set -x

function convertBambooDate() {
# EG s="2010-01-01T01:00:00.000+01:00"
# TO 100101.0100
python <<EOF
from dateutil.parser import parse
print parse("${BAMBOO_DATE}").strftime('%y%m%d.%H%M')
EOF
}
echo "start version is $VER"

BUILD="${BUILD}"
VER="${VER}"
DATE="`convertBambooDate`"

if [ "${VER}" == '${bamboo.jira.version}' ]; then
    VER="b${DATE}"
fi

echo "New version is $VER"
echo "New build is $BUILD"

TAR_DIR="peek_agent_$VER#$BUILD"
DIR="deploy/$TAR_DIR"
mkdir -p $DIR


# Source
cp -pr rapui/src/rapui $DIR
cp -pr papp_base/src/papp_base $DIR
cp -pr peek_platform/src/peek_platform $DIR
cp -pr peek_agent/src/peek_agent $DIR
cp -p  peek_agent/src/run_peek_agent.py $DIR
cp -pr jsoncfg/src/jsoncfg $DIR

# Init scripts, etc
cp -p  peek_agent/init/peek_agent.init.rhel.sh $DIR
cp -p  peek_agent/init/run_peek_agent.sh $DIR

# Remove unneeded RapUI components
rm -rf $DIR/rapui/bower_components

find $DIR -iname .git -exec rm -rf {} \; || true
find $DIR -iname "test" -exec rm -rf {} \; 2> /dev/null || true
find $DIR -iname "tests" -exec rm -rf {} \; 2> /dev/null || true
find $DIR -iname "*test.py" -exec rm -rf {} \; || true
find $DIR -iname "*tests.py" -exec rm -rf {} \; || true
find $DIR -iname ".Apple*" -exec rm -rf {} \; || true
find $DIR -iname "*TODO*" -exec rm -rf {} \; || true
find $DIR -iname ".idea" -exec rm -rf {} \; || true



# Apply version number

for f in `grep -l -r  '#PEEK_VER#' .`; do
    echo "Updating version in file $f"
    sed -i "s/#PEEK_VER#/$VER/g" $f
done

for f in `grep -l -r  '#PEEK_BUILD#' .`; do
    echo "Updating build in file $f"
    sed -i "s/#PEEK_BUILD#/$BUILD/g" $f
done

for f in `grep -l -r  '#BUILD_DATE#' .`; do
    echo "Updating date in file $f"
    sed -i "s/#BUILD_DATE#/$DATE/g" $f
done


echo "Compiling all python modules"
( cd $DIR && python -m compileall -f . )

echo "Deleting all source files"
find $DIR -name "*.py" -exec rm {} \;

pushd deploy
tar cjf ${TAR_DIR}.tar.bz2  $TAR_DIR

rm -rf $TAR_DIR
popd
