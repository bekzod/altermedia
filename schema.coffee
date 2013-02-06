module.exports=(Schema,db,async)->
	ObjectId =Schema.Types.ObjectId
	

	# 
	# Content
	# 
	content=new Schema
		contentId:Number
		name:String
		status:String
		description:String


	# 
	# Transaction
	# 
	transtion=new Schema
		name:String
		duration:Number


	

	# 
	# Segment
	# 
	segment=new Schema
		# id:{type: String,index: {unique: true, dropDups: true}}
		totalDuration:Number
		playDuration:Number
		startDate:Number
		endDate:Number
		startOffset:Number
		transtions:
			showTranstion:{type:ObjectId,ref:'Transtion'}
			hideTranstion:{type:ObjectId,ref:'Transtion'}
			showAnimDuration:Number
			hideAnimDuration:Number
		content:{type:ObjectId,ref:'Content'}
		,
			toJSON:{getters:true,virtual: true,_id:false}

	



	# 
	# Player
	# 
	player=new Schema
		name:String
		description:String
		lastSync:Date
		segments:[{type:ObjectId,ref:'Segment',index:{unique:true,dropDups:true}}]
		content:[{type:ObjectId,ref:'Content',index:{unique:true,dropDups:true}}]


	player.methods.getSegmentsWhichStillPlaying=(cb)->
		now=Date.now()
		self=@
		db.model('Segment').find
			'_id': { $in:self.segments}
			'endDate': { $gte:Date.now()} 
			,cb

	player.methods.removeSegmentAndSave=(segmentId,cb)->
		self=@
		Segment=db.model 'Segment' 
		@segments.remove(segmentId)
		
		async.parallel [
			(callback)->Segment.remove {_id:segmentId},callback 
			(callback)->self.save callback
		],cb


	player.methods.removeSegmentsAndSave=(segmentIds,cb)=>
		self=@
		Segment=db.model 'Segment' 
		@segments.remove(segmentId)
		
		async.parallel [
			(callback)->db.model('Segment').remove {_id:{$in:segmentId}},callback 
			(callback)->self.save callback
		],cb


	player.methods.addSegmentAndSave=(prop,cb)->
		self=@
		Segment=db.model 'Segment' 
		
		newseg=new Segment prop 
		@segments.push newseg._id
		
		async.parallel [
			(callback)->newseg.save callback
			(callback)->self.save callback
		],cb


	player.methods.addSegmentsAndSave=(props,cb)->
		self=@
		Segment=db.model 'Segment' 
		
		async.map props,(prop,callback)->
			newseg=new Segment prop 
			@segments.push segment._id 
			newseg.save callback
		,(err,res)->
			self.save cb&&cb err,res




	Transtion: db.model("Transition",transtion)
	Segment:   db.model("Segment",segment)
	Content:   db.model("Content",content)
	Player:    db.model("Player",player)



