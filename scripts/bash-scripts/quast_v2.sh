#!/bin/bash

###########################
# This script has been used to evaluate the draft-assemblies with the program QUAST https://github.com/ablab/quast .

# It is important to note that it has been designed for a specific working directory. Therefore, the reproduction of the results will require small modifications of the script or the adaptation of your working directory.

# Created on Wednesday March 18 2020.

# @author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.

# Version: 2
###########################

# Create the following lists:
# -	INFO contains the dataset information. The structure of the information contained in INFO is: (Name Nomenclature Size). For example: (Even_GridION EG3 3Gb).
# -	Assemblers contains the name of the assemblers. For example: (canu).
# In both cases, the number of datasets and assemblers can be reduced.
INFO=(Even_GridION EG3 3Gb Even_GridION EG6 6Gb Log_GridION LG3 3Gb Log_GridION LG6 6Gb Even_PromethION EP3 3Gb Even_PromethION EP6 6Gb Log_PromethION LP3 3Gb Log_PromethION LP6 6Gb)
Assemblers=(canu metaflye_v24 metaflye_v27 megahit minia miniasm pomoxis raven redbean shasta unicycler wtdbg2)

echo -e "\n\n"---------------------------STARTING----------------------------

for ((i=0; i<=${#INFO[@]}-1; i+=3)); do
	for ((j=0; j<=${#Assemblers[@]}-1; j++)); do

		# Check the existence of directory.
		FOLDER=${INFO[$i]}_assembly/${INFO[$i+2]}/${Assemblers[$j]}_${INFO[$i+2]}
		if [ -d ./$FOLDER ]; then
			echo -e "\n\n"quast ${Assemblers[$j]} ${INFO[$i]} ${INFO[$i+2]} | tr '[:lower:]' '[:upper:]'
			echo
			cd $FOLDER
		else
			echo -e "\n\n"CONTINUE IN THE FOLLOWING ASSEMBLER OR DATASET
			echo
			echo ./$FOLDER "doesn't exist"
			echo -------------------------------------------------------------------------------------------------------
			continue
		fi
		
		# Check the existence of draft-assembly file.
		# The draft-assembly file name has always the same structure: draft_assembly_(dataset nomenclature like EG3)_(Name of assembler like canu).fa
		FILE=draft_assembly_${INFO[$i+1]}_${Assemblers[$j]}.fa
		if [ -s $FILE ]; then
			
			# Execute QUAST.
			quast.py -o quast -t 16 $FILE
		else
			echo $FILE "doesn't exist"
		fi

		echo -------------------------------------------------------------------------------------------------------
		cd ../../../
	done
done
