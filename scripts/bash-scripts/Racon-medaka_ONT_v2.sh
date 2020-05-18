#!/bin/bash

###########################
# This script has been used to evaluate the polishing step using ONT data. The state-of-art polishing pipeline of metagenomic assemblies with ONT data is 4 rounds of racon + medaka.

# It is important to note that it has been designed for a specific working directory. Therefore, the reproduction of the results will require small modifications of the script or the adaptation of your working directory.

# Created on Wednesday April 8 2020.

# @author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.

# Version: 2
###########################

Path_current=$(pwd)

# The variable Path_reference contains the path to the folder where all the FASTA files of the individual reference genomes are located. Put always a slash at the end of the path.
Path_reference=/media/darwin/Externo/Directorio_estudio_2/Polishing/Genomes/

# Check the existence of directory.
if [ ! -d $Path_reference ]; then
	echo $Path_reference "doesn't exist"
	echo -------------------------------------------------------------------------------------------------------
	exit 1
fi	

cd $Path_reference
echo -e "\n"CREATE THE METAGENOME REFERENCE OF THE GENOMES LOCATED IN... 
pwd
echo -e "\n"GENOMES":"
cat List_genomes.txt
echo -e "\n"

# Create the metagenome reference with metagenome_reference.py (in-house script).
metagenome_reference.py $Path_reference metagenome_reference.fasta List_genomes.txt

cd $Path_current

# Path of sequences ONT which are used to polih the draft-assembly. Put always a slash at the end of the path.
Path_ONT_sequences=/media/darwin/Externo/Directorio_estudio_2/Polishing/Sequences_ONT/

# Check the existence of directory.
if [ ! -d $Path_ONT_sequences ]; then
	echo $Path_ONT_sequences "doesn't exist"
	echo -------------------------------------------------------------------------------------------------------
	exit 1
fi	

# Activate the medaka enviornment. For more information (https://github.com/nanoporetech/medaka).
source activate medaka

# This variable control if the Racon rounds loop "for" has been broken due to some error.
# Value= 0 --> It has not been broken.
# Value= 1 --> It has been broken.
check_break=0

# Create the following lists:
# -	Assemblers contains the name of the assemblers. For example: (canu).
# - 	Rounds_Racon_by_assembler allows you to perform a different number of rounds for each assembler.
# In both cases, the number of datasets and assemblers can be reduced.
Assemblers=(canu metaflye_v24 metaflye_v27 megahit minia miniasm pomoxis raven redbean shasta unicycler wtdbg2)
Rounds_Racon_by_assembler=(2 1)

echo -e "\n\n"---------------------------STARTING----------------------------

for ((j=0; j<=${#Assemblers[@]}-1; j++)); do

	# Check the existence of directory.
	FOLDER=Racon+Medaka_ONT/${Assemblers[$j]}/0/
	if [ -d ./$FOLDER ]; then
		echo -e "\n\n"racon 0 ${Assemblers[$j]} | tr '[:lower:]' '[:upper:]'
		echo
		cd $FOLDER
	else
		echo -e "\n\n"CONTINUE IN THE FOLLOWING ASSEMBLER
		echo
		echo ./$FOLDER "doesn't exist"
		echo -------------------------------------------------------------------------------------------------------
		continue
	fi

	echo -e CALCULATING THE NUMBER OF SNPS AND INDELS..."\n"
	# In this script, the file name of draft-assembly is always draft.fasta. Each assembler has a folder, so these files can't be confused.
	# Create SAM file mapping the draft-assembly on the metagenome reference with NUCmer (https://github.com/mummer4/mummer).
	nucmer "$Path_reference"metagenome_reference.fasta draft.fasta -p aln

	# Manipulate the delta encoded alignment files output by the NUCmer pipelines. It takes a delta file as input and filters the information.
	delta-filter -1 aln.delta > aln.delta.filtered.delta

	# Report polymorphisms contained in a delta encoded alignment file output by NUCmer. It catalogs all of the single nucleotide polymorphisms (SNPs) and insertions/deletions within the delta file alignments.
	show-snps aln.delta.filtered.delta > aln.delta.filtered.snps

	# Extract the number of SNPs and INDELs.
	count_SNPS_indels.pl aln.delta.filtered.snps aln_${Assemblers[$j]}_0.counts.txt
	
	# Delete some files.
	rm *delta*
	
	echo --------------------------------------------------------------------	
	cd ..

	# ROUNDS RACON
	for ((i=1; i<=${Rounds_Racon_by_assembler[$j]}; i++)); do

		echo -e "\n\n"racon $i ${Assemblers[$j]} | tr '[:lower:]' '[:upper:]'
		echo
		mkdir $i
		cd $i
		echo -e "\n\n"${Assemblers[$j]} RACON $i >> ../time.txt
		echo -e "\n\n"${Assemblers[$j]} RACON $i >> ../assemble.stderr

		# In each round of racon the unpolished draft-assembly file will be the draft-assembly file polished in the previous round. EXCEPTION: the input of round 1 will be the unpolished draft-assembly file, it means the unpolished draft-assembly file obtained directly from the assembler and present in folder 0.
		if [ $i -eq 1 ]; then
			no_corrected=draft
			FILE=./../$((i-1))/$no_corrected.fasta
			if [ ! -s $FILE ]; then
				cd ../../../
				echo $FILE "doesn't exist"

				check_break=1
				break
			fi
		else
			no_corrected=draft_corrected_$((i-1))
			FILE=./../$((i-1))/$no_corrected.fasta
			if [ ! -s $FILE ]; then
				cd ../../../
				echo $FILE "doesn't exist"
				check_break=1
				break
			fi
		fi

		echo -e PREPARING AND RUNNING RACON..."\n"
		# Index the unpolished draft-assembly file.
		minimap2 -x map-ont -d $no_corrected.mmi ./../$((i-1))/$no_corrected.fasta

		# Create the SAM file by mapping the ONT sequence file used to polish (sequences.fastq) on the uncorrected draft assembly file.
		minimap2 -ax map-ont -t 16 $no_corrected.mmi "$Path_ONT_sequences"sequences.fastq > overlaps.sam

		# Run Racon
		{ time racon -t 16 "$Path_ONT_sequences"sequences.fastq overlaps.sam ./../$((i-1))/$no_corrected.fasta > draft_corrected_$i.fasta 2>> ../assemble.stderr ; } 2>> ../time.txt

		# Delete some files.
		rm *.sam

		echo -e "\n"CALCULATING THE NUMBER OF SNPS AND INDELS..."\n"
		# Calculate the number of SNPs and INDELs. Explained above.
		nucmer "$Path_reference"metagenome_reference.fasta draft_corrected_$i.fasta -p aln
		delta-filter -1 aln.delta > aln.delta.filtered.delta
		show-snps aln.delta.filtered.delta > aln.delta.filtered.snps 
		count_SNPS_indels.pl aln.delta.filtered.snps aln_${Assemblers[$j]}_$i.counts.txt
		rm *delta*
		
		cd ..
		echo -------------------------------------------------------------------------------------------------------
	
	done
	
	# MEDAKA
	# It is important check if the previous loop (Racon rounds) has been broken. If it has been broken medaka can't be executed.	
	if [ $check_break -eq 0 ]; then

		echo -e "\n\n"medaka ${Assemblers[$j]} | tr '[:lower:]' '[:upper:]'
		echo
		mkdir medaka
		cd medaka
		echo -e "\n\n"${Assemblers[$j]} MEDAKA >> ../time.txt
		echo -e "\n\n"${Assemblers[$j]} MEDAKA >> ../assemble.stderr

		# Run medaka. For more information (https://github.com/nanoporetech/medaka).
		{ time medaka_consensus -i "$Path_ONT_sequences"sequences.fastq -d ./../${Rounds_Racon_by_assembler[$j]}/draft_corrected_${Rounds_Racon_by_assembler[$j]}.fasta -o consensus -t 16 2>> ../assemble.stderr ; } 2>> ../time.txt
		mv ./consensus/consensus.fasta ./draft_assembly_medaka.fasta

		echo -e "\n"CALCULATING THE NUMBER OF SNPS AND INDELS..."\n"
		# Calculate the number of SNPs and INDELs. Explained above.
		nucmer "$Path_reference"metagenome_reference.fasta draft_assembly_medaka.fasta -p aln
		delta-filter -1 aln.delta > aln.delta.filtered.delta
		show-snps aln.delta.filtered.delta > aln.delta.filtered.snps 
		count_SNPS_indels.pl aln.delta.filtered.snps aln_${Assemblers[$j]}_medaka.counts.txt
		rm *delta*
		
		cd ../../../
		echo --------------------------------------------------------------------
	else
		check_break=0
	fi
done
