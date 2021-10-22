nextflow.enable.dsl=2


process fastp {
    publishDir "6b.workflow_nextflow/${id}/1.quality_control", mode: 'copy'
    input:
        tuple val(id), path(reads)
    output:
        tuple val(id), path('*trimmed.fq.gz'), emit: trimmed_reads
        tuple val(id), path('*.json'), emit: json
        tuple val(id), path('*.html'), emit: html
        tuple val(id), path('*.log'), emit: log
    shell:
        """
        fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${id}_R1_trimmed.fq.gz --out2 ${id}_R2_trimmed.fq.gz --json ${id}.fastp.json --html ${id}.fastp.html > ${id}.fastp.log 2>&1
        """
}


process shovill {
    publishDir "6b.workflow_nextflow/${id}/2.assembly", mode: 'copy'
    input:
        tuple val(id), path(trimmed_reads)
    output:
        tuple val(id), path("contigs.fa"), emit: assembly
        tuple val(id), path('*.log'), emit: log
    shell:
        """
        shovill --R1 ${trimmed_reads[0]} --R2 ${trimmed_reads[1]} --outdir . --force > ${id}.shovill.log
        """
}


process amrfinderplus {
    publishDir "6b.workflow_nextflow/${id}/3.amr_gene_detection", mode: 'copy'
    input:
        tuple val(id), path(assembly)
    output:
        tuple val(id), path("*_amrfinderplus_results.tsv"), emit: report
        tuple val(id), path("*.log"), emit: log 
    shell:
        """
        amrfinder --update > ${id}.amrfinder.log
        amrfinder --nucleotide ${assembly} --output ${id}_amrfinderplus_results.tsv >> ${id}.amrfinder.log 2>&1
        """
}

        
process hAMRonize {
    publishDir "6b.workflow_nextflow/${id}/4.hAMRonization", mode: 'copy'
    input:
        tuple val(id), path(amr_report)
    output:
        path("*amrfinderplus_hamronized.tsv"), emit: hamronized_report
    shell:
        """
        db_version="\$(amrfinder --update 2>&1 | grep 'Database version' | cut -d ':' -f2)"
        hamronize amrfinderplus --analysis_software_version \$(amrfinder --version) --reference_database_version "\$db_version" --input_file_name ${id} ${amr_report} > ${id}_amrfinderplus_hamronized.tsv
        """
}


process summarize {
    publishDir "6b.workflow_nextflow", mode: 'copy'
    input:
        path(hAMRonized_reports)
    output:
        path("amr_summary.html")
    shell:
        """
        hamronize summarize --summary_type interactive ${hAMRonized_reports.join(' ')} > amr_summary.html
        """
}





workflow {

    samples = channel.fromFilePairs('0.raw_data/*_R{1,2}.fq.gz')
    
    trimmed_samples = fastp(samples) 

    assemblies = shovill(trimmed_samples.trimmed_reads)

    amr_genes = amrfinderplus(assemblies.assembly)
    
    hamronized_amr = hAMRonize(amr_genes.report)
    
    summary = summarize(hamronized_amr.hamronized_report.collect())
}
