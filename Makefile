all: lint docs

lint:
	docker run --rm --name chart-testing -w /data -v $(PWD):/data quay.io/helmpack/chart-testing:v3.14.0 ct lint --config /data/ct.yaml

docs:
	docker run --rm -v "$(PWD):/workdir" -w /workdir mikefarah/yq:4 \
	  '. *= load("charts/tenant/values-docs.yaml")' \
	  charts/tenant/values.yaml \
	  > charts/tenant/.values-merged.yaml
	docker run --rm --name helm-docs -v "$(PWD):/helm-docs" jnorwood/helm-docs:v1.14.2 --sort-values-order file --chart-to-generate charts/tenant --output-file README.md --values-file .values-merged.yaml
	rm -f charts/tenant/.values-merged.yaml
	docker run --rm --name helm-docs -v "$(PWD):/helm-docs" jnorwood/helm-docs:v1.14.2 --sort-values-order file --chart-to-generate charts/project --output-file README.md --values-file values.yaml
