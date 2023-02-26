find ./rngs/ | sort | tail -n +2 | jq --raw-input . | jq --slurp . > slideshow.json
