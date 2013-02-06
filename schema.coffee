module.exports=(Schema,db)->
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


	player.methods.removeSegmentAndSave=(segmentId,cb)->
		db.model('Segment').remove {_id:segmentId} 
		@segments.remove(segmentId)
		@save cb


	player.methods.removeSegmentsAndSave=(segmentIds,cb)->
		db.model('Segment').remove {_id:{$in:segmentId}} 
		@segments.remove(segmentId)
		@save cb


	player.methods.addSegmentAndSave=(prop,cb)->
		Segment=db.model('Segment')
		newseg=new Segment(props) 
		@segments.push(segment._id)
		newseg.save();
		@save cb


	player.methods.addSegmentsAndSave=(props,cb)->
		Segment=db.model('Segment')
		for prop in props
			newseg=new Segment(props) 
			@segments.push(segment._id)
			newseg.save();
		@save cb




	Transtion: db.model("Transition",transtion)
	Segment:   db.model("Segment",segment)
	Content:   db.model("Content",content)
	Player:    db.model("Player",player)



