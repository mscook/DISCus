#!/bin/bash

# Author: Leah Roberts
# Affiliations: Scott Beatson Lab Group - University of Queensland St Lucia
# Date: October 2014

############# Licence ###########################

# The MIT License (MIT)

# Copyright (c) 2015 Leah Wendy Roberts

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

###################### Script Description ################################

############### fimS invertible DNA switch script ########################

# This script is designed to align reads to a reference using BWA, and then count the 
# number of reads overlapping predefined regions. This script generates two outputs: one
# output describes the number of reads physically overlapping the predefined regions, and
# another output describing read-pairs that span across the desired regions.

# The script should be run from inside the directory with the fastq reads: 

# $ bash <script.sh> $REFERENCE $BEDMAP_REFERENCE

# It is very important that the fastq files are formatted correctly for the script to work:
# 	name_1.fastq
# 	name_2.fastq

# Reads will be mapped to the REFERENCE. It should be in the format ../reference.fa
# the BEDMAP_REFERENCE defines the desired regions. It should be in the format ../bedmap_format.fa
# To find out more, please read the README file available on Github (https://github.com/LeahRoberts/DISCus). 


REFERENCE=$1
BEDMAP_REFERENCE=$2

# First need to index the reference fasta file to be used in the mapping:
echo "indexing " $REFERENCE
bwa index $REFERENCE

# Write a loop that will generate .sai files by reading each of the paired strains to the 
# reference strain using the tool BWA. These are outputted as $name_1.sai or $name_2.sai.

for f in * 

do

# Used cut to parse out the strain name - THIS WILL ONLY WORK IF THE FASTQ FILE IS 
# FORMATTED CORRECTLY (i.e. $strainname_1.fastq).
# Prints the name of the strain currently being processed:

	echo "processing $(echo $f | cut -f1 -d.)"
	
# Formatted script so that it will take in both zipped and unzipped fastq files	

		if [[ $f == *_1.fastq.gz ]]
		then
			gunzip $f
			read1=$(echo $f | cut -f1-2 -d.)
			name1=$(echo $f | cut -f1 -d.)
			bwa aln $REFERENCE $read1 > $name1.sai
		
		elif [[ $f == *_2.fastq.gz ]]
		then
			gunzip $f
			read2=$(echo $f | cut -f1-2 -d.)
			name2=$(echo $f | cut -f1 -d.)	
			bwa aln $REFERENCE $read2 > $name2.sai
		
		elif [[ $f == *_1.fastq ]]
		then
			name1=$(echo $f | cut -f1 -d.)
                        bwa aln $REFERENCE $f > $name1.sai
		
		elif [[ $f == *_2.fastq ]]
		then	
			name2=$(echo $f | cut -f1 -d.)
                        bwa aln $REFERENCE $f > $name2.sai
	fi
done

# Write another loop that will take the .sai files from the previous section, and map them 
# to the reference strain generating .sam and .bam files.

for f in *
do
	if [[ $f == *fastq ]]
	then

# Parse out just the name of the strain (again, in the format $name_1.fastq). 
		name=$(echo $f | cut -f1 -d_)
		
# Want to only perform the alignment once - as there are two .sai files, this has the 
# potential to interate through twice. This if statement prevents the script from 
# iterating through more than once on the same strain:
		if [[ ! -e $name.bam ]]
		then
			echo "checking for pairs - " $name

            		if [[ $(echo $f | cut -f1 -d. | cut -f2 -d_) == "1" ]]
            		then
            			name1=$f
            			echo "first paired read = " $name1
            			
# Make sure that the names of paired files (.sai and .fastq) are the SAME and that the SAME strain files are being aligned 
# to the reference (again using BWA):
                		for g in *
                		do
                			if [[ $(echo $g | cut -f2 -d_) == "2.fastq" ]] && [[ $(echo $g | cut -f1 -d_) == $name ]]
                    			then
                    				echo $f "and" $g "are a pair - performing alignment"
                        			bwa sampe $REFERENCE $name\_1.sai $name\_2.sai $f $g > $name.sam
                        			
# '-f 0x0002' tells samtools to only take correctly paired reads. '-F 4' tells samtools to only take reads that have mapped 
# to the reference.                        			
                        			samtools view -bS -f 0x0002 -F 4 $name.sam > $name.bam
                        			samtools sort $name.bam $name.sorted
                        			samtools index $name.sorted.bam

# Removes the original fastq files and the SAM file. These should be commented out if using the script for the first time or 
# if the user prefers to keep all the data:                        			
#						rm $f
#						rm $g
						rm $name.sam

                    			fi
                		done

# A second loop exactly the same as the first, except it takes in "read2" files:                		

			elif [[ $(echo $f | cut -f1 -d. | cut -f2 -d_) == "2" ]]
         		then
                    		name2=$f
                    		echo "second paired read = " $name2

                    		for g in *
                    		do
                    			if [[ $(echo $g | cut -f2 -d_) == "1.fastq" ]] && [[ $(echo $g | cut -f1 -d_) == $name ]]
                        		then
                        			echo $f "and" $g "are a pair"
                            			bwa sampe $REFERENCE $name\_1.sai $name\_2.sai $g $f > $name.sam
                            			samtools view -bS -f 0x0002 -F 4 $name.sam > $name.bam
                            			samtools sort $name.bam $name.bam.sorted
                            			samtools index $name.bam.sorted
					#	rm $f
					#	rm $g
						rm $name.sam
                        		fi
                		done
            		fi
		fi
	fi
	

done

# The above loop should have generated the BAM alignment files for all the reads against the reference. 

# Getting rid of the .sai files to clean up the directory.

for f in *
do
        if [[ $f == *.sai ]]
        then
                echo "deleting " $f
                rm $f

# The next command then counts all the reads aligning the "exons" defined by the BEDMAP_REFERENCE file.
# This BEDMAP_REFERENCE file can be generated using DISCus_create_reference.py (see README and documentation). 

# Taking the $name.sorted.bam files and converting them to .bed files, and then using bedmaps to count the 
# reads overlapping the 'exon' regions (in this case, the borders of the invertible DNA switch for fimS).
# The results for each strain are saved as $name.result.bed.

	elif [[ $f == *.sorted.bam ]] 
	then
		echo "converting " $f " to bed file"
		bam2bed < $f > $f.bed
		bedmap --echo --count $BEDMAP_REFERENCE $f.bed > $f.result.bed
		echo "results for "$f" have finished compiling"
	fi
done

# Loop to parse all of the $name.result.bed file contents into a single result.csv file with the strain name identifier.

echo "STRAIN,OFF_1,OFF_2,ON_1,ON_2" > fimS_OFF_ON_bed_results.csv

for f in *
do
	if [[ $f == *.result.bed ]]
    	then
		NAME=$(echo $f | cut -f1 -d.) 
		OFF_1=$(head -1 $f | cut -f2 -d\|)
        	OFF_2=$(head -2 $f | tail -1 | cut -f2 -d\|)
        	ON_1=$(tail -2 $f | head -1 | cut -f2 -d\|)
        	ON_2=$(tail -1 $f | cut -f2 -d\|)
                        
    		echo $NAME','$OFF_1','$OFF_2','$ON_1','$ON_2 >> fimS_OFF_ON_bed_results.csv

    	fi
done

echo "finished creating csv file containing bedmaps results"

# The next section counts the number of read-pairs that overlap the 3 regions for each orientation, namely Left Flank, 
# Switch Region and Right Flank.

for f in *
do
	if [[ $f == *.sorted.bam ]]
	then
	
# Reads the sorted bam file and obtains all of the read IDs.
# These are then sorted, where duplicate read names are discarded.This ultimately results in a unique list of 
# read names that have mapped to the reference. 

		samtools view $f | cut -f1 -d$'\t' > readnames
		sort readnames | uniq >> readnames.sorted
		echo "assigning reads to..."$f
		
# The below variables are used to count the reads overlapping the regions of interest (i.e. OFF_1, OFF_2, ON_1, ON_2).
# The other remaining variables can be used to validate the script and check that it is running accordingly. 

		readcount=$(wc -l readnames.sorted)
	
		OFF_1=0
		OFF_2=0
		ON_1=0
		ON_2=0
		DIFF_REGION=0
		SAME_REGION=0
		
# The next loop reads in the 'readnames.sorted' file containing all of the read IDs. 

		while read name
		do
		
# For each read that is fed through the while loop, its coordinate (as well as the coordinate of its pair) are 
# obtained from the .sorted.bam file using 'grep' and cutting the fourth field (which is the coordinate field). 
# This is temporarily saved in a 'positions.txt' file. Variable 'a' is then assigned one of these numbers,
# while variable 'b' is assigned the other. The script then determines what region the read lies in based on its
# starting coordinate, either 'left_flank', 'switch_region' or 'right_flank' for either orientation.
 
			samtools view $f | grep $name | cut -f4 -d$'\t' > position.txt
				
			
			a=$(head -1 position.txt)
			
			if [ $a -le 1000 ]
			then
				read1='OFF_left_flank'
				
			elif [ $a -ge 1001 -a $a -le 1313 ]
			then
				read1='OFF_switch_region'
				
			elif [ $a -ge 1314 -a $a -le 2313 ]
			then
				read1='OFF_right_flank'
				
			elif [ $a -ge 2314 -a $a -le 3313 ]
			then
				read1='ON_left_flank'
				
			elif [ $a -ge 3314 -a $a -le 3626 ]
			then
				read1='ON_switch_region'
				
			elif [ $a -ge 3627 ]
			then
				read1='ON_right_flank'	
			fi
			
			b=$(tail -1 position.txt)
			
			if [ $b -le 999 ]
			then
				read2='OFF_left_flank'
			
			elif [ $b -ge 1000 -a $b -le 1313 ]
			then
				read2='OFF_switch_region'
			
			elif [ $b -ge 1314 -a $b -le 2313 ]
			then
				read2='OFF_right_flank'
				
			elif [ $b -ge 2314 -a $b -le 3313 ]
                        then
                                read2='ON_left_flank'
                               
			elif [ $b -ge 3314 -a $b -le 3626 ]
                        then
                                read2='ON_switch_region'
                                
			elif [ $b -ge 3627 ]
                        then
                                read2='ON_right_flank'
			fi

# At this point the script counts the number of reads overlapping different region. 
# Since some of the reads can be in the same region, the first if statement filters only for 
# reads that are in different regions. 
# The next if statements encompass all of the possibilites for the read positions. Depending on
# where the reads lie, a '+1' is added to the tally for either OFF_1 (i.e. read pairs in the left flank and 
# in the switch region), or OFF_2 (i.e. read pairs in the right flank and in the switch region), and again 
# similarly for the ON region. 

			if [[ $read1 != $read2  ]]
			then
				DIFF_REGION=$(($DIFF_REGION + 1))
				
				if [[ $read1 == 'OFF_switch_region' ]] && [[ $read2 == 'OFF_right_flank' ]]
				then
					OFF_2=$(($OFF_2 + 1))
					echo $name >> mapped_reads_OFF.txt		
				
				elif [[ $read1 == 'OFF_switch_region' ]] && [[ $read2 == 'OFF_left_flank' ]]
				then
					OFF_1=$(($OFF_1 + 1))
					echo $name >> mapped_reads_OFF.txt
				
				elif [[ $read2 == 'OFF_switch_region' ]] && [[ $read1 == 'OFF_right_flank' ]]
				then
					OFF_2=$(($OFF_2 + 1))
					echo $name >> mapped_reads_OFF.txt
				
				elif [[ $read2 == 'OFF_switch_region' ]] && [[ $read1 == 'OFF_left_flank' ]]
				then
					OFF_1=$(($OFF_1 + 1))	
					echo $name >> mapped_reads_OFF.txt
				
				elif [[ $read1 == 'ON_switch_region' ]] && [[ $read2 == 'ON_right_flank' ]]
                                then    
                                        ON_2=$(($ON_2 + 1))
                                        echo $name >> mapped_reads_ON.txt                  
                                
				elif [[ $read1 == 'ON_switch_region' ]] && [[ $read2 == 'ON_left_flank' ]]
                                then    
                                        ON_1=$(($ON_1 + 1))
                                        echo $name >> mapped_reads_ON.txt
                                
				elif [[ $read2 == 'ON_switch_region' ]] && [[ $read1 == 'ON_right_flank' ]]
                                then    
                                        ON_2=$(($ON_2 + 1))
                                        echo $name >> mapped_reads_ON.txt
                                
				elif [[ $read2 == 'ON_switch_region' ]] && [[ $read1 == 'ON_left_flank' ]]
                                then    
                                        ON_1=$(($ON_1 + 1))   
                                        echo $name >> mapped_reads_ON.txt

				fi
			else
				SAME_REGION=$(($SAME_REGION + 1))
			fi
		
		done <readnames.sorted

### Printing out results (optional)

#	echo 'OFF_1 = ' $OFF_1
#       echo 'OFF_2 = ' $OFF_2
#	echo 'ON_1 = ' $ON_1
#	echo 'ON_2 = ' $ON_2
#       echo 'read_count = ' $readcount
#       echo "reads in the same region = " $SAME_REGION
#       echo "reads in different regions = " $DIFF_REGION   


# Creating a csv file for the results output:

	rm readnames.sorted

	NAME=$(echo $f | cut -f1 -d.)
	echo $NAME','$OFF_1','$OFF_2','$ON_1','$ON_2 >> fimS_OFF_ON_positions.csv
	
	
	fi
done

# Cleaning up unnecessary files:

rm readnames
rm position.txt

# Move all of the files into directories of their own

for f in *
do
	if [[ $f == *.result.bed ]]
	then
		NAME=$(echo $f | cut -f1 -d.)
		mkdir ana_$NAME
		mv $NAME* ana_$NAME
	fi
done


echo "Finished!"
