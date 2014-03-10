function getdepth(orderbook::String)
	takergets=zeros(99)
	takerpays=zeros(99)
	oc=0
	bookfeed=open("$(orderbook)","r")
	l=readline(bookfeed)
	while l!=""
		l=readline(bookfeed)
		if ismatch(r"(\"TakerGets\": {)",l)  
			while !ismatch(r"(\"value\":)",l) 
				l=readline(bookfeed)
			end
#			println(l)
			tgbegin=match(r"[0-9]",l)
			tgend=match(r"([0-9]\")",l)
			oc+=1
			takergets[oc]=float(l[tgbegin.offset:tgend.offset])
			while !ismatch(r"(\"TakerPays\":)",l) 
				l=readline(bookfeed)
			end
			tpbegin=match(r"[0-9]",l)
			tpend=match(r"([0-9]\")",l)
			takerpays[oc]=float(l[tpbegin.offset:tpend.offset])/1e6	
		end
		if oc==99
			break
		end
	end
	close(bookfeed)
	takergets=takergets[1:oc]
	takerpays=takerpays[1:oc]
	return takergets,takerpays
end
