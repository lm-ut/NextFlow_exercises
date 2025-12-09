// ------------------------------------------------------------
// PROCESS 1: ped_to_bim
// ------------------------------------------------------------
// Use PLINK/1.9 to convert ped/map in bed format
// The process is applied to all files named 'sampleN'.ped/map 
// In the indicated directory (given via function path)

process ped_to_bim {

	publishDir "01_Binary_PLINK", mode: "copy"

	input:

// val e' un valore generico, NON un file, passa una str/num
// passera' l'etichetta 'sample1' o 'sample2' passata in cmdline

// path indica che val e' un file (??)

// tuple all'inizio indica che gli stiamo rifilando un minestrone
	tuple val(sample), path(ped), path(map)

	output:
        tuple val(sample), 
	path("${sample}.bed"), 
	path("${sample}.bim"), 
	path("${sample}.fam")

	script: 
	"""
	plink --ped ${ped} --map ${map} --make-bed --out ${sample} 
	"""
}

// ------------------------------------------------------------
// PROCESS 2: count_snps
// ------------------------------------------------------------
// Count SNPs in converted bim files
//

process count_snps {

	publishDir "02_SNP_count", mode: "copy"

	input:

// Keep all files for best pract, even if currently only bim is needed
	tuple val(sample), 
	path(bed),
	path(bim),
	path(fam)

	output:
	tuple val(sample), path("${sample}.snpcount.txt")

	script: 
	"""
	wc -l ${bim} > ${sample}.snpcount.txt
	"""
}

// ------------------------------------------------------------
// PROCESS 3: plotting
// ------------------------------------------------------------
// Producing a plot with SNP count
//

process plotting {

	publishDir "03_Plots", mode: "copy"

	input: 
	path file_snpcount

	output:
	path "plot_samples.png"

	script: 
	"""
	python ${projectDir}/plotting_script.py --input ${file_snpcount.join(' ')} --output plot_samples.png
	"""
}

// ------------------------------------------------------------
// WORKFLOW
// ------------------------------------------------------------
// 1. Create Channel for sample file names
//

workflow {
ped_ch = Channel.fromPath("*.ped")

samples = ped_ch.map {ped -> 
	def base = ped.baseName
	def map = file("${base}.map")
	tuple(base, ped, map)
}

// 2. Process 1
plinked = ped_to_bim(samples)

// 3. Process 2
count_snps = count_snps(plinked)

// 4. Conditional Collect

merged_counts = count_snps 
		.map {sample, file -> file}
		.collect()

// 5. Process 3
plotting(merged_counts) 
}
