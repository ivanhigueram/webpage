DATESTRING := $(shell date +"%Y-%m-%d_%H-%M-%S")


CV_SRC := ../cv/main.pdf
CV_DST := static/cv.pdf

.PHONY: all public deploy update sync-cv

all: sync-cv public deploy invalidate.json update clean

sync-cv:
	@if [ -f $(CV_SRC) ]; then \
		echo "Syncing CV from $(CV_SRC) -> $(CV_DST)"; \
		cp $(CV_SRC) $(CV_DST); \
	else \
		echo "Warning: $(CV_SRC) not found, leaving $(CV_DST) untouched"; \
	fi

public: sync-cv
	echo "Building website!"
	hugo build

deploy: public
	echo "Copying public/ to S3"
	aws s3 cp public/ ${PUBLIC_S3_BUCKET} --recursive

invalidate.json:
	echo '{ \
	  "Paths": { \
	    "Quantity": 1, \
	    "Items": ["/*"] \
	  }, \
	  "CallerReference": "$(DATESTRING)" \
	}' > invalidate.json

update: invalidate.json
	aws cloudfront create-invalidation \
		--distribution-id ${DISTRIBUTION_ID} \
		--invalidation-batch file://invalidate.json

.PHONY: clean
	rm invalidate.json
	rm -r ./public

