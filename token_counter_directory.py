import os
import tiktoken

directory = 'formatted_md/spo_pages'
file_type = '.md'
model = 'gpt-4' # Choices include gpt-4

# Build list of files in directory
def list_files(directory):
    file_list = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(f'{file_type}'):
                file_list.append(os.path.join(root, file))
    return file_list

# Count tokens
def count_tokens(tokens):
    return len(tokens)

# Tokenize text
def tokenize(text, model):
    encoding = tiktoken.encoding_for_model(model)
    return encoding.encode(text)

# Open the file and get the tokens
def read_and_tokenize(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            text = file.read()
        tokens = tokenize(text, model)
        return tokens
    except IOError as e:
        print(f'Error reading {file_path}: {e}')
        return []

# Easily comprehend size
def convert_size(size_bytes):
    if size_bytes < 1024:
        return f"{size_bytes} Bytes"
    elif size_bytes < 1048576:
        return f"{size_bytes / 1024:.2f} KB"
    elif size_bytes < 1073741824:
        return f"{size_bytes / 1048576:.2f} MB"
    else:
        return f"{size_bytes / 1073741824:.2f} GB"

# Put it all together
def process_directory(directory):
    total_tokens = 0
    total_size = 0  # Initialize total size

    for file_path in list_files(directory):
        total_size += os.path.getsize(file_path)  # Add the size of each file
        total_tokens += count_tokens(read_and_tokenize(file_path))

    total_cost = total_tokens * 0.0004 / 1000  # Calculate the cost

    return total_tokens, total_cost, total_size

total_tokens, total_cost, total_size = process_directory(directory)

print(f'The number of tokens in the {directory} directory is: {total_tokens}')
print(f'The cost of tokenizing this directory is: ${total_cost:.4f}')
print(f'Total size of data in the directory: {convert_size(total_size)}')