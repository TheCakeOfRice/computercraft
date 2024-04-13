import requests
import os

readme = requests.get(f"https://api.github.com/repos/TheCakeOfRice/computercraft/contents/ci_pipeline/pastebins.txt?ref=mulungus-server")
print(readme.text)
# Loops through all .lua files
for cpu_folder in os.listdir("./computers"):
    for filename in os.listdir(f"./computers/{cpu_folder}"):
        # Check if the current file is a regular file (not a directory)
        if filename.endswith(".lua"):
            # Do something with the file
            print(f"{cpu_folder}: {filename}")
# POST to pastebin
# publish .txt of map of file to pastebin hashes