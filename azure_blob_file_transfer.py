from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv
import os

# Small utility to transfer files between two blob storage containers in Azure

load_dotenv()

# Get the connection strings from the environment variables
connection_string_source = os.getenv('CONNECTION_STRING_SOURCE')
connection_string_destination = os.getenv('CONNECTION_STRING_DESTINATION')

# Set the container names
source_container = os.getenv('SOURCE_CONTAINER')
destination_container = os.getenv('DESTINATION_CONTAINER')

# Create the BlobServiceClient object which will be used to create a container client
blob_service_client_source = BlobServiceClient.from_connection_string(connection_string_source)

def transfer_files(source_container, destination_container, source_file, destination_file):
    connection_string = "<your_connection_string>"
    
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    
    source_blob_client = blob_service_client.get_blob_client(container=source_container, blob=source_file)
    destination_blob_client = blob_service_client.get_blob_client(container=destination_container, blob=destination_file)
    
    with source_blob_client.open_read() as source_file_data:
        destination_blob_client.upload_blob(source_file_data)
    
    print("File transfer completed successfully.")

# Usage example:
transfer_files("source_container", "destination_container", "source_file.txt", "destination_file.txt")
