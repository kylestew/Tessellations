import { fit01 } from "@thi.ng/math";

const PADDING = 0.2;

const renderPoly = (ctx, poly, settings) => {
  ctx.beginPath();
  const p0 = poly.points[0];
  ctx.moveTo(p0[0], p0[1]);
  poly.points.slice(1).map((p) => {
    ctx.lineTo(p[0], p[1]);
  });
  ctx.lineTo(p0[0], p0[1]);
  // ctx.fillStyle = poly.attribs.fill;
  ctx.fill();
  if (settings.strokeEnabled) {
    ctx.stroke();
  }
};

const renderPolygons = (ctx, polys, settings) => {
  let width = ctx.canvas.width;
  let height = ctx.canvas.height;
  var scale = width < height ? height : width;
  scale *= (1.0 - PADDING) / 2.0;

  // center and scale canvas
  // all geometry should be centered on (0, 0)
  ctx.translate(ctx.canvas.width / 2, ctx.canvas.height / 2);
  ctx.scale(scale, scale);

  // render out polys
  ctx.strokeStyle = "white";
  ctx.lineJoin = "round";
  ctx.lineCap = "round";
  ctx.lineWidth = (1.0 / scale) * fit01(settings.strokeWeight, 0.5, 16);

  polys.map((poly) => renderPoly(ctx, poly, settings));
};

export { renderPolygons };
