DATESTRING := $(shell date +"%Y-%m-%d_%H-%M-%S")


.PHONY: all public deploy update

all: public deploy invalidate.json update clean


public: 
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

