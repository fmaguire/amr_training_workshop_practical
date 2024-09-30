IDS, = glob_wildcards("0.raw_data/{id}_R1.fq.gz")

rule all:
    input:
        "6a.workflow_snakemake/amr_summary.html"

rule summarize:
    input:
        expand("6a.workflow_snakemake/{id}/4.hAMRonization/amrfinderplus_hamronized.tsv", id=IDS),
    output:
        "6a.workflow_snakemake/amr_summary.html"
    shell:
        """
        hamronize summarize --summary_type interactive {input} > {output}
        """
        
rule hAMRonize:
    input:
        "6a.workflow_snakemake/{id}/3.amr_gene_detection/amrfinderplus_results.tsv"
    output:
        "6a.workflow_snakemake/{id}/4.hAMRonization/amrfinderplus_hamronized.tsv"
    params:
        name = "{id}"
    shell:
        """
        db_version="$(amrfinder --update 2>&1 | grep 'Database version' | cut -d ':' -f2)"
        hamronize amrfinderplus --analysis_software_version $(amrfinder --version) --reference_database_version "$db_version" --input_file_name {params.name} {input} > {output}
        """

rule amrfinderplus:
    input:
        "6a.workflow_snakemake/{id}/2.assembly/contigs.fa"
    output:
        "6a.workflow_snakemake/{id}/3.amr_gene_detection/amrfinderplus_results.tsv"
    log:
        "6a.workflow_snakemake/{id}/3.amr_gene_detection/amrfinderplus.log"
    shell:
        """
        amrfinder --update > {log} 2>&1
        amrfinder --nucleotide {input} --output {output} >> {log} 2>&1
        """

rule shovill:
    input:
        R1 = "6a.workflow_snakemake/{id}/1.quality_control/{id}_R1_trimmed.fq.gz",
        R2 = "6a.workflow_snakemake/{id}/1.quality_control/{id}_R2_trimmed.fq.gz"
    output:
        "6a.workflow_snakemake/{id}/2.assembly/contigs.fa"
    params:
        prefix = "6a.workflow_snakemake/{id}/2.assembly"
    log:
        "6a.workflow_snakemake/{id}/2.assembly/assembly.log"
    shell:
        """
        shovill --R1 {input.R1} --R2 {input.R2} --outdir {params.prefix} --force > {log} 2>&1
        """

rule fastp:
    input:
        R1 = "0.raw_data/{id}_R1.fq.gz",
        R2 = "0.raw_data/{id}_R2.fq.gz"
    output:
        R1 = "6a.workflow_snakemake/{id}/1.quality_control/{id}_R1_trimmed.fq.gz",
        R2 = "6a.workflow_snakemake/{id}/1.quality_control/{id}_R2_trimmed.fq.gz",
        html = "6a.workflow_snakemake/{id}/1.quality_control/fastp.html",
        json = "6a.workflow_snakemake/{id}/1.quality_control/fastp.json"
    log:
        "6a.workflow_snakemake/{id}/1.quality_control/fastp.log"
    shell:
        """
        fastp --in1 {input.R1} --in2 {input.R2} --out1 {output.R1} --out2 {output.R2} --json {output.json} --html {output.html} > {log} 2>&1
        """

