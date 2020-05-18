#!/bin/bash

###########################
# This script has been used to calculate the metagenome assembled fraction of each draft-assembly. This script uses pileup.sh (https://github.com/BioInfoTools/BBMap) and is the alternative of metaQUAST strategy.

# It is important to note that it has been designed for a specific working directory. Therefore, the reproduction of the results will require small modifications of the script or the adaptation of your working directory.

# Created on Friday March 20 2020.

# @author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.

# Version: 2
###########################

Path_current=$(pwd)

# The variable Path_reference contains the path to the folder where all the FASTA files of the individual reference genomes are located. Put always a slash at the end of the path.
Path_reference=/media/darwin/Externo/TFM/Ensamblaje_y_evaluacion/Genomes/

# Check the existence of directory.
if [ ! -d $Path_reference ]; then
	echo $Path_reference "doesn't exist"
	echo -------------------------------------------------------------------------------------------------------
	exit 1
fi	

cd $Path_reference
echo -e "\n"CREATE AND INDEX THE METAGENOME REFERENCE OF THE GENOMES LOCATED IN... 
pwd
echo -e "\n"GENOMES":"
cat List_genomes.txt
echo -e "\n"

# create the metagenome reference with metagenome_reference.py (in-house script)
metagenome_reference.py $Path_reference metagenome_reference.fasta List_genomes.txt

# Index the metagenome the reference with minimap2 (https://github.com/lh3/minimap2)
minimap2 -x map-ont -d metagenome_reference.mmi metagenome_reference.fasta

cd $Path_current

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
			echo -e "\n\n"coverage ${Assemblers[$j]} ${INFO[$i]} ${INFO[$i+2]} | tr '[:lower:]' '[:upper:]'
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

			# Create SAM file mapping the draft-assembly on the metagenome reference.
			minimap2 -ax map-ont -t 16 -a "$Path_reference"metagenome_reference.mmi $FILE > aln.sam

			# Calculate the metagenome assembled fraction.
			{ pileup.sh in=aln.sam out=stats.txt hist=histogram.txt 2> coverage_${INFO[$i+1]}_${Assemblers[$j]}.txt ; }

			# Delete some files.
			rm *.sam

		else
			echo $FILE "doesn't exist"
		fi

		echo -------------------------------------------------------------------------------------------------------
		cd ../../../
	done
done
