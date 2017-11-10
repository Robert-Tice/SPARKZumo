import textwrap

from shapely.geometry import Point
from shapely.geometry.polygon import LinearRing, Polygon

import sys

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


def findBindingPolygons(x, y):
    point = Point(x, y)
    matchList = []
    for key, shape in shapes.iteritems():
        if point.within(shape["polygon"]):
            matchList.append(key)
    return matchList

def populatePoints():
    for y in range(yMin, yMax+1):
        for x in range(xMin, xMax+1):
            matchList = findBindingPolygons(x, y)

            if len(matchList) == 1:
                shapes[matchList[0]]["points"].append(Point(x, y))   
            elif len(matchList) == 0:
                pass
            else:
                raise Exception("Something bad happened")

def synthesizeArray():
    array = [["Unknown" for x in range(0, xMax - xMin + 1)] for y in range(0, yMax - yMin + 1)]

    for key, shape in shapes.iteritems():
        for point in shape["points"]:
            if array[int(point.x) - xMin][int(point.y) - yMin] == "Unknown":
                array[int(point.x) - xMin][int(point.y) - yMin] = key
            else:
                print "Found (%d, %d): %s" % (point.x, point.y, array[int(point.x) - xMin][int(point.y) - yMin])
                raise Exception('Something bad happened')

    return array

def array2String(array):
    return "(%s));" % ("(%s" % ("),\n(".join([', '.join([item for item in row]) for row in array])))

def GenerateOutputFile():
    populatePoints()

    array = synthesizeArray()  

    output_str = "   AvgPoint2StateLookup : constant array\n     (X_Coordinate'Range, Y_Coordinate'Range)\n     of LineState :=\n      "

    print "array length: %d" % (len(array) * len(array[0]))

    output_str += array2String(array)

    output_str = textwrap.fill(output_str, width=78, subsequent_indent="                              ")

    with open("output.txt", "w") as file:
        file.write(output_str)

def testArray(x, y):
    populatePoints()
    array = synthesizeArray()

    print array2String(array)

    return array[x][y]


def main():
    if len(sys.argv) == 1:
        GenerateOutputFile()
    elif len(sys.argv) == 3:
        x = int(sys.argv[1])
        y = int(sys.argv[2])
        myList = findBindingPolygons(x, y)

        if len(myList) == 0:
            myList.append("Unknown")
        elif len(myList) > 1:
            raise Exception("Something bad happened")

        x -= xMin
        y -= yMin

        result = testArray(x, y)

        print myList
        if myList[0] == result:
            print "Test passed"
        else:
            print "Test failed: got %s expected %s" % (result, myList[0])


if __name__ == "__main__":
    main() 


