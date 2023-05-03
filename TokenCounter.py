import tiktoken
import tkinter as tk
from tkinter import simpledialog
from tkinter import messagebox

filepath = 'text.txt'

def num_tokens(text:str, model: str = 'gpt-4'):
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

def check_tokens():
    text = text_box.get("1.0", tk.END).strip()
    tokens = num_tokens(text)
    messagebox.showinfo("Token Count", f"The number of tokens in the text is: {tokens}")

def main():
    root = tk.Tk()
    root.title("Token Counter")

    root.rowconfigure(0, weight=1)  # make row 0 stretchable
    root.columnconfigure(0, weight=1)  # make column 0 stretchable

    global text_box
    text_box = tk.Text(root, wrap=tk.WORD)
    text_box.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)  # sticky="nsew" makes the Text widget stretchable

    check_button = tk.Button(root, text="Check Tokens", command=check_tokens)
    check_button.grid(row=1, column=0, pady=5)

    global token_label
    token_label = tk.Label(root, text="")
    token_label.grid(row=2, column=0, pady=5)

    root.mainloop()

if __name__ == '__main__':
    main()