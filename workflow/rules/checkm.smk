import re
import subprocess
import os

prefix = config["prefix"]
outdir = config["outdir"]
maxthreads = snakemake.utils.available_cpu_count()

logs = config["base_log_outdir"]

if platform.system() == "Darwin":
    checkm_env = "../envs/checkm_macOSX.yaml"
else:
    checkm_env = "../envs/checkm.yaml"

if platform.system() == "Darwin":
    rule install_pplacer:
        output:
            dummy_out = temp("downloaded_pplacer")
        conda:
            checkm_env
        threads:
            maxthreads
        shell:
            """
            FILE=$CONDA_PREFIX/bin/pplacer
            if test -f "$FILE"; then
                echo "$FILE exists. pplacer will not be downloaded"
            else
                echo "Downloading pplacer..."
                wget -q https://github.com/matsen/pplacer/releases/download/v1.1.alpha17/pplacer-Darwin-v1.1.alpha17.zip
                echo "Unzipping pplacer..."
                unzip pplacer-Darwin-v1.1.alpha17.zip && rm pplacer-Darwin-v1.1.alpha17.zip
                echo "Moving pplacer and associated scripts to $CONDA_PREFIX/bin"
                mv pplacer-Darwin-v1.1.alpha17*/* $CONDA_PREFIX/bin && rmdir pplacer-Darwin-v1.1.alpha17*/
                ls $CONDA_PREFIX/bin/pplacer
            fi
            touch {output}
            """

if path.exists('resources/dbs/checkm') == False:
    rule install_checkmdb:
        output:
            checkm_db = "resources/dbs/checkm/hmms/phylo.hmm"
        conda:
            checkm_env
        threads:
            maxthreads
        shell:
            """
            FILE=resources/dbs/checkm/hmms/phylo.hmm
            if test -f "$FILE"; then
                echo "$FILE exists. CheckM database will not be downloaded"
            else
                echo "Downloading CheckM database..."
                wget -q https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
                echo "Moving CheckM database to 'resources/dbs/checkm'"
                mkdir -p resources/dbs/checkm
                echo "Decompressing checkmdb..."
                tar -xvf checkm_data_2015_01_16.tar.gz --directory resources/dbs/checkm && rm checkm_data_2015_01_16.tar.gz
            fi
            touch {output}
            checkm data setRoot resources/dbs/checkm
            """


rule checkm_tree_and_tree_qa:
    input:
        checkm_db = "resources/dbs/checkm/hmms/phylo.hmm",
        assemblies = config['outdir']+"/{prefix}/shovill/assemblies_temp",
    output:
        directory(config['outdir']+"/{prefix}/QC_workflow/checkm/checkm_out")
    conda:
        checkm_env
    log:
        tree = config['base_log_outdir']+"/{prefix}/QC_workflow/checkm/checkm_tree_and_tree_qa.log"
    threads:
        maxthreads
    shell:
        """
        checkm tree {input.assemblies} -x fasta {output} -t {threads}
        checkm tree_qa {output}
        """

rule checkm_lineage_set:
    input:
        config['outdir']+"/{prefix}/QC_workflow/checkm/checkm_out"
    output:
        markers = config['outdir']+"/{prefix}/QC_workflow/checkm/markers"
    conda:
        checkm_env
    log:
        config['base_log_outdir']+"/{prefix}/QC_workflow/checkm/checkm_lineage_set.log"
    threads:
        maxthreads
    shell:
        """
        checkm lineage_set {input} {output}
        """

rule checkm_analyze:
    input:
        assemblies = config['outdir']+"/{prefix}/shovill/assemblies_temp",
        markers = config['outdir']+"/{prefix}/QC_workflow/checkm/markers"
    output:
        config['outdir']+"/{prefix}/QC_workflow/checkm/checkm_dummy"
    conda:
        checkm_env
    log:
        config['base_log_outdir']+"/{prefix}/QC_workflow/checkm/checkm_analyze.log"
    threads:
        maxthreads
    shell:
        """
        checkm analyze {input.markers} {input.assemblies} {output} -t {threads} -x fasta
        touch {output}
        """

rule checkm_qa:
    input:
        markers = config['outdir']+"/{prefix}/QC_workflow/checkm/markers",
        pseudoinput = config['outdir']+"/{prefix}/QC_workflow/checkm_dummy"
    output:
        config['outdir']+"/{prefix}/QC_workflow/checkm/checkm_qa/qa.tsv"
    conda:
        checkm_env
    log:
        config['base_log_outdir']+"/{prefix}/checkm/checkm_qa.log"
    shell:
        "checkm qa {input.markers} {output} -f {output} -o 2 --tab_table"
