# **METABARCODING ANALYSIS**
                                     _       _
         /\                         (_)     | |
        /  \   _ __ ___   ___  _ __  _  ___ | |_
       / /\ \ | '_ ` _ \ / _ \| '_ \| |/ _ \| __|
      / ____ \| | | | | | (_) | | | | | (_) | |_
     /_/    \_\_| |_| |_|\___/|_| |_| |\___/ \__|
                                 _/ |
                                |__/
19/01/2024

**This is a workflow to carried out a metabarcoding sequencing data analysis with vsearch on unix-64 bit personal computer.**

### **Clone repository**

`git clone https://github.com/amonjot/MeTaB.git`

`cd MeTaB`

### **Dependencies: (installed during installation script)**

    - python (>v3.7)
    - fastqc
    - vsearch
    - cutadapt
    - perl
    - wget
    - gzip
    - nano
    - git
    - csvkit

### **1. Setup:**

To format current repository and install dependencies. 

First, launch the part A of installation script which install miniconda:

`bash 0A_Miniconda.sh`

You have to close and open a new terminal to initialize miniconda. Then, launch the part B of the installation script: 

`bash 0B_Install.sh`

Specify a database (PR2, SILVA or BOTH).

You also can use a home made database using *mothur* database format:

    - 1 fasta file linking accesion number to SSU sequences
            >AY505519
            ATTCGACGA...
    - 1 text file linking accesion number to taxonomy (tabulation as delimiter)
            AY505519    Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Halobacillus

### **2. Launch analyses:**

To launch metabarcoding analysis, use Launch script with an initialization file *.ini* in argument.

We provide a *test* data set. To launch the analysis use the following command:

`bash 1_Launch.sh test.ini`

For your own data set, prepare a directory containing reads (compressed or not) and a *metadata.txt* file. Place it in the *rawdata/* directory.

Reads must be identified as following: *Sample1_XYZ_R1_XYZ.fastq(.gz)* & *Sample1_XYZ_R2_XYZ.fastq(.gz)*.

Prepare an initialization file using the *test.ini* as model:

    PROJET : The name of your project and the name of the directory containing raw paired-end reads.
    SAMPLE : Names of samples to analyze (space is delimiter). Specify *ALL* if you want to analyze all samples.
    MAXMERGE : The maximum length of the reads assembly.
    MINMERGE : The minimum length of the reads assembly.
    MAXDIFFS : The maximum number of differences between the paired-end reads.
    MAXNS : The maximum number of ambiguous nucleotide differences in the assembly.
    PRIMERF : Forward primer sequence in 5'-3'.
    PRIMERR : Reverse primer sequence in 5'-3'.
    DATABASE : Database (specified the name of the database directory: *PR2*, *SILVA* or your own database).
    IDENTITY : Clustering treshold (e.g. *0.97*).
    CHIMERAYN : Specify if you want to detect and remove chimeras or not (*Y* or *N*). This step take a while.
    THREADS : The maximum number of threads to launch the process.

Results will be placed in the result directory.

