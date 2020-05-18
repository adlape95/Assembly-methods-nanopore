#!/bin/bash

###########################
# This script has been used to remove the adapters of the datasets with the program porechop https://github.com/rrwick/Porechop

# It is important to note that it has been designed for a specific working directory. Therefore, the reproduction of the results will require small modifications of the script or the adaptation of your working directory.

# Created on Friday March 6 2020.

# @author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.

# Version: 2
###########################

# Create the following list:
# -	INFO contains the dataset information. The structure of the information contained in INFO is: (Name Size). For example: (Even_GridION 3Gb). The structure of this list changes in the other scripts.
INFO=(Even_GridION 3Gb Even_GridION 6Gb Log_GridION 3Gb Log_GridION 6Gb Even_PromethION 3Gb Even_PromethION 6Gb Log_PromethION 3Gb Log_PromethION 6Gb)

echo -e "\n\n"---------------------------STARTING----------------------------

for ((i=0; i<=${#INFO[@]}-1; i+=2)); do

	# Check the existence of directory.
	FOLDER=${INFO[$i]}_assembly/${INFO[$i+1]}
	if [ -d ./$FOLDER ]; then
		echo -e "\n\n"Finding and removing adapters from ${INFO[$i]} ${INFO[$i+1]} fastq files...
		echo
		cd $FOLDER
	else
		echo -e "\n\n"CONTINUE IN THE FOLLOWING DATASET
		echo
		echo ./$FOLDER "doesn't exist"
		echo -------------------------------------------------------------------------------------------------------
		continue
	fi

	# Check the existence of dataset file.
	# The dataset file name has always the same structure: (dataset name like Even_GridION)_(Size like 3Gb).fastq
	FILE=${INFO[$i]}_${INFO[$i+1]}.fastq
	if [ -s $FILE ]; then

		# Remove the adapters
		porechop -i $FILE --format fastq -t 16 -o ${INFO[$i]}_${INFO[$i+1]}_trimmed.fastq

	else
		echo $FILE "doesn't exist"
	fi

	echo -------------------------------------------------------------------------------------------------------
	cd ../../
done
