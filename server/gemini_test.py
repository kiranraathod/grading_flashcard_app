from google import genai

client = genai.Client(api_key="AIzaSyA2VhzYFqn4i2-Vf2gQ2md4zB57kE9vh-E")

response = client.models.generate_content(
    model="gemini-2.0-flash", contents="Explain how AI works in a few words"
)
print(response.text)