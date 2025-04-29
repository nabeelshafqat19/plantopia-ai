import requests

# Aapka naya endpoint aur API key
endpoint = "https://ai-mnabeelbhatti-7510-plantopia.cognitiveservices.azure.com/vision/v3.2/analyze"
api_key = "8FbfA3r3SAf7VR5E3zhGRNFYsO42nY6zOnfnJgwGZrf7yXPwNvfiJQQJ99BDAC5RqLJXJ3w3AAAAACOGf9dr"

# Image ka path
image_path = r"C:\Users\Personal 3\Pictures\screen.png"

# Image ko read karo
with open(image_path, "rb") as f:
    image_data = f.read()

# Request ka Header
headers = {
    "Ocp-Apim-Subscription-Key": api_key,
    "Content-Type": "application/octet-stream"
}

# Parameters jo humko caption chahiye
params = {
    "visualFeatures": "Description"
}

# Send request
response = requests.post(
    endpoint,
    headers=headers,
    params=params,
    data=image_data
)

# Check response
if response.status_code == 200:
    result = response.json()
    captions = result["description"]["captions"]
    if captions:
        print("Generated Caption:", captions[0]["text"])
    else:
        print("Koi caption nahi mila.")
else:
    print(f"Error: {response.status_code}")
    print(response.text)
