#!/bin/bash

###########################
# This script has been used to calculate the number os SNPs and INDELs of each draft-assembly. In this case, the script use the strategy 1: minimap2 + samtools + bcftools + indels_and_snps.py

# It is important to note that it has been designed for a specific working directory. Therefore, the reproduction of the results will require small modifications of the script or the adaptation of your working directory.

# Created on Monday March 30 2020.

# @author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.

# Version: 2
###########################

Path_current=$(pwd)

# The variable Path_reference contains the path to the folder where all the FASTA files of the individual reference genomes are located. Put always a slash at the end of the path.
Path_reference=/media/darwin/Externo/TFM/SNPs_e_INDELs/Estrategia_1/Genomes/

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

# Create the metagenome reference with metagenome_reference.py (in-house script).
metagenome_reference.py $Path_reference metagenome_reference.fasta List_genomes.txt

# Index the metagenome the reference with minimap2 (https://github.com/lh3/minimap2).
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
		FOLDER=${INFO[$i]}_variants/${INFO[$i+2]}/${Assemblers[$j]}_${INFO[$i+2]}
		if [ -d ./$FOLDER ]; then
			echo -e "\n\n"variants ${Assemblers[$j]} ${INFO[$i]} ${INFO[$i+2]} | tr '[:lower:]' '[:upper:]'
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
			echo -e "\n\n"${INFO[$i]}_variants_1, ${INFO[$i+2]}, ${Assemblers[$j]}"\n" >> ../variants_1.stderr
			echo -e "\n\n"${INFO[$i]}_variants_1, ${INFO[$i+2]}, ${Assemblers[$j]}"\n" >> ../Results_variants_1.txt
			
			# Create SAM file mapping the draft-assembly on the metagenome reference with minimap2.
			minimap2 -ax map-ont -t 16 "$Path_reference"metagenome_reference.mmi $FILE > aln.sam

			# Convert SAM to BAM file and sort it.
			samtools view -bS aln.sam > aln.bam
			samtools sort aln.bam -o aln_sorted.bam

			# Index the metagenome reference FASTA file.
			samtools faidx "$Path_reference"metagenome_reference.fasta
			samtools index aln_sorted.bam
			
			# Search SNPs and INDELs and generate the VCF file.
			{ bcftools mpileup -Oz --threads 16 -f "$Path_reference"metagenome_reference.fasta aln_sorted.bam | bcftools call -cv - > var.raw.vcf 2>> ../variants_1.stderr ; }
			
			# Extract the number of SNPs and INDELs from the VCF file.
			indels_and_snps.py var.raw.vcf >> ../Results_variants_1.txt
			
			# Delete some files.
			rm *.sam
			rm *.bam
			rm *sorted.bam.bai
			rm *.vcf

		else
			echo $FILE "doesn't exist"
		fi

		echo -------------------------------------------------------------------------------------------------------
		cd ../../../
	done
done
