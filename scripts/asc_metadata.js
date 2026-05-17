const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');

const KEY_ID = process.env.ASC_KEY_ID || 'WDXGY9WX55';
const ISSUER_ID = process.env.ASC_ISSUER_ID || '2be0734f-943a-4d61-9dc9-5d9045c46fec';
const API_KEY_PATH = process.env.ASC_KEY_PATH || `${process.env.USERPROFILE}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;
const APP_ID = process.env.ASC_APP_ID || '6770267550';
const VERSION = process.env.ASC_VERSION || '1.0';

function makeJWT() {
  const key = fs.readFileSync(API_KEY_PATH, 'utf8');
  const now = Math.floor(Date.now() / 1000) - 60;
  const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ iss: ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })).toString('base64url');
  const sign = crypto.createSign('SHA256');
  sign.update(`${header}.${payload}`);
  sign.end();
  return `${header}.${payload}.${sign.sign({ key, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
}

function api(method, requestPath, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = https.request({
      hostname: 'api.appstoreconnect.apple.com',
      path: requestPath,
      method,
      headers: {
        Authorization: `Bearer ${makeJWT()}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    }, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        let parsed = raw;
        try {
          parsed = raw ? JSON.parse(raw) : {};
        } catch {}
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(parsed);
        } else {
          reject(new Error(`HTTP ${res.statusCode} ${method} ${requestPath}\n${JSON.stringify(parsed, null, 2)}`));
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function upload(url, method, headers, buffer) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const req = https.request({
      protocol: parsed.protocol,
      hostname: parsed.hostname,
      port: parsed.port || 443,
      path: `${parsed.pathname}${parsed.search}`,
      method,
      headers,
    }, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(raw);
        } else {
          reject(new Error(`Upload failed ${res.statusCode}: ${raw}`));
        }
      });
    });
    req.on('error', reject);
    req.write(buffer);
    req.end();
  });
}

async function appInfo() {
  const infos = await api('GET', `/v1/apps/${APP_ID}/appInfos?include=primaryCategory,appInfoLocalizations`);
  return infos.data[0];
}

async function appStoreVersion() {
  const result = await api('GET', `/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${encodeURIComponent(VERSION)}&limit=1`);
  if (!result.data?.length) throw new Error(`Version ${VERSION} not found.`);
  return result.data[0];
}

async function versionLocalization(versionId) {
  const result = await api('GET', `/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=10`);
  if (result.data?.length) return result.data[0];
  return (await api('POST', '/v1/appStoreVersionLocalizations', {
    data: {
      type: 'appStoreVersionLocalizations',
      attributes: {
        locale: 'en-US',
        description: 'DUB UNIVERSE generates deep, industrial dub techno patterns from simple controls. Shape bass, chords, echo textures, drums, and MIDI ideas with a rusted hardware-inspired interface.',
        keywords: 'dub techno,music generator,midi,bass,sequencer',
        marketingUrl: 'https://github.com/snarfnet/DUB_UNIVERSE',
        promotionalText: 'Generate rough, deep dub techno ideas with one rusted machine.',
        supportUrl: 'https://github.com/snarfnet/DUB_UNIVERSE/issues',
        whatsNew: 'Initial release.',
      },
      relationships: {
        appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } },
      },
    },
  })).data;
}

async function listCategories() {
  const cats = await api('GET', '/v1/appCategories?limit=200');
  for (const cat of cats.data) {
    console.log(`${cat.id}\t${cat.attributes.platforms?.join(',') || ''}\t${cat.attributes.name}`);
  }
}

async function patchAppInfo(infoId, categoryId) {
  const body = {
    data: {
      type: 'appInfos',
      id: infoId,
    },
  };
  if (categoryId) {
    body.data.relationships = {
      primaryCategory: {
        data: { type: 'appCategories', id: categoryId },
      },
    };
  }
  return api('PATCH', `/v1/appInfos/${infoId}`, body);
}

async function patchApp() {
  return api('PATCH', `/v1/apps/${APP_ID}`, {
    data: {
      type: 'apps',
      id: APP_ID,
      attributes: {
        contentRightsDeclaration: 'DOES_NOT_USE_THIRD_PARTY_CONTENT',
      },
    },
  });
}

async function patchVersion(versionId) {
  return api('PATCH', `/v1/appStoreVersions/${versionId}`, {
    data: {
      type: 'appStoreVersions',
      id: versionId,
      attributes: {
        copyright: 'Copyright (c) 2026 Satoshi Amasaki',
        releaseType: 'AFTER_APPROVAL',
        usesIdfa: true,
      },
    },
  });
}

async function setPrivacyPolicy() {
  const info = await appInfo();
  const localizations = await api('GET', `/v1/appInfos/${info.id}/appInfoLocalizations?limit=20`);
  for (const loc of localizations.data || []) {
    await api('PATCH', `/v1/appInfoLocalizations/${loc.id}`, {
      data: {
        type: 'appInfoLocalizations',
        id: loc.id,
        attributes: {
          privacyPolicyUrl: 'https://github.com/snarfnet/DUB_UNIVERSE/blob/main/PRIVACY_POLICY.md',
        },
      },
    });
    console.log(`Updated privacy policy URL for ${loc.attributes.locale}`);
  }
}

async function screenshotSet(localizationId, displayType) {
  const existing = await api('GET', `/v1/appStoreVersionLocalizations/${localizationId}/appScreenshotSets?filter[screenshotDisplayType]=${displayType}&include=appScreenshots&limit=10`);
  for (const set of existing.data || []) {
    await api('DELETE', `/v1/appScreenshotSets/${set.id}`);
    console.log(`Deleted old screenshot set ${set.id}`);
  }
  return (await api('POST', '/v1/appScreenshotSets', {
    data: {
      type: 'appScreenshotSets',
      attributes: {
        screenshotDisplayType: displayType,
      },
      relationships: {
        appStoreVersionLocalization: {
          data: { type: 'appStoreVersionLocalizations', id: localizationId },
        },
      },
    },
  })).data;
}

async function uploadScreenshot(setId, filePath) {
  const data = fs.readFileSync(filePath);
  const reservation = await api('POST', '/v1/appScreenshots', {
    data: {
      type: 'appScreenshots',
      attributes: {
        fileName: path.basename(filePath),
        fileSize: data.length,
      },
      relationships: {
        appScreenshotSet: {
          data: { type: 'appScreenshotSets', id: setId },
        },
      },
    },
  });

  const screenshot = reservation.data;
  for (const op of screenshot.attributes.uploadOperations || []) {
    const offset = Number(op.offset || 0);
    const length = Number(op.length || data.length);
    const chunk = data.subarray(offset, offset + length);
    const headers = {};
    for (const header of op.requestHeaders || []) {
      headers[header.name] = header.value;
    }
    headers['Content-Length'] = chunk.length;
    await upload(op.url, op.method, headers, chunk);
  }

  await api('PATCH', `/v1/appScreenshots/${screenshot.id}`, {
    data: {
      type: 'appScreenshots',
      id: screenshot.id,
      attributes: {
        uploaded: true,
        sourceFileChecksum: crypto.createHash('md5').update(data).digest('hex'),
      },
    },
  });
  console.log(`Uploaded ${path.basename(filePath)}`);
}

async function uploadScreenshots() {
  const version = await appStoreVersion();
  const loc = await versionLocalization(version.id);
  const set = await screenshotSet(loc.id, 'APP_IPHONE_65');
  const dir = path.resolve('ASC_Submission_Assets/screenshots');
  const files = fs.readdirSync(dir)
    .filter((name) => /^iphone_6_5_.*\.png$/.test(name))
    .sort()
    .map((name) => path.join(dir, name));
  for (const file of files) {
    await uploadScreenshot(set.id, file);
  }
}

async function latestBuild() {
  const result = await api('GET', `/v1/builds?filter[app]=${APP_ID}&filter[version]=${encodeURIComponent(VERSION)}&sort=-uploadedDate&limit=5`);
  return result.data || [];
}

async function setExportCompliance() {
  const builds = await latestBuild();
  const build = builds.find((item) => item.attributes.processingState === 'VALID') || builds[0];
  if (!build) throw new Error('No build found.');
  await api('PATCH', `/v1/builds/${build.id}`, {
    data: {
      type: 'builds',
      id: build.id,
      attributes: {
        usesNonExemptEncryption: false,
      },
    },
  });
  console.log(`Set export compliance for build ${build.id}`);
}

async function setAgeRating() {
  const info = await appInfo();
  await api('PATCH', `/v1/ageRatingDeclarations/${info.id}`, {
    data: {
      type: 'ageRatingDeclarations',
      id: info.id,
      attributes: {
        advertising: true,
        alcoholTobaccoOrDrugUseOrReferences: 'NONE',
        contests: 'NONE',
        gambling: false,
        gamblingSimulated: 'NONE',
        gunsOrOtherWeapons: 'NONE',
        healthOrWellnessTopics: false,
        kidsAgeBand: null,
        lootBox: false,
        medicalOrTreatmentInformation: 'NONE',
        messagingAndChat: false,
        parentalControls: false,
        profanityOrCrudeHumor: 'NONE',
        ageAssurance: false,
        sexualContentGraphicAndNudity: 'NONE',
        sexualContentOrNudity: 'NONE',
        horrorOrFearThemes: 'NONE',
        matureOrSuggestiveThemes: 'NONE',
        unrestrictedWebAccess: false,
        userGeneratedContent: false,
        violenceCartoonOrFantasy: 'NONE',
        violenceRealisticProlongedGraphicOrSadistic: 'NONE',
        violenceRealistic: 'NONE',
        ageRatingOverrideV2: 'NONE',
        koreaAgeRatingOverride: 'NONE',
      },
    },
  });
  console.log('Updated age rating declaration.');
}

async function setFreePrice() {
  const points = await api('GET', `/v1/apps/${APP_ID}/appPricePoints?filter[territory]=JPN&limit=20`);
  const freePoint = (points.data || []).find((point) => point.attributes.customerPrice === '0');
  if (!freePoint) throw new Error('Free price point not found.');
  await api('POST', '/v1/appPriceSchedules', {
    data: {
      type: 'appPriceSchedules',
      relationships: {
        app: { data: { type: 'apps', id: APP_ID } },
        baseTerritory: { data: { type: 'territories', id: 'JPN' } },
        manualPrices: {
          data: [{ type: 'appPrices', id: '${manual-price-0}' }],
        },
      },
    },
    included: [{
      type: 'appPrices',
      id: '${manual-price-0}',
      attributes: {
        startDate: null,
      },
      relationships: {
        appPricePoint: {
          data: { type: 'appPricePoints', id: freePoint.id },
        },
      },
    }],
  });
  console.log('Set app price to free.');
}

async function setReviewDetail() {
  const version = await appStoreVersion();
  const existing = await api('GET', `/v1/appStoreVersions/${version.id}/appStoreReviewDetail`);
  const attributes = {
    contactFirstName: process.env.REVIEW_CONTACT_FIRST_NAME,
    contactLastName: process.env.REVIEW_CONTACT_LAST_NAME,
    contactEmail: process.env.REVIEW_CONTACT_EMAIL,
    contactPhone: process.env.REVIEW_CONTACT_PHONE,
    demoAccountRequired: false,
    demoAccountName: '',
    demoAccountPassword: '',
    notes: 'No login is required. Audio generation and MIDI export can be tested directly after opening the app.',
  };
  for (const key of ['contactFirstName', 'contactLastName', 'contactEmail', 'contactPhone']) {
    if (!attributes[key]) throw new Error(`Missing ${key}. Set REVIEW_CONTACT_* env values and run again.`);
  }
  if (existing.data) {
    await api('PATCH', `/v1/appStoreReviewDetails/${existing.data.id}`, {
      data: {
        type: 'appStoreReviewDetails',
        id: existing.data.id,
        attributes,
      },
    });
    console.log('Updated review contact information.');
  } else {
    await api('POST', '/v1/appStoreReviewDetails', {
      data: {
        type: 'appStoreReviewDetails',
        attributes,
        relationships: {
          appStoreVersion: {
            data: { type: 'appStoreVersions', id: version.id },
          },
        },
      },
    });
    console.log('Created review contact information.');
  }
}

async function main() {
  const command = process.argv[2] || 'status';
  if (command === 'categories') {
    await listCategories();
    return;
  }
  if (command === 'set-basic-info') {
    const info = await appInfo();
    const version = await appStoreVersion();
    await patchAppInfo(info.id, process.env.PRIMARY_CATEGORY_ID || 'MUSIC');
    await patchApp();
    await patchVersion(version.id);
    await setPrivacyPolicy();
    console.log('Updated category, content rights, version basics, and privacy policy URL.');
    return;
  }
  if (command === 'screenshots') {
    await uploadScreenshots();
    return;
  }
  if (command === 'export-compliance') {
    await setExportCompliance();
    return;
  }
  if (command === 'age-rating') {
    await setAgeRating();
    return;
  }
  if (command === 'free-price') {
    await setFreePrice();
    return;
  }
  if (command === 'review-detail') {
    await setReviewDetail();
    return;
  }
  const info = await appInfo();
  const version = await appStoreVersion();
  const loc = await versionLocalization(version.id);
  console.log(`AppInfo ${info.id}`);
  console.log(`AppStoreVersion ${version.id} ${version.attributes.appStoreState}`);
  console.log(`Localization ${loc.id} ${loc.attributes.locale}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
