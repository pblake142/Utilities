import os
import tiktoken

directory = '' # Insert your directory here
model = 'gpt-4' # gpt-4, gpt-3.5-turbo, and ada all use cl100k_base

# Build list of files in directory
def list_files(directory):
    file_list = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.md'): # This script currently only targets .md files, as that's the format I'm working with
                file_list.append(os.path.join(root, file))
    return file_list

# Count tokens
def count_tokens(tokens):
    return len(tokens)

def tokenize(text, model):
    encoding = tiktoken.encoding_for_model(model)
    return encoding.encode(text)

def read_and_tokenize(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            text = file.read()
        tokens = tokenize(text, model)
        return tokens
    except IOError as e:
        print(f'Error reading {file_path}: {e}')
        return []

def process_directory(directory):
    total_tokens = sum(count_tokens(read_and_tokenize(file_path)) for file_path in list_files(directory))
    total_cost = total_tokens * 0.0004 / 1000  # Calculate the cost
    return total_tokens, total_cost

total_tokens, total_cost = process_directory(directory)

print(f'The number of tokens in the {directory} directory is: {total_tokens}')
print(f'The cost of tokenizing this directory is: {total_cost}')