import { response } from 'express';
import https from 'https';
// this is needed for default trusted list of CAs
import tls from 'tls';
// for reading files
import fs from 'fs';
 
//  Get dot env
import dotenv from 'dotenv';
dotenv.config();
 
 
export async function getAccessToken() {
  const url: string = process.env.HM_TOKEN_URI || 'empty';
  const clientId = process.env.HM_CLIENT_ID;
  const clientSecret = process.env.HM_CLIENT_SECRET;
  try {
    if (process.env.ENVIRONMENT === 'local_dev') {
      let path = process.env.NODE_EXTRA_CA_CERTS!;
      const additionalCert = fs.readFileSync(path, 'utf8');
      https.globalAgent.options.ca = [
        ...tls.rootCertificates,
        additionalCert,
      ];
    }
 
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      }),
    },
    );
 
    console.log('SUCCESS');
  } catch (e) {
    console.log('ERRPR', e);
  }
}
 
getAccessToken();