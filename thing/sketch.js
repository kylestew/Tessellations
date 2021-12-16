import { circle } from "@thi.ng/geom";
import { fit } from "@thi.ng/math";
import * as dx from "./snod/drawer";

import { BaseGeoTypes, createBaseGeo } from "./base-geo";
import { tintedPoly, centroidToHSL } from "./tint";
import { renderPolygons } from "./render";

import { polygon, tessellate } from "@thi.ng/geom";
import {
  earCut2,
  rimTris,
  quadFan,
  triFan,
  edgeSplit,
} from "@thi.ng/geom-tessellate";

const settings = {
  animated: true,
  clearColor: "black",
};

let circ;

function update(time) {
  let rad = fit(Math.sin(time / 1000), -1, 1, 0.2, 0.8);
  circ = circle([0, 0], rad);
}

function render({ ctx, canvasScale }) {
  ctx.strokeWidth(12);
  ctx.strokeStyle = "#fff";
  dx.circle(ctx, circ.pos, circ.r, true);

  // function render(ctx) {
  //   let aspect = ctx.canvas.width / ctx.canvas.height;
  //   console.log("aspect:", aspect);

  //   const baseGeo = createBaseGeo(params.geometry, aspect, params.density);
  //   // console.log(baseGeo);

  //   // select tint function
  //   // TODO: color mapping has a TON of options
  //   // const tintFn = (poly) => centroidToHSL(poly, size / 2);
  //   // const polyTintFn = (points) => tintedPoly(points, tintFn);

  //   // setup tessellate -> tint pipeline
  //   // TODO: selectable tesselation stack
  //   // const tessFn = (poly) => tessellate(poly, [quadFan, triFan]).map(polyTintFn);
  //   // const tessedPolys = baseGeo.map(tessFn).flat();

  //   renderPolygons(ctx, baseGeo, {
  //     strokeEnabled: params.drawLines,
  //     strokeWeight: params.lineStrength,
  //   });
  // }
}

export { settings, update, render };
