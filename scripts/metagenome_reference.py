#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This Python script creates a reference metagenome from all the individual reference 
genomes of the microorganisms that make up a microbial community. The reference 
metagenome is a multi-FASTA file and the individual reference genomes are also 
found in multi-FASTA files. The header of the contig or the contigs of the different 
individual genomes will be modified to avoid duplication of the headers in the 
metagenome file. The script receives as arguments: the directory path where the 
individual reference genomes are located, the name of the output file with the 
fasta termination and the name of a TXT file containing the list of the individual 
reference genomes that make up the metagenome (it must be in the indivividual genomes 
FASTA files directory).

Created on Fri Apr 12 10:15:14 2019

@author: Pascual Villalba-Bermell - Darwin Bioprospecting Excellence S.L.
"""
# Import modules
import os
import sys


def main():
    """
    Main program.
    """
    ## Arguments.
    # Directory path with individual reference genomes.
    directorio = sys.argv[1]
    # Name of output file (included .fasta)
    output_file = sys.argv[2]
    # TXT file containing the list of the individual reference genomes.
    file_genomes_fasta = sys.argv[3]
    
    ## Steps.
    # Change the directory.
    os.chdir(directorio)
    # Convert the TXT file with the individual genomes into a list.
    list_genomes = List_genomes (file_genomes_fasta)
    # Create the new headers of the contig/s of the individual genomes.
    headers, seqs = Double_list (list_genomes)
    # Write the new multi-FASTA file (metagenome).
    Write_output (directorio, output_file, headers, seqs)


def List_genomes (file_genomes_fasta):
    """
    Convert the TXT file with the individual genomes into a list with the complete
    names of each individual genome.
    """
    # Create the list:
    list_genomes = []
    # Open the file to read.
    genomes = open(file_genomes_fasta, 'r')
    for line in genomes:
        line = line.strip()
        list_genomes.append(line)
            
    return list_genomes


def Double_list (list_genomes):
    """
    Create the new headers of the contig/s of the individual genomes and save the
    headers and sequences in different lists. In the same position in a list 
    it will be the header and in the other its respective nucleotide sequence.
    """
    # Create the lists:
    headers = []
    seqs = []
    # In each genome, modify the headers and then save the headers and sequences
    # in diferent lists.
    for file in list_genomes:
        n = 0
        # Open the file to read.
        file_in = open(file, 'r')
        for line in file_in:
            line = line.strip()
            if line[0] == '>':
                n += 1
                # New format of header.
                header = '>' + file[:-6] + '_' + str(n)
                headers.append(header)  
            else:
                seqs.append(line)
    
    return headers, seqs

                
def Write_output (directorio, output_file, headers, seqs):
    """
    Write the new multi-FASTA file (metagenome). This file will be saved in the 
    same directory as the individual genomes
    """
    # Open the file to write.
    if directorio[-1] == '/':
        file_out = open(directorio + output_file, 'w')
    else:
        file_out = open(directorio + '/' + output_file, 'w')
    # Write the headers and sequences in the new file.
    for i in range(len(headers)):
        file_out.write(headers[i] + '\n')
        file_out.write(seqs[i] + '\n')


if __name__ == '__main__':
    """
    Call the main program.
    """
    main()
