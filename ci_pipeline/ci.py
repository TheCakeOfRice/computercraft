import os
import shutil
import json
from pygit2 import Repository

#####
# GITHUB VERSION
#####

base_url = "https://api.github.com/repos/TheCakeOfRice/computercraft/contents"
branch_name = Repository('.').head.shorthand

file_map = {}
for cpu_name in os.listdir("./computers"):
    # Init list for cpu_name
    file_map[cpu_name] = []

    # Propagate cd_pipeline to all computers
    try:
        os.mkdir(f"./computers/{cpu_name}/_cd_pipeline")
    except FileExistsError:
        pass

    for filename in os.listdir("./cd_pipeline"):
        if filename.endswith(".lua"):
            shutil.copy(f"./cd_pipeline/{filename}", f"./computers/{cpu_name}/_cd_pipeline/_{filename}")
            print(f"Found .lua file at ./computers/{cpu_name}/_cd_pipeline/_{filename}?ref={branch_name}")

            # Construct github api urls for .lua files in _cd_pipeline
            file_map[cpu_name].append(f"{base_url}/computers/{cpu_name}/_cd_pipeline/_{filename}?ref={branch_name}")

    # Loop through all other .lua files and construct github api urls
    for filename in os.listdir(f"./computers/{cpu_name}"):
        if filename.endswith(".lua"):
            print(f"Found .lua file at ./computers/{cpu_name}/{filename}?ref={branch_name}")
            file_map[cpu_name].append(f"{base_url}/computers/{cpu_name}/{filename}?ref={branch_name}")

# Publish .json of map of file to url
with open("ci_pipeline/file_map.json", "w") as outfile:
    json.dump(file_map, outfile, indent=4)

### USAGE
# import requests
# import base64
# pastebins = requests.get(f"https://api.github.com/repos/TheCakeOfRice/computercraft/contents/ci_pipeline/file_map.json?ref=mulungus-server")
# print(pastebins.text)
# content = base64.b64decode(pastebins.json()["content"]).decode('utf-8')
# print(content)


#####
# PASTEBIN (MANUAL IMPORT) VERSION
#####

# print("Pastebin is limited to 20 posts per 24 hrs per user!  Find a way to decode base64 directly from github or else deal with limitations of pastebin.")

# from dotenv import dotenv_values
# env_vars = dotenv_values("ci_pipeline/.env")
# pastebin_api_key = env_vars.get("PASTEBIN_API_KEY")
# if not pastebin_api_key: raise Exception("api key failed to read from .env")

# # Loops through all .lua files
# pastebin_map = {}
# for cpu_folder in os.listdir("./computers"):
#     pastebin_map[cpu_folder] = {}
#     for filename in os.listdir(f"./computers/{cpu_folder}"):
#         if filename.endswith(".lua"):
#             # grab file contents
#             with open(os.path.join(f"./computers/{cpu_folder}/{filename}"), "r") as lua_file:
#                 text = lua_file.read()
            
#             # POST to pastebin
#             data = {
#                 "api_dev_key": pastebin_api_key,
#                 "api_option": "paste",
#                 "api_paste_code": text,
#                 "api_paste_expire_date": "1H",
#             }
#             response = requests.post("https://pastebin.com/api/api_post.php", data=data)
#             if response.status_code == 200:
#                 print(f"Posted {cpu_folder}: {filename} to pastebin at {response.text}")
#                 pastebin_map[cpu_folder][filename] = response.text
#             else:
#                 print(f"Failed to post {cpu_folder}: {filename} to pastebin!  HTTP status {response.status_code}")
#                 print(response.text)

# # # publish .json of map of file to pastebin hashes
# with open("ci_pipeline/pastebins.json", "w") as outfile:
#     json.dump(pastebin_map, outfile)
