.PHONY: clean-dangling-images delete-image \
build push pull run run-clean

-include .env
-include version.properties

export REGISTRY=desholmes
export REPOSITORY=acr-rc-deleter

clean-dangling-images:
	@docker rmi -f $$(docker images -f 'dangling=true' -q)

delete-image:
	@docker rmi -f $(REGISTRY)/$(REPOSITORY):$(VERSION)

build:
	@make -s clean-dangling-images &
	docker build \
		--build-arg APP_VERSION="$(VERSION)" \
		-t $(REGISTRY)/$(REPOSITORY):$(VERSION) .

build-and-push:
	@make -s build
	@make -s push

push:
	docker push $(REGISTRY)/$(REPOSITORY):$(VERSION)

run:
	@make -s build
	@docker run -it \
		-e AZURE_TENANT=$(AZURE_TENANT) \
		-e AZURE_SUBSCRIPTION=$(AZURE_SUBSCRIPTION) \
		-e REGISTRY_NAME=$(REGISTRY_NAME) \
		-e REGISTRY_USERNAME=$(REGISTRY_USERNAME) \
		-e REGISTRY_PASSWORD=$(REGISTRY_PASSWORD) \
		-e REPO=$(REPO) \
		-e TAG=$(TAG) \
		-e DRY_RUN=$(DRY_RUN) \
		-v $(PWD)/untag.sh:/usr/src/untag.sh \
	$(REGISTRY)/$(REPOSITORY):$(VERSION)

run-clean:
	@make -s delete-image & make build
	@make -s run
