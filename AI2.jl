#Article describing this code: http://jhlq.wordpress.com/2014/06/09/ripple-ml-2/

function transpatinvari(d) #spatially invariant transform
	dn=d/maximum(abs(d))
	nd=length(dn)
	if nd%2==0
		push!(dn,0)
		nd+=1
	end
	t=zeros(nd)
	for da in 1:nd
		for dat in 0:nd-da
			t[1+dat]+=dn[da]*simil(dn[da],dn[da+dat])
		end
	end
	return t
end
using JSON
function rsample()
	start=1000*abs(rand(Int)%100)
	trades=JSON.parse(readall(`curl https://ripple.com/chart/BTC/XRP/trades.json?since=$start`))
	#trades=JSON.parse(get("https://ripple.com/chart/BTC/XRP/trades.json?since=$start").data) #Requests package
	np=100
	peek=zeros(np,2)
	for t in 1:np
		peek[t,1]=float(trades[t]["price"])
		peek[t,2]=float(trades[t]["amount"])*(0.5+0.5*t/100)
	end
	ma=maximum(peek[:,1])
	mi=minimum(peek[:,1])
	niv=33
	bars=zeros(niv)
	intervall=(ma-mi)/niv
	for t in 1:np
		for iv in 1:niv
			if peek[t,1]<mi+intervall*iv
				bars[iv]+=peek[t,2]
				break
			end
		end
	end
	maxi=sortperm(bars,rev=true)
	bidiv1=maxi[1]*intervall+mi
	bidiv2=maxi[2]*intervall+mi

	bid1val=0
	bid2val=0
	barval=0
	for testi in 101:1000
		test=[float(trades[testi]["price"]),float(trades[testi]["amount"])]
		for iv in 1:niv
			if test[1]<bidiv1 && test[1]>bidiv1-intervall
				bid1val+=test[2]
				break
			elseif test[1]<bidiv2 && test[1]>bidiv2-intervall
				bid2val+=test[2]
				break
			end
		end
		if bid1val>1 && bid2val>1
			println(testi)
			barval=1-(testi-101)/900
			break
		end
	end
	return transpatinvari(bars),barval
end
function rsamples(ns)
	tbarsa=Array(Array,ns)
	barvals=Array(Float64,ns)
	for i in 1:ns
		tbarsa[i],barvals[i]=rsample()
	end
	return tbarsa,barvals
end
function makenet(nil,nml,nol)
	net=Array(Array,3)
	net[1]=zeros(nil,nml)+rand(nil,nml).-0.5
	net[2]=zeros(nml,nol)+rand(nml,nol).-0.5
	net[3]=[nil,nml,nol]
	return net
end
function sigmoid(x)
	return x/(abs(x)+1)
end
function sigmoid(x::Array)
	return x./(abs(x)+1)
end
function feed(net,d) #nets eat data
	(nil,nml,nol)=net[end][1],net[end][2],net[end][3]
	
	td=zeros(nml)
	for n in 1:nml
		td[n]=dot(net[1][:,n],d)
	end
	s=zeros(nol)
	for n in 1:nol
		s[n]=abs(sigmoid(dot(net[2][:,n],td)))
	end
	return s
end
function simil(v1,v2)
	1-abs((v1-v2))
end
type Mutator
	scoreimps::Array
	net
end
function init(il=33,ml=50,ol=1) #input layer, middle layer, output layer
	net=makenet(il,ml,ol)
	m=Mutator(Array(Array,2),net)
	m.scoreimps[1]=ones(Float64,il,ml)
	m.scoreimps[2]=ones(Float64,ml,ol)
	return m
end
function score(net::Array,tbars::Array{Float64},bval::Number)
	pred=feed(net,tbars)
	tscore=simil(sum(pred),bval)
end
function score(net::Array,tbars::Array{Array},bvals::Array)
	ns=length(bvals)
	scores=zeros(Float64,ns)
	for i in 1:ns
		scores[i]=score(net,tbars[i],bvals[i])
	end
	return scores
end
function poke!(m::Mutator,tbars::Array{Float64},bval::Number,mf=0.1)
	tscore=score(m.net,tbars,bval)

	layer=1
	if randbool()
		layer=2
	end
	
	s=sum(m.scoreimps[layer])
	r=abs(rand(Float64)*s)
	rn=1 # random neuron
	ra=1 # random axon
	ts=0
	b=false
	for i in 1:length(m.scoreimps[layer][:,1])
		for j in 1:length(m.scoreimps[layer][1,:])
			ts+=m.scoreimps[layer][i,j]
			
			if ts>r
				rn=i
				ra=j
				b=true
				break
			end
		end
		if b==true
			break
		end
	end
	ov=m.net[layer][rn,ra]
	m.net[layer][rn,ra]=mod(m.net[layer][rn,ra]+mf+1,2)-1
	nscore=score(m.net,tbars,bval)
	if nscore>tscore
		m.scoreimps[layer][rn,ra]=nscore-tscore
	else
		m.net[layer][rn,ra]=mod(m.net[layer][rn,ra]-2mf+1,2)-1
		nscore=score(m.net,tbars,bval)
		if nscore>tscore
			m.scoreimps[layer][rn,ra]=nscore-tscore
		else 
			m.net[layer][rn,ra]=ov
			m.scoreimps[layer][rn,ra]=minimum(m.scoreimps[layer])
			#print_with_color(:cyan,"Connection $layer $rn $ra settled at $(net[layer][rn,ra]).")
		end
	end
	return m.scoreimps[layer][rn,ra]
end
function poke!(m::Mutator,tbars::Array{Array},bval::Array,mf=0.1)
	ns=length(bval)
	for i in 1:ns
		poke!(m,tbars[i],bval[i],mf)
	end
end
function evolve(m::Mutator,tbarsa::Array{Array},barvals::Array{Float64},numit,mf=0.1)
	bestm=deepcopy(m)
	bestscore=sum(score(m.net,tbarsa,barvals))
	println(bestscore)
	for it in 1:numit
		poke!(m,tbarsa,barvals,mf)
		s=sum(score(m.net,tbarsa,barvals))
		if s>bestscore
			println(s)
			bestscore=s
			bestm=deepcopy(m)
		end
	end
	return bestm
end
