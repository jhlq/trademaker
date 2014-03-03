prevhighestbids=zeros(1)
prevlowestoffers=zeros(1)
precision=0.001
sellseq=zeros(1)
buyseq=zeros(1)

function getseq(log::String)
	logfeed=open("$(log)","r")
	l=readline(logfeed)
	while !ismatch(r"(Sequence)",l) && l!=""
		l=readline(logfeed)
	end
	println(l)
	seqbegin=match(r"[0-9]",l)
	seqend=match(r"([0-9],)",l)
	seq=float(l[seqbegin.offset:seqend.offset])
	close(logfeed)
	return seq
end
function resetlog(log::String)
	log=open("$log","w")
	write(log,"0") #reset the file
	close(log)
end
	
function startrading(prevhighestbids=prevhighestbids,prevlowestoffers=prevlowestoffers, buyseq=buyseq,sellseq=sellseq)
while true
	tradethese=readdlm("trade",',')
	currencies=tradethese[:,1]
	issuers=tradethese[:,2]
	sellcurr=tradethese[:,3]
	sellforlist=convert(Array{Float64},tradethese[:,4])
	buycurr=tradethese[:,5]
	buyforlist=convert(Array{Float64},tradethese[:,6])
	spreadlims=convert(Array{Float64},tradethese[:,7])
	ncurr=length(currencies)
	tprevhighestbids=prevhighestbids
	prevhighestbids=zeros(ncurr)
	tprevlowestoffers=prevlowestoffers
	prevlowestoffers=zeros(ncurr)
	tsellseq=sellseq
	sellseq=zeros(ncurr)
	tbuyseq=buyseq
	buyseq=zeros(ncurr)
	for t in 1:min(ncurr,length(tprevhighestbids))
		prevhighestbids[t]=tprevhighestbids[t]
		prevlowestoffers[t]=tprevlowestoffers[t]
	end
	for t in 1:min(ncurr,length(tsellseq))
		sellseq[t]=tsellseq[t]
		buyseq[t]=tbuyseq[t]
	end
for cur in 1:ncurr
try
	println(currencies[cur])
###GET SPREAD
	resetlog("buyoffers.txt")
	run(`node getbuyoffers.js $(currencies[cur]) $(issuers[cur])` |> "buyoffers.txt")
	buyfeed=open("buyoffers.txt","r")
	l=readline(buyfeed)
	while !ismatch(r"(TakerGets)",l)
		l=readline(buyfeed)
		if l==""
			break;
		end
	end
	pricebegin=match(r"[0-9]",l)
	priceend=match(r"([0-9]\")",l)
	takergetsdrops=float(l[pricebegin.offset:priceend.offset])
	while !ismatch(r"(value)",l) && l!=""
		l=readline(buyfeed)
	end
	amountbegin=match(r"[0-9]",l)
	amountend=match(r"([0-9]\")",l)
	foramount=float(l[amountbegin.offset:amountend.offset])
	close(buyfeed)

	dropsperripple=1000000
	buyoffer=takergetsdrops/dropsperripple
	highestbid=buyoffer/foramount
###
	resetlog("sellprice.txt")
	run(`node getsellprice.js $(currencies[cur]) $(issuers[cur])` |> "sellprice.txt")
	sellfeed=open("sellprice.txt","r")
	l=readline(sellfeed)
	while !ismatch(r"(TakerGets)",l) && l!=""
		l=readline(sellfeed)
	end
	while !ismatch(r"(value)",l) && l!=""
		l=readline(sellfeed)
	end
	pricebegin=match(r"[0-9]",l)
	priceend=match(r"([0-9]\")",l)
	takergets=float(l[pricebegin.offset:priceend.offset])
	while !ismatch(r"(TakerPays)",l) && l!=""
		l=readline(sellfeed)
	end
	close(sellfeed)
	amountbegin=match(r"[0-9]",l)
	amountend=match(r"([0-9]\")",l)
	takerpays=float(l[amountbegin.offset:amountend.offset])

	dropsperripple=1000000
	XRPrice=takerpays/dropsperripple
	lowestoffer=XRPrice/takergets
	
	spread=lowestoffer-highestbid
	nspread=2*spread/(lowestoffer+highestbid)
	println("Spread: $spread Normalized: $nspread")
###TRADE
	dobuy=buycurr[cur]
	dosell=sellcurr[cur]
print(1)
	if nspread<spreadlims[cur]
		dobuy=false
		dosell=false
		println("Not trading: Spread too small.")
		continue
	end
print(2)
	buyfor=buyforlist[cur]
	if buyoffer/10<buyfor
		buyfor=buyoffer/10
		if buyfor<1
			dobuy=false
			println("Not trading: Too small amount.")
		end
	end
print(3)
	sell4amount=sellforlist[cur]
	if XRPrice/10<sell4amount
		sell4amount=XRPrice/10
		if sell4amount<1
			dosell=false
			println("Not trading: Too small amount.")
		end
	end
print(4)
if dobuy=="true" || dobuy==true
	amountCUR=buyfor/highestbid
#	if highestbid<(1-precision)*prevhighestbids[cur] || highestbid>(1+precision)*prevhighestbids[cur] 
		resetlog("buylog.txt")
		run(`node buyseq.js $(round(buyfor,6)) $(round(amountCUR,6)) $(currencies[cur]) $(issuers[cur]) $(int(buyseq[cur]))` |> "buylog.txt") 
		println("Sent a bid of $buyfor XRP for $amountCUR $(currencies[cur]).")
		prevhighestbids[cur]=highestbid
		seq=getseq("buylog.txt")
		buyseq[cur]=seq
#	end
end
print(5)
	#println(dosell)
if dosell=="true" || dosell==true
	botoffer=sell4amount/lowestoffer
#	if lowestoffer<(1-precision)*prevlowestoffers[cur] || lowestoffer>(1+precision)*prevlowestoffers[cur]
		resetlog("sellog.txt")
		run(`node sellseq.js $(round(sell4amount,6)) $(round(botoffer,6)) $(currencies[cur]) $(issuers[cur]) $(int(sellseq[cur]))` |> "sellog.txt") 
		println("Sent a offer of $botoffer $(currencies[cur]) for $sell4amount XRP.")
		prevlowestoffers[cur]=lowestoffer
		sellseq[cur]=getseq("sellog.txt")
#	end
end
print(6)
	bidmove=highestbid/prevhighestbids[cur]
	offermove=lowestoffer/prevlowestoffers[cur]
	println("Highestbid: $highestbid ($foramount $(currencies[cur]) for $buyoffer XRP) Change: $bidmove")
	println("Lowestoffer: $lowestoffer ($takergets $(currencies[cur]) for $XRPrice XRP) Change: $offermove")
catch er
	println(er)
end
	sleep(60)
end #for
	sleep(600)
end
end #trading
