import requests
import os
import base64
from dotenv import dotenv_values
import json

print("Pastebin is limited to 20 posts per 24 hrs per user!  Find a way to decode base64 directly from github or else deal with limitations of pastebin.")

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

# pastebins = requests.get(f"https://api.github.com/repos/TheCakeOfRice/computercraft/contents/ci_pipeline/pastebins.json?ref=mulungus-server")
# print(pastebins.text)
# content = base64.b64decode(pastebins.json()["content"]).decode('utf-8')
# print(content)
