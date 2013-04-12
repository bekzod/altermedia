REPORTER = dot
REMOTE_DATABASE=mongodb://nodejitsu:fb813f44c2434b9323749f86067f475c@alex.mongohq.com:10016/nodejitsudb9526573754
LOCAL_DATABASE=mongodb://localhost:27017/local

test:
	@DATABASE=$(REMOTE_DATABASE) NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--compilers coffee:coffee-script

test-w:
	@DATABASE=$(REMOTE_DATABASE) NODE_ENV=test ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--growl \
	--watch \
	--compilers coffee:coffee-script


generate-js: remove-js
	@coffee -c --bare -o lib src

generate-w-js:
	@coffee -wc --bare -o lib src

remove-js:
	@rm -fr lib/

test-local:
	@DATABASE=$(LOCAL_DATABASE) NODE_ENV=test  ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--compilers coffee:coffee-script

test-local-w:
	@DATABASE=$(LOCAL_DATABASE) NODE_ENV=test  ./node_modules/.bin/mocha \
	--reporter $(REPORTER) \
	--watch \
	--compilers coffee:coffee-script

.PHONY: test test-w