# JPI-AMR PHA4GE MRC-CLIMB-BIG-DATA AMR Genomics Training Workshop

This repository contains all the files and instructions presented in the lecture.
This procedure will be different depending on the exact type of genomics sequencing you have performed.
The examples here will work for short (100-250bp) paired-end Illumina reads from a bacterial genome.

## 0. Setting up

First thing you need is a UNIX shell this can be accessed via a "terminal" and can be found on 
Mac OSX, Windows Subsystem Linux, or a Linux operating system.

You can learn the basics of navigating using the shell from great tutorials like this one from [softwarecarpentry](https://swcarpentry.github.io/shell-novice/)

Once you have your shell you need to install [miniconda](https://docs.conda.io/en/latest/miniconda.html)
then configure [bioconda](https://bioconda.github.io/) following the instructions [here](https://bioconda.github.io/user/install.html#install-conda)

This will provide you with an easy way to install bioinformatics tools in self-contained environments.
We will use this to create an environment called `amr` and install the tools we are going to use today into it.

    conda create -n amr fastp shovill ncbi-amrfinderplus hAMRonization

Then we are going to activate this `amr` environment, this means the computer will run all the commands in this terminal using this environment:

    conda activate amr

## 1. Quality Control

There are many parts to good quality control for AMR genomics.
Today we are only going to focus on checking the raw reads and trimming them.
However, when running real experiments it always a good idea to include positive (a sample containing DNA that you already know the sequence of) and negative (a sample you know contains no DNA) controls.
It is also very sensible to check your raw reads for contamination using tools such as [kraken2](https://ccb.jhu.edu/software/kraken2/).
To check the reads and do some trimming we are going to use `fastp`:

    fastp --in1 0.raw_data/sampleA_R1.fq.gz --in2 0.raw_data/sampleA_R2.fq.gz --out1 1.quality_control/sampleA_R1_trimmed.fq.gz --out2 1.quality_control/sampleA_R2_trimmed.fq.gz --json 1.quality_control/fastp.json --html 1.quality_control/fastp.html

We can then open `1.quality_control/fastp.html` in our browser and check the before and after quality of our reads.

## 2. Assembly

To assemble our reads into contigs we will use [shovill](https://github.com/tseemann/shovill).
Shovill is a handy tool as it does a lot of things automatically for us and produces a decent genome assembly relatively quickly (we can even use the `--trim` option to have shovill do the read trimming for us as well).

    shovill --R1 1.quality_control/sampleA_R1_trimmed.fq.gz --R2 1.quality_control/sampleA_R2_trimmed.fq.gz --outdir 2.assembly --force

Assuming everything went to plan, this will create a corrected genome assembly.
You can find this as a fasta file that contains all the genomic contigs (`2.assembly/contigs.fa`)

## 3. AMR Gene Prediction

We are going to use [AMRFinderPlus](https://www.ncbi.nlm.nih.gov/pathogens/antimicrobial-resistance/AMRFinder/) to predict whether there are any AMR genes in our assembled contigs.
See Mike Feldgarden's lecture today for details about how tools like this work.

The first thing we have to do is make sure the database is up to date.
See Kara Tsang's lecture today for more details about why AMR databases need updated so much and the differences between databases.
Keep a note of the database version that has been installed as you will need it later.

    amrfinder --update

Then we can run `amrfinder` on your assembled contigs:

    amrfinder --nucleotide 2.assembly/contigs.fa --output 3.amr_gene_detection/amrfinderplus_results.tsv

This will create a file called `3.amr_gene_detection/amrfinderplus_results.tsv`

You can open this file in any spreadsheet software (such as excel or libreoffice) or via python/R to view the results, create summaries, and generate plots.

You'll find there are 8 different AMR genes predicted in our assembly by AMRFinderPlus.

## 4. hAMRonizing Prediction Results

There are many AMR prediction tools all of which have different incompatible outputs.
This makes comparing the performance of different tools difficult. It also makes it hard to change tools because
you rely on the idiosyncratic format of one particular tool.

To make this easier, a common language can be created and the output of tool's translated to it using [hAMRonization](https://github.com/pha4ge/hAMRonization).
See Ines Mendes' lecture today for more details on this idea and its utility.

We need a few extra details about our AMR prediction tool to do this.
These are needed because AMRFinderPlus doesn't include them but they are important to include when comparing or storing results.

First we need the version of `amrfinder` we used:

    amrfinder --version

Then we need the version of the AMR database we used which we saw when we ran `amrfinder --update` (see previous step).

Finally, we need the name of our sample: `sampleA`

The following are correct for me right now but when you run this things may have updated meaning the software and database versions have changed!

    hamronize amrfinderplus --analysis_software_version 3.10.16 --reference_database_version 2021-09-30.1 --input_file_name sampleA 3.amr_gene_detection/amrfinderplus_results.tsv > 4.hAMRonization/hAMRonized_amr_report.tsv

This will create a hAMRonized output file. If you have multiple samples you can summarize and compare results across them.
We are just going to summarize our one result for now.

    hamronize summarize --summary_type interactive 4.hAMRonization/hAMRonized_amr_report.tsv > 4.hAMRonization/amr_summary.html

We can then open `4.hAMRonization/amr_summary.html` in our browser to explore our AMR predictions (again this is at its most useful when running multiple samples)

## 5. Simple Automation

We don't want to type in all these commands every time, ideally we want to automate them so they all happen themselves.
One way we can do this is by writing a "shell script" to do this.
 
I've created an example shell script in `5.simple_automation/full_run.sh` that will redo all the commands after setting up your conda environment and create outputs in `5.simple_automation/`

This is just the commands above but with one little trick to store the database and amrfinder versions in variables and give them directly to `hAMRonization`.

## 6. Workflows 

Workflows offer a much safer and more efficient way to run a series of commands on a number of samples.
There are many workflow languages but we are going to use [snakemake](snakemake.readthedocs.io/) today.
If you are doing this for real I highly recommend using a more fully featured and complex workflow that has already been made by someone.
Examples of these for bacterial AMR analyses include [ARETE](http://github.com/fmaguire/arete), [Bactopia](https://github.com/rpetit3/bactopia), and [nullarbor](https://github.com/tseemann/nullarbor).
However there are many more workflow managers and "best-practice" workflows:

- [Galaxy](https://usegalaxy.org) is most user friendly and provides graphical interfaces. I recommend using highly rated/well used workflows avaiable [here](https://usegalaxy.org/workflows/list_published)
- [Snakemake](snakemake.readthedocs.io) isn't too hard if you know a bit of python and shell but the mental model (working backwards from outputs) can be a little challenging. Best practices snakemake workflows are avaiable [here](https://github.com/snakemake-workflows).
- [NextFlow](nextflow.io/) uses a language less people are familiar with (called groovy) but works very similar to simple "UNIX" shell pipes (connecting outputs from tool A to the input of tool B). Nextflow best practice workflows are created and stored by [nf-core](https://nf-co.re/).

You can see a simple snakemake workflow in `6.workflows/Snakemake`.
This will rerun all the results so far and repeat them for `sampleB`

To run this you need to install snakemake:

    conda install snakemake

Then execute:

    snakemake --snakefile 6.workflows/Snakemake --cores 2

This will result in a nice tidy set of folders under `6.workflows/` with a summary
file of the AMR genes predicted in both samples `6.workflows/amr_summary.html`


	6.workflows/
	├── amr_summary.html
	├── sampleA
	│   ├── 1.quality_control
	│   │   ├── sampleA_R1_trimmed.fq.gz
	│   │   └── sampleA_R2_trimmed.fq.gz
	│   ├── 2.assembly
	│   │   ├── contigs.fa
	│   ├── 3.amr_gene_detection
	│   │   └── amrfinderplus_results.tsv
	│   └── 4.hAMRonization
	│       └── amr_summary.html
	├── sampleB
	│   ├── 1.quality_control
	│   │   ├── sampleB_R1_trimmed.fq.gz
	│   │   └── sampleB_R2_trimmed.fq.gz
	│   ├── 2.assembly
	│   │   ├── contigs.fa
	│   ├── 3.amr_gene_detection
	│   │   └── amrfinderplus_results.tsv
	│   └── 4.hAMRonization
	│       └── amr_summary.html
	└── Snakemake

If you try and run this snakemake command again it will only run for any missing
files! Which is handy when a computer dies or you have a bug and need to restart your analysis.
