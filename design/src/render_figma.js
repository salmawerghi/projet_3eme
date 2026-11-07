/* ============================================================
   DarImmo — Plugin Figma : dessine les maquettes de spec.js
   Résultat : une page « DarImmo · Maquettes v3 » avec
   - les variables de couleur (modes Clair / Sombre)
   - la planche Design system
   - 23 écrans en auto-layout, rangés par membre (A, B, C)
   ============================================================ */
var VARS = {};          // nom du token -> Variable Figma
var FONT = {};          // graisse -> FontName
var FONT_D = {};        // police display : { regular, italic }
var IMG_HASH = {};      // clé image -> imageHash
var WARN = [];

function hexToRgba(hex) {
  var h = hex.replace('#', '');
  return {
    r: parseInt(h.substr(0, 2), 16) / 255, g: parseInt(h.substr(2, 2), 16) / 255, b: parseInt(h.substr(4, 2), 16) / 255,
    a: h.length >= 8 ? parseInt(h.substr(6, 2), 16) / 255 : 1
  };
}
function lightHex(name) { return TOKENS[name] ? TOKENS[name][0] : name; }

function solidPaint(c) {
  var parts = c.split('/'), name = parts[0], mult = parts[1] ? parseFloat(parts[1]) / 100 : 1;
  var rgba = hexToRgba(lightHex(name));
  var paint = { type: 'SOLID', color: { r: rgba.r, g: rgba.g, b: rgba.b }, opacity: rgba.a * mult };
  if (VARS[name]) {
    try {
      paint = figma.variables.setBoundVariableForPaint(paint, 'color', VARS[name]);
      paint = Object.assign({}, paint, { opacity: mult });   // l'alpha est porté par la variable
    } catch (e) { /* on garde la couleur fixe */ }
  }
  return paint;
}
function gradientPaint(g) {
  var T = { v: [[0, 1, 0], [-1, 0, 1]], h: [[1, 0, 0], [0, 1, 0]], d: [[0.5, 0.5, 0], [-0.5, 0.5, 0.5]] }[g.g];
  var n = g.s.length;
  return {
    type: 'GRADIENT_LINEAR', gradientTransform: T,
    gradientStops: g.s.map(function (c, i) {
      var parts = c.split('/'), rgba = hexToRgba(lightHex(parts[0]));
      if (parts[1]) rgba.a = rgba.a * parseFloat(parts[1]) / 100;
      return { position: n === 1 ? 0 : i / (n - 1), color: rgba };
    })
  };
}
function paintFor(c) { return typeof c === 'object' ? gradientPaint(c) : solidPaint(c); }

var SHADOWS_FIG = {
  sm: [[0, 1, 2, 0, 0.06], [0, 2, 6, 0, 0.06]],
  md: [[0, 6, 16, -4, 0.22]],
  lg: [[0, 18, 36, -10, 0.30]],
  up: [[0, -6, 24, 0, 0.12]]
};
function effectsFor(name) {
  return SHADOWS_FIG[name].map(function (s) {
    return { type: 'DROP_SHADOW', color: { r: 16 / 255, g: 24 / 255, b: 40 / 255, a: s[4] }, offset: { x: s[0], y: s[1] },
      radius: s[2], spread: s[3], visible: true, blendMode: 'NORMAL' };
  });
}
var MAIN_FIG = { start: 'MIN', center: 'CENTER', end: 'MAX', between: 'SPACE_BETWEEN' };
var CROSS_FIG = { start: 'MIN', center: 'CENTER', end: 'MAX' };

function setPad(node, p) {
  if (p === undefined) return;
  var t, r, b, l;
  if (typeof p === 'number') { t = r = b = l = p; }
  else if (p.length === 2) { t = b = p[0]; r = l = p[1]; }
  else { t = p[0]; r = p[1]; b = p[2]; l = p[3]; }
  node.paddingTop = t; node.paddingRight = r; node.paddingBottom = b; node.paddingLeft = l;
}
function trySet(node, prop, val) {
  try { node[prop] = val; } catch (e) { WARN.push(node.name + ' · ' + prop + '=' + val + ' : ' + e.message); }
}
function sizing(node, n, pDir, isAutoLayout) {
  var inAuto = !!pDir && !n.abs;
  ['w', 'h'].forEach(function (axis) {
    var v = n[axis], prop = axis === 'w' ? 'layoutSizingHorizontal' : 'layoutSizingVertical';
    if (typeof v === 'number') { if (inAuto || isAutoLayout) trySet(node, prop, 'FIXED'); }
    else if (v === 'fill') { if (inAuto) trySet(node, prop, 'FILL'); }
    else if (isAutoLayout) trySet(node, prop, 'HUG');
  });
}
function placeAbs(node, n, parent) {
  var a = n.abs;
  if (parent.layoutMode && parent.layoutMode !== 'NONE') trySet(node, 'layoutPositioning', 'ABSOLUTE');
  var x = a.l !== undefined ? a.l : (a.r !== undefined ? parent.width - a.r - node.width : 0);
  var y = a.t !== undefined ? a.t : (a.b !== undefined ? parent.height - a.b - node.height : 0);
  node.x = x; node.y = y;
  try { node.constraints = { horizontal: a.r !== undefined && a.l === undefined ? 'MAX' : 'MIN', vertical: a.b !== undefined && a.t === undefined ? 'MAX' : 'MIN' }; } catch (e) { }
}
function bindVectorColors(root, color) {
  var paint = solidPaint(color);
  root.findAll(function () { return true; }).forEach(function (v) {
    if ('strokes' in v && v.strokes.length) v.strokes = [paint];
    if ('fills' in v && v.fills.length && v.type !== 'FRAME') v.fills = [paint];
  });
}
function svgForFigma(svg) {
  return svg.replace(/\{([^}]+)\}/g, function (m, tok) { return lightHex(tok.split('/')[0]); });
}

async function build(n, parent, pDir) {
  var node;
  if (n.t === 'text') {
    node = figma.createText();
    var parts = n.s.split('*'), plain = parts.join(''), ranges = [], pos = 0;
    if (parts.length > 2) parts.forEach(function (seg, i) { if (i % 2 && seg) ranges.push([pos, pos + seg.length]); pos += seg.length; });
    else plain = n.s;
    node.fontName = n.font === 'display' ? (n.it ? FONT_D.italic : FONT_D.regular) : (FONT[n.wt] || FONT[500]);
    node.characters = plain;
    node.fontSize = n.size;
    node.lineHeight = { unit: 'PIXELS', value: n.lh || Math.round(n.size * 1.4) };
    if (n.ls) node.letterSpacing = { unit: 'PIXELS', value: n.ls };
    if (n.align) node.textAlignHorizontal = n.align === 'center' ? 'CENTER' : n.align === 'right' ? 'RIGHT' : 'LEFT';
    node.fills = [paintFor(n.color)];
    ranges.forEach(function (r) {
      try { node.setRangeFontName(r[0], r[1], FONT_D.italic); if (n.em) node.setRangeFills(r[0], r[1], [paintFor(n.em)]); } catch (e) { WARN.push('Texte riche : ' + e.message); }
    });
    node.name = n.name || plain.slice(0, 40);
    parent.appendChild(node);
    if (n.w === 'fill' && pDir) { node.textAutoResize = 'HEIGHT'; trySet(node, 'layoutSizingHorizontal', 'FILL'); }
    else if (typeof n.w === 'number') { node.resize(n.w, node.height); node.textAutoResize = 'HEIGHT'; }
    else node.textAutoResize = 'WIDTH_AND_HEIGHT';
    if (n.max) { try { node.textTruncation = 'ENDING'; node.maxLines = n.max; } catch (e) { } }
  } else if (n.t === 'icon') {
    node = figma.createNodeFromSvg(iconSVG(n.n, '#000000', n.size, n.filled, n.sw));
    node.name = 'icône/' + n.n;
    node.fills = [];
    bindVectorColors(node, n.color);
    parent.appendChild(node);
    node.resize(n.size, n.size);
  } else if (n.t === 'svg') {
    node = figma.createNodeFromSvg(svgForFigma(n.svg));
    node.name = n.name || 'Illustration';
    node.fills = [];
    parent.appendChild(node);
    if (n.w && n.h) node.resize(n.w, n.h);
  } else {
    node = figma.createFrame();
    node.name = n.name || (n.dir === 'H' ? 'Ligne' : n.dir === 'V' ? 'Colonne' : 'Cadre');
    node.fills = [];
    node.clipsContent = !!(n.clip || n.scroll);
    if (n.dir) {
      node.layoutMode = n.dir === 'H' ? 'HORIZONTAL' : 'VERTICAL';
      node.itemSpacing = n.gap || 0;
      node.primaryAxisAlignItems = MAIN_FIG[n.main || 'start'];
      node.counterAxisAlignItems = CROSS_FIG[n.cross || 'start'];
      if (n.wrap && n.dir === 'H') { node.layoutWrap = 'WRAP'; node.counterAxisSpacing = n.gap || 0; }
      setPad(node, n.pad);
    }
    node.resize(typeof n.w === 'number' ? n.w : 100, typeof n.h === 'number' ? n.h : 100);
    var fills = [];
    if (n.img) fills.push({ type: 'SOLID', color: hexToRgba(lightHex('surface2')) });
    if (n.img && IMG_HASH[n.img]) fills = [{ type: 'IMAGE', scaleMode: 'FILL', imageHash: IMG_HASH[n.img] }];
    else if (n.fill) fills.push(paintFor(n.fill));
    node.fills = fills.map(function (f) { if (f.color && f.color.a !== undefined && f.type === 'SOLID' && !f.boundVariables) { var c = f.color; return { type: 'SOLID', color: { r: c.r, g: c.g, b: c.b }, opacity: c.a }; } return f; });
    if (n.r !== undefined) {
      if (Array.isArray(n.r)) { node.topLeftRadius = n.r[0]; node.topRightRadius = n.r[1]; node.bottomRightRadius = n.r[2]; node.bottomLeftRadius = n.r[3]; }
      else node.cornerRadius = n.r;
    }
    if (n.stroke) {
      node.strokes = [paintFor(n.stroke)];
      node.strokeAlign = 'INSIDE';
      var sw = n.sw || 1;
      if (n.sides) {
        node.strokeTopWeight = n.sides.indexOf('t') >= 0 ? sw : 0;
        node.strokeBottomWeight = n.sides.indexOf('b') >= 0 ? sw : 0;
        node.strokeLeftWeight = n.sides.indexOf('l') >= 0 ? sw : 0;
        node.strokeRightWeight = n.sides.indexOf('r') >= 0 ? sw : 0;
      } else node.strokeWeight = sw;
      if (n.dash) node.dashPattern = [6, 4];
    }
    if (n.shadow) node.effects = effectsFor(n.shadow);
    if (n.scroll) try { node.overflowDirection = 'VERTICAL'; } catch (e) { }
    parent.appendChild(node);
    sizing(node, n, pDir, !!n.dir);
    for (var i = 0; i < n.c.length; i++) await build(n.c[i], node, n.dir);
  }
  if (n.op !== undefined) node.opacity = n.op;
  if (n.t !== 'frame' && n.t !== 'text') sizing(node, n, pDir, false);
  if (n.abs) placeAbs(node, n, parent);
  return node;
}

async function loadDisplayFont() {
  var list = (typeof FONTS !== 'undefined' && FONTS.display) ? FONTS.display : [];
  for (var f = 0; f < list.length; f++) {
    try {
      await figma.loadFontAsync({ family: list[f], style: 'Regular' });
      FONT_D.regular = { family: list[f], style: 'Regular' };
      try { await figma.loadFontAsync({ family: list[f], style: 'Italic' }); FONT_D.italic = { family: list[f], style: 'Italic' }; }
      catch (e) { FONT_D.italic = FONT_D.regular; }
      return list[f];
    } catch (e) { }
  }
  FONT_D.regular = FONT[500]; FONT_D.italic = FONT[500];
  if (list.length) WARN.push('Police display introuvable (' + list.join(', ') + ') : remplacée par la police de texte.');
  return null;
}
async function loadFonts() {
  var families = (typeof FONTS !== 'undefined' && FONTS.body) ? FONTS.body : ['Plus Jakarta Sans', 'Inter'];
  var styles = { 400: ['Regular'], 500: ['Medium'], 600: ['SemiBold', 'Semi Bold'], 700: ['Bold'], 800: ['ExtraBold', 'Extra Bold'] };
  for (var f = 0; f < families.length; f++) {
    var ok = true, res = {};
    for (var w in styles) {
      var found = false;
      for (var s = 0; s < styles[w].length && !found; s++) {
        try { await figma.loadFontAsync({ family: families[f], style: styles[w][s] }); res[w] = { family: families[f], style: styles[w][s] }; found = true; } catch (e) { }
      }
      if (!found) { ok = false; break; }
    }
    if (ok) { FONT = res; var d = await loadDisplayFont(); return families[f] + (d ? ' + ' + d : ''); }
  }
  throw new Error('Aucune police disponible (' + families.join(', ') + ').');
}

async function setupVariables() {
  var NAME = (typeof META !== 'undefined' && META.collection) || 'DarImmo · Couleurs';
  var cols = await figma.variables.getLocalVariableCollectionsAsync();
  var col = null;
  for (var i = 0; i < cols.length; i++) if (cols[i].name === NAME) col = cols[i];
  if (!col) { col = figma.variables.createVariableCollection(NAME); col.renameMode(col.modes[0].modeId, 'Clair'); }
  var lightId = col.modes[0].modeId, darkId = null;
  for (var m = 0; m < col.modes.length; m++) if (col.modes[m].name === 'Sombre') darkId = col.modes[m].modeId;
  if (!darkId) { try { darkId = col.addMode('Sombre'); } catch (e) { WARN.push('Mode Sombre non créé (offre Figma gratuite limitée à 1 mode).'); } }
  var existing = await figma.variables.getLocalVariablesAsync('COLOR');
  for (var name in TOKENS) {
    var v = null;
    for (var j = 0; j < existing.length; j++) if (existing[j].name === name && existing[j].variableCollectionId === col.id) v = existing[j];
    if (!v) v = figma.variables.createVariable(name, col, 'COLOR');
    v.setValueForMode(lightId, hexToRgba(TOKENS[name][0]));
    if (darkId) v.setValueForMode(darkId, hexToRgba(TOKENS[name][1]));
    VARS[name] = v;
  }
}

function loadImages() {
  if (typeof IMAGES === 'undefined') return;
  for (var k in IMAGES) {
    try {
      var b64 = IMAGES[k].split(',')[1];
      IMG_HASH[k] = figma.createImage(figma.base64Decode(b64)).hash;
    } catch (e) { WARN.push('Image ' + k + ' : ' + e.message); }
  }
}

async function main() {
  figma.notify('DarImmo : préparation des polices, couleurs et images…', { timeout: 2500 });
  var family = await loadFonts();
  try { await setupVariables(); } catch (e) { WARN.push('Variables : ' + e.message); }
  loadImages();

  var page = figma.createPage();
  page.name = (typeof META !== 'undefined' && META.page) || 'DarImmo · Maquettes v3';
  await figma.setCurrentPageAsync(page);

  var GAP_X = 80, y = 0, total = 0;

  // Planche design system
  var ds = await build(designSystem(), page, null);
  ds.x = 0; ds.y = y; y += ds.height + 240;

  for (var g = 0; g < GROUPS.length; g++) {
    var grp = GROUPS[g];
    var title = figma.createText();
    title.fontName = FONT[800]; title.fontSize = 56; title.characters = 'Tâche ' + grp.task + ' · ' + grp.owner;
    title.fills = [paintFor('text')]; page.appendChild(title); title.x = 0; title.y = y;
    var sub = figma.createText();
    sub.fontName = FONT[500]; sub.fontSize = 26; sub.characters = grp.title + ' · ' + grp.epics;
    sub.fills = [paintFor('muted')]; page.appendChild(sub); sub.x = 0; sub.y = y + 76;
    y += 150;
    var frames = [];
    for (var s = 0; s < grp.screens.length; s++) {
      var spec = grp.screens[s]();
      var f = await build(spec, page, null);
      f.x = s * (390 + GAP_X); f.y = y;
      f.setPluginData('stories', spec.meta.stories);
      var cap = figma.createText();
      cap.fontName = FONT[600]; cap.fontSize = 18; cap.characters = 'Stories ' + spec.meta.stories;
      cap.fills = [paintFor('muted')]; page.appendChild(cap); cap.x = f.x; cap.y = y + 844 + 20;
      frames.push(f); total++;
    }
    try {
      var sec = figma.createSection();
      sec.name = grp.id + ' · ' + grp.owner + ' (' + grp.task + ')';
      page.appendChild(sec);
      sec.x = -60; sec.y = y - 60;
      sec.resizeWithoutConstraints(grp.screens.length * (390 + GAP_X) - GAP_X + 120, 844 + 140);
      frames.forEach(function (fr) { var ax = fr.x, ay = fr.y; sec.appendChild(fr); fr.x = ax - sec.x; fr.y = ay - sec.y; });
    } catch (e) { WARN.push('Sections : ' + e.message); }
    y += 844 + 260;
    figma.notify(grp.owner + ' : ' + grp.screens.length + ' écrans créés', { timeout: 1500 });
  }
  figma.viewport.scrollAndZoomIntoView(page.children);
  if (WARN.length) console.warn('DarImmo — avertissements :\n' + WARN.join('\n'));
  figma.closePlugin('✓ ' + total + ' écrans + design system créés (police : ' + family + ')' + (WARN.length ? ' · ' + WARN.length + ' avertissement(s), voir la console' : ''));
}

main().catch(function (e) { console.error(e); figma.closePlugin('Erreur : ' + e.message); });
