import re
import subprocess
import os

#configfile: "misc/masterconfig2.yaml"

# Get assemblies
#sample_ids, = glob_wildcards(config['raw_reads_path']+"/{sample}.R1.fastq.gz")
prefix = config['prefix']
maxthreads = snakemake.utils.available_cpu_count()

db_location = config['gene_db_location']
gene_dbs = expand(config['gene_dbs'])

logs = config['base_log_outdir']

#print(sample_ids)
#print(db_location)
#print(gene_dbs)


#rule all:
#    input:
#        expand(config['outdir']+"/{prefix}/summaries/mlst.txt", prefix=prefix)
#               sample=sample_ids, gene_db=gene_dbs, prefix=prefix),
#       expand(config['outdir']+"/{prefix}/summaries/abricate_hits.txt", prefix=prefix)

rule mlst_run:
    input:
        assembly = config['outdir']+"/{prefix}/shovill/assemblies/{sample}.fasta"
    output:
        config['outdir']+"/{prefix}/mlst/{sample}_mlst.txt"
    conda:
        "config/mlst.yaml"
    threads:
        1
    shell:
        "mlst {input} > {output}"

# in beta
#rule mlst_combine:
#    input:
#        expand(config['outdir']+"/{prefix}/mlst/{sample}_mlst.txt", sample=sample_ids, prefix=prefix)
#    output:
#        mlst_temp = config['outdir']+"/{prefix}/summaries/mlst_temp.txt",
#        mlst = config['outdir']+"/{prefix}/summaries/mlst.txt"
#    log:
#        config['base_log_outdir']+"/{prefix}/mlst/combine/log"
#    conda:
#        "config/abricate.yaml"
#    threads:
#        1
#    params:
#        summaries_dir = config['outdir']+"/{prefix}/summaries"
#    shell:
#        """
#        if [[ ! -e {params.summaries_dir} ]]; then
#            mkdir -p {params.summaries_dir}
#        fi
#        touch {output.mlst_temp}
#        xargs cat > {output.mlst_temp} <<'EOF'\n
#        {input}\n
#        EOF\n
#        # Clean sample name column
#        perl -p -i -e 's@.*assemblies/@@g' {output.mlst_temp}
#        perl -p -i -e 's@.fasta@@g' {output.mlst_temp}
#        # Insert a header
#        echo -e "name\tscheme\tST" | cat - {output.mlst_temp} > {output.mlst}
#        """


#include: "genome_assembly.smk"