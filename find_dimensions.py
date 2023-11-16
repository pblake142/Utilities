import os
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

file_path = ''

def read_markdown(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            text = file.read()
        return text
    except IOError as e:
        print(f'Error reading {file_path}: {e}')
        return []

def get_embedding_dimension(model_name, text):
    response = openai.Embedding.create(input=text, model=model_name)
    embedding = response['data'][0]['embedding']
    return len(embedding)

# Replace 'text-embedding-ada-002' with the actual model name if different
dimensionality = get_embedding_dimension('text-embedding-ada-002', text=read_markdown(file_path))
print(f"The dimensionality of the model is: {dimensionality}")
