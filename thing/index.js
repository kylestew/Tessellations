import {
  plane,
  rect,
  circle,
  translate,
  transform,
  transformVertices,
} from "@thi.ng/geom";
import { asPolygon } from "@thi.ng/geom/as-polygon";
import { polygon, tessellate, centroid, arcLength } from "@thi.ng/geom";
import { polar } from "@thi.ng/vectors";
import { scale22, IDENT22 } from "@thi.ng/matrices";
import { fit01, fit11, deg } from "@thi.ng/math";
import { values } from "@thi.ng/intervals";
import {
  earCut2,
  rimTris,
  quadFan,
  triFan,
  edgeSplit,
} from "@thi.ng/geom-tessellate";
import * as dat from "dat.gui";
import Stats from "stats.js";

const PADDING = 0.2;
var ctx;
var stats;
var params;

/**
 * Creates a color by mapping the centroid of given shape from cartesian
 * space to HSL.
 */
const centroidToHSL = (p, radius) => {
  const c = polar(null, centroid(p));
  const h = deg(c[1]);
  const s = fit01(c[0] / radius, 0, 100);
  const l = fit01(c[0] / radius, 100, 50);
  return `hsl(${h},${s}%,${l}%)`;
};

/**
 * Creates an HSL color from the arc length / circumference of the given
 * shape.
 */
const arclengthToHSL = (max, p) =>
  `hsl(${fit01(arcLength(p) / max, 0, 360)},100%,50%)`;

/**
 * Converts given point array into a polygon and computes fill color
 * with provided `tint` function.
 */
const tintedPoly = (points, tint) => {
  const p = polygon(points);
  p.attribs = {
    fill: tint(p),
  };
  return p;
};

const createTriangularGrid = (rows, cols, width, height) => {
  // create grid of points
  var pts = [];
  const cell_width = width / cols;
  const cell_height = height / rows;
  for (var y = 0; y < rows + 1; ++y) {
    for (var x = 0; x < cols + 1; ++x) {
      pts.push([x * cell_width, y * cell_height]);
    }
  }

  // gather points into polygons
  var polys = [];
  for (var y = 0; y < rows; ++y) {
    for (var x = 0; x < cols; ++x) {
      // (0:0, 0:1, 1:0), (1:0, 0:1, 1:1)
      const idx0 = y * cols + x + y;
      const idx1 = (y + 1) * cols + x + (y + 1);
      polys.push(polygon([pts[idx0], pts[idx0 + 1], pts[idx1]]));
      polys.push(polygon([pts[idx1], pts[idx0 + 1], pts[idx1 + 1]]));
    }
  }
  return polys;
};

const createBaseGeo = (size) => {
  const translateFn = (poly) => translate(poly, [-size / 2, -size / 2]);
  return createTriangularGrid(4, 4, size, size).map(translateFn);

  // TODO: other shapes to use
  // return asPolygon(rect([-size / 2, -size / 2], size), 12);
  // return asPolygon(circle([0, 0], size / 2), params.polySides);
};

function render(ctx) {
  // bound size by smallest canvas dimension
  let width = ctx.canvas.width;
  let height = ctx.canvas.height;
  var size = width < height ? width : height;
  size *= 1.0 - PADDING;

  // TODO: selectable base geo
  const baseGeo = createBaseGeo(size);

  // setup tessellate -> tint pipeline
  const tintFn = (poly) => centroidToHSL(poly, size / 2);
  const polyTintFn = (points) => tintedPoly(points, tintFn);
  // TODO: selectable tesselation stack
  // TODO: color mapping has a TON of options
  // https://github.com/thi-ng/umbrella/tree/develop/packages/geom-tessellate
  const tessFn = (poly) => tessellate(poly, [quadFan, triFan]).map(polyTintFn);
  const tessedPolys = baseGeo.map(tessFn).flat();

  const renderPoly = (poly) => {
    ctx.beginPath();
    const p0 = poly.points[0];
    ctx.moveTo(p0[0], p0[1]);
    poly.points.slice(1).map((p) => {
      ctx.lineTo(p[0], p[1]);
    });
    ctx.lineTo(p0[0], p0[1]);
    ctx.fillStyle = poly.attribs.fill;
    ctx.fill();
    ctx.stroke();
  };

  // center canvas
  ctx.translate(ctx.canvas.width / 2, ctx.canvas.height / 2);

  // render out polys
  ctx.lineWidth = 0.5;
  tessedPolys.map(renderPoly);
}

function initGUI() {
  stats = new Stats();
  stats.showPanel(1);
  document.body.appendChild(stats.dom);

  const gui = new dat.GUI();
  params = {
    polySides: 12,
  };
  var folder1 = gui.addFolder("Base Geometry");
  var polySides = folder1
    .add(params, "polySides")
    .name("Poly Side Count")
    .min(3)
    .max(48)
    .step(1)
    .listen();
  folder1.open();

  polySides.onChange(() => {
    update();
  });
}

function update() {
  stats.begin();
  ctx.canvas.width = window.innerWidth;
  ctx.canvas.height = window.innerHeight;
  render(ctx);
  stats.end();
}

function init() {
  var canvas = document.getElementById("canvas");
  ctx = canvas.getContext("2d");
  initGUI();
  update();
}

window.onload = function () {
  init();
};

window.onresize = function () {
  update();
};
