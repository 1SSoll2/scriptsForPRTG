import site
site.addsitedir(r"C:\Users\USER\AppData\Roaming\Python\Python313\site-packages")
# 라이브러리 인식시키기
import paramiko
import json
import re
import sys

SERVER_IP = 'IP'
USERNAME = 'linuxUserID'
PASSWORD = 'linuxUserPw'
JEUS_USER = 'jeusUserID'
JEUS_PASS = 'jeusUserPw'
JEUS_SERVER = 'jeusServer'
JEUS_ADMIN_PATH = '~/jeus9/bin/jeusadmin'
channel_info = [
    {"key": "NumberofProcessors", "name": "Number of Processors", "type": "integer", "kind": "count", "id": 10},
    {"key": "SystemCPULoad", "name": "System CPU Load", "type": "float", "kind": "percent_cpu", "id": 11},
    {"key": "ThreadCount", "name": "Thread Count", "type": "integer", "kind": "count", "id": 12},
    {"key": "ProcessCPULoad", "name": "Process CPU Load", "type": "float", "kind": "percent_cpu", "id": 13},
    {"key": "CurrentUsedHeapMemoryRatio", "name": "Heap Memory Usage", "type": "float", "kind": "percent", "id": 14},
    {"key": "UpTime", "name": "UpTime", "type": "integer", "kind": "time_seconds", "id": 15}
]
def fetch_jeus_output():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(SERVER_IP, username=USERNAME, password=PASSWORD)
        jeus_cmd = f"echo -e 'connect -u {JEUS_USER} -p {JEUS_PASS}\\nsystem-info {JEUS_SERVER}\\nexit' | {JEUS_ADMIN_PATH}"
        stdin, stdout, stderr = client.exec_command(jeus_cmd)
        output = stdout.read().decode()
        client.close()
        return output, None
    except Exception as e:
        return None, str(e)

def parse_output(output):
    pattern = re.compile(r"\|\s*(.*?)\s*\|\s*(.*?)\s*\|")
    matches = pattern.findall(output)
    data = {}
    for key, value in matches:
        key = key.strip().replace(" ", "").replace("_", "")
        value = value.strip()
        if key.lower() not in ("key", "value"):
            data[key] = value
    return data

def build_prtg_v2_json(info_dict):
    channels = []
    for item in channel_info:
        raw_val = info_dict.get(item["key"], "0")
        value = re.sub(r"[^\d.]", "", raw_val)
        try:
            val = float(value)
            if item["type"] == "integer":
                val = int(val)
        except:
            continue
        channel = {
            "id": item["id"],
            "name": item["name"],
            "type": item["type"],
            "value": val,
            "kind": item["kind"]
        }
        channels.append(channel)

    return {
        "version": 2,
        "status": "ok",
        "message": f"JEUS server : {JEUS_SERVER}",
        "channels": channels
    }

output, err = fetch_jeus_output()

if err:
    result = {
        "version": 2,
        "status": "error",
        "message": f"SSH/JEUS Connection Error : {err}"
    }
else:
    info = parse_output(output)
    result = build_prtg_v2_json(info)

print(json.dumps(result, ensure_ascii=False))
sys.exit(0 if result.get("status") == "ok" else 1)
