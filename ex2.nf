// ------------------------------------------------------------
// PROCESS 1: count_chars
// ------------------------------------------------------------
// A Nextflow "process" runs a job (a script or command).
// It is a template that will execute once per item received from the input channel.
//
process count_chars {

    // publishDir tells Nextflow where to SAVE the output files.
    // mode: "copy" = copy files to the directory (not symlink)
    publishDir "FakeFasta_RES", mode: "copy"

    input:
        // We expect a tuple coming from the workflow:
        // (id, file)
        //
        // `val(id)`     = a value (string or int) that is passed in but not a file
        // `path(file)`  = an actual file path that Nextflow will stage in the work dir
        tuple val(id), path(file)

    output:
        // We emit a tuple:
        // (id, output_file)
        //
        // The "id" lets us keep the sample identity through the pipeline
        // while "path()" tells NF which generated file to pass on.
        tuple val(id), path("count_characters_${id}.txt")

    script:
    """
    // wc -m prints the number of characters in ${file}
    // We redirect it into a file named count_characters_<id>.txt
    wc -m ${file} > count_characters_${id}.txt
    """
}



// ------------------------------------------------------------
// PROCESS 2: add_chars
// ------------------------------------------------------------
// Takes ALL output files from process 1 and sums the numbers inside them.
//
process add_chars {

    publishDir "FakeFasta_Counter", mode: "copy"

    input: 
        // Here we expect *one item*: a LIST of files (because .collect() was used)
        // Nextflow automatically groups them into a single input.
        path count_files

    output:
        // The final summary file
        path "add_chars_output.txt"

    script:
    """
    // AWK loops over each file, adds the first column ($1), and prints the sum.
    awk '{sum += \$1} END {print sum}' ${count_files} > add_chars_output.txt
    """
}



// ------------------------------------------------------------
// WORKFLOW BLOCK
// ------------------------------------------------------------
// This is where you define:
//   1) how input data becomes channels
//   2) how processes are connected
//   3) the overall sequence of the pipeline
//
workflow {

    // --------------------------------------------------------
    // STEP 1: Create a channel of input tuples
    // --------------------------------------------------------
    // Channel.fromPath('*_fakeinput.txt') finds all matching files.
    // Example files:
    //   Fasta1_fakeinput.txt
    //   Fasta2_fakeinput.txt
    //
    // .map(...) transforms each file path into a tuple (id, file)
    //
    // def id = file.baseName.split('_')[0]
    //   For "Fasta1_fakeinput.txt"
    //   baseName = "Fasta1_fakeinput"
    //   split('_') = ["Fasta1", "fakeinput"]
    //   so id = "Fasta1"
    //
    // The output is a channel of:
    //   ("Fasta1", path/to/Fasta1_fakeinput.txt)
    //
    fasta_file = Channel
        .fromPath('*_fakeinput.txt')
        .map { file ->
            def id = file.baseName.split('_')[0]
            tuple(id, file)
        }

    // --------------------------------------------------------
    // STEP 2: Run process 1
    // --------------------------------------------------------
    // count_chars() receives the channel fasta_file
    // and returns a new channel ("counted")
    //
    // counted contains tuples:
    //   (id, "count_characters_<id>.txt")
    //
    counted = count_chars(fasta_file)

    // --------------------------------------------------------
    // STEP 3: Prepare inputs for process 2
    // --------------------------------------------------------
    // counted emits a tuple (id, output_file).
    //
    // We do not need id anymore for the summation. We only want the file names.
    //
    // .map { id, out_file -> out_file }
    //   transforms (id, file) → file
    //
    // .collect()
    //   waits until ALL files have been produced
    //   then makes a *single list* of paths
    //
    aggregated_files = counted
        .map { id, out_file -> out_file }  
        .collect()

    // --------------------------------------------------------
    // STEP 4: Run process 2 on the collected files
    // --------------------------------------------------------
    add_chars( aggregated_files )
}
