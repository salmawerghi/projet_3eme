/* ============================================================
   DarImmo — Spécification des maquettes (source unique)
   Ce fichier décrit TOUS les écrans sous forme d'arbre de calques.
   - render_html.js  le dessine dans la page web
   - render_figma.js le dessine dans Figma (plugin)
   Modifier un écran ici = le modifier dans les deux.
   ============================================================ */

/* ---------- 1. Couleurs (variables) : [clair, sombre] ---------- */
var TOKENS = {
  primary:     ['#1D5FAD', '#6FA4E8'],   // Bleu Sidi Bou Saïd
  primaryDark: ['#133F75', '#A9C9F1'],
  primarySoft: ['#E5EEF9', '#1B2B42'],
  onPrimary:   ['#FFFFFF', '#0B1626'],
  accent:      ['#B85A26', '#EE9A62'],   // Ocre / terre cuite
  accentSoft:  ['#FAEBDD', '#3A2617'],
  bg:          ['#F6F4EF', '#0E131C'],   // Sable clair
  surface:     ['#FFFFFF', '#161D29'],
  surface2:    ['#EFECE5', '#1F2836'],
  text:        ['#14203A', '#EDF1F7'],
  text2:       ['#47526A', '#B9C3D3'],
  muted:       ['#737C8F', '#8893A6'],
  border:      ['#E4DFD4', '#2A3446'],
  success:     ['#17784F', '#43C58E'],
  successSoft: ['#E2F3EA', '#13301F'],
  warning:     ['#9A6412', '#E8B04A'],
  warningSoft: ['#FBF1DC', '#3A2D12'],
  danger:      ['#C23838', '#F07272'],
  dangerSoft:  ['#FBE6E4', '#3E1A1C'],
  scrim:       ['#0B1220A6', '#000000B8'],
  white:       ['#FFFFFF', '#FFFFFF'],
  mapLand:     ['#EEF0E8', '#19212D'],
  mapBlock:    ['#E2E4DA', '#212A38'],
  mapWater:    ['#BCD9EF', '#10304C'],
  mapPark:     ['#D4E8C4', '#1C3526'],
  mapRoad:     ['#FFFFFF', '#2D394B'],
  mapMain:     ['#F3CF83', '#5C4B25']
};
var TOKEN_LABELS = {
  primary: 'Primaire · Bleu Sidi Bou Saïd', accent: 'Accent · Ocre', bg: 'Fond · Sable',
  surface: 'Surface', surface2: 'Surface 2 (champs)', text: 'Texte', text2: 'Texte secondaire',
  muted: 'Texte discret', border: 'Bordure', success: 'Succès', warning: 'Attente', danger: 'Erreur'
};

/* ---------- 2. Icônes (tracés 24×24, style Lucide, licence ISC) ---------- */
var ICONS = {
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  heart: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
  home: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  message: '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  minus: '<path d="M5 12h14"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  bed: '<path d="M2 4v16"/><path d="M2 8h18a2 2 0 0 1 2 2v10"/><path d="M2 17h20"/><path d="M6 8v9"/>',
  maximize: '<path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/>',
  arrowLeft: '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
  arrowRight: '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
  chevronRight: '<path d="m9 18 6-6-6-6"/>',
  chevronDown: '<path d="m6 9 6 6 6-6"/>',
  camera: '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/>',
  image: '<rect width="18" height="18" x="3" y="3" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.09-3.09a2 2 0 0 0-2.82 0L6 21"/>',
  send: '<path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  checks: '<path d="M18 6 7 17l-5-5"/><path d="m22 10-7.5 7.5L13 16"/>',
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  eye: '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  eyeOff: '<path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><path d="M2 2l20 20"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  mail: '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
  phone: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>',
  flag: '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><path d="M4 22v-7"/>',
  sliders: '<path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M2 14h4"/><path d="M10 8h4"/><path d="M18 16h4"/>',
  star: '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>',
  pencil: '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
  share: '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m8.59 13.51 6.83 3.98"/><path d="m15.41 6.51-6.82 3.98"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9 12 2 2 4-4"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  alert: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  map: '<path d="M3 6l6-3 6 3 6-3v15l-6 3-6-3-6 3z"/><path d="M9 3v15"/><path d="M15 6v15"/>',
  locate: '<path d="M2 12h3"/><path d="M19 12h3"/><path d="M12 2v3"/><path d="M12 19v3"/><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.5"/>',
  more: '<circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/>',
  grip: '<circle cx="9" cy="5" r="1"/><circle cx="9" cy="12" r="1"/><circle cx="9" cy="19" r="1"/><circle cx="15" cy="5" r="1"/><circle cx="15" cy="12" r="1"/><circle cx="15" cy="19" r="1"/>',
  building: '<rect width="16" height="20" x="4" y="2" rx="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/>',
  store: '<path d="M3 9l1.5-5h15L21 9"/><path d="M3 9h18v1.5a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0z"/><path d="M5 13v8h14v-8"/><path d="M10 21v-5h4v5"/>',
  mountain: '<path d="m8 3 4 8 5-5 5 15H2L8 3z"/>',
  checkCircle: '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
  upload: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m17 8-5-5-5 5"/><path d="M12 3v12"/>',
  list: '<path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/>',
  tag: '<path d="M12.59 2.59A2 2 0 0 0 11.17 2H4a2 2 0 0 0-2 2v7.17a2 2 0 0 0 .59 1.42l8.7 8.7a2.43 2.43 0 0 0 3.42 0l6.58-6.58a2.43 2.43 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r="1"/>',
  key: '<circle cx="7.5" cy="15.5" r="5.5"/><path d="m21 2-9.6 9.6"/><path d="m15.5 7.5 3 3L22 7l-3-3"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  ban: '<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>',
  moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>',
  rotate: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
  info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  layers: '<path d="m12 2 10 5-10 5L2 7z"/><path d="m2 17 10 5 10-5"/><path d="m2 12 10 5 10-5"/>',
  trendDown: '<path d="m22 17-8.5-8.5-5 5L2 7"/><path d="M16 17h6v-6"/>',
  calendar: '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>',
  wifi: '<path d="M12 20h.01"/><path d="M2 8.82a15 15 0 0 1 20 0"/><path d="M5 12.86a10 10 0 0 1 14 0"/><path d="M8.5 16.43a5 5 0 0 1 7 0"/>',
  signal: '<rect x="2" y="15" width="3.5" height="6" rx="1" fill="currentColor" stroke="none"/><rect x="7.5" y="11" width="3.5" height="10" rx="1" fill="currentColor" stroke="none"/><rect x="13" y="7" width="3.5" height="14" rx="1" fill="currentColor" stroke="none"/><rect x="18.5" y="3" width="3.5" height="18" rx="1" fill="currentColor" stroke="none"/>',
  battery: '<rect x="1.5" y="6.5" width="19" height="11" rx="3"/><rect x="3.5" y="8.5" width="13" height="7" rx="1.5" fill="currentColor" stroke="none"/><path d="M23 10.5v3"/>'
};

function iconSVG(name, color, size, filled, sw) {
  var body = (ICONS[name] || ICONS.info).split('currentColor').join(color);
  return '<svg xmlns="http://www.w3.org/2000/svg" width="' + size + '" height="' + size +
    '" viewBox="0 0 24 24" fill="' + (filled ? color : 'none') + '" stroke="' + color +
    '" stroke-width="' + (sw || 2) + '" stroke-linecap="round" stroke-linejoin="round">' + body + '</svg>';
}

/* ---------- 3. Mini-langage de calques ----------
   F = cadre (frame)   props : name, dir 'H'|'V', gap, pad, fill, img, r, stroke, sw, sides,
                               dash, shadow, main, cross, clip, scroll, abs{l,t,r,b}, op, wrap, w, h
   T = texte           props : size, wt (graisse), color, lh, ls, align, w, max (lignes)
   I = icône           props : size, color, filled
   S = SVG libre       props : w, h (couleurs {token} remplacées au rendu)
   w / h : nombre (fixe) | 'fill' (remplir) | absent (ajusté au contenu)              */
function clean(list) { var out = []; for (var i = 0; i < list.length; i++) if (list[i]) out.push(list[i]); return out; }
function F(p, c) { var n = { t: 'frame' }; for (var k in p) n[k] = p[k]; n.c = clean(c || []); return n; }
function H(p, c) { p.dir = 'H'; return F(p, c); }
function V(p, c) { p.dir = 'V'; return F(p, c); }
function T(s, p) { var n = { t: 'text', s: s, size: 15, wt: 500, color: 'text' }; for (var k in (p || {})) n[k] = p[k]; return n; }
function I(name, p) { var n = { t: 'icon', n: name, size: 20, color: 'text' }; for (var k in (p || {})) n[k] = p[k]; return n; }
function S(svg, p) { var n = { t: 'svg', svg: svg }; for (var k in p) n[k] = p[k]; return n; }
function fx(v) { return Math.round(v * 10) / 10; }

/* ---------- 4. Données de démonstration (alignées sur la base Supabase) ---------- */
var L = {
  marsa:    { img: 'villa1',  titre: 'Villa avec piscine',           ville: 'La Marsa, Tunis',      prix: '1 250 000', type: 'Villa',       offre: 'Vente',    surface: 320, pieces: 6, photos: 8 },
  ennasr:   { img: 'salon1',  titre: 'Appartement S+3 haut standing', ville: 'Ennasr 2, Ariana',     prix: '385 000',   type: 'Appartement', offre: 'Vente',    surface: 145, pieces: 4, photos: 6 },
  sousse:   { img: 'salon2',  titre: 'S+2 meublé vue mer',           ville: 'Khezama, Sousse',      prix: '1 400',     type: 'Appartement', offre: 'Location', surface: 98,  pieces: 3, photos: 5 },
  hammamet: { img: 'villa2',  titre: 'Villa contemporaine',          ville: 'Yasmine Hammamet',     prix: '890 000',   type: 'Villa',       offre: 'Vente',    surface: 260, pieces: 5, photos: 9 },
  nabeul:   { img: 'terrain', titre: 'Terrain constructible 600 m²', ville: 'Béni Khiar, Nabeul',   prix: '96 000',    type: 'Terrain',     offre: 'Vente',    surface: 600, pieces: 0, photos: 3 },
  sfax:     { img: 'local',   titre: 'Local commercial centre-ville', ville: 'Bab Bhar, Sfax',      prix: '2 200',     type: 'Local',       offre: 'Location', surface: 85,  pieces: 1, photos: 4 },
  lac:      { img: 'salon3',  titre: 'Duplex S+4 Les Berges du Lac', ville: 'Lac 2, Tunis',         prix: '640 000',   type: 'Appartement', offre: 'Vente',    surface: 210, pieces: 5, photos: 7 }
};
function unit(l) { return l.offre === 'Location' ? 'DT/mois' : 'DT'; }
function piecesLabel(l) { return l.type === 'Terrain' ? '—' : 'S+' + (l.pieces - 1); }

/* ---------- 5. Composants ---------- */
function statusBar(light) {
  var c = light ? 'white' : 'text';
  return H({ name: 'Barre d’état', w: 'fill', h: 50, pad: [0, 26, 0, 34], main: 'between', cross: 'center' }, [
    T('9:41', { size: 16, wt: 700, color: c }),
    H({ gap: 6, cross: 'center' }, [I('signal', { size: 16, color: c }), I('wifi', { size: 17, color: c }), I('battery', { size: 24, color: c, sw: 1.6 })])
  ]);
}
function homeInd(light) {
  return H({ name: 'Indicateur', w: 'fill', h: 28, main: 'center', cross: 'center' }, [F({ w: 134, h: 5, r: 3, fill: light ? 'white' : 'text' })]);
}
function iconBtn(n, p) {
  p = p || {};
  var s = p.size || 42;
  return H({ name: 'Bouton ' + n, w: s, h: s, r: s / 2, fill: p.fill === undefined ? 'surface' : p.fill, stroke: p.stroke === undefined ? 'border' : p.stroke,
    main: 'center', cross: 'center', shadow: p.shadow, abs: p.abs }, [I(n, { size: p.icon || 20, color: p.color || 'text', filled: p.filled })]);
}
function badgeDot(count) {
  return H({ name: 'Pastille', h: 18, pad: [0, 5], r: 9, fill: 'danger', stroke: 'surface', sw: 2, main: 'center', cross: 'center', abs: { r: -6, t: -5 } },
    [T(String(count), { size: 10, wt: 800, color: 'white', lh: 12 })]);
}
function tabBar(active) {
  var items = [['home', 'Accueil'], ['heart', 'Favoris'], ['plus', 'Publier'], ['message', 'Messages'], ['user', 'Profil']];
  return V({ name: 'Barre de navigation', w: 'fill', fill: 'surface', stroke: 'border', sides: 't' }, [
    H({ w: 'fill', pad: [8, 14, 0, 14], main: 'between', cross: 'end' }, items.map(function (it) {
      var on = it[0] === active;
      if (it[0] === 'plus') {
        return V({ name: 'Onglet Publier', w: 64, gap: 4, cross: 'center' }, [
          H({ w: 50, h: 50, r: 25, fill: 'primary', main: 'center', cross: 'center', shadow: 'md' }, [I('plus', { size: 24, color: 'onPrimary', sw: 2.4 })]),
          T('Publier', { size: 11, wt: 700, color: on ? 'primary' : 'muted' })
        ]);
      }
      return V({ name: 'Onglet ' + it[1], w: 64, gap: 4, pad: [6, 0, 0, 0], cross: 'center' }, [
        F({ w: 26, h: 24, dir: 'H', main: 'center', cross: 'center' }, [I(it[0], { size: 22, color: on ? 'primary' : 'muted', filled: on && it[0] === 'heart' }), it[0] === 'message' ? badgeDot(2) : null]),
        T(it[1], { size: 11, wt: on ? 800 : 600, color: on ? 'primary' : 'muted' })
      ]);
    })),
    homeInd()
  ]);
}
function appBar(title, p) {
  p = p || {};
  return H({ name: 'En-tête', w: 'fill', pad: [6, 20, 12, 20], gap: 12, cross: 'center' }, [
    p.back ? iconBtn('arrowLeft') : null,
    V({ w: 'fill', gap: 2 }, [T(title, { size: p.big ? 26 : 20, wt: 800, w: 'fill' }), p.sub ? T(p.sub, { size: 13, color: 'muted', wt: 500 }) : null]),
  ].concat((p.actions || []).map(function (a) { return typeof a === 'string' ? iconBtn(a) : a; })));
}
function body(children, p) {
  var b = { name: 'Contenu défilant', w: 'fill', h: 'fill', scroll: true, pad: [6, 20, 24, 20], gap: 16 };
  for (var k in (p || {})) b[k] = p[k];
  return V(b, children);
}
function field(o) {
  var focus = o.focus, err = o.err, multi = o.multi;
  var border = err ? 'danger' : focus ? 'primary' : 'border';
  return V({ name: 'Champ ' + (o.label || ''), w: o.w || 'fill', gap: 8 }, [
    o.label ? H({ w: 'fill', main: 'between' }, [T(o.label, { size: 13, wt: 700, color: 'text2' }), o.counter ? T(o.counter, { size: 12, color: 'muted' }) : null]) : null,
    H({ w: 'fill', h: multi ? 104 : 52, pad: multi ? [14, 16] : [0, 16], gap: 10, r: 14, cross: multi ? 'start' : 'center',
      fill: o.disabled ? 'surface2' : 'surface', stroke: border, sw: (focus || err) ? 1.5 : 1 }, [
      o.icon ? I(o.icon, { size: 18, color: focus ? 'primary' : 'muted' }) : null,
      o.prefix ? T(o.prefix, { size: 15, wt: 700, color: 'text2' }) : null,
      T(o.value || o.ph, { size: 15, wt: o.value ? 600 : 500, color: o.value ? (o.disabled ? 'muted' : 'text') : 'muted', w: 'fill', max: multi ? 4 : 1 }),
      o.trail ? (typeof o.trail === 'string' ? I(o.trail, { size: 18, color: 'muted' }) : o.trail) : null
    ]),
    err ? H({ gap: 6, cross: 'center' }, [I('alert', { size: 14, color: 'danger' }), T(err, { size: 12, wt: 600, color: 'danger' })]) : null,
    o.hint ? T(o.hint, { size: 12, color: 'muted', w: 'fill' }) : null
  ]);
}
var BTN = {
  primary: ['primary', 'onPrimary', null], soft: ['primarySoft', 'primary', null], outline: ['surface', 'text', 'border'],
  danger: ['danger', 'white', null], dangerSoft: ['dangerSoft', 'danger', null], success: ['successSoft', 'success', null],
  ghost: [null, 'primary', null], glass: ['white/16', 'white', 'white/40'], dark: ['text', 'surface', null]
};
function btn(label, p) {
  p = p || {};
  var v = BTN[p.v || 'primary'], h = p.h || 54;
  return H({ name: 'Bouton ' + label, w: ('w' in p) ? p.w : 'fill', h: h, pad: [0, p.px || 18], r: p.r || 16, gap: 8, main: 'center', cross: 'center',
    fill: v[0], stroke: v[2], shadow: p.shadow }, [
    p.icon ? I(p.icon, { size: p.small ? 16 : 19, color: v[1] }) : null,
    T(label, { size: p.small ? 13 : 16, wt: 700, color: v[1] }),
    p.iconRight ? I(p.iconRight, { size: 19, color: v[1] }) : null
  ]);
}
function chip(label, on, p) {
  p = p || {};
  return H({ name: 'Puce ' + label, h: p.h || 38, pad: [0, 14], gap: 6, r: (p.h || 38) / 2, cross: 'center',
    fill: on ? (p.onFill || 'primary') : (p.fill || 'surface'), stroke: on ? null : 'border', shadow: p.shadow }, [
    p.icon ? I(p.icon, { size: 16, color: on ? 'onPrimary' : 'text2' }) : null,
    T(label, { size: 13, wt: 700, color: on ? 'onPrimary' : 'text2' })
  ]);
}
function seg(options, active, p) {
  p = p || {};
  return H({ name: 'Sélecteur', w: 'fill', pad: 4, r: 14, fill: 'surface2', gap: 4 }, options.map(function (o, i) {
    var on = i === active;
    return H({ w: 'fill', h: p.h || 40, r: 11, main: 'center', cross: 'center', fill: on ? 'surface' : null, shadow: on ? 'sm' : null }, [
      T(o, { size: 14, wt: on ? 800 : 600, color: on ? 'text' : 'muted' })]);
  }));
}
var STATUTS = {
  brouillon:  ['Brouillon', 'text2', 'surface2', 'pencil'],
  en_attente: ['En attente', 'warning', 'warningSoft', 'clock'],
  publiee:    ['Publiée', 'success', 'successSoft', 'checkCircle'],
  rejetee:    ['Rejetée', 'danger', 'dangerSoft', 'x'],
  vendue:     ['Vendue', 'primary', 'primarySoft', 'tag'],
  louee:      ['Louée', 'primary', 'primarySoft', 'key'],
  masquee:    ['Masquée', 'text2', 'surface2', 'eyeOff']
};
function statusBadge(st) {
  var s = STATUTS[st];
  return H({ name: 'Statut ' + s[0], h: 26, pad: [0, 10, 0, 8], gap: 5, r: 13, fill: s[2], cross: 'center' }, [
    I(s[3], { size: 13, color: s[1], sw: 2.4 }), T(s[0], { size: 12, wt: 800, color: s[1] })]);
}
function feat(icon, label) {
  return H({ gap: 5, cross: 'center' }, [I(icon, { size: 15, color: 'muted' }), T(label, { size: 13, wt: 600, color: 'text2' })]);
}
function priceT(l, size) {
  size = size || 20;
  return H({ name: 'Prix', gap: 4, cross: 'end' }, [
    T(l.prix, { size: size, wt: 800, color: 'primary', lh: Math.round(size * 1.2) }),
    T(unit(l), { size: Math.max(12, Math.round(size * 0.6)), wt: 700, color: 'primary', lh: Math.round(size * 1.2) - 2 })]);
}
function photoPill(text, p) {
  p = p || {};
  return H({ h: 26, pad: [0, 10], r: 13, gap: 5, cross: 'center', fill: p.fill || 'surface' }, [
    p.icon ? I(p.icon, { size: 13, color: p.color || 'primary' }) : null,
    T(text, { size: 11, wt: 800, color: p.color || 'primary', ls: 0.6 })]);
}
function heartBtn(on, size) {
  size = size || 38;
  return H({ name: 'Favori', w: size, h: size, r: size / 2, fill: 'surface', main: 'center', cross: 'center', shadow: 'sm' }, [
    I('heart', { size: 18, color: on ? 'danger' : 'text', filled: on })]);
}
function listingCard(l, p) {
  p = p || {};
  return V({ name: 'Carte annonce · ' + l.titre, w: p.w || 'fill', r: 22, fill: 'surface', stroke: 'border', clip: true, shadow: 'sm' }, [
    V({ name: 'Photo', w: 'fill', h: p.ih || 188, img: l.img, pad: 12, main: 'between' }, [
      H({ w: 'fill', main: 'between', cross: 'start' }, [photoPill(l.offre.toUpperCase()), heartBtn(p.fav)]),
      H({ w: 'fill', main: 'between', cross: 'end' }, [
        p.verified ? photoPill('VÉRIFIÉE', { fill: 'success', color: 'white', icon: 'shield' }) : F({ w: 1, h: 1 }),
        photoPill('1/' + l.photos, { fill: 'scrim', color: 'white', icon: 'image' })])
    ]),
    V({ w: 'fill', pad: [14, 16, 16, 16], gap: 6 }, [
      H({ w: 'fill', main: 'between', cross: 'center' }, [T(l.type.toUpperCase() + ' · ' + l.offre.toUpperCase(), { size: 11, wt: 800, color: 'accent', ls: 0.8 }), T(p.time || 'il y a 2 h', { size: 12, color: 'muted' })]),
      T(l.titre, { size: 17, wt: 800, w: 'fill', max: 1 }),
      H({ gap: 4, cross: 'center' }, [I('pin', { size: 14, color: 'muted' }), T(l.ville, { size: 13, color: 'muted', wt: 500 })]),
      F({ w: 'fill', h: 1, fill: 'border' }),
      H({ w: 'fill', main: 'between', cross: 'center', pad: [4, 0, 0, 0] }, [
        priceT(l, 19),
        H({ gap: 12, cross: 'center' }, [feat('maximize', l.surface + ' m²'), l.type === 'Terrain' ? null : feat('bed', piecesLabel(l))])
      ])
    ])
  ]);
}
function listingRow(l, p) {
  p = p || {};
  return H({ name: 'Ligne annonce · ' + l.titre, w: p.w || 'fill', pad: 10, gap: 12, r: 20, fill: 'surface', stroke: p.stroke === undefined ? 'border' : p.stroke, cross: 'center', shadow: p.shadow }, [
    F({ name: 'Photo', w: p.size || 92, h: p.size || 92, r: 14, img: l.img, dir: 'H', pad: 6, main: 'end', cross: 'start' }, [p.photoBadge || null]),
    V({ w: 'fill', gap: 5 }, [
      H({ w: 'fill', main: 'between', cross: 'center' }, [T(l.type.toUpperCase() + ' · ' + l.offre.toUpperCase(), { size: 10, wt: 800, color: 'accent', ls: 0.7 }), p.topRight || null]),
      T(l.titre, { size: 15, wt: 800, w: 'fill', max: 1 }),
      H({ gap: 4, cross: 'center' }, [I('pin', { size: 13, color: 'muted' }), T(l.ville, { size: 12, color: 'muted', wt: 500 })]),
      H({ w: 'fill', main: 'between', cross: 'center' }, [priceT(l, 16), p.right || null]),
      p.extra || null
    ])
  ]);
}
function avatar(p) {
  var s = p.size || 48;
  if (p.img) return F({ name: 'Avatar', w: s, h: s, r: s / 2, img: p.img, stroke: p.ring ? 'surface' : null, sw: p.ring ? 3 : 1 }, [
    p.online ? F({ w: 14, h: 14, r: 7, fill: 'success', stroke: 'surface', sw: 2, abs: { r: 0, b: 0 } }) : null]);
  return H({ name: 'Avatar', w: s, h: s, r: s / 2, fill: p.fill || 'accentSoft', main: 'center', cross: 'center' }, [
    T(p.initials, { size: Math.round(s * 0.36), wt: 800, color: p.color || 'accent' })]);
}
function sectionTitle(t, right) {
  return H({ w: 'fill', main: 'between', cross: 'center' }, [T(t, { size: 17, wt: 800 }), right || null]);
}
function linkT(t, icon) {
  return H({ gap: 4, cross: 'center' }, [T(t, { size: 13, wt: 700, color: 'primary' }), icon ? I(icon, { size: 15, color: 'primary' }) : null]);
}
function checkbox(on) {
  return H({ w: 22, h: 22, r: 7, fill: on ? 'primary' : 'surface', stroke: on ? null : 'border', sw: 1.5, main: 'center', cross: 'center' }, [on ? I('check', { size: 14, color: 'onPrimary', sw: 3 }) : null]);
}
function toggle(on) {
  return H({ name: 'Interrupteur', w: 50, h: 30, r: 15, fill: on ? 'primary' : 'border', pad: 3, main: on ? 'end' : 'start', cross: 'center' }, [
    F({ w: 24, h: 24, r: 12, fill: 'white', shadow: 'sm' })]);
}
function radio(label, on, color) {
  color = color || 'primary';
  return H({ name: 'Choix ' + label, w: 'fill', h: 52, pad: [0, 16], gap: 12, r: 14, cross: 'center',
    fill: on ? color + 'Soft' : 'surface', stroke: on ? color : 'border', sw: on ? 1.5 : 1 }, [
    H({ w: 20, h: 20, r: 10, stroke: on ? color : 'muted', sw: 2, main: 'center', cross: 'center' }, [on ? F({ w: 10, h: 10, r: 5, fill: color }) : null]),
    T(label, { size: 14, wt: on ? 700 : 600, color: 'text', w: 'fill' })]);
}
function banner(kind, text, icon) {
  return H({ name: 'Bandeau', w: 'fill', pad: [12, 14], gap: 10, r: 14, fill: kind + 'Soft', cross: 'start' }, [
    I(icon || 'info', { size: 18, color: kind }), T(text, { size: 13, wt: 600, color: kind === 'primary' ? 'primaryDark' : kind, w: 'fill', lh: 19 })]);
}
function bottomBar(children) {
  return V({ name: 'Barre d’action', w: 'fill', fill: 'surface', stroke: 'border', sides: 't' }, [
    H({ w: 'fill', pad: [12, 20, 4, 20], gap: 12, cross: 'center' }, children), homeInd()]);
}
function divider() { return F({ name: 'Séparateur', w: 'fill', h: 1, fill: 'border' }); }
function spacer() { return F({ name: 'Espace', w: 'fill', h: 'fill' }); }
function sheet(children) {
  return V({ name: 'Feuille du bas', w: 390, fill: 'surface', r: [28, 28, 0, 0], pad: [10, 20, 0, 20], gap: 18, abs: { l: 0, b: 0 }, shadow: 'up' }, [
    H({ w: 'fill', main: 'center' }, [F({ w: 40, h: 5, r: 3, fill: 'border' })])].concat(children).concat([homeInd()]));
}
function scrim() { return F({ name: 'Voile', w: 390, h: 844, fill: 'scrim', abs: { l: 0, t: 0 } }); }

/* Carte stylisée (SVG) */
function mapSVG(w, h, seed) {
  var s = '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">';
  s += '<rect width="' + w + '" height="' + h + '" fill="{mapLand}"/>';
  var sd = seed || 7;
  function rnd() { sd = (sd * 9301 + 49297) % 233280; return sd / 233280; }
  for (var y = -20; y < h; y += 56) for (var x = -30; x < w; x += 70) {
    s += '<rect x="' + fx(x + rnd() * 8) + '" y="' + fx(y + rnd() * 8) + '" width="' + fx(48 + rnd() * 12) + '" height="' + fx(36 + rnd() * 10) + '" rx="7" fill="{mapBlock}"/>';
  }
  s += '<rect x="' + fx(w * 0.05) + '" y="' + fx(h * 0.5) + '" width="' + fx(w * 0.3) + '" height="' + fx(h * 0.15) + '" rx="18" fill="{mapPark}"/>';
  s += '<circle cx="' + fx(w * 0.72) + '" cy="' + fx(h * 0.8) + '" r="' + fx(Math.min(w, h) * 0.13) + '" fill="{mapPark}"/>';
  s += '<path d="M' + fx(w * 0.55) + ' 0 C' + fx(w * 0.62) + ' ' + fx(h * 0.16) + ' ' + fx(w * 0.8) + ' ' + fx(h * 0.26) + ' ' + w + ' ' + fx(h * 0.3) + ' L' + w + ' 0 Z" fill="{mapWater}"/>';
  function road(x1, y1, x2, y2, wd, c) {
    s += '<path d="M' + fx(x1) + ' ' + fx(y1) + ' L' + fx(x2) + ' ' + fx(y2) + '" stroke="' + (c || '{mapRoad}') + '" stroke-width="' + wd + '" stroke-linecap="round" fill="none"/>';
  }
  road(-10, h * 0.22, w + 10, h * 0.42, 9); road(w * 0.3, -10, w * 0.42, h + 10, 11); road(-10, h * 0.72, w + 10, h * 0.62, 8);
  road(w * 0.82, h * 0.32, w * 0.62, h + 10, 7); road(-10, h * 0.96, w * 0.56, -10, 7, '{mapMain}');
  return s + '</svg>';
}
function mapBg(w, h, seed) { return S(mapSVG(w, h, seed), { name: 'Fond de carte', w: w, h: h, abs: { l: 0, t: 0 } }); }
function pricePin(label, x, y, on, accent) {
  return H({ name: 'Repère ' + label, h: 30, pad: [0, 11], r: 15, cross: 'center', gap: 4, abs: { l: x, t: y }, shadow: 'md',
    fill: on ? 'primary' : accent ? 'accent' : 'surface', stroke: on || accent ? 'white' : 'border', sw: 2 }, [
    T(label, { size: 12, wt: 800, color: on ? 'onPrimary' : accent ? 'white' : 'text' })]);
}
function bigPin(x, y) {
  return S('<svg xmlns="http://www.w3.org/2000/svg" width="46" height="56" viewBox="0 0 24 29"><ellipse cx="12" cy="27" rx="5" ry="1.6" fill="#0B1220" fill-opacity="0.25"/><path d="M12 24s9-7 9-14a9 9 0 0 0-18 0c0 7 9 14 9 14z" fill="{primary}" stroke="#FFFFFF" stroke-width="1.5"/><circle cx="12" cy="10" r="3.6" fill="#FFFFFF"/></svg>',
    { name: 'Marqueur déplaçable', w: 46, h: 56, abs: { l: x, t: y } });
}
function spinner() {
  return S('<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="{border}" stroke-width="3"/><path d="M21 12a9 9 0 0 0-9-9" stroke="{primary}" stroke-width="3" stroke-linecap="round"/></svg>', { name: 'Chargement', w: 22, h: 22 });
}
function progressRing(pct) {
  var c = 2 * Math.PI * 16, d = fx(c * pct / 100);
  return S('<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 40 40" fill="none"><circle cx="20" cy="20" r="16" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="4"/><circle cx="20" cy="20" r="16" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" stroke-dasharray="' + d + ' ' + fx(c) + '" transform="rotate(-90 20 20)"/></svg>', { name: 'Progression', w: 44, h: 44 });
}
function logo(light, size) {
  size = size || 40;
  return H({ name: 'Logo DarImmo', gap: 10, cross: 'center' }, [
    H({ w: size, h: size, r: size * 0.3, fill: light ? 'white' : 'primary', main: 'center', cross: 'center' }, [
      S('<svg xmlns="http://www.w3.org/2000/svg" width="' + Math.round(size * 0.6) + '" height="' + Math.round(size * 0.6) + '" viewBox="0 0 24 24" fill="none"><path d="M4 21V10.5a8 8 0 0 1 16 0V21" stroke="' + (light ? '{primary}' : '{onPrimary}') + '" stroke-width="2.4" stroke-linecap="round"/><path d="M9 21v-6a3 3 0 0 1 6 0v6" stroke="' + (light ? '{accent}' : '{onPrimary}') + '" stroke-width="2.4" stroke-linecap="round"/></svg>',
        { w: Math.round(size * 0.6), h: Math.round(size * 0.6) })]),
    H({ cross: 'center' }, [T('Dar', { size: Math.round(size * 0.55), wt: 800, color: light ? 'white' : 'text' }), T('Immo', { size: Math.round(size * 0.55), wt: 800, color: light ? 'white' : 'primary' })])
  ]);
}
function screen(id, title, stories, children, p) {
  p = p || {};
  return F({ name: id + ' · ' + title, w: 390, h: 844, dir: 'V', fill: p.fill || 'bg', clip: true, meta: { id: id, title: title, stories: stories, note: p.note || '' } }, children);
}

/* ============================================================
   6. ÉCRANS
   ============================================================ */

/* ---------- Membre A ---------- */
function A1() {
  return screen('A1', 'Bienvenue', '—', [
    F({ name: 'Photo plein écran', w: 390, h: 844, img: 'villa3', abs: { l: 0, t: 0 } }),
    F({ name: 'Dégradé', w: 390, h: 844, fill: { g: 'v', s: ['#0B122033', '#0B122000', '#0B1220E6'] }, abs: { l: 0, t: 0 } }),
    statusBar(true),
    H({ w: 'fill', pad: [8, 24] }, [logo(true, 40)]),
    spacer(),
    V({ name: 'Accroche', w: 'fill', pad: [0, 24, 12, 24], gap: 14 }, [
      photoPill('2 400 BIENS VÉRIFIÉS', { fill: 'white/16', color: 'white', icon: 'shield' }),
      T('Trouvez le bien qui vous ressemble, partout en Tunisie.', { size: 32, wt: 800, color: 'white', w: 'fill', lh: 38 }),
      T('Achetez, louez ou publiez votre bien en quelques minutes. Échangez directement avec les propriétaires.', { size: 15, color: 'white', op: 0.85, w: 'fill', lh: 22 }),
      H({ gap: 6, pad: [6, 0, 10, 0] }, [F({ w: 22, h: 6, r: 3, fill: 'white' }), F({ w: 6, h: 6, r: 3, fill: 'white/50' }), F({ w: 6, h: 6, r: 3, fill: 'white/50' })]),
      btn('Créer un compte', { v: 'primary' }),
      btn('J’ai déjà un compte', { v: 'glass' }),
      H({ w: 'fill', main: 'center', pad: [4, 0, 0, 0] }, [T('Continuer sans compte', { size: 14, wt: 700, color: 'white' })])
    ]),
    homeInd(true)
  ], { fill: 'text' });
}
function A2() {
  return screen('A2', 'Connexion', '2.2 · 2.5 (bonus)', [
    statusBar(),
    H({ w: 'fill', pad: [6, 20] }, [iconBtn('arrowLeft')]),
    body([
      logo(false, 44),
      V({ w: 'fill', gap: 8, pad: [6, 0, 4, 0] }, [
        T('Content de vous revoir', { size: 28, wt: 800, w: 'fill' }),
        T('Connectez-vous pour retrouver vos favoris, vos annonces et vos messages.', { size: 15, color: 'text2', w: 'fill', lh: 22 })]),
      banner('danger', 'Email ou mot de passe incorrect. Vérifiez vos informations et réessayez.', 'alert'),
      field({ label: 'Adresse email', value: 'acheteur@darimmo.test', icon: 'mail' }),
      field({ label: 'Mot de passe', value: '••••••••', icon: 'lock', trail: 'eye', focus: true }),
      H({ w: 'fill', main: 'between', cross: 'center' }, [
        H({ gap: 8, cross: 'center' }, [checkbox(true), T('Rester connecté', { size: 13, wt: 600, color: 'text2' })]),
        linkT('Mot de passe oublié ?')]),
      btn('Se connecter', { shadow: 'md' }),
      H({ w: 'fill', gap: 12, cross: 'center' }, [divider(), T('ou', { size: 13, color: 'muted' }), divider()]),
      btn('Continuer avec Google', { v: 'outline', icon: 'user' }),
      H({ w: 'fill', main: 'center', gap: 4 }, [T('Pas encore de compte ?', { size: 14, color: 'text2' }), T('Créer un compte', { size: 14, wt: 800, color: 'primary' })])
    ], { gap: 18 })
  ]);
}
function A3() {
  return screen('A3', 'Inscription', '2.1', [
    statusBar(),
    appBar('Créer un compte', { back: true, sub: 'Gratuit · moins d’une minute' }),
    body([
      field({ label: 'Nom complet', value: 'Yasmine Trabelsi', icon: 'user' }),
      field({ label: 'Adresse email', value: 'yasmine.t@gmail.com', icon: 'mail', err: 'Cet email est déjà utilisé. Connectez-vous ou choisissez une autre adresse.' }),
      field({ label: 'Mot de passe', value: '••••••••••', icon: 'lock', trail: 'eyeOff', focus: true }),
      V({ w: 'fill', gap: 8 }, [
        H({ w: 'fill', gap: 6 }, [F({ w: 'fill', h: 5, r: 3, fill: 'success' }), F({ w: 'fill', h: 5, r: 3, fill: 'success' }), F({ w: 'fill', h: 5, r: 3, fill: 'success' }), F({ w: 'fill', h: 5, r: 3, fill: 'border' })]),
        H({ w: 'fill', main: 'between' }, [T('Mot de passe solide', { size: 12, wt: 700, color: 'success' }), T('10 caractères · 8 minimum', { size: 12, color: 'muted' })])]),
      field({ label: 'Téléphone (facultatif)', value: '22 345 678', prefix: '+216', icon: 'phone' }),
      H({ w: 'fill', gap: 10, cross: 'start' }, [checkbox(true), T('J’accepte les conditions d’utilisation et la politique de confidentialité de DarImmo.', { size: 13, color: 'text2', w: 'fill', lh: 19 })]),
      btn('Créer mon compte', { shadow: 'md' }),
      H({ w: 'fill', main: 'center', gap: 4 }, [T('Déjà inscrit ?', { size: 14, color: 'text2' }), T('Se connecter', { size: 14, wt: 800, color: 'primary' })])
    ], { gap: 16 })
  ]);
}
function A4() {
  return screen('A4', 'Mot de passe oublié', '2.4', [
    statusBar(),
    H({ w: 'fill', pad: [6, 20] }, [iconBtn('arrowLeft')]),
    body([
      H({ w: 'fill', main: 'center', pad: [24, 0, 8, 0] }, [
        H({ w: 112, h: 112, r: 56, fill: 'primarySoft', main: 'center', cross: 'center' }, [
          H({ w: 72, h: 72, r: 36, fill: 'primary', main: 'center', cross: 'center', shadow: 'md' }, [I('mail', { size: 32, color: 'onPrimary' })])])]),
      T('Vérifiez votre boîte mail', { size: 26, wt: 800, w: 'fill', align: 'center' }),
      T('Nous avons envoyé un lien de réinitialisation à y••••••@gmail.com. Le lien expire dans 60 minutes.', { size: 15, color: 'text2', w: 'fill', align: 'center', lh: 22 }),
      V({ w: 'fill', pad: 16, gap: 14, r: 18, fill: 'surface', stroke: 'border' }, [
        H({ w: 'fill', gap: 12, cross: 'center' }, [H({ w: 28, h: 28, r: 14, fill: 'successSoft', main: 'center', cross: 'center' }, [I('check', { size: 15, color: 'success', sw: 3 })]), T('Lien envoyé', { size: 14, wt: 700, w: 'fill' }), T('il y a 1 min', { size: 12, color: 'muted' })]),
        H({ w: 'fill', gap: 12, cross: 'center' }, [H({ w: 28, h: 28, r: 14, fill: 'primarySoft', main: 'center', cross: 'center' }, [T('2', { size: 13, wt: 800, color: 'primary' })]), T('Ouvrez le lien depuis ce téléphone', { size: 14, wt: 600, color: 'text2', w: 'fill' })]),
        H({ w: 'fill', gap: 12, cross: 'center' }, [H({ w: 28, h: 28, r: 14, fill: 'surface2', main: 'center', cross: 'center' }, [T('3', { size: 13, wt: 800, color: 'muted' })]), T('Choisissez un nouveau mot de passe', { size: 14, wt: 600, color: 'text2', w: 'fill' })])
      ]),
      spacer(),
      btn('Ouvrir ma messagerie', { icon: 'mail' }),
      btn('Renvoyer le lien dans 0:45', { v: 'ghost' }),
      H({ w: 'fill', main: 'center' }, [T('Modifier l’adresse email', { size: 13, wt: 700, color: 'text2' })])
    ], { gap: 16 })
  ]);
}
function menuRow(icon, label, p) {
  p = p || {};
  return H({ name: 'Menu ' + label, w: 'fill', h: 60, pad: [0, 16], gap: 14, cross: 'center', stroke: p.last ? null : 'border', sides: 'b' }, [
    H({ w: 38, h: 38, r: 12, fill: p.soft || 'primarySoft', main: 'center', cross: 'center' }, [I(icon, { size: 19, color: p.color || 'primary' })]),
    T(label, { size: 15, wt: 700, w: 'fill', color: p.danger ? 'danger' : 'text' }),
    p.trail || I('chevronRight', { size: 18, color: 'muted' })]);
}
function A5() {
  return screen('A5', 'Profil', '2.3 · 2.6 (bonus)', [
    statusBar(),
    appBar('Mon profil', { actions: ['pencil'] }),
    body([
      V({ name: 'Carte profil', w: 'fill', pad: 18, gap: 16, r: 24, fill: 'primary', clip: true }, [
        H({ w: 'fill', gap: 14, cross: 'center' }, [
          avatar({ img: 'avatarF', size: 68, ring: true }),
          V({ w: 'fill', gap: 3 }, [
            T('Yasmine Trabelsi', { size: 19, wt: 800, color: 'onPrimary' }),
            T('yasmine.t@gmail.com', { size: 13, color: 'onPrimary', op: 0.8 }),
            T('+216 22 345 678', { size: 13, color: 'onPrimary', op: 0.8 })])]),
        H({ w: 'fill', pad: [12, 0, 0, 0], stroke: 'white/25', sides: 't' }, [
          V({ w: 'fill', gap: 2, cross: 'center' }, [T('3', { size: 20, wt: 800, color: 'onPrimary' }), T('Annonces', { size: 12, color: 'onPrimary', op: 0.8 })]),
          V({ w: 'fill', gap: 2, cross: 'center' }, [T('12', { size: 20, wt: 800, color: 'onPrimary' }), T('Favoris', { size: 12, color: 'onPrimary', op: 0.8 })]),
          V({ w: 'fill', gap: 2, cross: 'center' }, [T('5', { size: 20, wt: 800, color: 'onPrimary' }), T('Conversations', { size: 12, color: 'onPrimary', op: 0.8 })])])
      ]),
      V({ name: 'Menu', w: 'fill', r: 20, fill: 'surface', stroke: 'border', clip: true }, [
        menuRow('list', 'Mes annonces', { trail: H({ gap: 8, cross: 'center' }, [statusBadge('en_attente'), I('chevronRight', { size: 18, color: 'muted' })]) }),
        menuRow('heart', 'Mes favoris'),
        menuRow('bell', 'Notifications'),
        menuRow('moon', 'Mode sombre', { trail: toggle(false), last: true })]),
      V({ name: 'Menu admin', w: 'fill', r: 20, fill: 'surface', stroke: 'border', clip: true }, [
        menuRow('shield', 'Espace administration', { soft: 'accentSoft', color: 'accent', trail: H({ gap: 8, cross: 'center' }, [photoPill('6 À TRAITER', { fill: 'accentSoft', color: 'accent' }), I('chevronRight', { size: 18, color: 'muted' })]) }),
        menuRow('logout', 'Se déconnecter', { soft: 'dangerSoft', color: 'danger', danger: true, last: true, trail: F({ w: 1, h: 1 }) })]),
      H({ w: 'fill', main: 'center' }, [T('Membre depuis mars 2026 · DarImmo v1.0', { size: 12, color: 'muted' })])
    ], { gap: 16 }),
    tabBar('user')
  ]);
}
function A6() {
  return screen('A6', 'Modifier le profil', '2.3', [
    statusBar(),
    appBar('Modifier le profil', { back: true }),
    body([
      V({ w: 'fill', gap: 10, cross: 'center', pad: [8, 0, 8, 0] }, [
        F({ w: 112, h: 112 }, [
          avatar({ img: 'avatarF', size: 112 }),
          H({ w: 38, h: 38, r: 19, fill: 'primary', stroke: 'bg', sw: 3, main: 'center', cross: 'center', abs: { r: 0, b: 0 } }, [I('camera', { size: 18, color: 'onPrimary' })])]),
        T('Changer la photo', { size: 14, wt: 800, color: 'primary' }),
        T('JPG ou PNG · depuis votre galerie', { size: 12, color: 'muted' })]),
      field({ label: 'Nom complet', value: 'Yasmine Trabelsi', icon: 'user' }),
      field({ label: 'Téléphone', value: '22 345 678', prefix: '+216', icon: 'phone', focus: true }),
      field({ label: 'Adresse email', value: 'yasmine.t@gmail.com', icon: 'mail', trail: 'lock', disabled: true, hint: 'L’email sert à vous connecter. Il ne peut pas être modifié ici.' })
    ], { gap: 18 }),
    H({ name: 'Message de confirmation', w: 350, h: 52, pad: [0, 16], gap: 10, r: 14, fill: 'text', cross: 'center', abs: { l: 20, b: 112 }, shadow: 'lg' }, [
      I('checkCircle', { size: 19, color: 'success' }), T('Profil mis à jour', { size: 14, wt: 700, color: 'surface', w: 'fill' }), T('OK', { size: 14, wt: 800, color: 'primarySoft' })]),
    bottomBar([btn('Enregistrer les modifications')])
  ]);
}
function modCard(l, who, when, p) {
  p = p || {};
  return V({ name: 'Annonce à modérer', w: 'fill', pad: 12, gap: 12, r: 20, fill: 'surface', stroke: p.focus ? 'primary' : 'border', sw: p.focus ? 1.5 : 1 }, [
    H({ w: 'fill', gap: 12, cross: 'center' }, [
      F({ w: 72, h: 72, r: 14, img: l.img }),
      V({ w: 'fill', gap: 4 }, [
        T(l.titre, { size: 15, wt: 800, w: 'fill', max: 1 }),
        T(l.ville + ' · ' + l.prix + ' ' + unit(l), { size: 12, wt: 600, color: 'text2', w: 'fill', max: 1 }),
        H({ gap: 6, cross: 'center' }, [avatar({ initials: who.split(' ').map(function (x) { return x[0]; }).join(''), size: 20 }), T(who + ' · ' + when, { size: 12, color: 'muted' })])])]),
    p.motif ? V({ w: 'fill', gap: 10 }, [
      field({ label: 'Motif du rejet (visible par l’annonceur)', value: 'Les photos ne montrent pas l’intérieur. Ajoutez au moins 3 photos des pièces.', multi: true, focus: true }),
      H({ gap: 6, wrap: true, w: 'fill' }, [chip('Photos insuffisantes', true, { h: 32 }), chip('Prix incohérent', false, { h: 32 }), chip('Doublon', false, { h: 32 })])]) : null,
    H({ w: 'fill', gap: 10 }, p.motif ? [btn('Annuler', { v: 'outline', h: 44, small: true }), btn('Confirmer le rejet', { v: 'danger', h: 44, small: true, icon: 'x' })]
      : [btn('Rejeter', { v: 'dangerSoft', h: 44, small: true, icon: 'x' }), btn('Valider', { v: 'success', h: 44, small: true, icon: 'check' })])
  ]);
}
function A7() {
  return screen('A7', 'Admin · Modération', 'Admin (Epic A)', [
    statusBar(),
    appBar('Modération', { back: true, sub: 'Espace administrateur', actions: [iconBtn('shield', { fill: 'accentSoft', stroke: null, color: 'accent' })] }),
    H({ w: 'fill', pad: [0, 20, 8, 20] }, [seg(['En attente · 4', 'Signalements · 2', 'Comptes'], 0)]),
    body([
      H({ w: 'fill', main: 'between', cross: 'center' }, [T('Les plus anciennes d’abord', { size: 13, wt: 600, color: 'muted' }), linkT('Trier', 'chevronDown')]),
      modCard(L.ennasr, 'Karim Jaziri', 'il y a 3 h'),
      modCard(L.hammamet, 'Ines Gharbi', 'il y a 5 h', { motif: true, focus: true }),
      modCard(L.sousse, 'Sami Ben Salah', 'hier')
    ], { gap: 14 }),
    tabBar('user')
  ]);
}
function A8() {
  function report(txt, who, when) {
    return H({ w: 'fill', gap: 10, cross: 'start' }, [I('flag', { size: 16, color: 'danger' }), V({ w: 'fill', gap: 2 }, [
      T(txt, { size: 13, wt: 600, w: 'fill', lh: 18 }), T(who + ' · ' + when, { size: 12, color: 'muted' })])]);
  }
  return screen('A8', 'Admin · Signalements', '3.4 · Admin', [
    statusBar(),
    appBar('Modération', { back: true, sub: 'Espace administrateur', actions: [iconBtn('shield', { fill: 'accentSoft', stroke: null, color: 'accent' })] }),
    H({ w: 'fill', pad: [0, 20, 8, 20] }, [seg(['En attente · 4', 'Signalements · 2', 'Comptes'], 1)]),
    body([
      V({ name: 'Signalement', w: 'fill', pad: 14, gap: 14, r: 20, fill: 'surface', stroke: 'danger', sw: 1.5 }, [
        listingRow(L.sfax, { size: 64, stroke: null, w: 'fill', topRight: photoPill('3 SIGNALEMENTS', { fill: 'dangerSoft', color: 'danger' }) }),
        V({ w: 'fill', gap: 12, pad: 12, r: 14, fill: 'surface2' }, [
          report('« Le propriétaire demande un acompte avant toute visite. »', 'Annonce frauduleuse · Karim J.', 'il y a 2 h'),
          report('« Surface réelle d’environ 50 m², pas 85. »', 'Informations trompeuses · Yosr M.', 'hier'),
          report('« Même annonce publiée deux fois. »', 'Doublon · Anonyme', 'lun.')]),
        H({ w: 'fill', gap: 8 }, [btn('Classer', { v: 'outline', h: 44, small: true }), btn('Masquer l’annonce', { v: 'danger', h: 44, small: true, icon: 'eyeOff' })]),
        H({ w: 'fill', main: 'center', gap: 6, cross: 'center' }, [I('ban', { size: 15, color: 'danger' }), T('Bloquer l’annonceur', { size: 13, wt: 800, color: 'danger' })])
      ]),
      V({ name: 'Signalement traité', w: 'fill', pad: 14, gap: 10, r: 20, fill: 'surface', stroke: 'border' }, [
        listingRow(L.nabeul, { size: 64, stroke: null, topRight: photoPill('TRAITÉ', { fill: 'successSoft', color: 'success' }) }),
        banner('success', 'Annonce masquée le 04/11 · motif envoyé à l’annonceur.', 'checkCircle')])
    ], { gap: 14 }),
    tabBar('user')
  ]);
}

/* ---------- Membre B ---------- */
function homeHeader() {
  return V({ name: 'En-tête accueil', w: 'fill', pad: [4, 20, 12, 20], gap: 14 }, [
    H({ w: 'fill', gap: 12, cross: 'center' }, [
      avatar({ img: 'avatarF', size: 44 }),
      V({ w: 'fill', gap: 1 }, [T('Bonjour Yasmine', { size: 13, wt: 600, color: 'muted' }), T('Trouvez votre chez-vous', { size: 19, wt: 800, w: 'fill', max: 1 })]),
      F({ w: 42, h: 42 }, [iconBtn('bell'), badgeDot(3)])]),
    H({ w: 'fill', gap: 10 }, [
      H({ w: 'fill', h: 52, pad: [0, 16], gap: 10, r: 16, fill: 'surface', stroke: 'border', cross: 'center' }, [
        I('search', { size: 19, color: 'muted' }), T('Ville, quartier, type de bien…', { size: 15, color: 'muted', w: 'fill' })]),
      H({ w: 52, h: 52, r: 16, fill: 'primary', main: 'center', cross: 'center', shadow: 'md' }, [I('sliders', { size: 20, color: 'onPrimary' })])])
  ]);
}
function chipsRow(list, active) {
  return F({ name: 'Puces', w: 'fill', h: 38, clip: true }, [H({ gap: 8, abs: { l: 20, t: 0 } }, list.map(function (c, i) { return chip(c, i === active); }))]);
}
function B1() {
  return screen('B1', 'Accueil · Liste des annonces', '3.1 · 3.2', [
    statusBar(),
    homeHeader(),
    chipsRow(['Tout', 'Vente', 'Location', 'Appartement', 'Villa', 'Terrain'], 0),
    body([
      sectionTitle('Annonces récentes', linkT('Voir la carte', 'map')),
      listingCard(L.marsa, { fav: true, verified: true }),
      listingCard(L.ennasr, { time: 'il y a 5 h' }),
      H({ w: 'fill', main: 'center', gap: 10, cross: 'center', pad: [4, 0, 0, 0] }, [spinner(), T('Chargement des annonces suivantes…', { size: 13, wt: 600, color: 'muted' })])
    ], { pad: [16, 20, 20, 20] }),
    tabBar('home')
  ]);
}
function rangeSlider() {
  return F({ name: 'Curseur de prix', w: 350, h: 28 }, [
    F({ w: 350, h: 4, r: 2, fill: 'border', abs: { l: 0, t: 12 } }),
    F({ w: 150, h: 4, r: 2, fill: 'primary', abs: { l: 80, t: 12 } }),
    F({ w: 26, h: 26, r: 13, fill: 'white', stroke: 'primary', sw: 3, shadow: 'sm', abs: { l: 67, t: 1 } }),
    F({ w: 26, h: 26, r: 13, fill: 'white', stroke: 'primary', sw: 3, shadow: 'sm', abs: { l: 217, t: 1 } })]);
}
function B2() {
  return screen('B2', 'Filtres', '3.2', [
    statusBar(), homeHeader(), chipsRow(['Tout', 'Vente', 'Location', 'Appartement'], 0),
    scrim(),
    sheet([
      H({ w: 'fill', main: 'between', cross: 'center' }, [T('Filtres', { size: 22, wt: 800 }), T('Réinitialiser', { size: 14, wt: 800, color: 'primary' })]),
      seg(['Acheter', 'Louer'], 0),
      V({ w: 'fill', gap: 10 }, [T('Type de bien', { size: 14, wt: 800 }), H({ w: 'fill', gap: 8, wrap: true }, [
        chip('Appartement', true, { icon: 'building' }), chip('Villa', true, { icon: 'home' }), chip('Terrain', false, { icon: 'mountain' }), chip('Local', false, { icon: 'store' })])]),
      V({ w: 'fill', gap: 10 }, [
        H({ w: 'fill', main: 'between' }, [T('Prix (DT)', { size: 14, wt: 800 }), T('150 000 – 450 000', { size: 13, wt: 700, color: 'primary' })]),
        rangeSlider(),
        H({ w: 'fill', gap: 10 }, [field({ value: '150 000', ph: 'Min', w: 'fill' }), field({ value: '450 000', ph: 'Max', w: 'fill' })])]),
      field({ label: 'Ville', value: 'Tunis, Ariana', icon: 'pin', trail: 'chevronDown' }),
      V({ w: 'fill', gap: 10 }, [T('Nombre de pièces minimum', { size: 14, wt: 800 }), H({ w: 'fill', gap: 8 }, [
        chip('Tous', false), chip('S+1', false), chip('S+2', false), chip('S+3', true), chip('S+4 +', false)])]),
      btn('Afficher 128 annonces', { shadow: 'md' })
    ])
  ]);
}
function B3() {
  return screen('B3', 'Carte · Autour de moi', '4.1 · 4.2', [
    mapBg(390, 844, 11),
    F({ name: 'Rayon 5 km', w: 230, h: 230, r: 115, fill: 'primary/10', stroke: 'primary/45', sw: 2, abs: { l: 80, t: 300 } }),
    F({ name: 'Halo position', w: 54, h: 54, r: 27, fill: '#2F80ED/22', abs: { l: 168, t: 388 } }),
    F({ name: 'Ma position', w: 20, h: 20, r: 10, fill: '#2F80ED', stroke: 'white', sw: 3, shadow: 'md', abs: { l: 185, t: 405 } }),
    pricePin('1,25 M DT', 104, 300, true), pricePin('385 k', 238, 336), pricePin('890 k', 52, 452), pricePin('1 400 DT/m', 214, 470, false, true),
    pricePin('640 k', 128, 536), pricePin('96 k', 262, 238),
    statusBar(),
    V({ name: 'Recherche flottante', w: 'fill', pad: [4, 16, 0, 16], gap: 10 }, [
      H({ w: 'fill', gap: 10 }, [
        H({ w: 'fill', h: 52, pad: [0, 16], gap: 10, r: 16, fill: 'surface', cross: 'center', shadow: 'md' }, [
          I('search', { size: 19, color: 'primary' }), V({ w: 'fill', gap: 0 }, [T('La Marsa, Tunis', { size: 14, wt: 800 }), T('Rayon 5 km · 24 biens', { size: 12, color: 'muted' })])]),
        H({ w: 52, h: 52, r: 16, fill: 'primary', main: 'center', cross: 'center', shadow: 'md' }, [I('sliders', { size: 20, color: 'onPrimary' })])]),
      H({ gap: 8 }, [chip('Autour de moi', true, { icon: 'locate', shadow: 'sm' }), chip('Vente', false, { shadow: 'sm' }), chip('Villa', false, { shadow: 'sm' })])]),
    spacer(),
    V({ w: 'fill', pad: [0, 16, 12, 16], gap: 12, cross: 'end' }, [
      iconBtn('layers', { shadow: 'md', stroke: null }), iconBtn('locate', { shadow: 'md', stroke: null, color: 'primary' }),
      listingRow(L.marsa, { shadow: 'lg', stroke: null, right: heartBtn(true, 34) })]),
    tabBar('home')
  ], { fill: 'mapLand' });
}
function detailTile(icon, value, label) {
  return V({ w: 'fill', pad: [12, 10], gap: 6, r: 16, fill: 'surface', stroke: 'border', cross: 'center' }, [
    I(icon, { size: 20, color: 'primary' }), T(value, { size: 15, wt: 800 }), T(label, { size: 11, wt: 600, color: 'muted' })]);
}
function B4() {
  var l = L.marsa;
  return screen('B4', 'Détail d’une annonce', '3.3 · 3.4 · 5.1 · 7.1', [
    body([
      V({ name: 'Galerie photos', w: 390, h: 340, img: l.img, main: 'between' }, [
        F({ w: 390, h: 340, fill: { g: 'v', s: ['#0B122080', '#0B122000', '#0B122000', '#0B122099'] }, abs: { l: 0, t: 0 } }),
        V({ w: 'fill', gap: 0 }, [statusBar(true), H({ w: 'fill', pad: [4, 20], main: 'between' }, [
          iconBtn('arrowLeft', { fill: 'surface', stroke: null }), H({ gap: 10 }, [iconBtn('share', { stroke: null }), iconBtn('heart', { stroke: null, color: 'danger', filled: true })])])]),
        H({ w: 'fill', pad: [0, 20, 16, 20], main: 'between', cross: 'center' }, [
          H({ gap: 6 }, [F({ w: 22, h: 6, r: 3, fill: 'white' }), F({ w: 6, h: 6, r: 3, fill: 'white/60' }), F({ w: 6, h: 6, r: 3, fill: 'white/60' }), F({ w: 6, h: 6, r: 3, fill: 'white/60' })]),
          photoPill('1/8 PHOTOS', { fill: 'scrim', color: 'white', icon: 'image' })])
      ]),
      V({ name: 'Informations', w: 'fill', pad: [18, 20, 0, 20], gap: 16 }, [
        V({ w: 'fill', gap: 8 }, [
          H({ gap: 8 }, [photoPill('VILLA · VENTE', { fill: 'accentSoft', color: 'accent' }), photoPill('VÉRIFIÉE', { fill: 'successSoft', color: 'success', icon: 'shield' })]),
          T('Villa avec piscine et jardin à La Marsa', { size: 24, wt: 800, w: 'fill', lh: 30 }),
          H({ gap: 5, cross: 'center' }, [I('pin', { size: 15, color: 'muted' }), T('Corniche, La Marsa, Tunis', { size: 14, wt: 600, color: 'muted' })]),
          H({ w: 'fill', main: 'between', cross: 'end', pad: [4, 0, 0, 0] }, [priceT(l, 26), T('≈ 3 900 DT/m²', { size: 13, wt: 600, color: 'muted' })])]),
        H({ w: 'fill', gap: 8 }, [detailTile('maximize', '320 m²', 'Surface'), detailTile('bed', 'S+5', 'Pièces'), detailTile('home', 'Villa', 'Type'), detailTile('tag', 'Vente', 'Offre')]),
        V({ w: 'fill', gap: 8 }, [T('Description', { size: 17, wt: 800 }),
          T('Belle villa sur deux niveaux à 300 m de la plage. Grand salon lumineux, cuisine équipée, 4 chambres dont une suite parentale, piscine chauffée et jardin arboré. Garage pour 2 voitures.', { size: 15, color: 'text2', w: 'fill', lh: 23, max: 4 }),
          linkT('Lire la suite')]),
        H({ name: 'Annonceur', w: 'fill', pad: 14, gap: 12, r: 18, fill: 'surface', stroke: 'border', cross: 'center' }, [
          avatar({ img: 'avatarM', size: 50, online: true }),
          V({ w: 'fill', gap: 2 }, [T('Karim Jaziri', { size: 15, wt: 800 }), T('Membre depuis 2024 · 8 annonces', { size: 12, color: 'muted' })]),
          iconBtn('phone', { color: 'primary', fill: 'primarySoft', stroke: null })]),
        V({ w: 'fill', gap: 10 }, [T('Emplacement', { size: 17, wt: 800 }),
          F({ name: 'Mini-carte', w: 350, h: 150, r: 18, clip: true, stroke: 'border' }, [mapBg(350, 150, 3),
            F({ w: 90, h: 90, r: 45, fill: 'primary/15', abs: { l: 130, t: 30 } }), bigPin(152, 40)])]),
        H({ w: 'fill', main: 'center', gap: 6, cross: 'center', pad: [4, 0, 8, 0] }, [I('flag', { size: 15, color: 'muted' }), T('Signaler cette annonce', { size: 13, wt: 700, color: 'muted' })])
      ])
    ], { pad: 0, gap: 0 }),
    bottomBar([heartBtn(true, 54), btn('Contacter l’annonceur', { icon: 'message', shadow: 'md' })])
  ]);
}
function B5() {
  return screen('B5', 'Signaler une annonce', '3.4', [
    F({ name: 'Photo', w: 390, h: 420, img: 'villa1' }),
    scrim(),
    sheet([
      V({ w: 'fill', gap: 6 }, [T('Signaler cette annonce', { size: 22, wt: 800 }),
        T('Votre signalement est anonyme. Un administrateur l’examine sous 24 h.', { size: 14, color: 'text2', w: 'fill', lh: 20 })]),
      V({ w: 'fill', gap: 8 }, [
        radio('Annonce frauduleuse ou arnaque', true, 'danger'), radio('Bien déjà vendu ou loué', false), radio('Prix ou informations trompeurs', false),
        radio('Photos inappropriées', false), radio('Autre motif', false)]),
      field({ label: 'Précisez (facultatif)', value: 'Le vendeur demande un acompte de 2 000 DT avant toute visite.', multi: true }),
      H({ w: 'fill', gap: 8, cross: 'center' }, [I('info', { size: 15, color: 'muted' }), T('Vous ne pouvez signaler une annonce qu’une seule fois.', { size: 12, color: 'muted', w: 'fill' })]),
      btn('Envoyer le signalement', { v: 'danger', icon: 'flag' })
    ])
  ]);
}
function B6() {
  return screen('B6', 'Mes favoris', '5.1 · 8.4 (bonus)', [
    statusBar(),
    appBar('Mes favoris', { big: true, sub: '4 biens sauvegardés', actions: ['map'] }),
    H({ w: 'fill', pad: [0, 20, 8, 20], gap: 8 }, [chip('Tous · 4', true), chip('Vente · 3', false), chip('Location · 1', false)]),
    body([
      listingRow(L.sousse, { right: heartBtn(true, 34), extra: photoPill('PRIX EN BAISSE −7 %', { fill: 'successSoft', color: 'success', icon: 'trendDown' }) }),
      listingRow(L.marsa, { right: heartBtn(true, 34) }),
      listingRow(L.lac, { right: heartBtn(true, 34) }),
      listingRow(L.hammamet, { right: heartBtn(true, 34), extra: statusBadge('vendue') }),
      V({ w: 'fill', pad: [16, 16], gap: 8, r: 18, fill: 'primarySoft', cross: 'center' }, [
        I('bell', { size: 22, color: 'primary' }), T('Créez une alerte pour être prévenu des nouveaux biens à La Marsa.', { size: 13, wt: 600, color: 'primaryDark', align: 'center', w: 'fill', lh: 19 }),
        btn('Créer une alerte', { v: 'primary', h: 40, small: true, w: undefined, px: 16 })])
    ], { gap: 12 }),
    tabBar('heart')
  ]);
}

/* ---------- Membre C ---------- */
function pubHeader(step, label) {
  return V({ name: 'En-tête publication', w: 'fill', pad: [4, 20, 14, 20], gap: 14 }, [
    H({ w: 'fill', gap: 12, cross: 'center' }, [
      iconBtn(step === 1 ? 'x' : 'arrowLeft'),
      V({ w: 'fill', gap: 2 }, [T('Publier une annonce', { size: 18, wt: 800 }), T('Étape ' + step + ' sur 4 · ' + label, { size: 13, wt: 600, color: 'muted' })]),
      T('Brouillon', { size: 14, wt: 800, color: 'primary' })]),
    H({ w: 'fill', gap: 6 }, [1, 2, 3, 4].map(function (i) { return F({ w: 'fill', h: 5, r: 3, fill: i <= step ? 'primary' : 'border' }); }))
  ]);
}
function typeTile(icon, label, on) {
  return V({ name: 'Type ' + label, w: 'fill', h: 82, r: 16, gap: 8, main: 'center', cross: 'center', fill: on ? 'primarySoft' : 'surface', stroke: on ? 'primary' : 'border', sw: on ? 1.5 : 1 }, [
    I(icon, { size: 24, color: on ? 'primary' : 'text2' }), T(label, { size: 12, wt: on ? 800 : 600, color: on ? 'primary' : 'text2' })]);
}
function numStepper(v) {
  return H({ name: 'Compteur', r: 14, fill: 'surface', stroke: 'border', cross: 'center' }, [
    H({ w: 44, h: 44, main: 'center', cross: 'center' }, [I('minus', { size: 18, color: 'text2' })]),
    T(String(v), { size: 17, wt: 800, w: 30, align: 'center' }),
    H({ w: 44, h: 44, main: 'center', cross: 'center' }, [I('plus', { size: 18, color: 'primary' })])]);
}
function C1() {
  return screen('C1', 'Publier · Informations', '6.1', [
    statusBar(),
    pubHeader(1, 'Informations'),
    body([
      V({ w: 'fill', gap: 10 }, [T('Je souhaite', { size: 14, wt: 800 }), seg(['Vendre', 'Louer'], 0)]),
      V({ w: 'fill', gap: 10 }, [T('Type de bien', { size: 14, wt: 800 }), H({ w: 'fill', gap: 8 }, [
        typeTile('building', 'Appartement', true), typeTile('home', 'Villa', false), typeTile('mountain', 'Terrain', false), typeTile('store', 'Local', false)])]),
      field({ label: 'Titre de l’annonce', value: 'Appartement S+3 haut standing', counter: '29/120' }),
      H({ w: 'fill', gap: 10, cross: 'start' }, [
        field({ label: 'Prix (DT)', value: '385 000', w: 'fill' }),
        field({ label: 'Surface (m²)', ph: 'Ex : 120', w: 'fill', err: 'Champ obligatoire', focus: false })]),
      H({ w: 'fill', main: 'between', cross: 'center', pad: [4, 0] }, [
        V({ gap: 2 }, [T('Nombre de pièces', { size: 14, wt: 800 }), T('S+3 = 3 chambres + salon', { size: 12, color: 'muted' })]), numStepper(4)]),
      field({ label: 'Description', value: 'Appartement lumineux au 3e étage avec ascenseur, cuisine équipée, chauffage central et place de parking. Proche écoles et commerces.', multi: true, counter: '142/5000' })
    ], { gap: 18 }),
    bottomBar([btn('Continuer · Photos', { iconRight: 'arrowRight' })])
  ]);
}
function photoTile(img, p) {
  p = p || {};
  return F({ name: 'Photo', w: 106, h: 106, r: 16, img: img, clip: true, dir: 'V', pad: 6, main: 'between' }, [
    p.overlay ? F({ w: 106, h: 106, fill: p.overlay, abs: { l: 0, t: 0 } }) : null,
    H({ w: 'fill', main: 'between', cross: 'start' }, [
      p.cover ? photoPill('COUVERTURE', { fill: 'primary', color: 'onPrimary' }) : F({ w: 1, h: 1 }),
      p.noX ? null : H({ w: 24, h: 24, r: 12, fill: 'scrim', main: 'center', cross: 'center' }, [I('x', { size: 13, color: 'white', sw: 2.6 })])]),
    p.center ? H({ w: 'fill', main: 'center' }, [p.center]) : null,
    H({ w: 'fill', main: 'between', cross: 'end' }, [
      p.label ? T(p.label, { size: 11, wt: 800, color: 'white' }) : F({ w: 1, h: 1 }),
      p.noGrip ? null : H({ w: 24, h: 24, r: 8, fill: 'scrim', main: 'center', cross: 'center' }, [I('grip', { size: 14, color: 'white' })])])
  ]);
}
function C2() {
  return screen('C2', 'Publier · Photos', '6.2', [
    statusBar(),
    pubHeader(2, 'Photos'),
    body([
      banner('primary', 'Ajoutez jusqu’à 10 photos. La première est la photo de couverture. Les photos sont compressées avant l’envoi.', 'image'),
      sectionTitle('Photos (6/10)', linkT('Galerie', 'image')),
      H({ name: 'Grille de photos', w: 'fill', gap: 10, wrap: true }, [
        photoTile('salon1', { cover: true }), photoTile('salon3'), photoTile('chambre'),
        photoTile('salon2'),
        photoTile('salon4', { overlay: '#0B122099', noGrip: true, center: progressRing(68), label: 'Envoi 68 %' }),
        photoTile('villa2', { overlay: 'danger/80', noGrip: true, center: V({ gap: 4, cross: 'center' }, [I('rotate', { size: 22, color: 'white' }), T('Réessayer', { size: 12, wt: 800, color: 'white' })]), label: 'Échec' }),
        V({ name: 'Ajouter', w: 106, h: 106, r: 16, stroke: 'primary', sw: 1.5, dash: true, fill: 'primarySoft', main: 'center', cross: 'center', gap: 6 }, [
          I('plus', { size: 24, color: 'primary', sw: 2.4 }), T('Ajouter', { size: 12, wt: 800, color: 'primary' })])
      ]),
      banner('danger', 'Une photo n’a pas pu être envoyée (connexion perdue). Touchez « Réessayer ».', 'alert'),
      H({ w: 'fill', gap: 8, cross: 'center' }, [I('grip', { size: 16, color: 'muted' }), T('Maintenez une photo et glissez-la pour changer l’ordre.', { size: 12, color: 'muted', w: 'fill' })])
    ], { gap: 16 }),
    bottomBar([btn('Retour', { v: 'outline', w: 120 }), btn('Continuer', { iconRight: 'arrowRight' })])
  ]);
}
function C3() {
  return screen('C3', 'Publier · Position', '6.4', [
    statusBar(),
    pubHeader(3, 'Emplacement'),
    body([
      F({ name: 'Carte', w: 350, h: 330, r: 22, clip: true, stroke: 'border' }, [
        mapBg(350, 330, 5),
        F({ w: 110, h: 110, r: 55, fill: 'primary/12', abs: { l: 120, t: 120 } }),
        H({ name: 'Recherche adresse', w: 326, h: 48, pad: [0, 14], gap: 10, r: 14, fill: 'surface', cross: 'center', shadow: 'md', abs: { l: 12, t: 12 } }, [
          I('search', { size: 18, color: 'primary' }), T('Rue du Lac Léman, Lac 2', { size: 14, wt: 700, w: 'fill', max: 1 }), I('x', { size: 16, color: 'muted' })]),
        H({ name: 'Info-bulle', h: 32, pad: [0, 12], r: 10, fill: 'text', cross: 'center', abs: { l: 96, t: 98 } }, [T('Déplacez le marqueur', { size: 12, wt: 700, color: 'surface' })]),
        bigPin(152, 136),
        iconBtn('locate', { abs: { r: 12, b: 12 }, shadow: 'md', stroke: null, color: 'primary' }),
        H({ name: 'Ma position', h: 36, pad: [0, 12], gap: 6, r: 18, fill: 'surface', cross: 'center', shadow: 'md', abs: { l: 12, b: 15 } }, [
          I('locate', { size: 15, color: 'primary' }), T('Utiliser ma position', { size: 12, wt: 800, color: 'primary' })])
      ]),
      field({ label: 'Adresse', value: 'Rue du Lac Léman, Les Berges du Lac 2', icon: 'pin' }),
      H({ w: 'fill', gap: 10 }, [field({ label: 'Ville', value: 'Tunis', trail: 'chevronDown', w: 'fill' }), field({ label: 'Gouvernorat', value: 'Tunis', trail: 'chevronDown', w: 'fill' })]),
      H({ w: 'fill', pad: [10, 14], gap: 10, r: 12, fill: 'surface2', cross: 'center' }, [I('locate', { size: 16, color: 'muted' }),
        T('Lat. 36,8421 · Long. 10,2752', { size: 13, wt: 700, color: 'text2', w: 'fill' }), I('check', { size: 16, color: 'success', sw: 3 })])
    ], { gap: 16 }),
    bottomBar([btn('Retour', { v: 'outline', w: 120 }), btn('Récapitulatif', { iconRight: 'arrowRight' })])
  ]);
}
function stepLine(state, title, sub, last) {
  var col = state === 'done' ? 'success' : state === 'now' ? 'warning' : 'muted';
  var soft = state === 'done' ? 'successSoft' : state === 'now' ? 'warningSoft' : 'surface2';
  return H({ w: 'fill', gap: 12 }, [
    V({ cross: 'center', h: last ? undefined : 'fill' }, [
      H({ w: 30, h: 30, r: 15, fill: soft, main: 'center', cross: 'center' }, [I(state === 'done' ? 'check' : state === 'now' ? 'clock' : 'checkCircle', { size: 15, color: col, sw: 2.6 })]),
      last ? null : F({ w: 2, h: 'fill', fill: 'border' })]),
    V({ w: 'fill', gap: 2, pad: [4, 0, last ? 0 : 16, 0] }, [T(title, { size: 14, wt: 800, color: state === 'next' ? 'muted' : 'text' }), T(sub, { size: 12, color: 'muted', w: 'fill' })])]);
}
function C4() {
  return screen('C4', 'Publier · Envoyée', '6.1 · 6.5', [
    statusBar(),
    body([
      H({ w: 'fill', main: 'center', pad: [20, 0, 4, 0] }, [
        H({ w: 108, h: 108, r: 54, fill: 'successSoft', main: 'center', cross: 'center' }, [
          H({ w: 70, h: 70, r: 35, fill: 'success', main: 'center', cross: 'center', shadow: 'md' }, [I('check', { size: 34, color: 'white', sw: 3 })])])]),
      T('Annonce envoyée !', { size: 26, wt: 800, w: 'fill', align: 'center' }),
      T('Un administrateur va vérifier votre annonce. Vous recevrez une notification dès qu’elle sera publiée (en moyenne sous 24 h).', { size: 15, color: 'text2', w: 'fill', align: 'center', lh: 22 }),
      listingRow(L.ennasr, { extra: statusBadge('en_attente'), photoBadge: null }),
      V({ name: 'Suivi', w: 'fill', pad: 16, r: 18, fill: 'surface', stroke: 'border' }, [
        stepLine('done', 'Annonce créée', 'Aujourd’hui à 10:42 · 6 photos'),
        stepLine('now', 'Vérification par un administrateur', 'Statut « en attente »'),
        stepLine('next', 'Publication', 'Visible par tous les utilisateurs', true)]),
    ], { gap: 16 }),
    bottomBar([btn('Accueil', { v: 'outline', w: 120 }), btn('Voir mes annonces', { icon: 'list' })])
  ]);
}
function myCard(l, st, p) {
  p = p || {};
  return V({ name: 'Mon annonce · ' + st, w: 'fill', pad: 12, gap: 12, r: 20, fill: 'surface', stroke: 'border' }, [
    H({ w: 'fill', gap: 12, cross: 'center' }, [
      F({ w: 78, h: 78, r: 14, img: l.img }),
      V({ w: 'fill', gap: 4 }, [
        H({ w: 'fill', main: 'between', cross: 'center' }, [statusBadge(st), I('more', { size: 18, color: 'muted' })]),
        T(l.titre, { size: 15, wt: 800, w: 'fill', max: 1 }),
        H({ w: 'fill', main: 'between', cross: 'center' }, [priceT(l, 15), p.stats ? H({ gap: 10 }, [feat('eye', p.stats[0]), feat('heart', p.stats[1])]) : null])])]),
    p.motif ? V({ w: 'fill', gap: 6, pad: 12, r: 14, fill: st === 'rejetee' ? 'dangerSoft' : 'surface2' }, [
      T(st === 'rejetee' ? 'Motif du rejet' : 'Motif du masquage', { size: 12, wt: 800, color: st === 'rejetee' ? 'danger' : 'text2' }),
      T(p.motif, { size: 13, wt: 600, color: 'text', w: 'fill', lh: 19 })]) : null,
    p.actions ? H({ w: 'fill', gap: 8 }, p.actions) : null
  ]);
}
function myListingsContent() {
  return [
    statusBar(),
    appBar('Mes annonces', { big: true, sub: '5 annonces · 2 en ligne', actions: [iconBtn('plus', { fill: 'primary', stroke: null, color: 'onPrimary' })] }),
    chipsRow(['Toutes · 5', 'Publiées · 2', 'En attente · 1', 'Rejetées · 1', 'Vendues · 1'], 0),
    body([
      myCard(L.hammamet, 'rejetee', { motif: 'Les photos ne montrent pas l’intérieur. Ajoutez au moins 3 photos des pièces.', actions: [btn('Modifier et renvoyer', { v: 'soft', h: 42, small: true, icon: 'pencil' })] }),
      myCard(L.lac, 'publiee', { stats: ['248', '12'], actions: [btn('Modifier', { v: 'outline', h: 42, small: true, icon: 'pencil' }), btn('Marquer vendue', { v: 'soft', h: 42, small: true, icon: 'tag' }),
        H({ w: 42, h: 42, r: 14, fill: 'dangerSoft', main: 'center', cross: 'center' }, [I('trash', { size: 18, color: 'danger' })])] }),
      myCard(L.ennasr, 'en_attente', {}),
      myCard(L.sfax, 'masquee', { motif: 'Signalée plusieurs fois pour informations trompeuses (surface).' }),
      myCard(L.nabeul, 'vendue', { stats: ['512', '31'] })
    ], { gap: 12, pad: [14, 20, 20, 20] }),
    tabBar('user')
  ];
}
function C5() { return screen('C5', 'Mes annonces', '6.3 · 6.5 · 6.9 (bonus)', myListingsContent()); }
function C6() {
  return screen('C6', 'Supprimer une annonce', '6.3', myListingsContent().concat([
    scrim(),
    V({ name: 'Boîte de dialogue', w: 334, pad: 22, gap: 14, r: 26, fill: 'surface', cross: 'center', shadow: 'lg', abs: { l: 28, t: 250 } }, [
      H({ w: 64, h: 64, r: 32, fill: 'dangerSoft', main: 'center', cross: 'center' }, [I('trash', { size: 28, color: 'danger' })]),
      T('Supprimer cette annonce ?', { size: 20, wt: 800, align: 'center', w: 'fill' }),
      T('« Duplex S+4 Les Berges du Lac » et ses 7 photos seront supprimés définitivement. Les conversations liées restent accessibles.', { size: 14, color: 'text2', align: 'center', w: 'fill', lh: 20 }),
      H({ w: 'fill', gap: 10, pad: [6, 0, 0, 0] }, [btn('Annuler', { v: 'outline', h: 48 }), btn('Supprimer', { v: 'danger', h: 48 })])
    ])
  ]));
}
function convRow(p) {
  return H({ name: 'Conversation · ' + p.name, w: 'fill', pad: [14, 20], gap: 12, cross: 'center', fill: p.unread ? 'primarySoft' : null, stroke: 'border', sides: 'b' }, [
    avatar(p.av),
    V({ w: 'fill', gap: 4 }, [
      H({ w: 'fill', main: 'between', cross: 'center' }, [T(p.name, { size: 15, wt: 800 }), T(p.time, { size: 12, wt: p.unread ? 800 : 500, color: p.unread ? 'primary' : 'muted' })]),
      H({ gap: 6, cross: 'center' }, [F({ w: 18, h: 18, r: 5, img: p.l.img }), T(p.l.titre, { size: 12, wt: 600, color: 'muted', max: 1, w: 220 })]),
      H({ w: 'fill', gap: 8, cross: 'center' }, [
        p.mine ? I('checks', { size: 16, color: p.read ? 'primary' : 'muted' }) : null,
        T(p.msg, { size: 14, wt: p.unread ? 700 : 500, color: p.unread ? 'text' : 'text2', w: 'fill', max: 1 }),
        p.unread ? H({ w: 22, h: 22, r: 11, fill: 'primary', main: 'center', cross: 'center' }, [T(String(p.unread), { size: 11, wt: 800, color: 'onPrimary' })]) : null])])]);
}
function C7() {
  return screen('C7', 'Mes conversations', '7.3', [
    statusBar(),
    appBar('Messages', { big: true, sub: '2 messages non lus' }),
    H({ w: 'fill', pad: [0, 20, 10, 20] }, [field({ value: '', ph: 'Rechercher une personne ou un bien', icon: 'search' })]),
    body([
      convRow({ name: 'Karim Jaziri', av: { img: 'avatarM', size: 54, online: true }, l: L.marsa, msg: 'La visite samedi à 10 h vous convient ?', time: '14:32', unread: 2 }),
      convRow({ name: 'Ines Gharbi', av: { img: 'avatarF2', size: 54 }, l: L.sousse, msg: 'Le loyer inclut-il les charges de syndic ?', time: 'Hier', mine: true, read: true }),
      convRow({ name: 'Sami Ben Salah', av: { initials: 'SB', size: 54 }, l: L.sfax, msg: 'Merci, je vous rappelle demain matin.', time: 'Lun.' }),
      convRow({ name: 'Yosr Mansour', av: { initials: 'YM', size: 54, fill: 'primarySoft', color: 'primary' }, l: L.nabeul, msg: 'Le terrain est-il viabilisé (eau, électricité) ?', time: '03/11', mine: true, read: false }),
      convRow({ name: 'Mehdi Kallel', av: { initials: 'MK', size: 54, fill: 'successSoft', color: 'success' }, l: L.lac, msg: 'Parfait, à jeudi alors.', time: '28/10' })
    ], { pad: 0, gap: 0 }),
    tabBar('message')
  ]);
}
function bubble(text, p) {
  p = p || {};
  var out = p.out, long = text.length > 30;
  return H({ name: out ? 'Message envoyé' : 'Message reçu', w: 'fill', main: out ? 'end' : 'start' }, [
    V({ gap: 4, cross: out ? 'end' : 'start' }, [
      V({ pad: p.img ? 4 : [10, 14], gap: 6, r: out ? [20, 20, 6, 20] : [20, 20, 20, 6], fill: out ? 'primary' : 'surface', stroke: out ? null : 'border' }, [
        p.img ? F({ w: 230, h: 150, r: 16, img: p.img }) : null,
        T(text, { size: 15, wt: 500, color: out ? 'onPrimary' : 'text', w: long ? 240 : undefined, lh: 21, pad: 0 })]),
      H({ gap: 4, cross: 'center' }, [T(p.time, { size: 11, wt: 600, color: 'muted' }), out ? I('checks', { size: 15, color: p.read ? 'primary' : 'muted' }) : null])])]);
}
function C8() {
  return screen('C8', 'Discussion en temps réel', '7.1 · 7.2 · 7.4/7.5 (bonus)', [
    statusBar(),
    H({ name: 'En-tête discussion', w: 'fill', pad: [4, 16, 12, 16], gap: 10, cross: 'center', stroke: 'border', sides: 'b' }, [
      iconBtn('arrowLeft', { stroke: null, fill: null }),
      avatar({ img: 'avatarM', size: 44, online: true }),
      V({ w: 'fill', gap: 1 }, [T('Karim Jaziri', { size: 16, wt: 800 }), H({ gap: 5, cross: 'center' }, [F({ w: 7, h: 7, r: 4, fill: 'success' }), T('En ligne', { size: 12, wt: 600, color: 'success' })])]),
      iconBtn('phone', { color: 'primary' }), iconBtn('more', { stroke: null, fill: null })]),
    H({ name: 'Annonce liée', w: 'fill', pad: [10, 16], gap: 10, cross: 'center', fill: 'surface' , stroke: 'border', sides: 'b' }, [
      F({ w: 46, h: 46, r: 12, img: 'villa1' }),
      V({ w: 'fill', gap: 2 }, [T('Villa avec piscine · La Marsa', { size: 13, wt: 800, max: 1, w: 'fill' }), priceT(L.marsa, 14)]),
      btn('Voir', { v: 'soft', h: 34, small: true, w: undefined, px: 14, r: 10 })]),
    body([
      H({ w: 'fill', main: 'center' }, [photoPill('AUJOURD’HUI', { fill: 'surface2', color: 'muted' })]),
      bubble('Bonjour, la villa est-elle toujours disponible ?', { out: true, time: '10:02', read: true }),
      bubble('Bonjour Yasmine, oui elle est disponible. Vous souhaitez la visiter ?', { time: '10:05' }),
      bubble('Oui avec plaisir ! Le prix est-il négociable ?', { out: true, time: '10:06', read: true }),
      bubble('Voici le salon, rénové l’an dernier.', { time: '10:09', img: 'salon3' }),
      bubble('La visite samedi à 10 h vous convient ?', { time: '14:32' }),
      H({ name: 'En train d’écrire', pad: [12, 16], gap: 5, r: [20, 20, 20, 6], fill: 'surface', stroke: 'border', cross: 'center' }, [
        F({ w: 8, h: 8, r: 4, fill: 'muted' }), F({ w: 8, h: 8, r: 4, fill: 'muted', op: 0.6 }), F({ w: 8, h: 8, r: 4, fill: 'muted', op: 0.3 })])
    ], { gap: 12, pad: [14, 16, 14, 16] }),
    V({ name: 'Zone de saisie', w: 'fill', fill: 'surface', stroke: 'border', sides: 't' }, [
      H({ w: 'fill', pad: [10, 14, 4, 14], gap: 10, cross: 'center' }, [
        iconBtn('image', { fill: 'surface2', stroke: null, color: 'text2' }),
        H({ w: 'fill', h: 44, pad: [0, 16], r: 22, fill: 'surface2', cross: 'center' }, [T('Oui, samedi me va très bien|', { size: 15, wt: 500, w: 'fill', max: 1 })]),
        H({ w: 44, h: 44, r: 22, fill: 'primary', main: 'center', cross: 'center', shadow: 'md' }, [I('send', { size: 19, color: 'onPrimary' })])]),
      homeInd()])
  ]);
}
function notif(p) {
  return H({ name: 'Notification · ' + p.title, w: 'fill', pad: [14, 20], gap: 12, cross: 'start', fill: p.unread ? 'surface' : null, stroke: 'border', sides: 'b' }, [
    p.av ? avatar(p.av) : H({ w: 46, h: 46, r: 23, fill: p.kind + 'Soft', main: 'center', cross: 'center' }, [I(p.icon, { size: 21, color: p.kind })]),
    V({ w: 'fill', gap: 3 }, [
      H({ w: 'fill', main: 'between', cross: 'center', gap: 8 }, [T(p.title, { size: 14, wt: 800, w: 'fill', max: 1 }), T(p.time, { size: 12, color: 'muted' })]),
      T(p.text, { size: 13, color: 'text2', w: 'fill', lh: 19, max: 2 }),
      p.cta ? H({ pad: [6, 0, 0, 0] }, [p.cta]) : null]),
    p.unread ? F({ w: 9, h: 9, r: 5, fill: 'primary' }) : null]);
}
function C9() {
  return screen('C9', 'Notifications', '8.1 · 8.2 · 8.3/8.4 (bonus)', [
    statusBar(),
    appBar('Notifications', { big: true, sub: '3 non lues', actions: [T('Tout lire', { size: 14, wt: 800, color: 'primary' })] }),
    body([
      H({ w: 'fill', pad: [8, 20, 6, 20] }, [T('AUJOURD’HUI', { size: 11, wt: 800, color: 'muted', ls: 1 })]),
      notif({ unread: true, av: { img: 'avatarM', size: 46 }, title: 'Nouveau message de Karim Jaziri', time: '5 min', text: '« La visite samedi à 10 h vous convient ? » · Villa avec piscine' }),
      notif({ unread: true, kind: 'success', icon: 'checkCircle', title: 'Votre annonce est publiée', time: '1 h', text: 'Appartement S+3 haut standing est maintenant visible par tous les utilisateurs.' }),
      notif({ unread: true, kind: 'danger', icon: 'x', title: 'Annonce rejetée', time: '3 h', text: 'Villa contemporaine : les photos ne montrent pas l’intérieur du bien.', cta: btn('Corriger l’annonce', { v: 'dangerSoft', h: 34, small: true, w: undefined, px: 14, r: 10, icon: 'pencil' }) }),
      H({ w: 'fill', pad: [16, 20, 6, 20] }, [T('CETTE SEMAINE', { size: 11, wt: 800, color: 'muted', ls: 1 })]),
      notif({ kind: 'warning', icon: 'eyeOff', title: 'Annonce masquée par un administrateur', time: 'Lun.', text: 'Local commercial centre-ville : signalée plusieurs fois. Motif : informations trompeuses.' }),
      notif({ kind: 'accent', icon: 'trendDown', title: 'Baisse de prix sur un favori', time: 'Dim.', text: 'S+2 meublé vue mer passe à 1 300 DT/mois (−7 %).' }),
      notif({ kind: 'primary', icon: 'bell', title: 'Nouveau bien pour « Villa à La Marsa »', time: 'Sam.', text: 'Villa 5 pièces avec jardin · 1 100 000 DT · publiée il y a 2 h.' })
    ], { pad: 0, gap: 0 }),
    tabBar('user')
  ]);
}

/* ---------- Design system (planche) ---------- */
function designSystem() {
  var swatches = Object.keys(TOKEN_LABELS).map(function (k) {
    return V({ name: 'Couleur ' + k, w: 150, gap: 8 }, [
      F({ w: 150, h: 76, r: 16, fill: k, stroke: 'border' }),
      T(TOKEN_LABELS[k], { size: 13, wt: 800, w: 150, max: 2 }),
      T(TOKENS[k][0] + ' · ' + TOKENS[k][1], { size: 11, wt: 600, color: 'muted' })]);
  });
  var types = [['Display · 32 / ExtraBold', 32, 800], ['Titre 1 · 26 / ExtraBold', 26, 800], ['Titre 2 · 20 / ExtraBold', 20, 800],
    ['Titre 3 · 17 / ExtraBold', 17, 800], ['Texte · 15 / Medium', 15, 500], ['Petit texte · 13 / SemiBold', 13, 600], ['LÉGENDE · 11 / EXTRABOLD', 11, 800]];
  var iconNames = Object.keys(ICONS);
  function block(title, sub, children) {
    return V({ name: title, w: 'fill', gap: 18 }, [V({ gap: 4 }, [T(title, { size: 22, wt: 800 }), T(sub, { size: 14, color: 'muted' })])].concat(children));
  }
  return V({ name: '00 · Design system', w: 1120, pad: 48, gap: 44, fill: 'bg', r: 32, meta: { id: 'DS', title: 'Design system', stories: '1.4a · 1.4b · 1.4c' } }, [
    H({ w: 'fill', main: 'between', cross: 'center' }, [
      V({ gap: 8 }, [logo(false, 52), T('Design system · Maquettes v3 · Sprint 0', { size: 15, wt: 600, color: 'muted' })]),
      V({ gap: 6, cross: 'end' }, [photoPill('PLUS JAKARTA SANS', { fill: 'primarySoft' }), T('Grille 8 px · marges 20 px · écran 390 × 844', { size: 13, color: 'muted' })])]),
    block('Couleurs', 'Chaque couleur est une variable Figma avec un mode Clair et un mode Sombre.', [H({ w: 'fill', gap: 20, wrap: true }, swatches)]),
    H({ w: 'fill', gap: 48 }, [
      block('Typographie', 'Une seule famille, quatre graisses.', [V({ gap: 14 }, types.map(function (t) { return T(t[0], { size: t[1], wt: t[2] }); }))]),
      block('Statuts d’annonce', 'Énumération statut_annonce de la base.', [V({ gap: 10 }, Object.keys(STATUTS).map(function (k) {
        return H({ gap: 12, cross: 'center' }, [statusBadge(k), T(k, { size: 13, wt: 600, color: 'muted' })]); }))])
    ]),
    block('Composants', 'Boutons, champs, puces et cartes réutilisés dans tous les écrans.', [
      H({ w: 'fill', gap: 32, cross: 'start' }, [
        V({ w: 300, gap: 12 }, [btn('Bouton principal'), btn('Bouton secondaire', { v: 'soft' }), btn('Bouton contour', { v: 'outline' }), btn('Bouton danger', { v: 'danger', icon: 'trash' })]),
        V({ w: 320, gap: 14 }, [field({ label: 'Champ normal', value: 'La Marsa', icon: 'pin' }), field({ label: 'Champ actif', value: '385 000', focus: true }), field({ label: 'Champ en erreur', ph: 'Ex : 120', err: 'Champ obligatoire' }),
          H({ gap: 8, wrap: true, w: 'fill' }, [chip('Active', true), chip('Inactive', false), chip('Avec icône', false, { icon: 'locate' })]),
          H({ gap: 16, cross: 'center' }, [toggle(true), toggle(false), checkbox(true), checkbox(false)])]),
        V({ w: 'fill', gap: 12 }, [listingCard(L.lac, { w: 'fill', ih: 160 })])])
    ]),
    block('Icônes', iconNames.length + ' icônes · trait 2 px · grille 24 px', [H({ w: 'fill', gap: 10, wrap: true }, iconNames.map(function (n) {
      return V({ name: 'Icône ' + n, w: 92, h: 76, r: 14, fill: 'surface', stroke: 'border', gap: 8, main: 'center', cross: 'center' }, [I(n, { size: 22 }), T(n, { size: 10, wt: 600, color: 'muted' })]); }))])
  ]);
}

/* ---------- 7. Regroupement par membre ---------- */
var GROUPS = [
  { id: 'C', task: '1.4c', owner: 'Membre C', title: 'Publication, mes annonces, messagerie et notifications', epics: 'Epics 6 · 7 · 8', screens: [C1, C2, C3, C4, C5, C6, C7, C8, C9] },
  { id: 'B', task: '1.4b', owner: 'Membre B', title: 'Recherche, carte, détail et favoris', epics: 'Epics 3 · 4 · 5', screens: [B1, B2, B3, B4, B5, B6] },
  { id: 'A', task: '1.4a', owner: 'Membre A', title: 'Authentification, profil et administration', epics: 'Epic 2 · Admin', screens: [A1, A2, A3, A4, A5, A6, A7, A8] }
];
