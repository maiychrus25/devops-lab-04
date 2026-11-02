import configparser
import json
import subprocess


inventory = json.loads(subprocess.check_output(["ansible-inventory", "--list"], text=True))
web_hosts = inventory["webservers"]["hosts"]
db_hosts = inventory["dbservers"]["hosts"]
hosts = inventory["_meta"]["hostvars"]
assert len(web_hosts) == 2 and len(db_hosts) == 1 and len(hosts) == 3
assert set(inventory["production"]["children"]) == {"webservers", "dbservers"}
assert len({data["ansible_port"] for data in hosts.values()}) == 3
for data in hosts.values():
    assert data["ansible_host"] == "127.0.0.1"
    assert data["ansible_connection"] == "ssh"
    assert "StrictHostKeyChecking=accept-new" in data["ansible_ssh_common_args"]
    assert "known_hosts_devops_lab4" in data["ansible_ssh_common_args"]
config = configparser.ConfigParser()
config.read("ansible.cfg")
assert config.getboolean("defaults", "host_key_checking")
listed = subprocess.check_output(["ansible-playbook", "playbook-full.yml", "--list-hosts"], text=True)
assert listed.count("hosts (3):") == 2
for name in hosts:
    assert listed.count(name) == 2
print("Lab configuration checks: PASS (three hosts, loopback SSH, host-key checks, all-host full playbook)")
