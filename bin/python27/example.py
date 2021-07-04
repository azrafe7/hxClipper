# Adapting examples from https://github.com/fonttools/pyclipper

from hxClipper import *

def polyClipExample():
  subjPolysTuples = (
    ((180, 200), (260, 200), (260, 150), (180, 150)),
    ((215, 160), (230, 190), (200, 190))
  )
  clipPolyTuples = ((190, 210), (240, 210), (240, 130), (190, 130))

  subjPolys = [[IntPoint(tpl[0], tpl[1]) for tpl in poly] for poly in subjPolysTuples]

  # explicit conversion
  #
  #subjPolys = []
  #for subjPolyList in subjPolysTuples:
  #  subjPoly = []
  #  for tpl in subjPolyList:
  #    subjPoly.append(IntPoint(tpl[0], tpl[1]))
  #  subjPolys.append(subjPoly)

  clipPoly = [IntPoint(tpl[0], tpl[1]) for tpl in clipPolyTuples]

  c = Clipper()
  c.addPath(clipPoly, PolyType.PT_CLIP, closed=True)
  c.addPaths(subjPolys, PolyType.PT_SUBJECT, closed=True)

  pft = PolyFillType.PFT_EVEN_ODD
  solution = []
  success = c.executePaths(ClipType.CT_INTERSECTION, solution, pft, pft)

  print "  Solution: " + str(solution)

  # solution (a list of paths):
  #   [[(x:240, y:200, z:0), (x:190, y:200, z:0), (x:190, y:150, z:0), (x:240, y:150,z:0)],
  #    [(x:200, y:190, z:0), (x:230, y:190, z:0), (x:215, y:160, z:0)]]


def polyOffsetExample():
  subjPolyTuples = ((180, 200), (260, 200), (260, 150), (180, 150))

  subjPoly = [IntPoint(tpl[0], tpl[1]) for tpl in subjPolyTuples]
  co = ClipperOffset()
  co.addPath(subjPoly, JoinType.JT_ROUND, EndType.ET_CLOSED_POLYGON)

  solution = []
  co.execute(solution, delta=-7.0)

  print "  Solution: " + str(solution)

  # solution (a list of paths):
  #   [[(x:253, y:193, z:0), (x:187, y:193, z:0), (x:187, y:157, z:0), (x:253, y:157, z:0)]]


if __name__ == "__main__":
  print "poly clip example"
  polyClipExample()

  print "poly offset example"
  polyOffsetExample()

