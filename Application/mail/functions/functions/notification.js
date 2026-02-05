const { google } = require('googleapis');
const readline = require('readline');

const CLIENT_ID = '277812411619-fi5tvc08sie7oku8qcipl7rnkihmpgns.apps.googleusercontent.com';
const CLIENT_SECRET = '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';
const REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob';

const oAuth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  REDIRECT_URI
);

const SCOPES = ['https://mail.google.com/'];

const authUrl = oAuth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: SCOPES,
});

console.log('Authorize this app by visiting this url:', authUrl);

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question('Enter the code from that page here: ', (code) => {
  oAuth2Client.getToken(code, (err, token) => {
    if (err) return console.error('Error retrieving access token', err);
    console.log('Refresh Token:', token.refresh_token);
    rl.close();
  });
});
