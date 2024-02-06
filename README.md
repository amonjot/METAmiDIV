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

**This is a workflow to carried out a metabarcoding sequencing data analysis with vsearch on unix-64 personnal computer.**

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

To format current repository and install dependencies, launch installation script: 

`bash 0_Install.sh`

Specify database (PR2, SILVA or BOTH).

You also can use an home made database using *mothur* database format:

### **2. Launch analyses:**

To launch metabarcoding analysis, use Launch script with an initialization file *.ini* in argument.

We provide a *test* dataset. To launch the analysis use the following command:

`bash 1_Launch.sh test.ini`

For your dataset, prepare a directory containing reads (compressed or not) and a *metadata.txt* file in the *rawdata/* directory.

Prepare an initialiation file using the *test.ini* as model.

Results will be placed in the result directory.

