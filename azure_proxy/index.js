const express = require('express');
const multer = require('multer');
const axios = require('axios');
const cors = require('cors');

const app = express();
const upload = multer();
app.use(cors());

const AZURE_ENDPOINT = 'https://ai-mnabeelbhatti6415ai493572554025.openai.azure.com/computervision/imageanalysis:analyze?api-version=2023-04-01&features=caption';
const AZURE_KEY = 'C25DDyKtg5LlVwGypjLeLTISStdCmD8X0NWOVRjWAWhNYUHiEbFTJQQJ99BDACHYHv6XJ3w3AAAAACOGdmp5';

app.post('/caption', upload.single('image'), async (req, res) => {
  try {
    const response = await axios.post(
      AZURE_ENDPOINT,
      req.file.buffer,
      {
        headers: {
          'Content-Type': 'application/octet-stream',
          'Ocp-Apim-Subscription-Key': AZURE_KEY,
        },
      }
    );
    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: err.toString(), details: err.response?.data });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Proxy server running on port ${PORT}`)); 