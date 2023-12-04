import os

current_dir = os.getcwd()
dir_above = os.path.dirname(current_dir)

def print_directory_structure(startpath, filename='directory_structure.txt'):
    with open(filename, 'w', encoding='utf-8') as file:
        for root, dirs, files in os.walk(startpath):
            level = root.replace(startpath, '').count(os.sep)
            indent = ' ' * 4 * level
            file.write(f"{indent}{os.path.basename(root)}/\n")  # Write the current directory name
            subindent = ' ' * 4 * (level + 1)
            for d in dirs:
                file.write(f"{subindent}{d}/\n")  # Write subdirectories
            for f in files:
                file.write(f"{subindent}{f}\n")  # Write files


print_directory_structure(current_dir, 'current_dir.txt')
# print_directory_structure(dir_above, 'dir_above.txt')  # Uncomment to use