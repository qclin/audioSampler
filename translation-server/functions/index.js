'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);
const request = require('request-promise');

// List of output languages.
const LANGUAGES = ['en', 'ar', 'es', 'de', 'fr', 'ja', 'zh-TW'];
// Translate an incoming message.
exports.translate = functions.database.ref('/messages/{languageID}/{messageID}').onWrite(event => {
  const snapshot = event.data;
  if (snapshot.val().translated) {
    return;
  }
  const promises = [];
  for (let i = 0; i < LANGUAGES.length; i++) {
    var language = LANGUAGES[i];
    if (language !== event.params.languageID) {
      promises.push(createTranslationPromise(event.params.languageID, language, snapshot));
    }
  }
  return Promise.all(promises);
});

// URL to the Google Translate API.
function createTranslateUrl(source, target, payload) {
    var requestURL = `https://www.googleapis.com/language/translate/v2?key=${functions.config().firebase.apiKey}&source=${source}&target=${target}&q=${payload}`;
    console.log("here is requestURL----- ", requestURL)
  return requestURL
}

function createTranslationPromise(source, target, snapshot) {
  const key = snapshot.key;
  const message = snapshot.val().text;
  return request(createTranslateUrl(source, target, message), {resolveWithFullResponse: true}).then(
      response => {
        if (response.statusCode === 200) {
          const data = JSON.parse(response.body).data;
          console.log("here's translated text -----", data, data.translations[0].translatedText)
          return admin.database().ref(`/messages/${target}/${key}`)
              .set({text: data.translations[0].translatedText, translated: true});
        }
        throw response.body;
      });
}
