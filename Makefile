.PHONY: sync generate check hooks models models-check

UV := UV_CACHE_DIR=/tmp/bytes-uv-cache uv

sync:
	$(UV) sync

generate:
	$(UV) run python scripts/bytes.py generate

check:
	$(UV) run python scripts/bytes.py check

hooks:
	$(UV) run pre-commit install

models:
	$(UV) run python scripts/models.py generate

models-check:
	$(UV) run python scripts/models.py check
