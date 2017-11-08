import textwrap

from matplotlib import pyplot as plt

from shapely.geometry import Point
from shapely.geometry.polygon import LinearRing, Polygon

Corner_Coord = 15

xMin = -1 * Corner_Coord
xMax = Corner_Coord
yMin = -1 * Corner_Coord
yMax = Corner_Coord

y_diff = yMax - int(yMax / 1.73)

shapes = {
    "Online": {
        "points": [],
        "polygon": Polygon([(xMax, yMax), (0, yMax), (0, 0), (xMax, y_diff)])
    },
    "BranchLeft": {
        "points": [],
        "polygon": Polygon([(xMin, y_diff), (0, 0), (0, yMax), (xMin, yMax)])
    },
    "Perp": {
        "points": [],
        "polygon": Polygon([(xMin, -1 * y_diff), (0, 0), (xMin, y_diff)])
    },
    "Lost": {
        "points": [],
        "polygon": Polygon([(0, yMin), (0, 0), (xMin, -1 * y_diff), (xMin, yMin)])
    },
    "Fork": {
        "points": [],
        "polygon": Polygon([(xMax, -1 * y_diff), (0, 0), (0, yMin), (xMax, yMin)])
    },
    "BranchRight": {
        "points": [],
        "polygon": Polygon([(xMax, y_diff), (0, 0), (xMax, -1 * y_diff)])
    }
}



# fig = plt.figure(1, figsize=(5,5), dpi=90)
# ax = fig.add_subplot(111)

# for key, shape in shapes.iteritems():
#     x, y = shape["polygon"].exterior.xy
#     ax.plot(x, y, color='#6699cc', alpha=0.7, linewidth=3, solid_capstyle='round', zorder=2)
# plt.show()

for y in range(yMin, yMax+1):
    for x in range(xMin, xMax+1):
        point = Point(x, y)
        matchList = []
        for key, shape in shapes.iteritems():
            if point.within(shape["polygon"]):
                matchList.append(key)


        if len(matchList) == 1:
            shapes[matchList[0]]["points"].append(point)   
        elif len(matchList) == 0:
            pass
        else:
            raise Exception("Something bad happened")


array = [["Unknown" for x in range(xMin, xMax+1)] for y in range(yMin, yMax+1)]

for key, shape in shapes.iteritems():
#    print "%s len: %d" % (key, len(shape["points"]))
    for point in shape["points"]:
#        print "(%d, %d): %s" % (point.x, point.y, key)

        if array[int(point.x)][int(point.y)] == "Unknown":
            array[int(point.x)][int(point.y)] = key
        else:
            print "Found (%d, %d): %s" % (point.x, point.y, array[int(point.x)][int(point.y)])
            raise Exception('Something bad happened')

output_str = "   AvgPoint2StateLookup : constant array\n     (X_Coordinate'Range, Y_Coordinate'Range)\n     of LineState :=\n      "

print "array length: %d" % (len(array) * len(array[0]))

output_str += "(%s));" % ("(%s" % ("),\n(".join([', '.join([item for item in row]) for row in array])))

output_str = textwrap.fill(output_str, width=78, subsequent_indent="                              ")

with open("output.txt", "w") as file:
    file.write(output_str)