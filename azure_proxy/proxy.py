from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

AZURE_ENDPOINT = 'https://ai-mnabeelbhatti6415ai493572554025.openai.azure.com/computervision/imageanalysis:analyze?api-version=2023-04-01&features=caption'
AZURE_KEY = 'C25DDyKtg5LlVwGypjLeLTISStdCmD8X0NWOVRjWAWhNYUHiEbFTJQQJ99BDACHYHv6XJ3w3AAAAACOGdmp5'

@app.route('/caption', methods=['POST'])
def caption():
    image = request.files['image']
    headers = {
        'Content-Type': 'application/octet-stream',
        'Ocp-Apim-Subscription-Key': AZURE_KEY,
    }
    resp = requests.post(AZURE_ENDPOINT, headers=headers, data=image.read())
    return (resp.content, resp.status_code, resp.headers.items())

if __name__ == '__main__':
    app.run(port=3000) 