mongoose = require 'mongoose'
async = require 'async'

con=require('../schema.js')(process.env.DATABASE)


Segment    = con.model 'Segment'
Content    = con.model 'Content'
Player     = con.model 'Player'


describe "Model Test", ->

	describe "Player Model",->
		player=null

		beforeEach (done)->
			async.series [
				(cb)->Player.remove {},cb
				(cb)->Segment.remove {},cb
				],(err,res)->
					player=new Player {name:"bekzod"} 
					player.save done
					

		it 'addSegmentAndSave', (done)->
			player.addSegmentAndSave {},(err,res)->
				throw err if err 
				player.segments.should.have.lengthOf 1
				player.segments.should.include res[0][0]._id
				done()


		it 'removeSegmentAndSave',(done)->
			async.series [
				(callback)->player.addSegmentAndSave {},callback
				(callback)->player.removeSegmentAndSave player.segments[0],callback
				(callback)->Segment.find callback
			],(err,res)->
				throw err if err 
				player.segments.should.be.empty
				res[2].should.be.empty
				done()


		it 'addSegmentsAndSave', (done)->
			player.addSegmentsAndSave [{},{},{}],(err,res)->
				throw err if err 
				player.segments.should.have.lengthOf 3
				done();


		it 'removeSegmentsAndSave',(done)->
			async.series [
				(callback)->player.addSegmentsAndSave [{},{},{}],callback
				(callback)->
					segs=player.segments.map (id)-> id
					player.removeSegmentsAndSave segs,callback
				(callback)->Segment.find callback
			],(err,res)->
				throw err if err
				# console.log player.segments
				# player.segments.should.be.empty
				# res[2].should.be.empty
				done()
					





















		# 	