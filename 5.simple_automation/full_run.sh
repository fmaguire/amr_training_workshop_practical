#!/bin/bash

mkdir -p 5.simple_automation/{1.quality_control,2.assembly,3.amr_gene_detection,4.hAMRonization}

fastp --in1 0.raw_data/sampleA_R1.fq.gz --in2 0.raw_data/sampleA_R2.fq.gz --out1 5.simple_automation/1.quality_control/sampleA_R1_trimmed.fq.gz --out2 5.simple_automation/1.quality_control/sampleA_R2_trimmed.fq.gz --json 5.simple_automation/1.quality_control/fastp.json --html 5.simple_automation/1.quality_control/fastp.html

shovill --R1 5.simple_automation/1.quality_control/sampleA_R1_trimmed.fq.gz --R2 5.simple_automation/1.quality_control/sampleA_R2_trimmed.fq.gz --outdir 5.simple_automation/2.assembly --force

db_version="$(amrfinder --update 2>&1 | grep "Database version" | cut -d ':' -f2)"
amrfinder_version=$(amrfinder --version)
amrfinder --nucleotide 5.simple_automation/2.assembly/contigs.fa --output 5.simple_automation/3.amr_gene_detection/amrfinderplus_results.tsv

hamronize amrfinderplus --analysis_software_version "$amrfinder_version" --reference_database_version "$db_version" --input_file_name sampleA 5.simple_automation/3.amr_gene_detection/amrfinderplus_results.tsv > 5.simple_automation/4.hAMRonization/hAMRonized_amr_report.tsv
hamronize summarize --summary_type interactive 5.simple_automation/4.hAMRonization/hAMRonized_amr_report.tsv > 5.simple_automation/4.hAMRonization/amr_summary.html
