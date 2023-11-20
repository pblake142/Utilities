import urllib.parse

def url_encode_text(text):
    return urllib.parse.quote(text)

text_to_encode = input("Enter text to URL encode: ")
encoded_text = url_encode_text(text_to_encode)
print("URL Encoded Text:", encoded_text)