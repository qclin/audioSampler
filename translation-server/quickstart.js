// Imports the Google Cloud client library
const Translate = require('@google-cloud/translate');

// Your Google Cloud Platform project ID
const projectId = 'audiosampler-2a090';

// Instantiates a client
const translateClient = Translate({
  projectId: projectId
});

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
