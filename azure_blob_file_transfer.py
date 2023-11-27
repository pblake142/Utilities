from azure.storage.fileshare import ShareClient
from dotenv import load_dotenv
import os

# Utility to transfer files between two blob storage containers in Azure

load_dotenv()

# Get the connection strings from the env
source_connection_string = os.getenv('CONNECTION_STRING_SOURCE')
dest_connection_string = os.getenv('CONNECTION_STRING_DESTINATION')

# Get the share names from the env
source_share_name = os.getenv('SOURCE_SHARE')
dest_share_name = os.getenv('DEST_SHARE')

# Create share clients for both source and destination
source_share_client = ShareClient.from_connection_string(source_connection_string, share_name=source_share_name)
dest_share_client = ShareClient.from_connection_string(dest_connection_string, share_name=dest_share_name)

def build_directory_structure(source_share_client, directory_name=''):
    structure = {}

    items = list(source_share_client.list_directories_and_files(directory_name=directory_name))

    for item in items:
        if item.is_directory:
            structure[item.name] = build_directory_structure(source_share_client, f"{directory_name}/{item.name}".strip('/'))
        else:
            structure[item.name] = None
    
    return structure

def ensure_directory_exists(client, directory_path):

    # Establish directory client from share client
    directory_client = client.get_directory_client(directory_path)
    try:
        directory_client.get_directory_properties()
    except Exception as e:
        print(f"Directory '{directory_path}' does not exist, attempting to create. Error: {e}")
        try:
            directory_client.create_directory()
            print(f"Directory '{directory_path}' created.")
        except Exception as e:
            print(f"Failed to create directory '{directory_path}'. Error: {e}")

def copy_files_between_shares(source_share_client, dest_share_client, structure, current_path=''):

    for item_name, contents in structure.items():
        full_path = f"{current_path}/{item_name}".strip('/')
        print(f"Full path: {full_path}")

        if contents is None:
            try:
                source_file_path = full_path
                destination_file_path = source_file_path

               # Determine the parent directory path for the destination file
                parent_directory_path = '/'.join(destination_file_path.split('/')[:-1])

                # Ensure the parent directory exists
                ensure_directory_exists(dest_share_client, parent_directory_path)

                print(f"Copying file {source_file_path} to {destination_file_path}")

                # Create a new file client for the destination and upload the file
                dest_file_client = dest_share_client.get_file_client(destination_file_path)
                source_file_client = source_share_client.get_file_client(source_file_path)

                download_stream = source_file_client.download_file()
                file_content = download_stream.readall()
                dest_file_client.upload_file(file_content)
                print(f"File {source_file_path} copied to {destination_file_path}")

            except Exception as ex:
                print(f"Error copying {source_file_path} Exception: {ex}")
        else:
            copy_files_between_shares(source_share_client, dest_share_client, contents, current_path=full_path)

directory_structure = build_directory_structure(source_share_client)
copy_files_between_shares(source_share_client, dest_share_client, directory_structure, current_path='')

# print(f"Directory structure: {directory_structure}")


