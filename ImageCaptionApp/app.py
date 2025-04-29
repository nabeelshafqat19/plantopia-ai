import os
from flask import Flask, render_template, request
from werkzeug.utils import secure_filename
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential

app = Flask(__name__)

# Upload folder setup
UPLOAD_FOLDER = os.path.join('static', 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Azure credentials
endpoint = "https://ai-mnabeelbhatti-7510-plantopia.cognitiveservices.azure.com/"
key = "8FbfA3r3SAf7VR5E3zhGRNFYsO42nY6zOnfnJgwGZrf7yXPwNvfiJQQJ99BDAC5RqLJXJ3w3AAAAACOGf9dr"

# Azure client
client = ImageAnalysisClient(
    endpoint=endpoint,
    credential=AzureKeyCredential(key)
)

@app.route("/", methods=["GET", "POST"])
def index():
    caption_text = None
    if request.method == "POST":
        uploaded_file = request.files.get("image_file")
        if uploaded_file:
            filename = secure_filename(uploaded_file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            uploaded_file.save(filepath)

            # **OPEN FILE as binary for Azure API**
            with open(filepath, "rb") as f:
                image_data = f.read()

            # Send image bytes instead of URL
            result = client.analyze(
                image_data=image_data,
                visual_features=[VisualFeatures.CAPTION],
                gender_neutral_caption=True
            )

            if result.caption is not None:
                caption_text = f"'{result.caption.text}', Confidence: {result.caption.confidence:.4f}"

    return render_template("index.html", caption=caption_text)

if __name__ == "__main__":
    app.run(debug=True)
