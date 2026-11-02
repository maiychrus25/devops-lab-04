.PHONY: build test lint

build:
	ansible-inventory --graph
	ansible-playbook playbook-webserver.yml --syntax-check
	ansible-playbook playbook-full.yml --syntax-check
	@echo "Build succeeded"

test:
	PYTHONDONTWRITEBYTECODE=1 python3 scripts/check_lab.py
	PYTHONDONTWRITEBYTECODE=1 python3 scripts/check_cleanup.py

lint:
	ansible-playbook playbook-webserver.yml --syntax-check
	ansible-playbook playbook-full.yml --syntax-check
	bash -n scripts/setup.sh scripts/cleanup.sh
	node scripts/check-docs.js
