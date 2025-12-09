#!/usr/bin/env python3

# Imports

import argparse
import pandas as pd
import matplotlib.pyplot as plt
import os

# Functions

def parse_args(): 
	parser = argparser.ArgumentParser(description = "Plot SNP counts")
	parser.add_argument("--input", nargs="+", required=True, help="List of SNP count files")
	parser.add_argument("--output", default = "snp_plot.png", help="Output plot file")

	return parser.parse_args()

def main():
	args=parse_args()
	
	# Initializing samples (filename) and counts (int information) 
	samples = []
	counts = []

	# Open and Read all count files
	for f in args.input:
		sample = os.path.basename(f).replace(".snpcount.txt","")
		with open(f) as infile:
			count = int(infile.read().strip().split()[0])
		samples.append(sample)
		counts.append(count)

	df = pd.DataFrame({"sample" :sample, "sample_count" :counts})
	df = df.sort_values("sample")

	plt.figure(figsize=(6,4))
	plt.scatter(df["sample"], df["snp_count"])
	plt.xticks(rotation=45)
	plt.xlabel("Sample")
	plt.ylabel("Num SNPs")
	plt.tight_layout()
	plt.savefig(args.output)

if __name__ == "__main__":
    main()
