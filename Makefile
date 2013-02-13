REPORTER = spec

test:
	@DATABASE=mongodb://nodejitsu:fb813f44c2434b9323749f86067f475c@alex.mongohq.com:10016/nodejitsudb9526573754 \
	@NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \

test-w:
	@DATABASE=mongodb://nodejitsu:fb813f44c2434b9323749f86067f475c@alex.mongohq.com:10016/nodejitsudb9526573754 \
	@NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--growl \
	--watch


test-local:
	@DATABASE=mongodb://localhost:27017/local NODE_ENV=test  ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \

test-local-w:
	@DATABASE=mongodb://localhost:27017/local NODE_ENV=test  ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--watch

.PHONY: test test-w