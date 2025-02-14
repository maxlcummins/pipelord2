import re
import subprocess
import os

prefix = config['prefix']

if path.exists(config['krakendb']) == False:
    if path.exists("resources/dbs/kraken2/minikraken2_v2_8GB_201904_UPDATE") == False:
        print('Kraken database not located, downloading minikracken2 DB ...')
        if path.exists("minikraken2.tgz") == False:
            os.system("wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz -O minikraken2.tgz")
        os.system("mkdir -p resources/dbs/kraken2")
        os.system("tar -xvf minikraken2.tgz --directory resources/dbs/kraken2 && rm minikraken2.tgz")
    krakendb = "resources/dbs/kraken2/minikraken2_v2_8GB_201904"
else: krakendb = config['krakendb']


if path.exists("resources/tools/Bracken/bracken") == False:
    print('bracken directory not located, downloading bracken...')
    os.system("git clone https://github.com/jenniferlu717/Bracken.git resources/tools/Bracken")

if config['input_type'] == 'assemblies':
    rule run_kraken2:
        input:
            db = config['krakendb'] if path.exists(config['krakendb']) else "resources/dbs/kraken2/minikraken2_v2_8GB_201904_UPDATE",
            assembly = config['outdir']+"/{prefix}/shovill/assemblies/{sample}.fasta"
        output:
            out = config['outdir']+"/{prefix}/QC_workflow/kraken2/{sample}.out",
            report = config['outdir']+"/{prefix}/QC_workflow/kraken2/{sample}.report"
        log:
            config['base_log_outdir']+"/{prefix}/QC_workflow/kraken2/run/{sample}_err.log"
        conda:
            "../envs/kraken2.yaml"
        threads:
            3
        #resources:
            #mem_mb=16000
        shell:
            """
            kraken2 --db {input.db} --use-names --memory-mapping --threads {threads} --report {output.report} --output {output.out} {input.assembly}  2> {log}
            """
elif config["input_type"] == "reads":
    rule run_kraken2:
        input:
            db = config['krakendb'] if path.exists(config['krakendb']) else "resources/dbs/kraken2/minikraken2_v2_8GB_201904_UPDATE",
            r1_filt = config['outdir']+"/{prefix}/fastp/{sample}.R1.fastq.gz",
            r2_filt = config['outdir']+"/{prefix}/fastp/{sample}.R2.fastq.gz"
        output:
            out = config['outdir']+"/{prefix}/QC_workflow/kraken2/{sample}.out",
            report = config['outdir']+"/{prefix}/QC_workflow/kraken2/{sample}.report"
        log:
            config['base_log_outdir']+"/{prefix}/QC_workflow/kraken2/run/{sample}_err.log"
        conda:
            "../envs/kraken2.yaml"
        threads:
            6
        #resources:
            #mem_mb=16000
        shell:
            """
            kraken2 --db {input.db} --use-names --memory-mapping --threads {threads} --report {output.report} --output {output.out} {input.r1_filt} {input.r2_filt}  2> {log}
            """

rule bracken:
    input:
        db = config['krakendb'] if path.exists(config['krakendb']) else "resources/dbs/kraken2/minikraken2_v2_8GB_201904_UPDATE",
        report = config['outdir']+"/{prefix}/QC_workflow/kraken2/{sample}.report"
    output:
        bracken=config['outdir']+"/{prefix}/QC_workflow/bracken/{sample}.bracken.txt",
        species=config['outdir']+"/{prefix}/QC_workflow/bracken/{sample}_bracken_species_report.txt"
    params:
        #krakendb=krakendb
        #extra="-t",
    log:
        config['base_log_outdir']+"/{prefix}/QC_workflow/bracken/{sample}.bracken.log",
    threads:
        4
    #resources:
        #mem_mb=16000
    conda:
        "../envs/kraken2.yaml"
    shell:
        "resources/tools/Bracken/bracken -d {input.db} -i {input.report} -o {output.bracken} -w {output.species} -r 100 -l S -t {threads} 2>&1 {log}"
    #wrapper:
        #"0.2.0/bio/assembly-stats"
    #    "https://raw.githubusercontent.com/maxlcummins/snakemake-wrappers/assembly-stats/bio/assembly-stats/wrapper.py"

rule run_bracken_summarise:
    input:
        #assembly-stats text files
        bracken_reports=expand(config['outdir']+"/{prefix}/QC_workflow/bracken/{sample}.bracken.txt", prefix=prefix, sample=sample_ids)
    output:
        #combined, tab-delimited assembly statistics
        combined_bracken=config['outdir']+"/{prefix}/QC_workflow/summaries/bracken_report.txt"
    params:
        extra="",
    log:
        "logs/{prefix}/QC_workflow/summaries/combine_bracken.log",
    threads:
        1
    #resources:
        #mem_mb=3000
    script:
        "../../scripts/combine_bracken.py"
