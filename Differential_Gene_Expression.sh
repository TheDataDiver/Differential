#!/bin/bash

####################### 1.0 Asking user to input the path, which will be used to create an output directory where all fastqc and further files will be outputted to. THEN STORING THE CREATED SUBDIRECTORY AS A VARIABLE  #######################

inputpathforoutput () {
echo -e "Please input the path of an existing directory followed by the name of the subdirectory you'd like to create (Do not include / at the end of the path). This is where where  all output data down the line will be stored"
### Reads the input from the user and saves it as a variable called theoutputdirectory
read theoutputdirectory
echo -e "\n"
read -p "Is "$theoutputdirectory" the subdirectory you wish to create? (y/n)" choice
if [ "$choice" = "y" ];
then
### Creating outuput directory where all future output will be saved
mkdir "${theoutputdirectory}"
echo -e "\nThe output directory has been succesfuly created, and it's path is listed below"
echo -e "${theoutputdirectory}"
else
### Safety loop, bringing the user back to the start of the function if he enters the wrong path.
inputpathforoutput;
fi
}

inputpathforoutput
