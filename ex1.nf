process count_chars {

	publishDir "FakeFasta_RES", mode: "copy"


	input:
		tuple val(id), path(file)

	output:
		path "count_characters_${id}.txt"

	"""
	wc -m ${file} > count_characters_${id}.txt
	"""
}

workflow {
	Channel 
		.fromPath('*_fakeinput.txt')
		.map { file ->
			def id = file.baseName.split('_')[0]
			tuple(id, file)
		}
		.set { fasta_file }
	count_chars(fasta_file)
}
