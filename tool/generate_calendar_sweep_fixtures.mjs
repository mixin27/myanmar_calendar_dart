#!/usr/bin/env node
// Day-by-day sweep of the vendored ceMmDateTime.js reference, for parity
// tests that cover every day of a range rather than random samples.
//
//   node tool/generate_calendar_sweep_fixtures.mjs
//
// Writes test/fixtures/calendar_sweep_fixtures.json:
// - myanmar: continuous Julian-day ranges (local, Myanmar Time) with each
//   day's Myanmar date as (year - 1000) * 10000 + month * 100 + day, so
//   j2m and its inverse can be checked for every day. Ranges include the
//   years with entries in the fme/wte exception tables.
// - holidays: for 2010-2035, the days where cal_holiday (public holidays)
//   or cal_holiday2 (anniversary days) is non-empty, with their names.
// - astro: for 2020-2030, each day as "sabbath yatyaza pyathada nagahle
//   mahabote nakhat|astrological days" (the cal_* codes and cal_astro).

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const root = process.cwd();
const referencePath = path.join(root, 'reference', 'ceMmDateTime.js');
const outputPath = path.join(
  root,
  'test',
  'fixtures',
  'calendar_sweep_fixtures.json',
);

const sandbox = { Math, Date, Array, Object, Number, String, JSON, Map, Set, console };
vm.createContext(sandbox);
vm.runInContext(
  `${fs.readFileSync(referencePath, 'utf8')}
this.__ceDateTime = ceDateTime;
this.__ceMmDateTime = ceMmDateTime;
`,
  sandbox,
  { filename: 'ceMmDateTime.js' },
);
const ceDateTime = sandbox.__ceDateTime;
const ceMmDateTime = sandbox.__ceMmDateTime;

// Local Julian day number (noon) of a Gregorian date.
const jdnOf = (y, m, d) => Math.round(ceDateTime.w2j(y, m, d, 12, 0, 0, 0, 2361222));

// Western years around the exception-table years (ME + 638), plus today's
// range.
const westernRanges = [
  [1838, 1846],
  [1871, 1873],
  [1898, 1903],
  [1981, 1984],
  [2010, 2035],
];

const myanmar = westernRanges.map(([from, to]) => {
  const start = jdnOf(from, 1, 1);
  const end = jdnOf(to, 12, 31);
  const days = [];
  for (let jdn = start; jdn <= end; jdn += 1) {
    const m = ceMmDateTime.j2m(jdn);
    days.push((m.my - 1000) * 10000 + m.mm * 100 + m.md);
  }
  return { startJdn: start, days };
});

const holidays = [];
for (let jdn = jdnOf(2010, 1, 1); jdn <= jdnOf(2035, 12, 31); jdn += 1) {
  const publicDays = ceMmDateTime.cal_holiday(jdn);
  const anniversaries = ceMmDateTime.cal_holiday2(jdn);
  if (publicDays.length || anniversaries.length) {
    holidays.push({ jdn, public: publicDays, anniversary: anniversaries });
  }
}

const astroStart = jdnOf(2020, 1, 1);
const astroDays = [];
for (let jdn = astroStart; jdn <= jdnOf(2030, 12, 31); jdn += 1) {
  const m = ceMmDateTime.j2m(jdn);
  const wd = (jdn + 2) % 7;
  const codes = [
    ceMmDateTime.cal_sabbath(m.md, m.mm, m.myt),
    ceMmDateTime.cal_yatyaza(m.mm, wd),
    ceMmDateTime.cal_pyathada(m.mm, wd),
    ceMmDateTime.cal_nagahle(m.mm),
    ceMmDateTime.cal_mahabote(m.my, wd),
    ceMmDateTime.cal_nakhat(m.my),
  ];
  astroDays.push(`${codes.join(' ')}|${ceMmDateTime.cal_astro(jdn).join(',')}`);
}

fs.writeFileSync(
  outputPath,
  JSON.stringify({
    reference: 'reference/ceMmDateTime.js',
    timezoneOffset: 6.5,
    myanmar,
    holidays,
    astro: { startJdn: astroStart, days: astroDays },
  }),
);
console.log(
  `Wrote ${outputPath}: ${myanmar.reduce((n, r) => n + r.days.length, 0)} days, ${holidays.length} holiday days`,
);
