import { fit01, deg } from "@thi.ng/math";
import { polar } from "@thi.ng/vectors";
import { centroid, arcLength } from "@thi.ng/geom";

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

export { tintedPoly, centroidToHSL };
