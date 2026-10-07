all: lint docs test-vrl

# Keep in sync with the kitapp chart's audit.image.tag.
VECTOR_VERSION ?= 0.59.0

clean-locks:
	find ./charts -maxdepth 2 -name "Chart.lock" -delete

lint: clean-locks
	docker run --rm --name chart-testing -w /data -v $(PWD):/data quay.io/helmpack/chart-testing:v3.14.0 \
		sh -c "helm repo add kvalitetsit https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/ && ct lint --config /data/ct.yaml"

docs:
	docker run --rm -v "$(PWD):/workdir" -w /workdir mikefarah/yq:4 \
	  '. *= load("charts/tenant/values-docs.yaml")' \
	  charts/tenant/values.yaml \
	  > charts/tenant/.values-merged.yaml
	docker run --rm --name helm-docs -v "$(PWD):/helm-docs" jnorwood/helm-docs:v1.14.2 --sort-values-order file --chart-to-generate charts/tenant --output-file README.md --values-file .values-merged.yaml
	rm -f charts/tenant/.values-merged.yaml
	docker run --rm --name helm-docs -v "$(PWD):/helm-docs" jnorwood/helm-docs:v1.14.2 --sort-values-order file --chart-to-generate charts/project --output-file README.md --values-file values.yaml

test-vrl:
	VECTOR_VERSION=$(VECTOR_VERSION) ./scripts/test-auditlog-vrl.sh
