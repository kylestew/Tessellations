import { polygon, circle, transform, translate, asPolygon } from "@thi.ng/geom";
import { fit01 } from "@thi.ng/math";
import { rotation22 } from "@thi.ng/matrices";

const createTriangularGrid = (density, width, height, aspect) => {
  const MinCells = 1;
  const MaxCells = 12;
  let horizCells, vertCells;
  if (aspect > 1.0) {
    horizCells = parseInt(fit01(density, MinCells, MaxCells));
    vertCells = Math.max(1, parseInt(horizCells / aspect));
  } else {
    vertCells = parseInt(fit01(density, MinCells, MaxCells));
    horizCells = Math.max(1, parseInt(vertCells * aspect));
  }

  // create grid of points evenly spaced to achieve cell count
  var pts = [];
  const cell_width = width / horizCells;
  const cell_height = height / vertCells;
  for (
    var y = -height / 2;
    y <= height / 2 + cell_height / 2;
    y += cell_height
  ) {
    for (var x = -width / 2; x <= width / 2 + cell_width / 2; x += cell_width) {
      pts.push([x, y]);
    }
  }

  // gather points into polygons
  var polys = [];
  for (var i = 0; i < vertCells * horizCells; ++i) {
    const idx0 = i + Math.floor(i / horizCells);
    const idx1 = idx0 + horizCells + 1;
    polys.push(polygon([pts[idx0], pts[idx0 + 1], pts[idx1]]));
    polys.push(polygon([pts[idx1], pts[idx0 + 1], pts[idx1 + 1]]));
  }
  return polys;
};

const createCircle = (density, size) => {
  const sideCount = parseInt(fit01(density, 3, 24));
  const rotMat = rotation22(null, Math.PI / 2.0);
  return transform(asPolygon(circle([0, 0], size / 2), sideCount), rotMat);
};

const createBaseGeo = (type, aspect, density) => {
  let width, height;
  if (aspect > 1.0) {
    // width is larger
    width = 2.0;
    height = width / aspect;
  } else {
    // height is larger
    height = 2.0;
    width = height * aspect;
  }

  switch (type) {
    case "mesh":
      return createTriangularGrid(density, width, height, aspect);

    default:
      const size = width > height ? height : width;
      return [createCircle(density, size)];
  }
};

const BaseGeoTypes = ["mesh", "circle"];

export { BaseGeoTypes, createBaseGeo };
