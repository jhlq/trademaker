using JSON
#using Requests
function rsample()
	start=1000*abs(rand(Int)%100)
	trades=JSON.parse(readall(`curl https://ripple.com/chart/BTC/XRP/trades.json?since=$start`))
	#trades=JSON.parse(get("https://ripple.com/chart/BTC/XRP/trades.json?since=$start").data)
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
	return bars,barval
end
function makenet(nil,nml,nol)
	net=Array(Array,3)
	net[1]=zeros(nil,nml)+rand(nil,nml).-0.5
	net[2]=zeros(nml,nol)+rand(nml,nol).-0.5
	net[3]=[nil,nml,nol]#ones(3)+rand().-0.5
	return net
end
function sigmoid(x)
	return x/(abs(x)+1)
end
function sigmoid(x::Array)
	return x./(abs(x)+1)
end
function feed(net,d)
	(nil,nml,nol)=net[end][1],net[end][2],net[end][3]
	
	td=zeros(nml)
	for n in 1:nml
		td[n]=dot(net[1][:,n],d)
	end
	s=zeros(nol)
	for n in 1:nol
		s[n]=sigmoid(dot(net[2][:,n],td))
	end
	return s
end
function simil(v1,v2)
	1-abs((v1-v2))
end
function transpatinvari(d)
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
type Mutator
	mutfac::Array
	scoreimps::Array
	ilmlol
	bestimprov
	net
	data
	target
end
function init(il=33,ml=50,ol=3)
	net=makenet(il,ml,ol)
	m=Mutator(Array(Array,2),Array(Array,2),[il,ml,ol],0,0,0,0)
	m.mutfac[1]=(ones(Float64,il,ml)+rand(il,ml).-0.5).+(-2.*int(randbool(il,ml)))
	m.mutfac[2]=(ones(Float64,ml,ol)+rand(ml,ol).-0.5).+(-2.*int(randbool(ml,ol)))
	m.scoreimps[1]=ones(Float64,il,ml)
	m.scoreimps[2]=ones(Float64,ml,ol)
	return net,m
end
function randcon(il,ml,ol)
	l=1
	n=1
	a=1
	if randbool()
		l=2
		n=abs(rand(Int64))%ml
		a=abs(rand(Int64))%ol
	else
		n=abs(rand(Int64))%il
		a=abs(rand(Int64))%ml
	end
	return l,n,a
end		

function netco(m::Mutator,i::Integer)
	(il,ml,ol)=m.ilmlol
	l=1
	n=1
	if i>il
		if i>il+ml
			l=3
			n=i-il-ml
			print_with_color(:red,"Too high index.")
		else
			l=2
			n=i-il
		end
	else
		n=i
	end
	return l,n
end
function poke!(net::Array,m::Mutator,numit::Int64=3)
	(bars,bval)=rsample()
	il,ml,ol=m.ilmlol
	tbars=transpatinvari(bars)
	pred=feed(net,tbars)
	tscore=simil(sum(pred)/3,bval)
	score=tscore
	s1=sum(m.scoreimps[1])
	s2=sum(m.scoreimps[2])
	m1=maximum(m.scoreimps[1])
	m2=maximum(m.scoreimps[2])

	for n in 1:numit

	r=[abs(rand(Float64)*s1),abs(rand(Float64)*s2)]
	ri=1
	rn=[1,1]
	ra=[1,1]
	ts=0
	#println(r)
	for layer in 1:2
		ts=0
		b=false
		for i in 1:length(m.scoreimps[layer][:,1])
			
			#print("$ts, ")
			for j in 1:length(m.scoreimps[layer][1,:])
				ts+=m.scoreimps[layer][i,j]
				
				if ts>r[layer]
					rn[layer]=i
					ra[layer]=j
					b=true
					break
				end
			end
			if b==true
				break
			end
		end
	end

	#l,n,a=randcon(il,ml,ol)
	#println("$rn,$ra")
	
	for layer in 1:2
		score=simil(sum(feed(net,tbars))/3,bval)
		ov=net[layer][rn[layer],ra[layer]]
		net[layer][rn[layer],ra[layer]]*=m.mutfac[layer][rn[layer],ra[layer]]
		nscore=simil(sum(feed(net,tbars))/3,bval)
		if nscore>score
			#m.pokesult[ri]+=1
			m.scoreimps[layer][rn[layer],ra[layer]]=nscore-score
			println(1)
		else
			net[layer][rn[layer],ra[layer]]=net[layer][rn[layer],ra[layer]]/(-m.mutfac[layer][rn[layer],ra[layer]])
			nscore=simil(sum(feed(net,tbars))/3,bval)
			if nscore>score
				#m.pokesult[ri]+=1
				m.mutfac[layer][rn[layer],ra[layer]]=-m.mutfac[layer][rn[layer],ra[layer]]
				m.scoreimps[layer][rn[layer],ra[layer]]=nscore-score
				println(2)
			else 
				net[layer][rn[layer],ra[layer]]*=m.mutfac[layer][rn[layer],ra[layer]]*1.1
				nscore=simil(sum(feed(net,tbars))/3,bval)
				if nscore>score
					m.mutfac[layer][rn[layer],ra[layer]]*=1.1
					m.scoreimps[layer][rn[layer],ra[layer]]=nscore-score
					println(3)
				else 
					net[layer][rn[layer],ra[layer]]*=m.mutfac[layer][rn[layer],ra[layer]]*0.9
					nscore=simil(sum(feed(net,tbars))/3,bval)
					if nscore>score
						m.mutfac[layer][rn[layer],ra[layer]]*=0.9
						m.scoreimps[layer][rn[layer],ra[layer]]=nscore-score
						println(4)
					else 
						m.mutfac[layer][rn[layer],ra[layer]]*=rand()*6-3
						m.scoreimps[layer][rn[layer],ra[layer]]=minimum(m.scoreimps[layer])*0.5
						net[layer][rn[layer],ra[layer]]=ov
					end
				end
			end
		end
	end
	
	end

	net[1]=sigmoid(net[1])
	net[2]=sigmoid(net[2])
	m.mutfac[1]=5*sigmoid(m.mutfac[1])
	m.mutfac[2]=5*sigmoid(m.mutfac[2])
	pred=feed(net,tbars)
	return simil(sum(pred)/3,bval)-tscore

end
	
function evolve2(net=makenet(33,50,3),gens=3,its=9)
	scores=Array(Array,gens)
	for gen in 1:gens
		
	end
end
