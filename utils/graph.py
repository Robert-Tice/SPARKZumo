#!/usr/bin/env python

import math

from shapely.geometry import Point
from shapely.geometry.polygon import Polygon


class graph:
    __shapes = {
        "Online": {
            "points": [],
            "color": "#ff00ff"
        },
        "BranchLeft": {
            "points": [],
            "color": "#0000ff"
        },
        "Perp": {
            "points": [],
            "color": "#ff0000"
        },
        "Lost": {
            "points": [],
            "color": "#00ff00"
        },
        "Fork": {
            "points": [],
            "color": "#ffaa00"
        },
        "BranchRight": {
            "points": [],
            "color": "#633c01"
        }
    }

    def __init__(self, cornerCoord):
        self.__xMin = -1 * cornerCoord
        self.__xMax = cornerCoord
        self.__yMin = -1 * cornerCoord
        self.__yMax = cornerCoord

        self.y_diff = cornerCoord - int(cornerCoord / (2 * math.sqrt(3)))

        self.radii = int(cornerCoord / 3 * math.sqrt(2))

        self.__shapes["Online"].update({
                "polygon": Polygon([(self.__xMax, self.__yMax), (0, self.__yMax), (0, 0), (self.__xMax, self.y_diff)]),
                "point": Point(self.__xMax, self.__yMax),
                "txtpos": Point(self.__xMax - 4.5, self.__yMax + 0.5)
            })
        self.__shapes["BranchLeft"].update({
                "polygon": Polygon([(self.__xMin, self.y_diff), (0, 0), (0, self.__yMax), (self.__xMin, self.__yMax)]),
                "point": Point(self.__xMin, self.__yMax),
                "txtpos": Point(self.__xMin + 1, self.__yMax + 0.5)
            })
        self.__shapes["Perp"].update({
                "polygon": Polygon([(self.__xMin, -1 * self.y_diff), (0, 0), (self.__xMin, self.y_diff)]),
                "point": Point(self.__xMin, 0),
                "txtpos": Point(self.__xMin + 1, 0)
            })
        self.__shapes["Lost"].update({
                "polygon": Polygon([(0, self.__yMin), (0, 0), (self.__xMin, -1 * self.y_diff), (self.__xMin, self.__yMin)]),
                "point": Point(self.__xMin, self.__yMin),
                "txtpos": Point(self.__xMin + 1, self.__yMin - 1.5)
            })
        self.__shapes["Fork"].update({
                "polygon": Polygon([(self.__xMax, -1 * self.y_diff), (0, 0), (0, self.__yMin), (self.__xMax, self.__yMin)]),
                "point": Point(self.__xMax, self.__yMin),
                "txtpos": Point(self.__xMax - 3, self.__yMin - 1.5)
            })
        self.__shapes["BranchRight"].update({
                "polygon": Polygon([(self.__xMax, self.y_diff), (0, 0), (self.__xMax, -1 * self.y_diff)]),
                "point": Point(self.__xMax, 0),
                "txtpos": Point(self.__xMax + 1, 0)
            })

        self.__populatePoints()

    def __del__(self):
        for key, shape in self.shapeIter():
            del shape["points"][:]

    def findBindingPolygons(self, x, y):
        point = Point(x, y)
        matchList = []
        for key, shape in self.shapeIter():
            if point.within(shape["polygon"]):
                matchList.append(key)
        return matchList

    def __populatePoints(self):
        for y in range(self.__yMin, self.__yMax + 1):
            for x in range(self.__xMin, self.__xMax + 1):
                matchList = self.findBindingPolygons(x, y)

                if len(matchList) == 1:
                    self.__shapes[matchList[0]]["points"].append(Point(x, y))   
                elif len(matchList) == 0:
                    pass
                else:
                    raise Exception("Something bad happened")

    def array2String(self, array):
        outputStr = "(%s));" % ("(%s" % ("),\n(".join([', '.join([item for item in row]) for row in array])))
        return outputStr


    def synthesizeArray(self):
        array = [["Unknown" for x in range(0, self.__xMax - self.__xMin + 1)] for y in range(0, self.__yMax - self.__yMin + 1)]

        for key, shape in self.shapeIter():
            for point in shape["points"]:
                x = int(point.x) - self.__xMin
                y = int(point.y) - self.__yMin
                if array[x][y] == "Unknown":
                    array[x][y] = key
                else:
                    print "Found (%d, %d): %s" % (point.x, point.y, array[x][y])
                    raise Exception('Something bad happened')

        return array

    def shapeIter(self):
        return self.__shapes.iteritems()

    def getBounds(self):
        return {
            "xMin": self.__xMin,
            "xMax": self.__xMax,
            "yMin": self.__yMin,
            "yMax": self.__yMax
        }
