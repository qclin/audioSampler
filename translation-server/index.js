///NOT USED 

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Imports the Google Cloud client library
const Translate = require('@google-cloud/translate');

// Your Google Cloud Platform project ID
const projectId = 'audiosampler-2a090';

// Instantiates a client
const translateClient = Translate({
  projectId: projectId
});


// List of output languages.
const LANGUAGES = ['en', 'es', 'de', 'fr', 'sv', 'ga', 'it', 'jp'];
//
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



function createTranslationPromise(source, target, snapshot){
    const key = snapshot.key;
    const message = snapshot.val().text
}


// The text to translate
const text = 'Hello, world!';
// The target language
const target = 'zh-TW';

// Translates some text into Russian
translateClient.translate(text, target)
  .then((results) => {
    const translation = results[0];

    console.log(`Text: ${text}`);
    console.log(`Translation: ${translation}`);
  });
