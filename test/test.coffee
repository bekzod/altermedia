mongoose = require 'mongoose'
async = require 'async'

con=require('../schema.js')(process.env.DATABASE)


Segment    = con.model 'Segment'
Content    = con.model 'Content'
Player     = con.model 'Player'

segmentProps=
	startDate:(Date.now()+1000)


describe "Model Test", ->

	describe "Player Model",->
		player=null

		beforeEach (done)->
			Player.remove {},(err)->
				throw err if err 
				player=new Player({})
				player.save done

		it 'addSegmentAndSave', ->
			player.addSegmentAndSave {},(err,res)->
				player.segments.should.have.length 1
				player.segments.should.include res[0][0]._id


		it 'removeSegmentAndSave', ->
			async.series [
				(callback)->player.addSegmentAndSave {},callback
				(callback)->player.removeSegmentAndSave player.segments[0],callback
				(callback)->Segment.find callback
			],(err,res)->
				console.log player
				player.segments.should.be.empty
				res[2].should.be.empty


	# it 'addSegmentsAndSave', ->
	# 	console.log player.segments
	# # 	props=new Array(20)
	# 	props[i]=segmentProps for i in [0...props.length] 
	# 	player.addSegmentsAndSave props,(err,res)->
	# 		resids=res.map (item)-> item._id
	# 		for i in [0...props.length]
	# 			console.log player.segments[i],resids[i]
	# 			# player.segments[i].should.equal resids[i]

				





















			