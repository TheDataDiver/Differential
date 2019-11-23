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


####################### 4.0 INSERTING "STAGE OF LIFECYCLE" TAKEN FROM THE SAMPLE DETAIL FILE INTO THE FILENAME OF THE COPIED RAW DATA FILES  #######################

### Sets a variable for the path of the sampledetail file, which has been copied to the output directory
sampledetailfile=$(find ${theoutputdirectory} -type f -name ${sampledetailfilename})
### Finds all the copied fq.gz files and sorts them alphabetically before displaying them in a table
find ${theoutputdirectory}/rawdata -name '*.fq.gz' | sort | nl | column -t
### Counts the total number of found fq.gz files
numberoffiles=$(find ${theoutputdirectory}/rawdata -name '*.fq.gz' | grep -c "/*.fq.gz")
echo -e "\nThere are ${numberoffiles} FASTQ sequencing data files in the output directory. \n"
echo "The raw data files as listed above from the output directory, shall now be renamed to include the sample detail name, to help in the identification of raw data. \n"
unset IFS
### Sets he columns of the sample detail file as variables, then uses these variables to rename the fq.gz files to contain the lifecyclename at the start of the file name
while read n1 lifecyclename forwardsequence reversesequence;
do
originalpathforward="${theoutputdirectory}/rawdata/$forwardsequence"
originalpathreverse="${theoutputdirectory}/rawdata/$reversesequence"
newpathforward=${theoutputdirectory}/rawdata/${lifecyclename}"_${forwardsequence}"
newpathreverse=${theoutputdirectory}/rawdata/${lifecyclename}"_${reversesequence}"
mv ${originalpathforward} ${newpathforward}
mv ${originalpathreverse} ${newpathreverse}
done < ${sampledetailfile}

### Finds the newly renamed fq.gz files and prints it on the screen for the user to see. Renaming of the files will enable for easier identification during fastqc etc
ls -l ${theoutputdirectory}/rawdata | grep "/*.fq.gz" | awk '{print $NF;}' | nl | column -t
echo -e "\n"
echo -e "Raw data files have now been succesfuly renamed to include the sample details as shown above. \n"


####################### 5.0 MAKING DIRECTORY FOR FASTQC RESULT OUTPUT. OUTPUTDIRECTORY/FASTQC_RESULT  #######################

mkdir ${theoutputdirectory}/fastqc_result


####################### 5.1 PERFORMING FASTQC ANALYSIS ON ALL SAMPLES  #######################

echo -e "\nPlease wait while all samples undergo FASTQC analysis"
fqcallfiles=$(find ${theoutputdirectory}/rawdata -name '*.fq.gz' | sort)
### Performs fastqc on all fq.gz files in the output directory. Fastqc is silenced and automatically extracts the output
fastqc -t 50 --quiet -o ${theoutputdirectory}/fastqc_result --extract ${fqcallfiles}
find ${theoutputdirectory}/fastqc_result -name '*.zip' | xargs rm
echo -e "\nFASTQC analysis complete for all samples.\n"


####################### 6.0 PRINTING IN A TABLE, THE SAMPLE NAME, TOTAL SEQUENCES, NUMBER OF POOR QUALITY READS, SEQUENCE LENGTH AND GC CONTENT OF ALL FQCED SAMPLES  ####################

allfqcdetails=$(find ${theoutputdirectory} -name '*fastqc_data.txt' | sort)

awk -F"\t" '
BEGIN { print "========================================================================================================================="
printf "%-25s %-25s %-25s %-25s %-25s\n","Sample name","Total sequences","Poor quality","Sequence length","GC content"
print "========================================================================================================================="
} '

for files in $allfqcdetails
do
awk -F"\t" ' NR == 4 { printf "%-30s", substr($2, 1, length($2)-6)}; NR == 7 { printf "%-25s",$2 }; NR == 8 { printf "%-25s", $2 }; NR == 9 { printf "%-25s", $2 }; NR == 10 { printf "%-25s\n", $2 }' $files
done

####################### 7.0 PRINTING IN A TABLE, ALL MODULES THAT FAILED OR WARNED FOR ALL FQCED SAMPLES  #######################

allfqcsummaries=$(find ${theoutputdirectory} -name '*summary.txt' | sort)

echo -e "\n"

awk -F"\t" '
BEGIN { print "========================================================================================================================="
printf "%-30s %-20s %-30s %-20s %-30s\n","Sample name","Modules Failed","Name of Failed Modules","Modules Warned","Name of Warned Modules"
print "========================================================================================================================="
} '

passcount=$(awk -F"\t" '/PASS/ {count++} END {print count}' $allfqcsummaries)
failcount=$(awk -F"\t" '/FAIL/ {count++} END {print count}' $allfqcsummaries)
warncount=$(awk -F"\t" '/WARN/ {count++} END {print count}' $allfqcsummaries)

for files in $allfqcsummaries
do
### Setting the variable to search the fastqc summary.txt file and retrieves the sample name, removing the fq.gz extension, to make it neater
nameofsample=$(awk -F"\t" '{print substr($3, 1, length($3)-6)}' $files | uniq)
### Setting variable to count the number of failed modules for the sample
failcount=$(awk -F"\t" '/FAIL/ {count++} END {print count}' $files)
### Setting variable to count the number of warned modules for the sample
warncount=$(awk -F"\t" '/WARN/ {count++} END {print count}' $files)
### setting variable to print the names of the failed modules for the sample
failmodules=$(awk -F"\t" '$1 == "FAIL" {print $2}' $files)
### setting the variable to print the names of the warned modules for the sample
warnedmodules=$(awk -F"\t" '$1 == "WARN" {print $2}' $files)

### Printing a table with all the aforementioned variables, outputting it in a neat fashion
printf {"%-30s %-20s %-30s %-20s %-30s\n","$nameofsample","$failcount","$failmodules","$warncount","$warnedmodules"}

done


####################### 8.0 ASKING THE USER IF HE'D LIKE TO VIEW IN FIREFOX, THE OUTPUT FOR A SPECIFIC FASTQC OUTPUT ##############

openfastqchtml () {
echo -e "\n \n"
read -p "Based on the above information, would you like to view the report of a specific fastqc sample? (y/n)" choice
if [ "$choice" = "y" ];
then
echo -e "Please type the name of the sample that you'd like to view the report of. Eg. 219_L8_1"
### Reads user input and saves it as a variable, subsequently reads the variable and finds files containing this variable that ends in html
read viewreportof
### Finds the html file containing the characters that the user has inputted, then opens it in firefox. Eg. Slender will open all slender html, 219_L8 will open both 219_L8_1 and 219_L8_2
firefoxlinks=$(find ${theoutputdirectory}/fastqc_result -name "*$viewreportof*" -a -name "*.html" | awk '{print}' ORS=" ")
firefox ${firefoxlinks}
echo -e "\n"
openfastqchtml
else
:
fi
}

openfastqchtml


####################### 9.0 CREATION OF ARRAY THAT ENABLES FILTERING OF FASTQC OUTPUT VIA USER INPUT, SO THAT THOSE FASTQC SAMPLES THAT THE USER DEEMED TO HAVE FAILED, ARE NOT ALIGNED  #######################

mkdir ${theoutputdirectory}/failedfastqc/

listingthefiles=($(find "${theoutputdirectory}/rawdata" -type f -name '*.fq.gz' | sort | tr '\n' ' '))

### Creating the array for the user to select files which he has deemed t have failed FASTQC analysis
failedfastqcselectionmenu () {
echo -e "\n\nAvailable options:"
for i in ${!listingthefiles[@]}; do
printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${listingthefiles[i]}"
done
[[ "$msg" ]] && echo "$msg";:
}


failedfastqcselection () {
echo -e "\n"
prompttheuser="Select files that failed FASTQC analysis, these files will not be aligned.  Enter an option (enter again to uncheck), press RETURN without any input to finalise selection:"
while failedfastqcselectionmenu && read -rp "$prompttheuser" num && [[ "$num" ]]; do
[[ "$num" != *[![:digit:]]* ]] && ((num > 0 && num <= ${#listingthefiles[@]} )) || {
msg="Option is not valid: $num"; continue
}

if [ $num == ${#listingthefiles[@]} ]; then
exit
fi

((num--)); msg="${listingthefiles[num]} was ${choices[num]:+un-}selected"
[[ "${choices[num]}" ]] && choices[num]="" || choices[num]="x"
done

### Following selection of the files and finalising the input by pressing RETURN, it will echo which files have been selected to be excluded from BAM alignment.
### These files will be moved to the failedfastqc subdirectory within the parent outputdirectory. They wont be aligned.
echo -e "\n"
printf "The following files will be excluded from BAM alignment"; msg=""
for i in ${!listingthefiles[@]}; do
[[ "${choices[i]}" ]] && { printf "%s" "${listingthefiles[i]}"; msg="";
echo -e "\n"
mv ${listingthefiles[i]} ${theoutputdirectory}/failedfastqc/
}
done
}

failedfastqcselection


####################### 10.0 CREATING DIRECTORY FOR ALIGNMENT OUTPUT, COPYING REFERENCE GENOME FROM ORIGINAL RAW DATA PATH TO ALIGNMENT OUTPUT DIRECTORY #######################

mkdir ${theoutputdirectory}/alignment

### Searches the path specified by the user in step 2.0, and copies the reference genome, and unzips it. It then finds the copied/unzipped reference genome and echos its path to the user
find ${rawdatamasterpath} -type f -name "*fasta.gz" | xargs -I {} cp {} $theoutputdirectory/alignment
find ${theoutputdirectory}/alignment -type f -name  "*fasta.gz" | xargs -I {} gunzip {}
referencegenomename=$(find ${theoutputdirectory}/alignment -name '*.fasta')
echo -e "\nReference genome file has been copied to output directory: ${referencegenomename} \n"


####################### 11.0 Changes directory to output directory and Builds bowtie2 index files from the unzipped reference genome  ##############

cd ${theoutputdirectory}/alignment
echo -e "Input the desired name for the bowtie2 index that is about to be built. Eg -> Trypanosome_Brucei"
read bowtie2index
### Allows user to input the name for the bowtie index that is about to be built.
echo -e "\nPlease wait while the bowtie index is being built... \n"
find ${theoutputdirectory}/alignment -type f -name  "*.fasta" | xargs -I {} bowtie2-build --quiet --threads 50 {} $bowtie2index
echo -e "The bowtie index has been built"


####################### 12.0 Aligning/Mapping the read pairs to THE REFERENCE Genome, and converting to BAM format  ##############

### Searches the rawdata subdirectpry for all the fq.gz files (those selected in the array by the user, were moved to the failedfastqc subdirectory, and thus won't be found
### It then removes the _1.fq.gz from the file name, leaving Slender_216_L8. Uniq gets rid of the duplicate lines
fqsortedfiles=$(find ${theoutputdirectory}/rawdata -type f -name "*.fq.gz" | sort | rev | cut -c 9- | rev | uniq)
for fqcfile in  ${fqsortedfiles};
do
outputbamname=$(echo "$fqcfile" | awk -F"/" '{print $NF}')
echo -e "\nNow aligning: ${fqcfile}, please wait"
bowtie2 -x $bowtie2index -1 ${fqcfile}_1.fq.gz -2 ${fqcfile}_2.fq.gz --no-mixed --no-discordant --no-unal -p 50 | samtools view -bS - > ${theoutputdirectory}/alignment/${outputbamname}.bam
done


####################### 13.0 COPYING BEDFILE TO OUTPUT DIRECTORY  ##############

echo -e "\n"
bedfilename=$(find ${rawdatamasterpath} -name *.bed)
echo -e "\n"
### Copies the bed file from the raw data path specified by the user, to the alignment subdirectory in the parent outputdirectory
cp ${bedfilename} ${theoutputdirectory}/alignment
bedfilecopiedname=$(find ${theoutputdirectory}/alignment -name *.bed)
echo -e "The bedfile has been succesfully copied to output directory: $bedfilecopiedname \n"


####################### 14.0 CREATING BAM INDEX FROM ALL BAM FILES  ##############

thebamfiles=$(find ${theoutputdirectory}/alignment -name '*.bam' | sort)

for files in $thebamfiles;
do
### Removes the _1 or _2 from the .bam files it has found in the alignment subdirectory, and saves it as a variable, which will be used to name the sorted.bam file
bamfilename=${files%%.*}
echo -e "Currently sorting the bam file of ${bamfilename}"
### Sorting the bam files
samtools sort -@ 50 $files -o ${bamfilename}.sorted.bam
echo -e "Bam file of ${bamfilename} has been succesfully sorted\n"
done

sortedbamfiles=$(find ${theoutputdirectory}/alignment -name '*.sorted.bam' | sort)

for files in $sortedbamfiles
do
### Indexing the sorted bam files
samtools index -@ 50 $files
echo -e "Currently creating the index for $files"
echo -e "Index succesfully created for $files \n"
done
