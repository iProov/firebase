import functions from 'firebase-functions';
import admin from 'firebase-admin';
import { getAuth } from 'firebase-admin/auth';
import axios from 'axios';
import Joi from 'joi';
import { google } from 'googleapis';
const iamcredentials = google.iamcredentials('v1');

const GATEWAY_URL = process.env.GATEWAY_URL ?? 'https://europe-west2-iproov-firebase-gateway.cloudfunctions.net/firebase-gateway';
const PROJECT_ID = JSON.parse(process.env.FIREBASE_CONFIG).projectId;
const INSTANCE_ID = process.env.EXT_INSTANCE_ID;

admin.initializeApp();

export const getToken = functions.https.onCall(async (data, context) => {

  const schema = Joi.object({
    userId: Joi.string().required(),
    claimType: Joi.string().valid('enrol', 'verify').required(),
    assuranceType: Joi.string().valid('genuine_presence', 'liveness').optional(), // GPA is the default
  });

  const { error } = schema.validate(data);
  if (error) {
    throw new functions.https.HttpsError('invalid-argument', error);
  }

  try {
    const result = await post({
      method: 'token',
      claimType: data.claimType,
      userId: data.userId,
      assuranceType: data.assuranceType ?? 'genuine_presence',
    });

    return result;
  } catch (error) {
    handleError(error);
  }
});

export const validate = functions.https.onCall(async (data, context) => {

  const schema = Joi.object({
    userId: Joi.string().required(),
    token: Joi.string().required(),
    claimType: Joi.string().valid('enrol', 'verify').required(),
  });

  const { error } = schema.validate(data);
  if (error) {
    throw new functions.https.HttpsError('invalid-argument', error);
  }

  let result;

  try {
    result = await post({
      method: 'validate',
      claimType: data.claimType,
      userId: data.userId,
      token: data.token,
    });
  } catch (error) {
    handleError(error);
  }

  if (result.passed) {
    try {
      const firebaseToken = await getAuth().createCustomToken(data.userId);
      return firebaseToken;
    } catch (error) {
      handleError(error);
    }
  } else {
    throw new functions.https.HttpsError('permission-denied', 'iProov validation failed');
  }
});

function handleError(error) {
  console.log(error);
  const response = error.response?.data;

  if (typeof response === 'string' || response instanceof String) {
    throw new functions.https.HttpsError('unknown', response);
  } else {
    throw new functions.https.HttpsError('unknown', error.message);
  }
}

async function post(payload) {
  const jwt = await signJwt(payload);

  // console.log(jwt);

  const result = await axios.post(GATEWAY_URL, jwt, { headers: { 'Content-Type': 'text/plain' } });
  return result.data;
}

async function signJwt(payload) {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });

  const authClient = await auth.getClient();

  const serviceAccount = `ext-${INSTANCE_ID}@${PROJECT_ID}.iam.gserviceaccount.com`;

  const request = {
    name: `projects/-/serviceAccounts/${serviceAccount}`,
    resource: {
      payload: JSON.stringify({
        iss: serviceAccount,
        sub: serviceAccount,
        region: process.env.REGION,
        aud: GATEWAY_URL,
        ...payload
      })
    },
    auth: authClient,
  };

  const response = await iamcredentials.projects.serviceAccounts.signJwt(request);
  return response.data.signedJwt;
}