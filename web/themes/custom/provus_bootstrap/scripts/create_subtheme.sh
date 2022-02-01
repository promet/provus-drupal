#!/bin/bash
# Script to quickly create sub-theme.

echo '
+------------------------------------------------------------------------+
| With this script you could quickly create provus 2.0 sub-theme     |
| In order to use this:                                                  |
| - provus theme (this folder) should be in the contrib folder   |
+------------------------------------------------------------------------+
'
echo 'The machine name of your custom theme? [e.g. myCUSTOM_PROVUS]'
read CUSTOM_PROVUS

echo 'Your theme name ? [e.g. My custom Provus site]'
read CUSTOM_PROVUS_NAME

if [[ ! -e ../../custom ]]; then
    mkdir ../../custom
fi
cd ../../custom
cp -r ../contrib/provus $CUSTOM_PROVUS
cd $CUSTOM_PROVUS
for file in *provus.*; do mv $file ${file//provus/$CUSTOM_PROVUS}; done
for file in config/*/*provus.*; do mv $file ${file//provus/$CUSTOM_PROVUS}; done

# Remove create_subtheme.sh file, we do not need it in customized subtheme.
rm scripts/create_subtheme.sh

# mv {_,}$CUSTOM_PROVUS.theme
grep -Rl provus .|xargs sed -i -e "s/provus/$CUSTOM_PROVUS/"
sed -i -e "s/Provus Starter Kit Subtheme/$CUSTOM_PROVUS_NAME/" $CUSTOM_PROVUS.info.yml
echo "# Check the themes/custom folder for your new sub-theme."
