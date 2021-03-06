DISCus - *D*NA *I*nver*S*ion *C*ounter
==========================================

Script for mapping illumina paired end reads with BWA and counting read overlap using: (1) Bedops; and (2) read-pairs traversing the desired region.

Installation Requirements
--------------------------

1. BWA (http://sourceforge.net/projects/bio-bwa/files/)
2. SAMtools (http://samtools.sourceforge.net/)
3. Bedops - bedmaps (http://bedops.readthedocs.org/en/latest/) 


File Requirements
------------------

1. REFERENCE in fasta format (see below - 'Construction of Reference')
2. BEDMAP_REFERENCE in bed format. (see below - 'Construction of Reference' and 'Construction of Bedmap_reference')
3. illumina paired-end read files (fastq) NOT interleaved (see below - Fastq File Format)
4. Coordinates file (see below - 'Construction of Reference' and 'Construction of Coordinates File')


Construction of Reference
--------------------------

**Automated:**

The python script, *DISCus_create_reference.py*, can automatically generate a fasta pseudo-reference, bed file reference and coordinates file for analysis with DISCus using a fasta file of the genome of interest.
The script takes in four arguments and can be exected as shown below::

 	$ python DISCus_create_reference.py <genome_sequence.fasta> <start_coordinate> <end_coordinate> <filename>
 
Where **start_coordinate** is the start of the invertible DNA region of interest, and **end_coordinate** is the end of the invertible DNA region. The script also requires a filename, which will become the name of the output file as well as the fasta header. 

The fasta header generated will be::

 	> <filename> _ <start_coordinate> _ <end_coordinate>
	 Sequence...
 
The sequence will include 1000 bp of flanking region, as well as both orientations of the invertible DNA region.

**Example:**

Using the EC958_complete.fasta genome as the input, and wanting a 100 bp inversion region between 182100 and 182200, the command to execute the script would be::
 
  	$ python DISCus_create_reference.py EC958_complete.fasta 182100 182200 EC958_100bp

*Note: the script will not run unless all four arguments are given. The filename argument should be without spaces.*

The output of this will be:

1. a pseudo-reference with the header ">EC958_100bp_182100_182200"
2. a bedmaps reference file indicating 10 bp overlap regions on either end of the invertible DNA region of interest (further explained in "Construction of Bedmap_reference" section)
3. A coordinates file (txt) defining the regions of the pseudo-reference necessary for determining paired-end read traversal


**Manual:**

You can also construct the reference manually, as explained below. This section can also serve as further explanation regarding the pseudo-reference and theory of the script. 

The REFERENCE will serve as the reference for the read mapping and should be in fasta format. 

The REFERENCE should contain the invertible DNA sequence with 1000 bp flanking sequence for both orientations. For example:

------------------>>>>>>>>>>------------------/------------------<<<<<<<<<<------------------

* ------ = Flanking regions
* >>>>>> = Invertible DNA sequence, orientation 1
* <<<<<< = Invertible DNA sequence, orientation 2
 
The flanking sequences remain the same for each orientation, while the invertible DNA switch should be reverse complemented. In this way, both orientations are represented in the REFERENCE. 

Construction of Coordinates File:
-----------------------------------
*Only necessary to construct if looking at an invertible DNA region other than fimS or hyxR*

This process is now automated by a python script, as described above.

In order to count reads traversing the bordering regions of the invertible DNA switch, it is necessary to assign reads to any of 6 regions in the REFERENCE, as in the above figure (you'll notice that there are six regions - 4 flanking regions and 2 invertible switch regions in opposing orientations). Assuming that these orientations are OFF and ON, the six regions are OFF-left-flank, OFF-switch-region, OFF-right-region, and similarly for the ON orientation. 

The start and end coordinates for each region is necessary for the assignation of reads to their correct region. Therefore, the script needs to read in a text file with these coordinate. The file needs to be in the below format, with the number changed accordingly::

	Region	Start	End
	A_left_flank	n/a	1000
	A_switch_region	1001	1313
	A_right_flank	1314	2313
	B_left_flank	2314	3313
	B_switch_region	3314	3626
	B_right_flank	3627	n/a
	
The 'n/a' regions are irrelevant as they represent the lower most and uppermost regions. The file needs to have a header, and should be **tab delimited**.

**The file needs to be called coordinates.txt** and should be in the directory above the reads.


Construction of Bedmap_reference
----------------------------------

**NOTE: this part can be automated now with a python script, as indicated above.**

The BEDMAP_REFERENCE will specify the location of the desired overlap regions and should be in .bed format, which can be generated from a .gff file using gff2bed.

You can generate this by using Bedops::

 	$ gff2bed < genes.gff > genes.bed
 	$ bam2bed < reads.bam > reads.bed


* It is very important that the nomenclature stays consistent between the reference sequences, particularly regarding the naming of the reference sequence. i.e. The fasta header for the reference should match that in the .bed file.*

For example, if the reference fasta header looks like this::

 	>EC958_fimpromoter_off_on_extended
 	ATAAACATTAAGTTAACCATATCCATACAAAATACAATGGTTTATGTTCTTCAAAATAAA
 	TAAACAAAATCATTCATAAATTTACACATCACTTAAATTCTCCTGTTTCCGCACTTTTTT
 	CTTTATTTTTTAAGCAACTGGAAGTTAATCCACTGCAATCTATTGTTATATTGAATCAAA

Then the bed file should look like this::

 	EC958_fimpromoter_off_on_extended	1001	1011	.	.	+	artemis	exon	.	gene_id=exon:1002..1011
 	EC958_fimpromoter_off_on_extended	1316	1326	.	.	+	artemis	exon	.	gene_id=exon:1317..1326
 	EC958_fimpromoter_off_on_extended	3322	3332	.	.	+	artemis	exon	.	gene_id=exon:3323..3332
 	EC958_fimpromoter_off_on_extended	3637	3647	.	.	+	artemis	exon	.	gene_id=exon:3638..3647

The exons for the DNA switch analysis were created as 10 bp pseudo-exons overlapping each end of the DNA switch regions, totally 4 pseudo-exons regions. 

Fastq File Format
---------------------

For the script to work, the fastq files should be named in a way similar to this::

 	$name_1.fastq
 	$name_2.fastq
 	$name_1.fastq.gz
 	$name_2.fastq.gz

The read files can be zipped or unzipped. 


How-To: Run Me
---------------
Simple overview::

	$ bash DISCus_general.sh <PATH_to_fasta_ref> <PATH_to_bedmaps_ref> <PATH_to_coordinates_file>
	

This bash scripts requires the reference sequences to have already been generated. Furthermore, the reads (illumina paired end - not interleaved) need to be in a directory below the reference files, and the bash script should be executed in the file containing the reads, according to this diagram:

![ScreenShot](https://github.com/LeahRoberts/DiSCus/blob/master/DISCus_how_to_run.png)


Output
-------

The script will generate directories for each strain containing the BAM and BAI files, and the bedmaps results. 


Two other files will also be created:

1. Bedmap_results.csv - The concatenated results for the bedmaps counts of reads overlapping the provided exon locations
2. Paired_read_results.csv - The concatenated results for the paired-end read counts which traverse the region of interest

**NOTE**: The script works based on counting the overlapping reads for two orientations of an invertible DNA region. Thus, the input requires a REFERENCE with opposing orientations of an invertible DNA switch, arbitrarily named OFF and ON. The output assumes that the REFERENCE has been designed with OFF orientation first (i.e leftmost), and the ON orientation second. 

Licence
--------

All scripts and files within this directory are under the MIT Licence (http://choosealicense.com/licenses/mit/)
