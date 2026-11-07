/* DarImmo — rendu HTML de la spécification (spec.js) */
var SHADOWS_CSS = {
  sm: '0 1px 2px rgba(16,24,40,.06), 0 2px 6px rgba(16,24,40,.06)',
  md: '0 6px 16px -4px rgba(16,24,40,.22)',
  lg: '0 18px 36px -10px rgba(16,24,40,.30)',
  up: '0 -6px 24px rgba(16,24,40,.12)'
};
var MAIN_CSS = { start: 'flex-start', center: 'center', end: 'flex-end', between: 'space-between' };
var CROSS_CSS = { start: 'flex-start', center: 'center', end: 'flex-end' };

function cssColor(c) {
  if (!c) return null;
  if (typeof c === 'object') {
    var ang = { v: '180deg', h: '90deg', d: '135deg' }[c.g];
    return 'linear-gradient(' + ang + ', ' + c.s.map(cssColor).join(', ') + ')';
  }
  var parts = c.split('/'), name = parts[0];
  var base = TOKENS[name] ? 'var(--t-' + name + ')' : name;
  if (parts[1]) return 'color-mix(in srgb, ' + base + ' ' + parts[1] + '%, transparent)';
  return base;
}
/* Dans un SVG, fill="{token}" devient style="fill:var(--t-token)" */
function svgForHTML(svg) {
  return svg.replace(/<[^>]+>/g, function (tag) {
    var styles = [];
    tag = tag.replace(/\s(fill|stroke)="\{([^}]+)\}"/g, function (m, attr, tok) { styles.push(attr + ':' + cssColor(tok)); return ''; });
    if (!styles.length) return tag;
    var selfClose = /\/>$/.test(tag);
    return tag.replace(/\/?>$/, ' style="' + styles.join(';') + '"' + (selfClose ? '/>' : '>'));
  });
}
function padCSS(p) {
  if (p === undefined) return null;
  if (typeof p === 'number') return p + 'px';
  if (p.length === 2) return p[0] + 'px ' + p[1] + 'px';
  return p.map(function (v) { return v + 'px'; }).join(' ');
}
function applySize(st, n, pDir, isText) {
  st.flexShrink = '0';
  if (typeof n.w === 'number') st.width = n.w + 'px';
  else if (n.w === 'fill') {
    if (pDir === 'H') { st.flex = '1 1 0'; st.minWidth = '0'; }
    else if (pDir === 'V') st.alignSelf = 'stretch';
    else st.width = '100%';
  }
  if (typeof n.h === 'number') st.height = n.h + 'px';
  else if (n.h === 'fill') {
    if (pDir === 'V') { st.flex = '1 1 0'; st.minHeight = '0'; }
    else if (pDir === 'H') st.alignSelf = 'stretch';
    else st.height = '100%';
  }
}
function applyAbs(st, a) {
  st.position = 'absolute';
  if (a.l !== undefined) st.left = a.l + 'px';
  if (a.t !== undefined) st.top = a.t + 'px';
  if (a.r !== undefined) st.right = a.r + 'px';
  if (a.b !== undefined) st.bottom = a.b + 'px';
}
function renderHTML(n, pDir) {
  var el = document.createElement('div'), st = el.style;
  st.position = 'relative';
  st.boxSizing = 'border-box';
  if (n.t === 'text') {
    /* *mot* = segment mis en valeur (italique display + couleur n.em) */
    var parts = n.s.split('*');
    if (parts.length > 2) {
      parts.forEach(function (seg, i) {
        if (!seg) return;
        if (i % 2) {
          var sp = document.createElement('span');
          sp.textContent = seg;
          sp.style.fontFamily = 'var(--font-display)';
          sp.style.fontStyle = 'italic';
          sp.style.fontWeight = '400';
          if (n.em) sp.style.color = cssColor(n.em);
          el.appendChild(sp);
        } else el.appendChild(document.createTextNode(seg));
      });
    } else el.textContent = n.s;
    if (n.font === 'display') { st.fontFamily = 'var(--font-display)'; st.fontWeight = '400'; }
    if (n.it) st.fontStyle = 'italic';
    st.fontSize = n.size + 'px';
    if (n.font !== 'display') st.fontWeight = n.wt;
    st.lineHeight = (n.lh || Math.round(n.size * 1.4)) + 'px';
    st.color = cssColor(n.color);
    if (n.ls) st.letterSpacing = n.ls + 'px';
    if (n.align) st.textAlign = n.align;
    st.whiteSpace = (n.w === 'fill' || typeof n.w === 'number') ? 'normal' : 'nowrap';
    if (n.max === 1) { st.whiteSpace = 'nowrap'; st.overflow = 'hidden'; st.textOverflow = 'ellipsis'; }
    else if (n.max) { st.display = '-webkit-box'; st.webkitLineClamp = n.max; st.webkitBoxOrient = 'vertical'; st.overflow = 'hidden'; }
  } else if (n.t === 'icon') {
    el.innerHTML = iconSVG(n.n, 'currentColor', n.size, n.filled, n.sw);
    st.color = cssColor(n.color);
    st.width = st.height = n.size + 'px';
    st.display = 'flex';
  } else if (n.t === 'svg') {
    el.innerHTML = svgForHTML(n.svg);
    st.display = 'flex';
  } else {
    if (n.dir) {
      st.display = 'flex';
      st.flexDirection = n.dir === 'H' ? 'row' : 'column';
      if (n.gap) st.gap = n.gap + 'px';
      st.justifyContent = MAIN_CSS[n.main || 'start'];
      st.alignItems = CROSS_CSS[n.cross || 'start'];
      if (n.wrap) st.flexWrap = 'wrap';
    }
    if (n.pad !== undefined) st.padding = padCSS(n.pad);
    var bg = [];
    if (n.fill && typeof n.fill === 'object') bg.push(cssColor(n.fill));
    if (n.img && typeof IMAGES !== 'undefined' && IMAGES[n.img]) {
      bg.push('url(' + IMAGES[n.img] + ')');
      st.backgroundSize = 'cover'; st.backgroundPosition = 'center';
      st.backgroundColor = cssColor('surface2');
    }
    if (bg.length) st.backgroundImage = bg.join(', ');
    if (n.fill && typeof n.fill === 'string') st.backgroundColor = cssColor(n.fill);
    if (n.r !== undefined) st.borderRadius = Array.isArray(n.r) ? n.r.map(function (v) { return v + 'px'; }).join(' ') : n.r + 'px';
    if (n.stroke) {
      var b = (n.sw || 1) + 'px ' + (n.dash ? 'dashed' : 'solid') + ' ' + cssColor(n.stroke);
      if (n.sides) { var map = { t: 'Top', b: 'Bottom', l: 'Left', r: 'Right' }; n.sides.split('').forEach(function (s) { st['border' + map[s]] = b; }); }
      else st.border = b;
    }
    if (n.shadow) st.boxShadow = SHADOWS_CSS[n.shadow];
    if (n.clip) st.overflow = 'hidden';
    if (n.scroll) { st.overflowY = 'auto'; st.overflowX = 'hidden'; el.className = 'scroll'; }
    if (n.name) el.title = '';
    (n.c || []).forEach(function (ch) { el.appendChild(renderHTML(ch, n.dir)); });
  }
  if (n.op !== undefined) st.opacity = n.op;
  applySize(st, n, pDir, n.t === 'text');
  if (n.abs) applyAbs(st, n.abs);
  if (n.name) el.setAttribute('data-layer', n.name);
  return el;
}
