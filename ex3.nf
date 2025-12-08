// ------------------------------------------------------------
// PROCESS 1: ped_to_bim
// ------------------------------------------------------------
// Use PLINK/1.9 to convert ped/map in bed format
// The process is applied to all files named 'sampleN'.ped/map 
// In the indicated directory (given via function path)

process ped_to_bim {

	publishDir "01_Binary_PLINK", mode: "copy"

	input:
	tuple val(sample), path(ped), path(map)

	output:
        tuple val(sample), path("${sample}.bed"), path("${sample}.bim"), path("${sample}.fam")

	script: 
	"""
	plink --file ${sample} --make-bed --out ${sample} 
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
	tuple val(sample), path(bed), path(bim), path(fam)

	output:
	tuple val(sample), path("${sample}.snpcount.txt")

	script: 
	"""
	wc -l ${bim_files} > ${sample}.snpcount
	"""
}

// ------------------------------------------------------------
// PROCESS 3: plotting
// ------------------------------------------------------------
// Producing a plot with SNP count
//

process new_process_name {

	publishDir "03_Plots", made: "copy"

	input: 
	path count_snps_file

	output:
	path "plot_sample"

	script: 
	"""
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
	def base = pd.baseName
	def map = file("${base}.map")
	tuple(base, ped, map)
}

// 2. Process 1
plinked = ped_to_bim(samples)

// 3. Process 2
count_snps = process_2(plinked)

// 4. Process 3
all_counts = count_snps.map { sample, file -> file }.collect() 

python_summary(all_counts) 
}
