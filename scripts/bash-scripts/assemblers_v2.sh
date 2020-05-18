#!/bin/bash

###########################
# This script has been used to generate the draft-assemblies evaluated in downstream analysis.

# It is important to note that it has been designed for a specific working directory. Therefore, the reproduction of the results will require small modifications of the script or the adaptation of your working directory.

# Regular updates to the Github could modify the script due to the appearance of any new bioinformatics tool for de novo assembly of ONT metagenomic data or the release of new versions (This could lead to changes in the execution parameters).

# Created on Thursday March 12 2020

# @author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.

# Version: 2
###########################

# It is necessary to activate the enviornment of pomoxis if you perform this script for several assemblers and pomoxis or only pomoxis. But you need to activate it from outside the script. Write the path of pomoxis enviornment of your computer (https://github.com/nanoporetech/pomoxis)
##. /home/darwin/Descargas/Programas/pomoxis/venv/bin/activate

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
		FOLDER=${INFO[$i]}_assembly/${INFO[$i+2]}
		if [ -d ./$FOLDER ]; then
			echo -e "\n\n"assembly ${Assemblers[$j]} ${INFO[$i]} ${INFO[$i+2]} | tr '[:lower:]' '[:upper:]'
			echo
			echo -e "\n\n"${INFO[$i]}_assembly, ${INFO[$i+2]}, ${Assemblers[$j]} >> assemble.stderr
			echo -e "\n\n"${INFO[$i]}_assembly, ${INFO[$i+2]}, ${Assemblers[$j]} >> time.txt
			cd $FOLDER
		else
			echo -e "\n\n"CONTINUE IN THE FOLLOWING DATASET
			echo
			echo ./$FOLDER "doesn't exist"
			echo -------------------------------------------------------------------------------------------------------
			break
		fi
		
		# For more information https://github.com/marbl/canu
		if [ ${Assemblers[$j]} == canu ]; then
			{ time canu -d canu_${INFO[$i+2]} -p ${INFO[$i]}_canu_${INFO[$i+2]} genomeSize=62m -nanopore-raw ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq 2>> assemble.stderr ; } 2>> time.txt
			mv ./canu_${INFO[$i+2]}/${INFO[$i]}_canu_${INFO[$i+2]}.contigs.fasta ./canu_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_canu.fa
			cd ../../

		# For more information https://github.com/fenderglass/Flye
		elif [ ${Assemblers[$j]} == metaflye_v27 ]; then
			{ time /home/darwin/Descargas/Programas/Flye-v2.7/Flye/bin/flye --nano-raw ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq --out-dir metaflye_v27_${INFO[$i+2]} --genome-size 62m --threads 16 --meta --plasmids 2>> assemble.stderr ; } 2>> time.txt
			# Flye v2.7 uses the file name assembly.fasta and Flye v2.4 uses the file name scaffolds.fasta (IMPORTANT: Do not confuse versions.)
			mv ./metaflye_v27_${INFO[$i+2]}/assembly.fasta ./metaflye_v27_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_metaflye_v27.fa
			cd ../../
		
		# For more information https://github.com/fenderglass/Flye
		elif [ ${Assemblers[$j]} == metaflye_v24 ]; then
			{ time /home/darwin/Descargas/Programas/Flye-v2.4/bin/flye --nano-raw ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq --out-dir metaflye_v24_${INFO[$i+2]} --genome-size 62m --threads 16 --meta 2>> assemble.stderr ; } 2>> time.txt
			# Flye v2.7 uses the file name assembly.fasta and Flye v2.4 uses the file name scaffolds.fasta (IMPORTANT: Do not confuse versions.)
			mv ./metaflye_v24_${INFO[$i+2]}/scaffolds.fasta ./metaflye_v24_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_metaflye_v24.fa
			cd ../../

		# For more information https://github.com/voutcn/megahit
		elif [ ${Assemblers[$j]} == megahit ]; then
			{ time megahit -t 16 -r ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq --out-prefix ${INFO[$i]}_megahit_${INFO[$i+2]} -o megahit_${INFO[$i+2]} 2>> assemble.stderr ; } 2>> time.txt
			mv ./megahit_${INFO[$i+2]}/${INFO[$i]}_megahit_${INFO[$i+2]}.contigs.fa ./megahit_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_megahit.fa
			cd ../../

		# For more information https://github.com/GATB/minia
		elif [ ${Assemblers[$j]} == minia ]; then
			mkdir minia_${INFO[$i+2]}
			cd minia_${INFO[$i+2]}
			{ time minia ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq 31 3 62000000 ${INFO[$i]}_minia_${INFO[$i+2]} 2>> ../assemble.stderr ; } 2>> ../time.txt
			mv ${INFO[$i]}_minia_${INFO[$i+2]}.contigs.fa draft_assembly_${INFO[$i+1]}_minia.fa
			cd ../../../

		# For more information https://github.com/lh3/miniasm
		elif [ ${Assemblers[$j]} == miniasm ]; then
			mkdir miniasm_${INFO[$i+2]}
			cd miniasm_${INFO[$i+2]}
			echo -e "\nminiasm-First_Part" >> ../assemble.stderr
			echo -e "\nminiasm-First_Part" >> ../time.txt
			{ time minimap2 -x ava-ont -t16 ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq | gzip -1 > ${INFO[$i]}_${INFO[$i+2]}_trimmed.paf.gz 2>> ../assemble.stderr ; } 2>> ../time.txt
			echo -e "\nminiasm-Second_Part" >> ../assemble.stderr
			echo -e "\nminiasm-Second_Part" >> ../time.txt
			{ time miniasm -f ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq ${INFO[$i]}_${INFO[$i+2]}_trimmed.paf.gz > ${INFO[$i]}_${INFO[$i+2]}_trimmed.gfa 2>> ../assemble.stderr ; } 2>> ../time.txt 
			awk '/^S/{print ">"$2"\n"$3}' ${INFO[$i]}_${INFO[$i+2]}_trimmed.gfa | fold > ${INFO[$i]}_${INFO[$i+2]}_miniasm.fa
			mv ${INFO[$i]}_${INFO[$i+2]}_miniasm.fa draft_assembly_${INFO[$i+1]}_miniasm.fa
			cd ../../../

		# For more information https://github.com/nanoporetech/pomoxis
		elif [ ${Assemblers[$j]} == pomoxis ]; then
			{ time mini_assemble -i ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq -o pomoxis_${INFO[$i+2]} -p draft_assembly_${INFO[$i+1]}_pomoxis -t 16 2>> assemble.stderr ; } 2>> time.txt
			mv ./pomoxis_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_pomoxis_final.fa ./pomoxis_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_pomoxis.fa
			cd ../../

		# For more information https://github.com/lbcb-sci/raven
		elif [ ${Assemblers[$j]} == raven ]; then
			mkdir raven_${INFO[$i+2]}
			cd raven_${INFO[$i+2]}
			{ time raven -t16 ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq > draft_assembly_${INFO[$i+1]}_raven.fa 2>> ../assemble.stderr ; } 2>> ../time.txt
			cd ../../../

		# For more information https://github.com/ruanjue/wtdbg2
		elif [ ${Assemblers[$j]} == redbean ]; then
			mkdir redbean_${INFO[$i+2]}
			cd redbean_${INFO[$i+2]}
			echo -e "\nredbean-First_Part" >> ../assemble.stderr
			echo -e "\nredbean-First_Part" >> ../time.txt
			{ time /home/darwin/Descargas/Programas/Redbean/wtdbg2/wtdbg2 -x ont -g 62m -t 16 -i ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq -fo draft_assembly_${INFO[$i+1]}_redbean 2>> ../assemble.stderr ; } 2>> ../time.txt
			echo -e "\nredbean-Second_Part" >> ../assemble.stderr
			echo -e "\nredbean-Second_Part" >> ../time.txt
			{ time /home/darwin/Descargas/Programas/Redbean/wtdbg2/wtpoa-cns -t 16 -i draft_assembly_${INFO[$i+1]}_redbean.ctg.lay.gz -fo draft_assembly_${INFO[$i+1]}_redbean.fa 2>> ../assemble.stderr ; } 2>> ../time.txt
			cd ../../../

		# For more information https://github.com/chanzuckerberg/shasta . IMPORTANT: This program always asks for the administrator password at the beginning of the execution. Therefore, its individual execution is recommended so that it does not stop the script.
		elif [ ${Assemblers[$j]} == shasta ]; then
			{ time shasta-Linux-0.4.0 --threads 16 --memoryBacking 2M --memoryMode filesystem --input ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq --assemblyDirectory shasta_${INFO[$i+2]} 2>> assemble.stderr ; } 2>> time.txt
			mv ./shasta_${INFO[$i+2]}/Assembly.fasta ./shasta_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_shasta.fa
			cd ../../

		# For more information https://github.com/rrwick/Unicycler
		elif [ ${Assemblers[$j]} == unicycler ]; then
			{ time unicycler -l ${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq -t 16 -o unicycler_${INFO[$i+2]} 2>> assemble.stderr ; } 2>> time.txt
			mv ./unicycler_${INFO[$i+2]}/assembly.fasta ./unicycler_${INFO[$i+2]}/draft_assembly_${INFO[$i+1]}_unicycler.fa
			cd ../../

		# For more information https://github.com/ruanjue/wtdbg2
		# wtdbg2 is an older version of the current redbean assembler.
		elif [ ${Assemblers[$j]} == wtdbg2 ]; then
			mkdir wtdbg2_${INFO[$i+2]}
			cd wtdbg2_${INFO[$i+2]}
			echo -e "\nwtdbg2-First_Part" >> ../assemble.stderr
			echo -e "\nwtdbg2-First_Part" >> ../time.txt
			{ time /home/darwin/Descargas/Programas/wtdbg2/wtdbg2 -x ont -g 62m -t 16 -i ../${INFO[$i]}_${INFO[$i+2]}_trimmed.fastq -fo ${INFO[$i]}_wtdgb2_${INFO[$i+2]} 2>> ../assemble.stderr ; } 2>> ../time.txt
			echo -e "\nwtdbg2-Second_Part" >> ../assemble.stderr
			echo -e "\nwtdbg2-Second_Part" >> ../time.txt
			{ time /home/darwin/Descargas/Programas/wtdbg2/wtpoa-cns -t 16 -i ${INFO[$i]}_wtdgb2_${INFO[$i+2]}.ctg.lay.gz -fo ${INFO[$i]}_wtpoa_${INFO[$i+2]}.ctg.fa 2>> ../assemble.stderr ; } 2>> ../time.txt
			mv ${INFO[$i]}_wtpoa_${INFO[$i+2]}.ctg.fa draft_assembly_${INFO[$i+1]}_wtdbg2.fa
			cd ../../../

		fi
		echo -------------------------------------------------------------------------------------------------------
	done
done
