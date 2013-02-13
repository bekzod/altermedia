REPORTER = spec
REMOTE_DATABASE=mongodb://nodejitsu:fb813f44c2434b9323749f86067f475c@alex.mongohq.com:10016/nodejitsudb9526573754
LOCAL_DATABASE=mongodb://localhost:27017/local

test:
	@DATABASE=$(REMOTE_DATABASE) NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \

test-w:
	@DATABASE=$(REMOTE_DATABASE) NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--growl \
	--watch


test-local:
	@DATABASE=$(LOCAL_DATABASE) NODE_ENV=test  ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \

test-local-w:
	@DATABASE=$(LOCAL_DATABASE) NODE_ENV=test  ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--watch

.PHONY: test test-w