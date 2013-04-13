_ = require 'underscore'

exports.sync = (dominant,secondary)->

	same   = _.intersection dominant,secondary
	remove = _.difference secondary,same
	add    = _.difference dominant,same
	
	{
		same
		remove
		add
	}

	