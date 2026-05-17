const fs = require('fs');
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

async function getOrCreateVersion() {
  const path = `/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]=${encodeURIComponent(VERSION)}&limit=1`;
  const existing = await api('GET', path);
  if (existing.data?.length) return existing.data[0];

  return (await api('POST', '/v1/appStoreVersions', {
    data: {
      type: 'appStoreVersions',
      attributes: {
        platform: 'IOS',
        versionString: VERSION,
      },
      relationships: {
        app: {
          data: {
            type: 'apps',
            id: APP_ID,
          },
        },
      },
    },
  })).data;
}

async function latestBuild() {
  const path = `/v1/builds?filter[app]=${APP_ID}&sort=-uploadedDate&limit=5`;
  const builds = await api('GET', path);
  return builds.data || [];
}

async function linkedBuild(versionId) {
  const rel = await api('GET', `/v1/appStoreVersions/${versionId}/relationships/build`);
  return rel.data || null;
}

async function linkBuild(versionId, buildId) {
  await api('PATCH', `/v1/appStoreVersions/${versionId}/relationships/build`, {
    data: {
      type: 'builds',
      id: buildId,
    },
  });
}

async function submit(versionId) {
  const submission = (await api('POST', '/v1/reviewSubmissions', {
    data: {
      type: 'reviewSubmissions',
      attributes: {
        platform: 'IOS',
      },
      relationships: {
        app: {
          data: {
            type: 'apps',
            id: APP_ID,
          },
        },
      },
    },
  })).data;

  await api('POST', '/v1/reviewSubmissionItems', {
    data: {
      type: 'reviewSubmissionItems',
      relationships: {
        reviewSubmission: {
          data: {
            type: 'reviewSubmissions',
            id: submission.id,
          },
        },
        appStoreVersion: {
          data: {
            type: 'appStoreVersions',
            id: versionId,
          },
        },
      },
    },
  });

  await api('PATCH', `/v1/reviewSubmissions/${submission.id}`, {
    data: {
      type: 'reviewSubmissions',
      id: submission.id,
      attributes: {
        submitted: true,
      },
    },
  });

  return submission;
}

async function main() {
  const command = process.argv[2] || 'status';
  const version = await getOrCreateVersion();
  const builds = await latestBuild();
  const linked = await linkedBuild(version.id);

  console.log(`App ID: ${APP_ID}`);
  console.log(`Version: ${version.attributes.versionString}`);
  console.log(`Version state: ${version.attributes.appStoreState}`);
  console.log(`Version ID: ${version.id}`);
  console.log(`Linked build: ${linked ? linked.id : 'none'}`);
  for (const build of builds) {
    console.log(`Build ${build.id}: version ${build.attributes.version}, number ${build.attributes.buildNumber}, state ${build.attributes.processingState}, uploaded ${build.attributes.uploadedDate}`);
  }

  if (command === 'link-build') {
    const build = builds.find((item) => item.attributes.processingState === 'VALID') || builds[0];
    if (!build) throw new Error('No uploaded build found yet.');
    await linkBuild(version.id, build.id);
    console.log(`Linked build ${build.id} to version ${version.id}`);
  }

  if (command === 'submit-review') {
    const submission = await submit(version.id);
    console.log(`Submitted for review: ${submission.id}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
