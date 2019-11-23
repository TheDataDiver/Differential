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


####################### 2.0 Creating function and running it: ASKING USER TO INPUT THE PATH OF THE  DIRECTORY WHERE ALL RAW DATA IS STORED, THEN STORING THE PATH AS A VARIABLE. THEN COPYING ALL FQ.GZ FILES INTO OUTPUTDIRECTORY/RAWDATA #######################

copyingrawdatafiles () {
echo -e "\nPlease input the full path of the main directory where ALL THE RAW DATA IS STORED (Do not include / at the end of the path)."
### Reads the input from the user and saves it as a variable called rawdatamasterpath
read rawdatamasterpath
echo -e "\n"
### Finds all files ending in fq.gz in the directory the user specified. It then prints it in a column and numbers the fq.gz files so the user can see how many sequencing data files is present
find ${rawdatamasterpath} -name '*.fq.gz' | sort | nl | column -t
echo -e "\n"
read -p "Are your FASTQ sequencing data files and sample details listed above? (y/n)" choice
if [ "$choice" = "y" ];
then
echo -e "\n"
allthefqfiles=$(find ${rawdatamasterpath} -name '*.fq.gz' | sort)
### Creates a subdirectory called rawdata, in the parent directory (theoutputdirectory). All raw data will subsequently be stored here.
### All files ending in fq.gz are then copied into this subdirectory
mkdir ${theoutputdirectory}/rawdata
cp -r ${allthefqfiles} ${theoutputdirectory}/rawdata
echo -e "The above listed files have now been succesfully copied to the output directory: ${theoutputdirectory}/rawdata \n"
### Safety loop, if user enters the wrong path, his fq.gz files will not be listed as it will not be able to find them. User then types n, which will bring him back to the start of the function
else
echo -e "\nThe specified path of the directory was probably wrong, try re-entering the path again\n"
copyingrawdatafiles;
fi
}

copyingrawdatafiles


####################### 3.0 CREATING FUNCTION AND RUNNING IT: ASKING USER TO INPUT THE NAME OF THE FILE CONTAINING SAMPLE DETAILS #######################

gettingsampledetails () {
echo -e "\nPlease provide ONLY THE NAME (not its path) of the file which contains the sample details. Eg. fqfiles"
### Reads the input from the user and saves the name of the sample detail file as a variable
read sampledetailfilename
echo -e "\n"
### Finds the sample detail file, opens it and prints the lifecycle name, and the name of both the forward and reverse sequence files
find ${rawdatamasterpath} -type f -name ${sampledetailfilename} | xargs -I {} cat {} | awk '{print $2, $3, $NF;}' | column -t | nl
echo -e "\n"
read -p "Are your sample details listed above? (y/n)" choice2
if [ "$choice2" = "y" ];
then
echo -e "\n"
### Finds the sample detail file by searching within the raw data path that is saved as a variable, for the sample detail file name which is saved as a variable
thesamplefile=$(find ${rawdatamasterpath} -type f -name ${sampledetailfilename})
### Copies the sample detail file to the rawdata subdirectory in parent outputdirectory
cp ${thesamplefile} ${theoutputdirectory}/rawdata
echo -e "The file containing sample details has been copied to the output directory: ${theoutputdirectory}/rawdata \n"
else
### Safety loop, if user entered the wrong file name for the sample detail, lifecyclenames and forward/reverse sequnce file names will not be printed. Typing n will loop the user back to the start of the function
echo -e "\n The specified path of the file which contains the sample details was probably wrong, try re-entering the path again. \n"
gettingsampledetails;
fi
}

gettingsampledetails
