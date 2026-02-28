#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const root = process.cwd();
const referencePath = path.join(root, 'reference', 'ceMmDateTime.js');
const outputPath = path.join(root, 'test', 'fixtures', 'reference_parity_fixtures.json');

const source = fs.readFileSync(referencePath, 'utf8');
const sandbox = {
  Math,
  Date,
  Array,
  Object,
  Number,
  String,
  JSON,
  Map,
  Set,
  console,
};

vm.createContext(sandbox);
vm.runInContext(
  `${source}
this.__ceDateTime = ceDateTime;
this.__ceMmDateTime = ceMmDateTime;
`,
  sandbox,
  { filename: 'ceMmDateTime.js' },
);

const ceDateTime = sandbox.__ceDateTime;
const ceMmDateTime = sandbox.__ceMmDateTime;

if (!ceDateTime || !ceMmDateTime) {
  throw new Error('Failed to load ceMmDateTime.js classes.');
}

let seed = 20260228;
const nextRandom = () => {
  seed = (1664525 * seed + 1013904223) >>> 0;
  return seed / 4294967296;
};

const randomInt = (min, max) => {
  return min + Math.floor(nextRandom() * (max - min + 1));
};

const fixedCases = [
  { year: 1600, month: 2, day: 29, hour: 12, minute: 0, second: 0 },
  { year: 1700, month: 2, day: 28, hour: 12, minute: 30, second: 45 },
  { year: 1752, month: 9, day: 2, hour: 11, minute: 59, second: 59 },
  { year: 1752, month: 9, day: 14, hour: 0, minute: 0, second: 0 },
  { year: 1900, month: 2, day: 28, hour: 8, minute: 15, second: 30 },
  { year: 2000, month: 2, day: 29, hour: 23, minute: 59, second: 59 },
  { year: 2024, month: 4, day: 17, hour: 12, minute: 0, second: 0 },
  { year: 2026, month: 11, day: 8, hour: 9, minute: 45, second: 12 },
];

const randomWesternCases = (count) => {
  const result = [];
  for (let i = 0; i < count; i += 1) {
    result.push({
      year: randomInt(1200, 2600),
      month: randomInt(1, 12),
      day: randomInt(1, 28),
      hour: randomInt(0, 23),
      minute: randomInt(0, 59),
      second: randomInt(0, 59),
    });
  }
  return result;
};

const westernConfigs = [
  { timezoneOffset: 0.0, calendarType: 0, gregorianStart: 2361222 },
  { timezoneOffset: 6.5, calendarType: 0, gregorianStart: 2361222 },
  { timezoneOffset: -5.0, calendarType: 1, gregorianStart: 2361222 },
  { timezoneOffset: 9.0, calendarType: 2, gregorianStart: 2361222 },
];

const myanmarConfigs = [
  { timezoneOffset: 0.0, sasanaYearType: 0 },
  { timezoneOffset: 6.5, sasanaYearType: 1 },
  { timezoneOffset: -5.0, sasanaYearType: 2 },
];

const westernToJulian = [];
const julianToWestern = [];
const julianToMyanmar = [];

const westernInputs = [...fixedCases, ...randomWesternCases(72)];

for (const config of westernConfigs) {
  for (const input of westernInputs) {
    const localJdn = ceDateTime.w2j(
      input.year,
      input.month,
      input.day,
      input.hour,
      input.minute,
      input.second,
      config.calendarType,
      config.gregorianStart,
    );

    const utcJdn = localJdn - config.timezoneOffset / 24.0;
    const western = ceDateTime.j2w(
      utcJdn + config.timezoneOffset / 24.0,
      config.calendarType,
      config.gregorianStart,
    );

    westernToJulian.push({
      config,
      input,
      expected: { julianDayNumber: utcJdn },
    });

    julianToWestern.push({
      config,
      input: { julianDayNumber: utcJdn },
      expected: {
        year: western.y,
        month: western.m,
        day: western.d,
        hour: western.h,
        minute: western.n,
        second: Math.round(western.s),
        weekday: (Math.floor(utcJdn + config.timezoneOffset / 24.0 + 0.5) + 2) % 7,
      },
    });
  }
}

const myanmarInputs = [...fixedCases, ...randomWesternCases(64)];
for (const config of myanmarConfigs) {
  for (const westernInput of myanmarInputs) {
    const utcJdn =
      ceDateTime.w2j(
        westernInput.year,
        westernInput.month,
        westernInput.day,
        westernInput.hour,
        westernInput.minute,
        westernInput.second,
        0,
        2361222,
      ) -
      config.timezoneOffset / 24.0;

    const localJdn = utcJdn + config.timezoneOffset / 24.0;
    const myanmar = ceMmDateTime.j2m(localJdn);
    const moonPhase = ceMmDateTime.cal_mp(
      myanmar.md,
      myanmar.mm,
      myanmar.myt,
    );
    const fortnightDay = ceMmDateTime.cal_mf(myanmar.md);
    const monthLength = ceMmDateTime.cal_mml(myanmar.mm, myanmar.myt);
    const sasanaYear = ceMmDateTime.my2sy(
      myanmar.my,
      myanmar.mm,
      myanmar.md,
      config.sasanaYearType,
    );

    julianToMyanmar.push({
      config,
      input: { julianDayNumber: utcJdn },
      expected: {
        year: myanmar.my,
        month: myanmar.mm,
        day: myanmar.md,
        yearType: myanmar.myt,
        moonPhase,
        fortnightDay,
        weekday: (Math.round(localJdn) + 2) % 7,
        sasanaYear,
        monthLength,
        monthType: Math.floor(myanmar.mm / 13),
      },
    });
  }
}

const output = {
  reference: {
    source: 'reference/ceMmDateTime.js',
    version: '20250726',
  },
  generatedAt: new Date().toISOString(),
  seed,
  counts: {
    westernToJulian: westernToJulian.length,
    julianToWestern: julianToWestern.length,
    julianToMyanmar: julianToMyanmar.length,
  },
  cases: {
    westernToJulian,
    julianToWestern,
    julianToMyanmar,
  },
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, 'utf8');

console.log(`Wrote ${outputPath}`);
