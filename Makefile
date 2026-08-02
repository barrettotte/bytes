.PHONY: sync generate check hooks

UV := UV_CACHE_DIR=/tmp/bytes-uv-cache uv

sync:
	$(UV) sync

generate:
	$(UV) run python scripts/bytes.py generate

check:
	$(UV) run python scripts/bytes.py check

hooks:
	$(UV) run pre-commit install
