#!/usr/bin/env python3
import os
import argparse
import pandas as pd
from pathlib import Path
from plumbum import local
from argparse import RawTextHelpFormatter
from plumbum.commands.processes import ProcessExecutionError
from scipy.cluster.hierarchy import ward, complete, average, dendrogram, fcluster, linkage

"""
Run all three python scripts in BioData workflow to generate combined results
Display options provided in KEGG_decoder will be available for final step only 

"""


class ArgParse:

    def __init__(self, arguments_list, description, *args, **kwargs):
        self.arguments_list = arguments_list
        self.args = []
        # Instantiate ArgumentParser
        self.parser = argparse.ArgumentParser(formatter_class=RawTextHelpFormatter, description=description,
                                              *args, **kwargs)
        # Add all arguments stored in self.arguments_list
        self._parse_arguments()
        # Parse arguments
        try:
            self.args = self.parser.parse_args()
        except:
            exit(1)

    def _parse_arguments(self):
        """ Protected method for adding all arguments stored in self.arguments_list
            Checks value of "require" and sets accordingly

        """
        for args in self.arguments_list:
            self.parser.add_argument(*args[0], **args[1])

    @staticmethod
    def description_builder(header_line, help_dict, flag_dict):
        """ Static method provides summary of programs/requirements

        :param header_line:
        :param help_dict:
        :param flag_dict:
        :return:
        """
        assert set(help_dict.keys()) == set(flag_dict.keys()), "Program names do not match in key/help dictionaries"
        to_return = header_line + "\n\nAvailable Programs:\n\n"
        programs = sorted(flag_dict.keys())
        for program in programs:
            to_return += program + ": " + help_dict[program] + "\n\t" + \
                         "\t(Flags: {})".format(" --" + " --".join(flag_dict[program])) + "\n"
        to_return += "\n"
        return to_return


def hClust_euclidean(genome_df):
    linkage_matrix = linkage(genome_df, method='average', metric='euclidean')
    # linkage_matrix = linkage(df, metric='braycurtis')
    names = genome_df.index.tolist()
    # clust = dendrogram(linkage_matrix, orientation="right", labels=names, get_leaves=True)
    clust = dendrogram(linkage_matrix, no_plot=True, labels=names, get_leaves=True)
    leaves = clust['ivl']
    leave_order = list(leaves)
    genome_df = genome_df.reindex(leave_order)

    return genome_df


def hClust_correlation(genome_df):
    linkage_matrix = linkage(genome_df, method='single', metric='correlation')
    # linkage_matrix = linkage(df, metric='braycurtis')
    names = genome_df.index.tolist()
    # clust = dendrogram(linkage_matrix, orientation="right", labels=names, get_leaves=True)
    clust = dendrogram(linkage_matrix, no_plot=True, labels=names, get_leaves=True)
    leaves = clust['ivl']
    leave_order = list(leaves)
    genome_df = genome_df.reindex(leave_order)

    return genome_df


def hClust_most_least(genome_df):
    sort_dex = genome_df.sum(axis=1).sort_values(ascending=True).index
    genome_df = genome_df.loc[sort_dex]

    return genome_df


def hClust_least_most(genome_df):
    sort_dex = genome_df.sum(axis=1).sort_values(ascending=False).index
    genome_df = genome_df.loc[sort_dex]

    return genome_df


def default_viz(genome_df, outfile_name):
    import seaborn as sns
    import matplotlib.pyplot as plt
    sns.set(font_scale=1.2)
    sns.set_style({"savefig.dpi": 200})
    ax = sns.heatmap(genome_df, cmap=plt.cm.YlOrRd, linewidths=2,
                     linecolor='k', square=True, xticklabels=True,
                     yticklabels=True, cbar_kws={"shrink": 0.1})
    ax.xaxis.tick_top()
    # ax.set_yticklabels(ax.get_yticklabels(), rotation=90)
    plt.xticks(rotation=90)
    plt.yticks(rotation=0)
    # get figure (usually obtained via "fig,ax=plt.subplots()" with matplotlib)
    fig = ax.get_figure()
    # specify dimensions and save
    # xLen = len(genome_df.columns.values.tolist())*20
    # yLen = len(genome_df.index.tolist())*20
    fig.set_size_inches(100, 100)
    fig.savefig(outfile_name, bbox_inches='tight', pad_inches=0.1)


def prefix(_path):
    """ Get prefix of file

    :param _path: Path, possibly relative
    :return:
    """
    return os.path.splitext(Path(_path).resolve())[0]


def try_which():
    """ Locate hmmsearch on path, if possible

    :return:
    """
    try:
        return str(local["which"]["hmmsearch"]()).rstrip("\r\n")
    except ProcessExecutionError:
        return "None"


def print_run(cmd):
    """
    :param cmd: plumbum local object
    :return:
    """
    print(cmd)
    cmd()


def plotly_viz(genome_df, output_file):
    # build heatmap in plotly.offline
    Euclidean_genome_df = hClust_euclidean(genome_df)

    Correlation_genome_df = hClust_correlation(genome_df)

    Most_Least_genome_df = hClust_most_least(genome_df)

    Least_Most_genome_df = hClust_least_most(genome_df)

    import plotly.graph_objs as go
    import plotly.offline as py

    xLen = len(genome_df.columns.values.tolist()) * 20
    len_genomes = len(genome_df.index.tolist())
    if len_genomes >= 200:
        yLen = len_genomes * 40
        menL = 1.05
    elif len_genomes >= 100:
        yLen = len_genomes * 30
        menL = 1.2
    elif len_genomes >= 50:
        yLen = len_genomes * 20
        menL = 1.5
    elif len_genomes >= 25:
        yLen = len_genomes * 10
        menL = 2.0
    else:
        yLen = 750
        menL = 3.0

    colorscale = [
        [0, '#f1eef6'],
        [0.2, '#f1eef6'],
        [0.2, '#bdc9e1'],
        [0.4, '#bdc9e1'],
        [0.4, '#74a9cf'],
        [0.6, '#74a9cf'],
        [0.6, '#2b8cbe'],
        [0.8, '#2b8cbe'],
        [0.8, '#045a8d'],
        [1, '#045a8d']]

    colorbar = {'tick0': 0, 'dtick': 0.2, 'lenmode': 'pixels', 'len': 500, 'y': 1}

    Euclidean_clust = go.Heatmap(x=Euclidean_genome_df.columns.values.tolist(),
                                 y=Euclidean_genome_df.index.tolist(),
                                 z=Euclidean_genome_df.values.tolist(),
                                 colorscale=colorscale,
                                 colorbar=colorbar,
                                 hovertemplate='Sample: %{y}<br>Function: %{x}<br>Proportion: %{z}<extra></extra>',
                                 xgap=1,
                                 ygap=1)

    Correlation_clust = go.Heatmap(x=Correlation_genome_df.columns.values.tolist(),
                                   y=Correlation_genome_df.index.tolist(),
                                   z=Correlation_genome_df.values.tolist(),
                                   colorscale=colorscale,
                                   colorbar=colorbar,
                                   xgap=1,
                                   ygap=1,
                                   hovertemplate='Sample: %{y}<br>Function: %{x}<br>Proportion: %{z}<extra></extra>',
                                   visible=False)

    Most_Least_clust = go.Heatmap(x=Most_Least_genome_df.columns.values.tolist(),
                                  y=Most_Least_genome_df.index.tolist(),
                                  z=Most_Least_genome_df.values.tolist(),
                                  colorscale=colorscale,
                                  colorbar=colorbar,
                                  xgap=1,
                                  ygap=1,
                                  hovertemplate='Sample: %{y}<br>Function: %{x}<br>Proportion: %{z}<extra></extra>',
                                  visible=False)

    Least_Most_clust = go.Heatmap(x=Least_Most_genome_df.columns.values.tolist(),
                                  y=Least_Most_genome_df.index.tolist(),
                                  z=Least_Most_genome_df.values.tolist(),
                                  colorscale=colorscale,
                                  colorbar=colorbar,
                                  xgap=1,
                                  ygap=1,
                                  hovertemplate='Sample: %{y}<br>Function: %{x}<br>Proportion: %{z}<extra></extra>',
                                  visible=False)

    data = [Euclidean_clust, Correlation_clust, Most_Least_clust, Least_Most_clust]

    updatemenus = [dict(
        buttons=[
            dict(label='Euclidean_Clustering', method='update', args=[{'visible': [True, False, False, False]}]),
            dict(label='Correlation_Clustering', method='update', args=[{'visible': [False, True, False, False]}]),
            dict(label='Most_to_Least', method='update', args=[{'visible': [False, False, True, False]}]),
            dict(label='Least_to_Most', method='update', args=[{'visible': [False, False, False, True]}])
        ],
        direction='down',
        pad={'r': 10, 't': 10},
        showactive=True,
        x=0.1,
        xanchor='left',
        y=menL,
        yanchor='top'
    )]

    layout = go.Layout(xaxis={'side': 'top'},
                       autosize=False,
                       width=xLen,
                       height=yLen,
                       plot_bgcolor='#000000',
                       margin=go.layout.Margin(t=500),
                       updatemenus=updatemenus,
                       )

    fig = go.Figure(data=data, layout=layout)
    py.plot(fig, filename=output_file, auto_open=False)


def make_tanglegram(genome_df, newick, output_file, tanglegram_opt):
    import pandas as pd
    import itertools
    from Bio import Phylo
    import tanglegram as tg
    from scipy.spatial.distance import pdist, squareform

    # FORMAT KEGGDECODER OUTPUT
    # generate distance matrix for genome_df from pathway values
    # genome_df = pd.read_csv(genome_df, index_col=0, sep='\t')
    kegg_d = squareform(pdist(genome_df, metric='euclidean'))
    kegg_m = pd.DataFrame(kegg_d)
    kegg_m.columns = genome_df.index.tolist()
    kegg_m.index = genome_df.index.tolist()
    kegg_m = kegg_m.reindex(sorted(kegg_m.columns), axis=1)  # reorder column names alphabetically
    kegg_m.sort_index(inplace=True)  # reorder row names alphabetically

    # FORMAT NEWICK FILE
    # generate distance matrix from newick file
    tree = Phylo.read(newick, 'newick')

    tree_d = {}
    for x, y in itertools.combinations(tree.get_terminals(), 2):
        v = tree.distance(x, y)
        tree_d[x.name] = tree_d.get(x.name, {})
        tree_d[x.name][y.name] = v
        tree_d[y.name] = tree_d.get(y.name, {})
        tree_d[y.name][x.name] = v

    for x in tree.get_terminals():
        tree_d[x.name][x.name] = 0

    tree_m = pd.DataFrame(tree_d)
    tree_m = tree_m.reindex(sorted(tree_m.columns), axis=1)  # reorder column names alphabetically
    tree_m.sort_index(inplace=True)  # reorder row names alphabetically

    # Plot and try to minimize cross-over
    yLen = len(genome_df.index.tolist()) * 0.4
    if len(genome_df.index.tolist()) <= 10:
        xLen = 10
    else:
        xLen = 10 + len(genome_df.index.tolist()) / 10
    fig = tg.gen_tangle(kegg_m, tree_m, optimize_order=tanglegram_opt, color_by_diff=True,
                        link_kwargs={'method': 'complete'})
    fig.set_size_inches(xLen, yLen)
    fig.savefig(output_file)


def write_final_output_file(koala_list, hmm_list, output_file, ap):
    koala = pd.read_csv(open(koala_list, "r"), index_col=0, sep="\t")
    hmm = pd.read_csv(open(hmm_list, "r"), index_col=0, sep="\t")
    output_df = koala.merge(hmm, left_index=True, right_index=True)

    # Reorganize column orientation to put like pathways together
    cols = output_df.columns.tolist()
    retinal_index = cols.index('Retinal biosynthesis')
    cols.insert(retinal_index + 1, cols.pop(int(cols.index('beta-carotene 15,15-monooxygenase'))))
    cols.insert(retinal_index + 2, cols.pop(int(cols.index('rhodopsin'))))
    trans_urea = cols.index('transporter: urea')
    cols.insert(trans_urea + 1, cols.pop(int(cols.index('transporter: ammonia'))))
    nifH_index = cols.index('nitrogen fixation')
    cols.insert(nifH_index + 1, cols.pop(int(cols.index('Vanadium-only nitrogenase'))))
    cols.insert(nifH_index + 2, cols.pop(int(cols.index('Iron-only nitrogenase'))))
    dmsplyase_index = cols.index('DMSP demethylation')
    cols.insert(dmsplyase_index, cols.pop(int(cols.index('DMSP lyase (dddLQPDKW)'))))
    cols.insert(dmsplyase_index + 1, cols.pop(int(cols.index('DMSP synthase (dsyB)'))))
    sulfitereductase_index = cols.index('dissimilatory sulfite < > sulfide')
    cols.insert(sulfitereductase_index + 1, cols.pop(int(cols.index('DsrD dissimilatory sulfite reductase'))))
    output_df = output_df[cols]
    output_df.index = [idx.replace(".protein", "") + ".fna" for idx in output_df.index]
    output_df.index.name = "ID"
    print(output_df)
    output_df.to_csv(output_file, sep="\t")

    file_in = open(output_file, "r")
    genome = pd.read_csv(file_in, index_col=0, sep='\t')
    rearrange = False
    if ap.args.myorder != 'None' and os.path.exists(ap.args.myorder):
        rearrange = True
        leaf_order = []
        for line in open(str(ap.args.myorder), "r"):
            line = line.rstrip("\r\n")
            leaf_order.append(line)
        genome = genome.reindex(leaf_order)

    if ap.args.vizoption == 'static':
        if len(genome.index) >= 2 and not rearrange:
            genome = hClust_euclidean(genome)
        default_viz(genome, prefix(ap.args.input) + ".svg")
    if ap.args.vizoption == 'interactive':
        plotly_viz(genome, prefix(ap.args.input) + ".html")
    if ap.args.vizoption == 'tanglegram':
        if len(genome.index) >= 3:
            make_tanglegram(genome, ap.args.newick, prefix(ap.args.input) + ".tanglegram.svg",
                            int(prefix(ap.args.tangleopt)))
        else:
            raise ValueError("Tanglegram mode requires three or more genomes")


def run():
    """ Primary calling script for flit

    :return:
    """
    possible_hmmsearch_path = try_which()
    ap = ArgParse(
        (
            (("-i", "--input"),
             {"help": "Input KOALA output (from blastKOALA, ghostKOALA, or kofamscan)", "required": True}),
            (("-p", "--protein_fasta"),
             {"help": "Protein FASTA file with ids matching KOALA output", "required": True}),
            (("-o", "--output"),
             {"help": "Prefix for all output files", "required": True}),
            (("-m", "--myorder"),
             {"help": "Orders output as specified by file", "default": "None"}),
            (("-v", "--vizoption"),
             {"help": "Options: static, interactive, tanglegram", "default": "interactive"}),
            (("-n", "--newick"),
             {"help": "Required input tree for tanglegram visualization", "default": "None"}),
            (("-t", "--tangleopt"),
             {"help": "Number of tree iterations for minimizing tangles in tanglegram", "default": "1000"}),
            (("-s", "--hmmsearch_path"),
             {"help": "Path to hmmsearch%s" %
                      ("; default: %s" % possible_hmmsearch_path if possible_hmmsearch_path else "None"),
              "default": possible_hmmsearch_path}),
        ),
        description="Decoder and expander workflow to parse through a KEGG-Koala outputs to determine the "
                    "completeness of various metabolic pathways."
    )
    # Require hmmsearch
    assert ap.args.hmmsearch_path != "None" and os.path.exists(ap.args.hmmsearch_path), "Provide valid path to " \
                                                                                        "hmmsearch "
    # Run KEGG-decoder
    decoder_outfile = prefix(ap.args.output) + ".decoder.tsv"
    print_run(
        local["python3"][
            os.path.join(os.path.dirname(__file__), "KEGG_decoder.py"),
            "--input", ap.args.input, "--output", decoder_outfile
        ]
    )
    # Run hmmsearch
    hmmsearch_results = prefix(ap.args.input) + ".expander.tbl"
    print_run(
        local[ap.args.hmmsearch_path]
        ["--tblout", hmmsearch_results, "-T", "75",
         os.path.join(os.path.dirname(__file__), "HMM_Models/expander_dbv0.7.hmm"),
         ap.args.protein_fasta]
    )
    # Run expander
    expander_outfile = prefix(ap.args.input) + ".expander.tsv"
    print_run(
        local["python3"][
            os.path.join(os.path.dirname(__file__), "KEGG_expander.py"),
            hmmsearch_results, expander_outfile
        ]
    )
    # Run decoder-expander and save final image
    write_final_output_file(decoder_outfile, expander_outfile, prefix(ap.args.output) + ".final.tsv", ap)


if __name__ == "__main__":
    run()
