#!/bin/bash
#
#                                 _       _
#     /\                         (_)     | |
#    /  \   _ __ ___   ___  _ __  _  ___ | |_
#   / /\ \ | '_ ` _ \ / _ \| '_ \| |/ _ \| __|
#  / ____ \| | | | | | (_) | | | | | (_) | |_
# /_/    \_\_| |_| |_|\___/|_| |_| |\___/ \__|
#                               _/ |
#                              |__/
# 19/01/2024
#
BEFORE=$SECONDS
# Install dependencies
## install conda environment
if [ $(conda env list | grep "^METAmiDIV " | wc -l) -eq 0 ]
then
conda env create -f METAmiDIV.yml
fi
#
## activate conda environment
PATHCONDA=$(conda info | grep -i 'base environment' | awk -F" " '{print $4}')
source $PATHCONDA'/etc/profile.d/conda.sh'
conda activate METAmiDIV
#
# Prepare directory and test dataset
mkdir database/
mkdir rawdata
mkdir result/
mkdir temp/
wget https://mothur.s3.us-east-2.amazonaws.com/wiki/miseqsopdata.zip -O rawdata/test.zip
unzip rawdata/test.zip -d rawdata/
rm rawdata/test.zip
mv rawdata/MiSeq_SOP rawdata/test
rm rawdata/test/HMP_MOCK.v35.fasta rawdata/test/Mock_S280_L001_R1_001.fastq rawdata/test/Mock_S280_L001_R2_001.fastq rawdata/test/mouse.dpw.metadata rawdata/test/stability.batch rawdata/test/stability.files
mv rawdata/test/mouse.time.design rawdata/test/metadata.txt
#
# Prepare database
## Read database
if [ $(echo $1 | grep "." | wc -l ) -eq 1 ]
then
DATABASE=$1
else
echo 'Enter database (PR2, SILVA or BOTH): '
read DATABASE
fi
## Format database
if [ $(echo $DATABASE | grep -e "SILVA" -e "BOTH" | wc -l) -eq 1 ]
then
mkdir database/SILVA
wget https://ftp.arb-silva.de/release_138_1/Exports/SILVA_138.1_SSURef_NR99_tax_silva.fasta.gz -O database/SILVA/SILVA_138.1_SSURef_NR99_tax_silva.fasta.gz
gunzip database/SILVA/SILVA_138.1_SSURef_NR99_tax_silva.fasta.gz
cat database/SILVA/SILVA_138.1_SSURef_NR99_tax_silva.fasta | awk -F"\t" '{if ($1 ~ ">") print $1"\t"$2}' | sed 's/>//g' | sed 's/ /\t/' | sed 's/ /_/g' > database/SILVA/SILVA_138.1_SSURef_NR99.tax
cat database/SILVA/SILVA_138.1_SSURef_NR99_tax_silva.fasta | awk '{if ($1 ~ ">") print "\n"$1 ; else printf $1 }' | sed '/^>/!y/U/T/' | tail -n +2 > database/SILVA/SILVA_138.1_SSURef_NR99.fasta
rm database/SILVA/SILVA_138.1_SSURef_NR99_tax_silva.fasta
fi
if [ $(echo $DATABASE | grep -e "PR2" -e "BOTH" | wc -l) == 1 ]
then
mkdir database/PR2
wget https://github.com/pr2database/pr2database/releases/download/v5.0.0/pr2_version_5.0.0_SSU_mothur.fasta.gz -O database/PR2/pr2_version_5.0.0_SSU_mothur.fasta.gz
wget https://github.com/pr2database/pr2database/releases/download/v5.0.0/pr2_version_5.0.0_SSU_mothur.tax.gz -O database/PR2/pr2_version_5.0.0_SSU_mothur.tax.gz
gunzip database/PR2/*.gz
fi
#
## Prepare database for lca
mkdir database/LCA
wget https://www.arb-silva.de/fileadmin/arb_web_db/release_138_1/ARB_files/SILVA_138.1_SSURef_NR99_12_06_20_opt.arb.gz -O database/LCA/SILVA_138.1_SSURef_NR99_12_06_20_opt.arb.gz
gunzip database/LCA/SILVA_138.1_SSURef_NR99_12_06_20_opt.arb.gz
#
## Krona tool
mkdir bin/
cd bin/
wget https://github.com/marbl/Krona/releases/download/v2.8/KronaTools-2.8.tar
tar -xvf KronaTools-2.8.tar
perl KronaTools-2.8/install.pl --prefix ./KronaTools-2.8
rm KronaTools-2.8.tar
cd ..
#
## Initialization file 
ELAPSED=$((($SECONDS-$BEFORE)/60))
echo "Installation stage is completed and takes $ELAPSED minutes"
