#!/usr/bin/env python

import sys
import textwrap

import matplotlib.pyplot as plt
from descartes.patch import PolygonPatch

import graph


def GenerateOutputFile(grph):
    array = grph.synthesizeArray()  

    output_str = "   AvgPoint2StateLookup : constant array\n     (X_Coordinate'Range, Y_Coordinate'Range)\n     of LineState :=\n      "

    print "array length: %d" % (len(array) * len(array[0]))

    output_str += grph.array2String(array)

    output_str = textwrap.fill(output_str, width=78, subsequent_indent="                              ")

    with open("output.txt", "w") as file:
        file.write(output_str)


def GeneratePlots(grph):
    bounds = grph.getBounds()

    plt.figure()
    ax = plt.axes()
    ax.set_aspect('equal')

    for key, shape in grph.shapeIter():
        patch = PolygonPatch(shape["polygon"], facecolor=shape["color"], edgecolor=[0,0,0], label=key)
        plt.plot(shape["point"].x, shape["point"].y, 'ko')
        plt.text(shape["txtpos"].x, shape["txtpos"].y, key)

        ax.add_patch(patch)

    # TODO: This threshold should not be hard coded
    thresh_circle = plt.Circle((0, 0), 7, facecolor='#ffffff', edgecolor=[0,0,0])
    ax.add_patch(thresh_circle)

    plt.text(-2, -1, "Noise")

    plt.xlim(bounds["xMin"] - 2, bounds["xMax"] + 2)
    plt.ylim(bounds["yMin"] - 2, bounds["yMax"] + 2)
    lgd = ax.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)

    plt.savefig('graph.png', bbox_extra_artists=(lgd,), bbox_inches='tight')


def usage():
    print "%s [corner coordinate]" % (sys.argv[0])
    print "\t Generate the plot and output file for the lookup graph with the specified corner coordinate"
    print "\t corner coordinate is cooresponds to half the width and half"
    print "\t the height of the graph. Since the graph is center around 0"
    print "\t the corner coordinate is the coordinate at the corner of the graph."
    print "\n"
    print "%s [corner colordinate] x y" % (sys.argv[0])
    print "\t Get the state that corresponds to the coordinate at (x, y)"


def main():
    if len(sys.argv) == 2:
        corner = int(sys.argv[1])
        grph = graph.graph(corner)

        GenerateOutputFile(grph)
        GeneratePlots(grph)

        print "Output file and graph generated successfully..."
        return
    elif len(sys.argv) == 4:
        corner = int(sys.argv[1])
        x = int(sys.argv[2])
        y = int(sys.argv[3])

        grph = graph.graph(corner)

        print grph.findBindingPolygons(x, y)
        return
    else:
        usage()
        return


if __name__ == "__main__":
    main() 
