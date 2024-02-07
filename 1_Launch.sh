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
# Activate conda environment
PATHCONDA=$(conda info | grep -i 'base environment' | awk -F" " '{print $4}')
source $PATHCONDA'/etc/profile.d/conda.sh'
conda activate MetaB
#
# Arguments
## enter initialization file
if [ $(echo $1 | grep ".ini" | wc -l ) -eq 1 ]
then
INI=$1
else
echo 'Enter initialization file (xyz.ini): '
read INI
fi
#
## Parse initialzation file
PROJET=$(cat $INI | grep "PROJET" | awk -F' : ' '{print $2}')
echo "Projet : $PROJET"
### detect sample.gz and unzip if present
if [ $(ls rawdata/$PROJET | grep ".gz$" | wc -l) -gt 0 ]
then
gunzip rawdata/$PROJET/*
fi
###
SAMPLE=$(cat $INI | grep "SAMPLE" | awk -F' : ' '{print $2}')
if [ $(echo $SAMPLE | grep "ALL" | wc -l) -eq 1 ]
then
SAMPLE=$(ls rawdata/$PROJET/ | grep ".fastq$" | cut -d"_" -f1 | sort | uniq)
fi
echo "Sample(s):"
for sampleI in $SAMPLE
do
echo -e "\t$sampleI"
done
echo -e "Paramaters:"
MAXMERGE=$(cat $INI | grep "MAXMERGE" | awk -F' : ' '{print $2}')
echo -e "\tMaximum merge length : $MAXMERGE"
MINMERGE=$(cat $INI | grep "MINMERGE" | awk -F' : ' '{print $2}')
echo -e "\tMinimum merge length : $MINMERGE"
MAXDIFFS=$(cat $INI | grep "MAXDIFFS" | awk -F' : ' '{print $2}')
echo -e "\tMaximum differences in the overlap : $MAXDIFFS"
MAXNS=$(cat $INI | grep "MAXNS" | awk -F' : ' '{print $2}')
echo -e "\tMaximum ambiguous nucleotide in the overlap : $MAXNS"
PRIMERF=$(cat $INI | grep "PRIMERF" | awk -F' : ' '{print $2}')
echo -e "\tPrimer forward : $PRIMERF"
PRIMERR=$(cat $INI | grep "PRIMERR" | awk -F' : ' '{print $2}' | tr 'ATCGRYKMBDHVNatcgrykmbdhvn' 'TAGCYRMKVHDBNtagcyrmkvhdbn' | rev )
echo -e "\tPrimer reverse : $PRIMERR"
DATABASE=$(cat $INI | grep "DATABASE" | awk -F' : ' '{print $2}')
echo -e "\tDatabase : $DATABASE"
IDENTITY=$(cat $INI | grep "IDENTITY" | awk -F' : ' '{print $2}')
echo -e "\tClustering treshold : $IDENTITY"
CHIMERAYN=$(cat $INI | grep "CHIMERAYN" | awk -F' : ' '{print $2}')
echo -e "\tChimera removal : $CHIMERAYN"
THREADS=$(cat $INI | grep "THREADS" | awk -F' : ' '{print $2}')
echo -e "\tNumber of threads : $THREADS"
#
# Create result folder
if [ $(ls result/ | grep ^$PROJET$ | wc -l) -eq 0 ]
then
mkdir result/$PROJET
mkdir result/$PROJET/quality
mkdir result/$PROJET/log
fi
echo -e "1/5 Preprocessing"
#
# Boucle metabarcoding preprocessing
## Def forward,reverse and label
SAMPLE_array=($SAMPLE)
Nsample=$(echo "${#SAMPLE_array[@]}")
num=0
for sampleI in $SAMPLE
do
    num=$((num+1))
    echo -e "\tSample $num/$Nsample: "$sampleI
    for forward in $(ls rawdata/$PROJET | grep $sampleI"_.*R1.*.fastq")
    do
        echo -e "\tForward: "$forward
        reverse=$(echo $forward | sed 's/R1/R2/g')
        echo -e "\tReverse: "$reverse
        label=$(echo $forward | cut -d"_" -f1)

        # Quality of assembly
        echo -e "\t\t1/5 Quality checking of paired reads"
        fastqc rawdata/$PROJET/$forward -o result/$PROJET/quality/ -q > /dev/null
        fastqc rawdata/$PROJET/$reverse -o result/$PROJET/quality/ -q > /dev/null
        ## Merging
        echo -e "\t\t2/5 Merging"
        vsearch -fastq_mergepairs rawdata/$PROJET/$forward -reverse rawdata/$PROJET/$reverse -fastq_maxmergelen $MAXMERGE -fastq_allowmergestagger -fastq_minmergelen $MINMERGE -fastq_maxdiffs $MAXDIFFS -fastq_maxns $MAXNS -fastqout temp/$label"_assembly.fastq" --log result/$PROJET/log/vsearch_merging_$label.log 2> /dev/null
        echo -e "\t\t\tPairs: "$(cat result/$PROJET/log/vsearch_merging_$label.log | grep " Pairs" | awk -F" Pairs" '{print $1}')
        echo -e "\t\t\tMerged: "$(cat result/$PROJET/log/vsearch_merging_$label.log | grep " Merged" | awk -F" Merged" '{print $1" "$2}')
        echo -e "\t\t\tNot merged: "$(cat result/$PROJET/log/vsearch_merging_$label.log | grep " Not merged" | awk -F" Not merged" '{print $1" "$2}')
        # Quality of assembly
        echo -e "\t\t3/5 Quality checking of assembly"
        fastqc temp/$label"_assembly.fastq" -o result/$PROJET/quality/ -q > /dev/null
        ## Cutadapt
        echo -e "\t\t4/5 Detection and trimming of primers sequences"
        LENF=$(($(echo $PRIMERF | wc -c)-1))
        LENR=$(($(echo $PRIMERR | wc -c)-1))
        PATTERN=$PRIMERF";min_overlap="$LENF";required..."$PRIMERR";min_overlap="$LENR";required"
        nohup cutadapt -a $PATTERN -o temp/$label"_assembly_trim.fastq" -q 30 -e 0 --discard-untrimmed temp/$label"_assembly.fastq" > result/$PROJET/log/cutadapt_$label.log 2>/dev/null
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Total reads processed:")
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Reads with adapters:")
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Reads discarded as untrimmed:")
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Reads written (passing filters):")
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Total basepairs processed:")
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Quality-trimmed:")
        echo -e "\t\t\t"$(cat result/$PROJET/log/cutadapt_$label.log | grep "Total written (filtered)")
        ## Convertion
        vsearch -fastq_filter temp/$label"_assembly_trim.fastq" -fastaout temp/$PROJET"_"$label"_assembly_trim.fasta" -relabel $label":" -fasta_width 0 --log result/$PROJET/log/vsearch_conversion_$label.log 2> /dev/null
        ### CHIMERA
        if [ $(echo $CHIMERAYN | grep "Y" | wc -l) -eq 1 ]
        then
        echo -e "\t\t5/5 Detection and removal of chimera: Yes"
        vsearch -uchime_denovo temp/$PROJET"_"$label"_assembly_trim.fasta" -nonchimeras "temp/nonchimera_"$PROJET"_"$label"_assembly_clean.fasta" -fasta_width 0 --log result/$PROJET/log/vsearch_chimera_$label.log 2> /dev/null
        echo -e "\t\t\tChimeras: "$(cat result/$PROJET/log/vsearch_chimera_$label.log | grep "temp/"$label"_assembly_trim.fasta: " | cut -d" " -f2,4)
        fi
        if [ $(echo $CHIMERAYN | grep "N" | wc -l) -eq 1 ]
        then
        echo -e "\t\t5/5 Detection and removal of chimera: No"
        fi
    done
done

# Concatenation
if [ $(echo $CHIMERAYN | grep "Y" | wc -l) -eq 1 ]
then
cat temp/nonchimera_$PROJET*.fasta >> result/$PROJET/$PROJET"_all.fasta"
fi
if [ $(echo $CHIMERAYN | grep "N" | wc -l) -eq 1 ]
then
cat temp/$PROJET*_assembly_trim.fasta >> result/$PROJET/$PROJET"_all.fasta"
fi
# Dereplication
vsearch -derep_fulllength result/$PROJET/$PROJET"_all.fasta" -output result/$PROJET/unique.fasta -relabel uniq_ --log result/$PROJET/log/vsearch_dereplication_$PROJET.log 2> /dev/null
# Clusterisation
echo -e "2/5 OTU clusterisation"
vsearch -cluster_fast result/$PROJET/unique.fasta -id $IDENTITY --threads $THREADS -centroids result/$PROJET/centroids.fasta -relabel OTU_ --log result/$PROJET/log/vsearch_clusterisation_$PROJET.log 2> /dev/null
echo -e "\t"$(cat result/$PROJET/log/vsearch_clusterisation_$PROJET.log | grep "Clusters")
echo -e "\t"$(cat result/$PROJET/log/vsearch_clusterisation_$PROJET.log | grep "Singletons:")
# OTU association
vsearch -usearch_global result/$PROJET/$PROJET"_all.fasta" -db result/$PROJET/centroids.fasta -id $IDENTITY --threads $THREADS -otutabout result/$PROJET/OTU-table-$PROJET.tab --log result/$PROJET/log/vsearch_OTU-association_$PROJET.log 2> /dev/null
# Taxonomic annotation
echo -e "3/5 Taxonomic affiliation"
## Set database files
Fasta_Database=$(ls database/$DATABASE | grep ".*.fasta$")
Tax_Database=$(ls database/$DATABASE | grep ".*.tax$")
## centroids annotation
vsearch -usearch_global result/$PROJET/centroids.fasta -db database/$DATABASE/$Fasta_Database -id 0.4 --threads $THREADS -blast6out result/$PROJET/centroids.blast --log result/$PROJET/log/vsearch_centroids-annotation_$PROJET.log 2> /dev/null
cut -f1,2 result/$PROJET/centroids.blast | sort -k 2,2 > temp/centroids-simple.blast
## Sort tax database file
Sort_Database=$(echo $Tax_Database | sed 's/.tax/.sort/g')
cat database/$DATABASE/$Tax_Database | sort -k 1,1 > database/$DATABASE/$Sort_Database
## Join
awk 'NR==FNR {h[$1]=$2; next} {print $1,h[$2]}' database/$DATABASE/$Sort_Database temp/centroids-simple.blast | sort -k 1 > result/$PROJET/centroids.taxo
#join -t $'\t' -12 -21 -o 1.1,2.2 temp/centroids-simple.blast database/$DATABASE/$Sort_Database | sort -k 1 > result/$PROJET/centroids.taxo
echo -e "\t"$(cat result/$PROJET/log/vsearch_centroids-annotation_$PROJET.log | grep "Matching unique query sequences:")
## Prepare result table
echo -e "4/5 OTU table generation"
HEADER=$(echo -e $(head -n1 result/$PROJET/OTU-table-$PROJET.tab | sed 's/ /_/g' | sed 's/\t/;/g')";Taxonomy;ID%")
tail -n +2 result/$PROJET/OTU-table-$PROJET.tab | sort -k 1 > temp/result-$PROJET.temp
h=0
LIST=''
for i in $SAMPLE
do
h=$(($h+1))
LIST=$(echo $LIST","$h)
if [ $(echo $LIST | grep "^,1" | wc -l) -eq 1 ]
then
LIST="1"
fi
done
echo $HEADER | sed 's/;/\t/g' > result/$PROJET/result-$PROJET.tab

cat result/$PROJET/centroids.blast | sort -k 1 > temp/xcentroids.blast

paste temp/result-$PROJET.temp result/$PROJET/centroids.taxo temp/xcentroids.blast | sed -e 's/\([^\t]\)\t/\1 /g;s/\t/     /g;s/\t/ /g;s/ /\t/g' | cut  -f $LIST,$(($h+1)),$(($h+3)),$(($h+6)) >> result/$PROJET/result-$PROJET.tab

## clean temp/ cache
rm temp/*

## Make Krona
echo -e "5/5 Krona generation"
if [ $(ls result/$PROJET/ | grep "Krona" | wc -l) -eq 0 ]
then
mkdir result/$PROJET/Krona
fi
h=1
LIST=''
for i in $SAMPLE
do
h=$(($h+1))
LIST=$(echo $LIST"+\$"$h)
if [ $(echo $LIST | grep "^+\$2" | wc -l) -eq 1 ]
then
LIST="\$2"
fi
done
cat result/$PROJET/result-$PROJET.tab | tail -n+2 | awk -F"\t" '{print '"$LIST"'"\t"$'"$(($h+1))"'}' | sed 's/;/\t/g' > result/$PROJET/Krona/Krona_Abundance_sum.csv
perl bin/KronaTools-2.8/scripts/ImportText.pl result/$PROJET/Krona/Krona_Abundance_sum.csv -o result/$PROJET/Krona/Krona_Abundance_sum.html > /dev/null
cat result/$PROJET/result-$PROJET.tab | tail -n+2 | awk -F"\t" '{print "1\t"$'"$(($h+1))"'}' | sed 's/;/\t/g' > result/$PROJET/Krona/Krona_Richness_sum.csv
perl bin/KronaTools-2.8/scripts/ImportText.pl result/$PROJET/Krona/Krona_Richness_sum.csv -o result/$PROJET/Krona/Krona_Richness_sum.html > /dev/null

## Sample
for sampleI in $SAMPLE
do
ETAT=$(cat rawdata/$PROJET/metadata.txt | grep '^'$sampleI$'\t' | cut -f2)
touch temp/$ETAT
echo $sampleI >> temp/$ETAT
done

for CDT in $(ls temp/)
do

h=0
LIST=''
for i in $(cat temp/$CDT)
do
h=$(($h+1))
LIST=$(echo $LIST"+\$"$h)
if [ $(echo $LIST | grep "^+\$1" | wc -l) -eq 1 ]
then
LIST="\$1"
fi
done

SAMPLEL=$(echo -e $(cat temp/$CDT | tr '\n' ',' | sed 's/,$//g'))
cat result/$PROJET/result-$PROJET.tab | tr '\t' ',' | csvcut -c $(echo $SAMPLEL",Taxonomy") | tr ',' '\t' > temp/Krona_$CDT.csv
cat temp/Krona_$CDT.csv | tail -n+2 | awk -F"\t" '{print '"$LIST"'"\t"$'"$(($h+1))"'}' | sed 's/;/\t/g' | sort -k $(($h+1)) > result/$PROJET/Krona/Krona_Abundance_$CDT.csv
perl bin/KronaTools-2.8/scripts/ImportText.pl result/$PROJET/Krona/Krona_Abundance_$CDT.csv -o result/$PROJET/Krona/Krona_Abundance_$CDT.html > /dev/null
done

## clean temp/ cache
rm temp/*
## END
ELAPSED=$((($SECONDS-$BEFORE)/60))
echo "Metabarcoding analysis stage is completed and takes $ELAPSED minutes"
